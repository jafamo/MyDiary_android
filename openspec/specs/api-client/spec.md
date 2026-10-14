# api-client Specification

## Purpose
Acceso de la app a la API de MyDiary (`/api/v1`): cliente HTTP único, errores tipados, sesión caducada, límite de intentos y modelos de los recursos.
## Requirements
### Requirement: Cliente único de la API
La app SHALL acceder al backend solo a través de `ApiClient`, que construye las URL sobre `<API_BASE_URL>/api/v1`, envía `Accept: application/json` y añade `Authorization: Bearer <token>` cuando hay token. Sin token, la cabecera MUST NOT enviarse.

#### Scenario: Petición con token
- **WHEN** hay token `abc` y se pide `GET /me`
- **THEN** la petición va a `<API_BASE_URL>/api/v1/me` con la cabecera `Authorization: Bearer abc`

#### Scenario: Petición sin token
- **WHEN** no hay token y se pide `POST /login`
- **THEN** la petición no lleva cabecera `Authorization`

### Requirement: Errores tipados
Todo fallo de una petición SHALL llegar como `ApiException` con `statusCode` (o `null` si no hubo respuesta), `code` y `message`. Si el cuerpo de error es `{"code", "message"}`, SHALL usar esos valores. Si no lo es, `code` SHALL derivarse del estado HTTP (`bad_request`, `unauthorized`, `forbidden`, `not_found`, `method_not_allowed`, `conflict`, `validation_failed`, `too_many_requests`, `internal_error`) o ser `http_<estado>` para los demás. Sin respuesta SHALL ser `network_error`, y una respuesta correcta que no se puede interpretar SHALL ser `invalid_response`.

#### Scenario: Error del backend
- **WHEN** el backend responde `409` con `{"code": "conflict", "message": "Solo se pueden editar audios transcritos."}`
- **THEN** se lanza `ApiException` con `statusCode` 409, `code` `conflict` y ese `message`

#### Scenario: Error sin formato de la API
- **WHEN** nginx responde `413` con un cuerpo HTML
- **THEN** se lanza `ApiException` con `statusCode` 413 y `code` `http_413`

#### Scenario: Sin conexión
- **WHEN** la petición falla sin respuesta (timeout o sin red)
- **THEN** se lanza `ApiException` con `statusCode` `null` y `code` `network_error`

#### Scenario: Respuesta inesperada
- **WHEN** el backend responde `200` con un JSON al que le falta un campo obligatorio del modelo
- **THEN** se lanza `ApiException` con `code` `invalid_response`

### Requirement: Sesión caducada
Ante un `401` en cualquier petición excepto `POST /login`, `ApiClient` SHALL notificar a la app que la sesión ha caducado (para que borre el token) además de lanzar la excepción. Un `401` en `POST /login` MUST NOT tratarse como sesión caducada.

#### Scenario: Token revocado
- **WHEN** una petición autenticada recibe `401`
- **THEN** se invoca el aviso de sesión caducada y se lanza `ApiException` con `code` `unauthorized`

#### Scenario: Credenciales incorrectas
- **WHEN** `POST /login` recibe `401`
- **THEN** se lanza `ApiException` con `code` `unauthorized` sin invocar el aviso de sesión caducada

### Requirement: Límite de intentos
Ante un `429`, `ApiException` SHALL incluir `retryAfter` con la duración de la cabecera `Retry-After` (segundos), o `null` si no viene.

#### Scenario: Login bloqueado
- **WHEN** el backend responde `429` con `Retry-After: 840`
- **THEN** la excepción tiene `code` `too_many_requests` y `retryAfter` de 840 segundos

### Requirement: Modelos de recursos
La app SHALL tener un modelo por cada esquema de recurso de `openapi.json` (`Audio`, `Transcription`, `Summary`, `SummaryGeneration`, `Topic`, `Reminder`) y una página genérica `Paginated<T>` (`items`, `page`, `perPage`, `total`), que se construyen desde el JSON de la API sin perder campos. Los instantes SHALL quedar como `DateTime` en UTC. Los días (`AAAA-MM-DD`) SHALL quedar como fecha de calendario sin aplicar zona horaria. Un valor de enumeración desconocido SHALL mapearse a `unknown` sin fallar.

#### Scenario: Audio con transcripción
- **WHEN** se interpreta un audio `TRANSCRIBED` con `received_at` `2026-10-08T07:09:33Z` y su transcripción
- **THEN** `status` es `AudioStatus.transcribed`, `receivedAt` es ese instante en UTC y `transcription.content` tiene el texto

#### Scenario: Día del resumen
- **WHEN** se interpreta un resumen con `date` `2026-10-05`
- **THEN** su fecha es el 5 de octubre de 2026 en cualquier zona horaria del dispositivo

#### Scenario: Estado nuevo en el backend
- **WHEN** llega un audio con `status` `ARCHIVED`
- **THEN** se interpreta con `AudioStatus.unknown`

#### Scenario: Recordatorio sin hora
- **WHEN** se interpreta un recordatorio con `"time": null`
- **THEN** `time` es `null`

