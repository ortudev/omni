FROM caddy:latest

ARG USERNAME=omni
ARG USER_UID=1000
ARG USER_GID=1000
ARG TZ=Asia/Jakarta

ENV TZ=${TZ}

RUN apk add --no-cache tzdata \
    && addgroup -g ${USER_GID} ${USERNAME} \
    && adduser -D -u ${USER_UID} -G ${USERNAME} ${USERNAME}

USER ${USERNAME}
