# Emulador de Android para desarrollo (opcional, perfil "emulator" de docker-compose).
# Hereda el SDK y el usuario de la imagen del toolchain; esa imagen no cambia.
ARG BASE=mydiary-flutter:3.47.7
FROM ${BASE}

ARG SYSTEM_IMAGE="system-images;android-36;google_apis;x86_64"

USER root

# Librerías de sistema que pide el emulador (ventana Qt sobre X11, NSS, audio).
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libpulse0 libasound2t64 libgl1 libegl1 libnss3 libdbus-1-3 libfontconfig1 \
        libxcomposite1 libxcursor1 libxdamage1 libxi6 libxrandr2 libxtst6 libxkbfile1 \
        libxkbcommon0 libxkbcommon-x11-0 libx11-xcb1 libxcb-cursor0 libxcb-icccm4 \
        libxcb-image0 libxcb-keysyms1 libxcb-randr0 libxcb-render-util0 libxcb-shape0 \
        libxcb-xinerama0 libxcb-xkb1 libxcb-xfixes0 libxshmfence1 libsm6 libice6 \
    && rm -rf /var/lib/apt/lists/*

USER builder

RUN yes | sdkmanager --licenses > /dev/null \
    && sdkmanager "emulator" "${SYSTEM_IMAGE}"

# AVD "mydiary": 2 GB de RAM y 2 núcleos (el host va justo), teclado del host activado.
RUN echo no | avdmanager create avd -n mydiary -k "${SYSTEM_IMAGE}" -d pixel_7 \
    && printf '%s\n' \
        'hw.ramSize=2048' \
        'hw.cpu.ncore=2' \
        'hw.keyboard=yes' \
        'disk.dataPartition.size=4G' \
        >> /home/builder/.android/avd/mydiary.avd/config.ini

ENV PATH=${ANDROID_HOME}/emulator:${PATH}

# - El estado del AVD vive en un volumen: si el emulador se cerró de golpe quedan ficheros de bloqueo
#   que impiden volver a arrancarlo, así que se limpian antes de cada arranque.
# - -feature -WiFiPacketStream: sin él la Wi-Fi pasa por netsim, que en el contenedor se cae y deja
#   Android sin red (Wi-Fi en "CONNECTING", sin IP). Así usa el punto de acceso interno del emulador.
CMD ["sh", "-c", "rm -rf /home/builder/.android/avd/mydiary.avd/*.lock && exec emulator -avd mydiary -gpu swiftshader_indirect -no-snapshot-save -no-boot-anim -no-audio -feature -WiFiPacketStream"]
