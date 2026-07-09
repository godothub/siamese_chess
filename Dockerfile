FROM alpine:latest

WORKDIR /root

ARG GODOT_VERSION="4.6.1"

ARG RELEASE_NAME="stable"

ARG GODOT_TEST_ARGS=""
ARG GODOT_PLATFORM="linux.x86_64"
ARG SIAMESECHESS_ANDROID_USER=""
ARG SIAMESECHESS_ANDROID_PASSWORD=""
ARG SIAMESECHESS_ANDROID_DNAME=""

# 通用准备工作，以及Linux版
RUN apk update \
 && apk add --no-cache curl wget zip git git-lfs scons pkgconf gcc g++ libatomic libx11-dev libxcursor-dev libxinerama-dev libxi-dev libxrandr-dev mesa-dev eudev-dev alsa-lib-dev pulseaudio-dev mingw-w64-gcc

# Web环境
RUN git clone https://github.com/emscripten-core/emsdk.git \
 && emsdk/emsdk install latest \
 && emsdk/emsdk activate latest

# 部分程序参考项目：https://github.com/abarichello/godot-ci
RUN wget https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}-${RELEASE_NAME}/Godot_v${GODOT_VERSION}-${RELEASE_NAME}_${GODOT_PLATFORM}.zip \
    && wget https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}-${RELEASE_NAME}/Godot_v${GODOT_VERSION}-${RELEASE_NAME}_export_templates.tpz \
    && mkdir -p ~/.cache \
    && mkdir -p ~/.config/godot \
    && mkdir -p ~/.local/share/godot/export_templates/${GODOT_VERSION}.${RELEASE_NAME} \
    && unzip Godot_v${GODOT_VERSION}-${RELEASE_NAME}_${GODOT_PLATFORM}.zip \
    && mv Godot_v${GODOT_VERSION}-${RELEASE_NAME}_${GODOT_PLATFORM} /usr/local/bin/godot \
    && unzip Godot_v${GODOT_VERSION}-${RELEASE_NAME}_export_templates.tpz \
    && mv templates/* ~/.local/share/godot/export_templates/${GODOT_VERSION}.${RELEASE_NAME} \
    && rm -f Godot_v${GODOT_VERSION}-${RELEASE_NAME}_export_templates.tpz Godot_v${GODOT_VERSION}-${RELEASE_NAME}_${GODOT_PLATFORM}.zip

# Download and set up Android SDK to export to Android.
ENV ANDROID_HOME="/usr/lib/android-sdk"
RUN wget https://googledownloads.cn/android/repository/commandlinetools-linux-14742923_latest.zip \
    && unzip commandlinetools-linux-*_latest.zip -d cmdline-tools \
    && mv cmdline-tools $ANDROID_HOME/ \
    && rm -f commandlinetools-linux-*_latest.zip

ENV PATH="${ANDROID_HOME}/cmdline-tools/cmdline-tools/bin:${PATH}"

RUN yes | sdkmanager --licenses \
    && sdkmanager "platform-tools" "build-tools;35.0.1" "platforms;android-35" "cmdline-tools;latest" "cmake;3.10.2.4988404" "ndk;28.1.13356709"

# Add Android keystore and settings.
RUN keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android -keystore debug.keystore -storepass android -dname "CN=Android Debug,O=Android,C=US" -validity 9999
RUN keytool -v -genkey -keystore siamesechess.keystore -alias ${SIAMESECHESS_ANDROID_USER} -keyalg RSA -storepass ${SIAMESECHESS_ANDROID_PASSWORD} -dname "${SIAMESECHESS_ANDROID_DNAME}" -validity 10000

RUN godot -v -e --quit --headless ${GODOT_TEST_ARGS}
# Godot editor settings are stored per minor version since 4.3.
# `${GODOT_VERSION:0:3}` transforms a string of the form `x.y.z` into `x.y`, even if it's already `x.y` (until Godot 4.9).
RUN echo '[gd_resource type="EditorSettings" format=3]' > ~/.config/godot/editor_settings-${GODOT_VERSION:0:3}.tres
RUN echo '[resource]' >> ~/.config/godot/editor_settings-${GODOT_VERSION:0:3}.tres
RUN echo 'export/android/java_sdk_path = "/usr/lib/jvm/java-17-openjdk-amd64"' >> ~/.config/godot/editor_settings-${GODOT_VERSION:0:3}.tres
RUN echo 'export/android/android_sdk_path = "/usr/lib/android-sdk"' >> ~/.config/godot/editor_settings-${GODOT_VERSION:0:3}.tres
RUN echo 'export/android/debug_keystore = "/root/debug.keystore"' >> ~/.config/godot/editor_settings-${GODOT_VERSION:0:3}.tres
RUN echo 'export/android/debug_keystore_user = "androiddebugkey"' >> ~/.config/godot/editor_settings-${GODOT_VERSION:0:3}.tres
RUN echo 'export/android/debug_keystore_pass = "android"' >> ~/.config/godot/editor_settings-${GODOT_VERSION:0:3}.tres
RUN echo 'export/android/force_system_user = false' >> ~/.config/godot/editor_settings-${GODOT_VERSION:0:3}.tres
RUN echo 'export/android/timestamping_authority_url = ""' >> ~/.config/godot/editor_settings-${GODOT_VERSION:0:3}.tres
RUN echo 'export/android/shutdown_adb_on_exit = true' >> ~/.config/godot/editor_settings-${GODOT_VERSION:0:3}.tres

WORKDIR /siamesechess
CMD /root/emsdk/emsdk activate latest \
 && cd /siamesechess \
 && scons platform=windows target=template_release use_mingw=yes debug_symbols=no optimize=speed_trace \
 && scons platform=android target=template_release debug_symbols=no optimize=speed_trace \
 && scons platform=web target=template_release debug_symbols=no optimize=speed_trace \
 && scons platform=linux target=template_release use_mingw=yes debug_symbols=no optimize=speed_trace \
 && godot --headless --export-release "Windows Desktop" bin/windows/SiameseChess-SecondPrototype-Windows.zip \
 && godot --headless --export-release Android bin/android/SiameseChess-SecondPrototype-Android.apk \
 && godot --headless --export-release Web bin/web/index.html \
 && godot --headless --export-release Linux bin/linux/SiameseChess-SecondPrototype-Linux.zip \
 && zip bin/web/SiameseChess-SecondPrototype-Web.zip bin/web/*
