# Omni — Full-Stack Local Development Environment

A containerized development workspace that gives you everything you need to build **PHP** and **Node.js** applications locally. Spin up multiple PHP versions simultaneously, serve projects through **Caddy** with automatic HTTPS, and access **MySQL**, **MongoDB**, **Redis**, and email testing — all with a single `docker compose up`.

## Features

- **PHP 5.6 - 8.5** — All 12 versions run in parallel via PHP-FPM, each on its own port. Switch per project without rebuilding.
- **Node.js 20 & 22** — via NVM, plus [Bun](https://bun.sh/), pnpm, and yarn.
- **Caddy reverse proxy** — Automatic local TLS certificates, PHP-FPM proxying, Node dev server proxying, and per-site config files.
- **Databases** — MySQL, MongoDB, and Redis, all with persistent storage.
- **Email testing** — [Mailpit](https://github.com/axllent/mailpit) catches all outbound email (SMTP + web UI at `mailpit.localhost`).
- **Dev tooling** — Composer 2, Xdebug, Oh My Zsh + Starship prompt, Homebrew, [OpenCode AI CLI](https://opencode.ai).
- **No permission issues** — Containers run with your host UID/GID. Files you create inside the container belong to you on the host.
- **Minimal setup** — Clone, copy `.env.example` → `.env`, adjust paths, `docker compose up`.

## Architecture

```
                         ┌──────────────┐
                         │   Caddy :80  │  ← Reverse proxy, TLS, logging
                         │   :443       │
                         └──────┬───────┘
                                │
               ┌────────────────┼──────────────────┐
               │                │                  │
        ┌──────▼──────┐   ┌─────▼──────┐   ┌────────▼─────────┐
        │   PHP-FPM   │   │  Node.js   │   │  Infrastructure  │
        │ 5.6 .. 8.5  │   │ NVM, Bun   │   │                  │
        │ :9081..9085 │   │ pnpm, yarn │   │  MySQL :3306     │
        │ Composer    │   │            │   │  Mongo :27017    │
        │ Xdebug      │   │            │   │  Redis :6379     │
        └─────────────┘   └────────────┘   │  Mailpit :1025   │
                                           │  Arcane          │
                                           └──────────────────┘
```

## Getting Started

### Prerequisites

- Docker & Docker Compose (v2)

### Setup

```bash
# 1. Clone the repository
git clone https://github.com/ortudev/omni.git omni
cd omni

# 2. Copy the environment template
cp .env.example .env

# 3. Edit .env to match your system
#    Set PROJECTS_PATH to where your code lives
#    Set HOME_PATH to your home directory
#    Adjust USER_UID / USER_GID if needed (run `id -u` and `id -g`)

# 4. Start everything
docker compose up -d

# 5. (Optional) Trust Caddy's local CA for zero-browser-warning HTTPS
docker compose exec caddy caddy trust
```

Your projects live at `$PROJECTS_PATH` (mounted into `/var/www` in every workspace container).

### Adding a New Project

Drop a `.caddy` file in `caddy/conf.d/`:

```caddy
# ── Laravel app ──
myapp.localhost {
    import logging myapp.localhost

    root * /var/www/myapp/public
    try_files {path} {path}/ /index.php?{query}

    php_fastcgi php:9084 {
        root /var/www/myapp/public
    }

    file_server
    encode gzip
}
```

Then reload Caddy without restarting:

```bash
docker compose exec -w /etc/caddy caddy caddy reload
```

See `caddy/conf.d/` for examples (PHP, Node, and tool services).

## Service Details

### PHP (`php`)

Based on **Ubuntu 24.04** with all PHP versions from the [ondrej/php](https://launchpad.net/~ondrej/+archive/ubuntu/php) PPA.

| PHP Version | FPM Port |
|-------------|----------|
| 5.6         | 9056     |
| 7.0         | 9070     |
| 7.1         | 9071     |
| 7.2         | 9072     |
| 7.3         | 9073     |
| 7.4         | 9074     |
| 8.0         | 9080     |
| 8.1         | 9081     |
| 8.2         | 9082     |
| 8.3         | 9083     |
| 8.4         | 9084     |
| 8.5         | 9085     |

The default `php` CLI is 8.3. Switch per-command with `php8.2`, `php8.4`, etc., or use symlinks like `php84`.

**PHP configuration** is managed via `php/conf/`:
- `common.ini` — Shared settings for all versions (memory limit, upload size, etc.)
- `dev.ini` — Development mode (display errors, assertions enabled)
- `xdebug.ini` — Xdebug configuration (debug + develop mode)

These are symlinked into each PHP version's `conf.d/` at startup.

### Node (`node`)

Based on **Ubuntu 24.04** with:

- Node.js 20 and 22 via NVM
- pnpm, yarn (npm global packages)
- Bun runtime
- Oh My Zsh + Starship prompt (Catppuccin theme)
- Homebrew for additional tooling

Run your dev server inside the container. Make sure it binds to `0.0.0.0` (not `127.0.0.1`) so Docker networking can reach it.

### Caddy (`caddy`)

Reverse proxy with automatic TLS via [Caddy's `local_certs`](https://caddyserver.com/docs/automatic-https#local-https). Per-site configuration is done by placing `.caddy` files in `caddy/conf.d/`. The main `Caddyfile` imports them all:

```caddy
import /etc/caddy/conf.d/*.caddy
```

- Admin API available at `caddy:2019` for live config reloads
- Logs written to `logs/caddy/` with rotation (100 MiB per file, keep 10)
- Error-level logging by default to reduce noise

### MySQL (`mysql`)

- Custom config at `mysql/conf.d/my.cnf` (utf8mb4, strict SQL mode)
- Persistent data stored at `$DATA_PATH/mysql`
- Init SQL scripts in `mysql/databases/` are available at `/databases/` inside the container

### MongoDB (`mongo`)

- Authentication enabled (configure credentials in `.env`)
- Persistent data at `$DATA_PATH/mongo`

### Redis (`redis`)

- Append-only persistence enabled
- Password-protected (configure in `.env`)
- Persistent data at `$DATA_PATH/redis`

### Mailpit (`mailpit`)

- SMTP server on port 1025 (catch-all)
- Web UI on port 8025 (proxied at `mailpit.localhost`)
- No configuration needed — just point your app to `mailpit:1025`

### Arcane (`arcane`)

[Docker management dashboard](https://github.com/getappmap/arcane). Accessible at `arcane.localhost` when configured in a Caddy site block.

## Environment Variables

All configuration lives in `.env`. See `.env.example` for a complete reference.

| Variable | Description |
|---|---|
| `USERNAME`, `USER_UID`, `USER_GID` | Container user matching your host user |
| `PROJECTS_PATH` | Path to your code on the host |
| `DATA_PATH` | Where persistent data lives (databases, caddy data) |
| `TIMEZONE` | Container timezone |
| `CADDY_HTTP_PORT`, `CADDY_HTTPS_PORT` | Ports for the reverse proxy |
| `MYSQL_*`, `MONGO_*`, `REDIS_*` | Database credentials and ports |
| `MAILPIT_HTTP_PORT`, `MAILPIT_SMTP_PORT` | Mailpit ports |
| `ARCANE_ENCRYPTION_KEY`, `ARCANE_JWT_SECRET` | Arcane secrets |

## Tips

- **SSH keys**: `~/.ssh` is mounted from the host — no need to regenerate keys inside the container.
- **Multiple PHP versions**: Reference the correct FPM port in your Caddy config (see table above).
- **Caddy reload**: After adding/changing a `.caddy` file, run `docker compose exec -w /etc/caddy caddy caddy reload`.
- **Workspace shells**: Jump into PHP or Node containers with `docker compose exec php zsh` or `docker compose exec node zsh`.
- **Logs**: Container logs go to `logs/<service>/`. Caddy access/error logs are here too.
- **Database imports**: Copy SQL files to `mysql/databases/`; they're available at `/databases/` inside the MySQL container.
