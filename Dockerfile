FROM alpine:latest

# 通用准备工作，以及Linux版
RUN apk upgrade && \
    apk add --no-cache curl git scons pkgconf gcc g++ libx11-dev libxcursor-dev libxinerama-dev libxi-dev libxrandr-dev mesa-dev eudev-dev alsa-lib-dev pulseaudio-dev

# Windows环境
RUN apk add mingw-w64-gcc

# Android环境
RUN apk add openjdk17 && \
    mkdir -p android-sdk && cd ~/android-sdk && \
    curl -LO https://googledownloads.cn/android/repository/commandlinetools-linux-14742923_latest.zip && \
    unzip commandlinetools-linux-14742923_latest.zip && \
    rm commandlinetools-linux-14742923_latest.zip && \
    yes | cmdline-tools/bin/sdkmanager --sdk_root="/root/sdk" --licenses && \
    cmdline-tools/bin/sdkmanager --sdk_root="/root/sdk" "platform-tools" "build-tools;35.0.1" "platforms;android-35" "cmdline-tools;latest" "cmake;3.10.2.4988404" "ndk;28.1.13356709"

# Web环境
RUN git clone https://github.com/emscripten-core/emsdk.git && \
    cd emsdk && \
    ./emsdk install latest && \
    ./ensdk activate latest && \
    source ./emsdk_env.sh

    
