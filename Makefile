.PHONY: build up down sh doctor get format format-check analyze test apk run devices adb-pair adb-connect

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

build:
	HOST_UID=$$(id -u) HOST_GID=$$(id -g) $(COMPOSE) build

up:
	HOST_UID=$$(id -u) HOST_GID=$$(id -g) $(COMPOSE) up -d

down:
	$(COMPOSE) down

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
