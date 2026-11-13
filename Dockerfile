FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG FLUTTER_VERSION=3.44.0

ARG USER_UID=1000
ARG USER_GID=1000
ARG USER_NAME=dev

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

ENV FLUTTER_HOME=/opt/flutter
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_HOME=/opt/android-sdk

ENV PATH="${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/emulator:${PATH}"

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    git \
    unzip \
    zip \
    xz-utils \
    libglu1-mesa \
    libgtk-3-0 \
    libstdc++6 \
    libc6 \
    lib32z1 \
    lib32stdc++6 \
    libpulse0 \
    libnss3 \
    libx11-6 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxi6 \
    libxrandr2 \
    libxrender1 \
    libxtst6 \
    libasound2t64 \
    openjdk-17-jdk \
    python3 \
    python3-pip \
    make \
    gcc \
    g++ \
    pkg-config \
    sudo \
    && rm -rf /var/lib/apt/lists/*

RUN git clone \
    --branch ${FLUTTER_VERSION} \
    --depth 1 \
    https://github.com/flutter/flutter.git \
    ${FLUTTER_HOME}

RUN flutter config --no-analytics \
    && flutter precache

RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools \
    && curl -fsSL \
       https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip \
       -o /tmp/cmdline-tools.zip \
    && unzip -q /tmp/cmdline-tools.zip \
       -d ${ANDROID_SDK_ROOT}/cmdline-tools \
    && mv ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools \
       ${ANDROID_SDK_ROOT}/cmdline-tools/latest \
    && rm /tmp/cmdline-tools.zip

RUN yes | sdkmanager --licenses >/dev/null || true

RUN sdkmanager \
    "platform-tools" \
    "platforms;android-35" \
    "build-tools;35.0.0" \
    "cmdline-tools;latest" \
    "emulator" \
    "system-images;android-35;google_apis;x86_64"

RUN flutter config --android-sdk ${ANDROID_SDK_ROOT}

RUN dart --disable-analytics

RUN dart pub global activate melos

RUN apt-get update && apt-get install -y --no-install-recommends \
    xvfb \
    x11vnc \
    x11-utils \
    fluxbox \
    libgl1 \
    libegl1 \
    libgles2 \
    libdrm2 \
    libxcb-cursor0 \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL \
       https://github.com/novnc/noVNC/archive/refs/tags/v1.5.0.tar.gz \
       -o /tmp/novnc.tar.gz \
    && mkdir -p /opt/novnc \
    && tar -xzf /tmp/novnc.tar.gz --strip-components=1 -C /opt/novnc \
    && rm /tmp/novnc.tar.gz

RUN pip3 install --break-system-packages websockify

ENV DISPLAY=:99

WORKDIR /workspace

COPY docker/dev-entrypoint.sh /usr/local/bin/dev-entrypoint.sh
RUN chmod +x /usr/local/bin/dev-entrypoint.sh

RUN userdel -r ubuntu 2>/dev/null || true

RUN groupadd --gid ${USER_GID} ${USER_NAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} --groups sudo \
       --create-home --shell /bin/bash ${USER_NAME} \
    && echo "${USER_NAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USER_NAME} \
    && chmod 0440 /etc/sudoers.d/${USER_NAME}

RUN chown -R ${USER_UID}:${USER_GID} /opt/flutter /opt/android-sdk \
    && mkdir -p /home/${USER_NAME}/.pub-cache \
                 /home/${USER_NAME}/.gradle \
                 /home/${USER_NAME}/.android \
    && chown -R ${USER_UID}:${USER_GID} /home/${USER_NAME}

USER ${USER_NAME}
WORKDIR /home/${USER_NAME}

ENV PUB_CACHE="/home/${USER_NAME}/.pub-cache"
ENV PATH="${PUB_CACHE}/bin:${PATH}"

RUN flutter config --no-analytics \
    && flutter config --android-sdk ${ANDROID_SDK_ROOT} \
    && dart --disable-analytics \
    && dart pub global activate melos

WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/dev-entrypoint.sh"]
CMD ["bash"]
