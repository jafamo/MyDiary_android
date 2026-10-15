## ADDED Requirements

### Requirement: Micrófono del emulador
El emulador de Android SHALL recibir como micrófono el audio de entrada del host, a través del servidor PulseAudio del escritorio (PulseAudio o PipeWire con `pipewire-pulse`). Solo SHALL tener acceso al micrófono mientras está arrancado.

#### Scenario: Grabar en el emulador
- **WHEN** con el emulador arrancado la app graba una nota mientras se habla al micrófono del PC
- **THEN** la nota subida contiene ese audio y no silencio
