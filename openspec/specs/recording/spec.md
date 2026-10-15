# recording Specification

## Purpose
Grabar notas de voz desde la app y subirlas al backend sin pasar por Telegram, con reintento desde la propia hoja si falla la subida.
## Requirements
### Requirement: Grabar una nota
El Diario SHALL tener un botón «Grabar nota» que abra una hoja inferior y empiece a grabar en AAC-LC `.m4a`. La hoja SHALL mostrar el estado («Grabando» o «En pausa»), el tiempo transcurrido y el nivel de entrada. SHALL permitir pausar y continuar. Mientras se graba, la pantalla MUST NOT apagarse.

#### Scenario: Empezar a grabar
- **WHEN** el usuario pulsa «Grabar nota» y el micrófono está permitido
- **THEN** se abre la hoja con «Grabando» y el tiempo avanza cada segundo

#### Scenario: Pausar y continuar
- **WHEN** el usuario pulsa «Pausa» y después «Continuar»
- **THEN** el tiempo se detiene mientras está «En pausa» y vuelve a avanzar al continuar

### Requirement: Permiso del micrófono
Al empezar a grabar, la app SHALL pedir el permiso del micrófono si no lo tiene. Si se deniega, la hoja SHALL explicar que hay que activarlo en los ajustes del sistema y MUST NOT grabar.

#### Scenario: Permiso denegado
- **WHEN** el usuario deniega el micrófono
- **THEN** la hoja muestra que hay que activarlo en los ajustes del sistema y no se graba nada

### Requirement: Límite de duración
La grabación SHALL pausarse sola a los 45 minutos, avisar de que se ha llegado al máximo y permitir solo enviar o descartar.

#### Scenario: Llegar al máximo
- **WHEN** la grabación alcanza 45 minutos
- **THEN** queda en pausa con «Has llegado al máximo de 45 min.» y no se puede continuar

### Requirement: Salir de la app grabando
Si la app deja de estar visible mientras graba, la grabación SHALL pausarse y conservar lo grabado. Al volver, SHALL seguir en pausa.

#### Scenario: Salir y volver
- **WHEN** el usuario sale de la app grabando y vuelve
- **THEN** la hoja muestra «En pausa» con el tiempo grabado hasta entonces

### Requirement: Enviar la nota
«Enviar» SHALL parar la grabación y subirla con `POST /api/v1/audios` (multipart, campo `file`), mostrando el progreso. Con menos de 1 segundo grabado, «Enviar» SHALL estar desactivado. Si la subida sale bien, la hoja SHALL cerrarse, el fichero local SHALL borrarse, el Diario SHALL recargarse y SHALL mostrarse un aviso según `result`:
- `created`: «Nota enviada. Se está transcribiendo.»
- `duplicate`: «Esta nota ya estaba subida.»
- `retrying`: «Esta nota ya estaba subida. Se vuelve a transcribir.»

#### Scenario: Nota nueva
- **WHEN** el usuario pulsa «Enviar» y el backend responde `201` con `created`
- **THEN** la hoja se cierra, aparece «Nota enviada. Se está transcribiendo.» y el Diario se recarga

#### Scenario: Nota repetida
- **WHEN** el backend responde `200` con `duplicate`
- **THEN** aparece «Esta nota ya estaba subida.»

### Requirement: Subida fallida
Si la subida falla, la hoja SHALL seguir abierta con el mensaje de error y los botones «Reintentar» y «Descartar», conservando el fichero. «Reintentar» SHALL subir el mismo fichero.

#### Scenario: Sin red al enviar
- **WHEN** el usuario pulsa «Enviar» sin conexión
- **THEN** la hoja muestra «No se pudo conectar con el servidor.» con «Reintentar» y «Descartar»

#### Scenario: Reintentar
- **WHEN** vuelve la conexión y el usuario pulsa «Reintentar»
- **THEN** se sube el mismo fichero y la hoja se cierra con el aviso correspondiente

### Requirement: Descartar
«Descartar» SHALL pedir confirmación y, si se confirma, cancelar la grabación, borrar el fichero y cerrar la hoja. Mientras haya algo grabado, la hoja MUST NOT cerrarse deslizando ni con «atrás» sin esa confirmación.

#### Scenario: Descartar confirmado
- **WHEN** el usuario pulsa «Descartar» y confirma
- **THEN** la hoja se cierra, no se sube nada y el fichero se borra

#### Scenario: Atrás grabando
- **WHEN** el usuario pulsa «atrás» mientras graba
- **THEN** se pregunta «¿Descartar la nota?» y, si cancela, sigue la grabación

