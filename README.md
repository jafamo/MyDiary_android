# 📱 MyDiary app

Cliente móvil (Flutter; Android primero, iPhone después con el mismo código) de [MyDiary](https://github.com/jafamo/MyDiary): diario de notas de voz transcritas y resumidas por el backend.

- Instrucciones del repositorio, stack y reglas: [`AGENTS.md`](AGENTS.md)
- Contrato de la API y contexto del backend: [`doc/BACKEND.md`](doc/BACKEND.md)
- Plan por fases: [`ROADMAP.md`](ROADMAP.md) · Cambios: [`CHANGELOG.md`](CHANGELOG.md)

## Puesta en marcha

Solo hace falta Docker: Flutter, JDK y SDK de Android van en la imagen.

```bash
make build                         # imagen del toolchain (la primera vez tarda)
make up                            # contenedor mydiary-flutter
cp env.example.json env/dev.json   # y ajustar API_BASE_URL
make get && make test              # dependencias y tests
make apk                           # build/app/outputs/flutter-apk/app-debug.apk
```

En un móvil Android 11+ por depuración inalámbrica: `make adb-pair ADDR=<ip>:<puerto>`, `make adb-connect ADDR=<ip>:<puerto>` y `make run`.

Calidad: `make format-check`, `make analyze`, `make test` (los mismos pasos que la CI).
