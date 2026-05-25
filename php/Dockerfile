FROM ubuntu:24.04

ARG USERNAME=omni
ARG USER_UID=1000
ARG USER_GID=1000
ARG TZ=Asia/Jakarta

ENV PHP_VERSIONS="5.6 7.0 7.1 7.2 7.3 7.4 8.0 8.1 8.2 8.3 8.4 8.5"
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=${TZ}

RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    ca-certificates \
    nano \
    curl \
    wget \
    git \
    zsh \
    zip \
    unzip \
    gnupg \
    lsb-release \
    sudo \
    locales \
    tzdata \
    build-essential \
    procps \
    iproute2 \
    iputils-ping \
    openssh-client \
    bash-completion \
  && locale-gen en_US.UTF-8 \
  && update-locale LANG=en_US.UTF-8 \
  && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
  && echo $TZ > /etc/timezone \
  && rm -rf /var/lib/apt/lists/*

RUN add-apt-repository ppa:ondrej/php && apt-get update

ARG PHP_EXTENSIONS="common cli fpm mbstring xml curl zip gd intl bcmath opcache \
  mysql pgsql sqlite3 redis mongodb xdebug soap memcached"

RUN for VERSION in $PHP_VERSIONS; do \
      PKGS=""; \
      for EXT in $PHP_EXTENSIONS; do \
        PKGS="${PKGS} php${VERSION}-${EXT}"; \
      done; \
      apt-get install -y --no-install-recommends php${VERSION} $PKGS || true; \
    done \
  && rm -rf /var/lib/apt/lists/*

RUN update-alternatives --set php /usr/bin/php8.3

RUN for VERSION in $PHP_VERSIONS; do \
      ln -sf /usr/bin/php${VERSION} /usr/local/bin/php$(echo $VERSION | tr -d .); \
    done

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

RUN if getent group $USER_GID >/dev/null; then \
      old_group=$(getent group $USER_GID | cut -d: -f1); \
      groupmod -n $USERNAME $old_group; \
    else \
      groupadd -g $USER_GID $USERNAME; \
    fi \
  && if getent passwd $USER_UID >/dev/null; then \
      old_user=$(getent passwd $USER_UID | cut -d: -f1); \
      usermod -l $USERNAME $old_user; \
      usermod -d "/home/$USERNAME" -m $USERNAME; \
    else \
      useradd -m -u $USER_UID -g $USER_GID -s /bin/bash $USERNAME; \
    fi \
  && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN mkdir -p "/home/$USERNAME/.config" \
  && mkdir -p "/home/$USERNAME/.local/share" \
  && mkdir -p "/home/$USERNAME/.local/state" \
  && chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/.config" \
  && chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/.local"

RUN curl -sS https://starship.rs/install.sh | sh -s -- -y

USER $USERNAME

ENV NVM_DIR="/home/$USERNAME/.nvm"

RUN mkdir -p $NVM_DIR \
  && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash \
  && . $NVM_DIR/nvm.sh \
  && nvm install 22 \
  && nvm install 20 \
  && nvm alias default 22 \
  && nvm use default \
  && npm install -g pnpm yarn

RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

RUN sudo chsh -s $(which zsh) $USERNAME

RUN NONINTERACTIVE=1 \
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
  && /home/linuxbrew/.linuxbrew/bin/brew install gcc

ENV OPENCODE_INSTALL_DIR="/home/$USERNAME/.local"
ENV PATH="${OPENCODE_INSTALL_DIR}/bin:${PATH}"

RUN mkdir -p ${OPENCODE_INSTALL_DIR} \
  && curl -fsSL https://opencode.ai/install | bash

RUN git clone https://github.com/zsh-users/zsh-autosuggestions \
${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions \
  && git clone https://github.com/zsh-users/zsh-syntax-highlighting \
${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

RUN sed -i 's/plugins=(git)/plugins=(git composer laravel zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc \
  && echo '\n\
bindkey "^[OB" down-line-or-search\n\
bindkey "^[OC" forward-char\n\
bindkey "^[OD" backward-char\n\
bindkey "^[OF" end-of-line\n\
bindkey "^[OH" beginning-of-line\n\
bindkey "^[[1~" beginning-of-line\n\
bindkey "^[[3~" delete-char\n\
bindkey "^[[4~" end-of-line\n\
bindkey "^[[5~" up-line-or-history\n\
bindkey "^[[6~" down-line-or-history\n\
bindkey "^?" backward-delete-char\n\
bindkey "^[[A" up-line-or-search\n\
bindkey "^[[B" down-line-or-search\n\
bindkey "^[[C" forward-char\n\
bindkey "^[[D" backward-char\n\
bindkey "^[[H" beginning-of-line\n\
bindkey "^[[F" end-of-line\n\
bindkey "^ " autosuggest-accept' >> ~/.zshrc

RUN echo '\n\
export NVM_DIR="$HOME/.nvm"\n\
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"\n\
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"\n' >> ~/.zshrc \
  && echo '\n\
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.zshrc \
  && echo '\n\
eval "$(starship init zsh)"' >> ~/.zshrc

RUN starship preset catppuccin-powerline -o ~/.config/starship.toml \
  && sed -i 's/pallete = .*/pallete = "catppuccin_macchiato"/' ~/.config/starship.toml

USER root

RUN for VERSION in $PHP_VERSIONS; do \
      mkdir -p /run/php; \
      sed -i "s|listen = /run/php/php${VERSION}-fpm.sock|listen = 90$(echo $VERSION | tr -d .)|g" \
        "/etc/php/${VERSION}/fpm/pool.d/www.conf" 2>/dev/null || true; \
    done

COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

RUN chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/.config" \
  && chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/.local"

WORKDIR /var/www

USER $USERNAME

CMD ["/usr/local/bin/start.sh"]
