.PHONY: build up down sh doctor get format format-check analyze test apk apk-release appbundle keystore run devices \
	adb-pair adb-connect \
	emulator-build emulator-up emulator-down emulator-logs emulator-reset

COMPOSE = docker compose
CONTAINER = mydiary-flutter
# Fichero de entorno de la app (env/$(ENV).json, no versionado; ver env.example.json).
ENV ?= dev
ENV_FILE = env/$(ENV).json

# -it solo con terminal (sin ella, p. ej. desde hooks o agentes, docker exec -t falla).
TTY := $(shell [ -t 0 ] && echo -it || echo -i)
EXEC = docker exec $(TTY) $(CONTAINER)
RUNNING = @docker inspect -f '{{.State.Running}}' $(CONTAINER) 2>/dev/null | grep -q true || { echo "Error: el contenedor $(CONTAINER) no está levantado. Ejecuta 'make up'."; exit 1; }
HAS_ENV = @[ -f $(ENV_FILE) ] || { echo "Error: falta $(ENV_FILE). Cópialo de env.example.json."; exit 1; }
# Las builds de publicación: firmadas con la clave de subida y solo contra un backend HTTPS.
RELEASE_CHECK = @[ -f android/key.properties ] || { echo "Error: falta android/key.properties. Crea la clave de subida con 'make keystore' (ver doc/RELEASE.md)."; exit 1; }; \
	grep -Eq '"API_BASE_URL"[[:space:]]*:[[:space:]]*"https://' $(ENV_FILE) || { echo "Error: $(ENV_FILE) no tiene una API_BASE_URL https. Usa ENV=prod (env/prod.json)."; exit 1; }
# Los demonios de Gradle y Kotlin se quedan vivos (~3 GB) y cuelgan el emulador al arrancarlo.
GRADLE_STOP = $(EXEC) sh -c 'cd android && ./gradlew --stop -q; pkill -f [K]otlinCompileDaemon; true'

build:
	HOST_UID=$$(id -u) HOST_GID=$$(id -g) $(COMPOSE) build

up:
	HOST_UID=$$(id -u) HOST_GID=$$(id -g) $(COMPOSE) up -d

down:
	$(COMPOSE) --profile emulator down

sh:
	$(RUNNING)
	$(EXEC) bash

doctor:
	$(RUNNING)
	$(EXEC) flutter doctor -v

get:
	$(RUNNING)
	$(EXEC) flutter pub get

format:
	$(RUNNING)
	$(EXEC) dart format lib test

format-check:
	$(RUNNING)
	$(EXEC) dart format --output=none --set-exit-if-changed lib test

analyze:
	$(RUNNING)
	$(EXEC) flutter analyze

test:
	$(RUNNING)
	$(EXEC) flutter test

apk:
	$(RUNNING)
	$(HAS_ENV)
	$(EXEC) flutter build apk --debug --dart-define-from-file=$(ENV_FILE)
	$(GRADLE_STOP)

# AAB firmado para subir a Google Play (doc/RELEASE.md): make appbundle ENV=prod
appbundle:
	$(RUNNING)
	$(HAS_ENV)
	$(RELEASE_CHECK)
	$(EXEC) flutter build appbundle --release --dart-define-from-file=$(ENV_FILE)
	$(GRADLE_STOP)

# APK de release firmado, para probar la build de publicación en el emulador o en un móvil.
apk-release:
	$(RUNNING)
	$(HAS_ENV)
	$(RELEASE_CHECK)
	$(EXEC) flutter build apk --release --dart-define-from-file=$(ENV_FILE)
	$(GRADLE_STOP)

# Clave de subida a Google Play (una vez). Pide la contraseña y escribe android/upload-keystore.jks y
# android/key.properties, que no se versionan. Guarda una copia de los dos fuera del repo.
keystore: SHELL := /bin/bash
keystore:
	$(RUNNING)
	@[ ! -e android/key.properties ] && [ ! -e android/upload-keystore.jks ] || { echo "Error: ya existe la clave de subida (android/upload-keystore.jks o android/key.properties)."; exit 1; }
	@read -rsp "Contraseña de la clave de subida (mínimo 6 caracteres): " pass; echo; \
	read -rsp "Repítela: " again; echo; \
	[ "$$pass" = "$$again" ] || { echo "Error: no coinciden."; exit 1; }; \
	[ $${#pass} -ge 6 ] || { echo "Error: mínimo 6 caracteres."; exit 1; }; \
	docker exec -i -e STORE_PASS="$$pass" $(CONTAINER) keytool -genkeypair -keystore android/upload-keystore.jks \
		-storetype PKCS12 -alias upload -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=MyDiary" \
		-storepass:env STORE_PASS -keypass:env STORE_PASS && \
	( umask 077; printf 'storeFile=upload-keystore.jks\nkeyAlias=upload\nstorePassword=%s\nkeyPassword=%s\n' "$$pass" "$$pass" > android/key.properties ) && \
	chmod 600 android/upload-keystore.jks && \
	echo "Clave creada. Guarda una copia de android/upload-keystore.jks y android/key.properties fuera del repo."

# Ejecuta en un móvil conectado por depuración inalámbrica (make adb-pair / make adb-connect).
# DEVICE=<id> si hay varios (ver make devices).
run:
	$(RUNNING)
	$(HAS_ENV)
	$(EXEC) flutter run --dart-define-from-file=$(ENV_FILE) $(if $(DEVICE),-d $(DEVICE),)

devices:
	$(RUNNING)
	$(EXEC) adb devices -l

# Móvil: Ajustes > Opciones de desarrollador > Depuración inalámbrica > Vincular con código.
# make adb-pair ADDR=192.168.1.50:37123   (IP y puerto de la ventana de vinculación; pide el código)
adb-pair:
	$(RUNNING)
	@[ -n "$(ADDR)" ] || { echo "Uso: make adb-pair ADDR=<ip>:<puerto de vinculación>"; exit 1; }
	$(EXEC) adb pair $(ADDR)

# make adb-connect ADDR=192.168.1.50:41234   (IP y puerto de la pantalla de Depuración inalámbrica)
adb-connect:
	$(RUNNING)
	@[ -n "$(ADDR)" ] || { echo "Uso: make adb-connect ADDR=<ip>:<puerto>"; exit 1; }
	$(EXEC) adb connect $(ADDR)

# --- Emulador de Android (opcional, solo desarrollo; ver AGENTS.md) ---

emulator-build:
	$(COMPOSE) --profile emulator build emulator

# Abre la ventana del emulador en el escritorio. Después, make run lo usa sin configurar nada.
emulator-up:
	@[ -e /dev/kvm ] || { echo "Error: no hay /dev/kvm (virtualización desactivada)."; exit 1; }
	@[ -n "$(DISPLAY)" ] || { echo "Error: DISPLAY vacía; ejecuta desde una sesión gráfica."; exit 1; }
	DISPLAY=$(DISPLAY) XAUTHORITY=$(XAUTHORITY) $(COMPOSE) --profile emulator up -d emulator
	@echo "Arrancando Android (1-3 min la primera vez). Compruébalo con 'make devices'."

emulator-down:
	$(COMPOSE) --profile emulator stop emulator

emulator-logs:
	$(COMPOSE) --profile emulator logs -f emulator

# Borra el estado del emulador (app instalada, datos): el siguiente arranque parte de cero.
emulator-reset:
	$(COMPOSE) --profile emulator rm -sf emulator
	docker volume rm -f $$(basename $$(pwd) | tr 'A-Z' 'a-z')_emulator-avd
