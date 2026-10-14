# Toolchain de la app: Flutter + SDK de Android + JDK 21 (el JDK del host no lo admite Gradle).
# Se ejecuta con el UID/GID del usuario del host para que lo generado en el proyecto no sea de root.
FROM eclipse-temurin:21-jdk-noble

ARG FLUTTER_VERSION=3.47.7
ARG ANDROID_CMDLINE_TOOLS=16111833
ARG UID=1000
ARG GID=1000

ENV ANDROID_HOME=/opt/android-sdk \
    ANDROID_SDK_ROOT=/opt/android-sdk \
    FLUTTER_HOME=/opt/flutter \
    PUB_CACHE=/home/builder/.pub-cache \
    GRADLE_USER_HOME=/home/builder/.gradle
ENV PATH=${FLUTTER_HOME}/bin:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}

RUN apt-get update \
    && apt-get install -y --no-install-recommends git curl unzip xz-utils zip ca-certificates make \
    && rm -rf /var/lib/apt/lists/*

# La imagen base trae el usuario "ubuntu" con UID 1000: se elimina para usar el del host.
RUN (userdel -r ubuntu 2>/dev/null || true) \
    && (getent group ${GID} || groupadd -g ${GID} builder) \
    && useradd -m -u ${UID} -g ${GID} -s /bin/bash builder \
    && mkdir -p ${ANDROID_HOME} ${FLUTTER_HOME} /app \
    && chown -R ${UID}:${GID} ${ANDROID_HOME} ${FLUTTER_HOME} /app

USER builder

RUN curl -fsSL -o /tmp/cmdline-tools.zip \
        https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS}_latest.zip \
    && unzip -q /tmp/cmdline-tools.zip -d /tmp/cmdline-tools \
    && mkdir -p ${ANDROID_HOME}/cmdline-tools \
    && mv /tmp/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest \
    && rm -rf /tmp/cmdline-tools /tmp/cmdline-tools.zip \
    && yes | sdkmanager --licenses > /dev/null \
    && sdkmanager "platform-tools"

RUN git clone --depth 1 --branch ${FLUTTER_VERSION} https://github.com/flutter/flutter.git ${FLUTTER_HOME} \
    && flutter config --no-analytics --no-cli-animations \
    && dart --disable-analytics \
    && flutter precache --android

# Calentamiento: un APK desechable instala en la imagen lo que Gradle pide (plataformas,
# build-tools, NDK, distribución de Gradle), para que el primer `make apk` no lo descargue.
RUN cd /tmp \
    && flutter create --platforms android warmup > /dev/null \
    && cd warmup \
    && flutter build apk --debug \
    && cd / && rm -rf /tmp/warmup

# Plataformas que piden los plugins del proyecto además de la del calentamiento
# (flutter_secure_storage, device_info_plus). Sin esto Gradle las descarga al compilar
# y se pierden al recrear el contenedor.
RUN sdkmanager "platforms;android-35"

WORKDIR /app
