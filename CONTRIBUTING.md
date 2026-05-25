# Contributing

Thanks for considering contributing to Omni!

## How to Contribute

### Report a Bug

Open a [GitHub Issue](https://github.com/ortudev/omni/issues/new?template=bug_report.md)
and include:

- Your OS and Docker version
- Steps to reproduce
- Expected vs actual behavior
- Relevant logs or error output

### Suggest a Feature

Open a [GitHub Issue](https://github.com/ortudev/omni/issues/new?template=feature_request.md)
and describe:

- What problem the feature solves
- How you envision it working
- Any alternative approaches you've considered

### Submit a Pull Request

1. Fork the repository
2. Create a feature branch (`git checkout -b feat/my-change`)
3. Make your changes
4. Test that everything still builds:
   ```bash
   docker compose build --no-cache php
   docker compose build --no-cache node
   docker compose build --no-cache caddy
   ```
5. Commit with a clear message
6. Push and open a PR against `main`

### Style Guide

- Keep the same directory structure and naming conventions
- Use environment variables for anything user-configurable
- Document new services or config options in `README.md` and `.env.example`
- Avoid hardcoding paths, ports, or credentials
