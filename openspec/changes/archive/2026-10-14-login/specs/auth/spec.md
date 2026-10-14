## ADDED Requirements

### Requirement: Inicio de sesión
La pantalla de login SHALL pedir usuario y contraseña y enviar `POST /api/v1/login` con `username`, `password` y un `device_name` generado a partir del dispositivo (modelo y versión del sistema, como máximo 100 caracteres, «MyDiary app» si no se puede obtener). Con éxito, la app SHALL guardar la sesión y mostrar el inicio. Con error, SHALL mostrar el `message` del backend bajo el formulario y no guardar nada. Con campos vacíos MUST NOT enviar la petición.

#### Scenario: Login correcto
- **WHEN** se envían credenciales correctas
- **THEN** se muestra el inicio y la sesión queda guardada en el almacenamiento seguro

#### Scenario: Credenciales incorrectas
- **WHEN** el backend responde `401` con «Usuario o contraseña incorrectos.»
- **THEN** el mensaje se muestra bajo el formulario, se sigue en el login y no se guarda nada

#### Scenario: Sin conexión
- **WHEN** el login falla sin respuesta del servidor
- **THEN** se muestra «No se pudo conectar con el servidor.»

#### Scenario: Campos vacíos
- **WHEN** se pulsa «Entrar» con la contraseña vacía
- **THEN** no se envía ninguna petición y se indica el campo obligatorio

### Requirement: Límite de intentos en el login
Ante un `429` del login, la app SHALL desactivar el botón «Entrar» y mostrar una cuenta atrás hasta el `Retry-After` (60 s si no viene), y SHALL reactivarlo al terminar.

#### Scenario: Login bloqueado
- **WHEN** el login responde `429` con `Retry-After: 840`
- **THEN** se muestra «Prueba de nuevo en 14:00» y el botón está desactivado

#### Scenario: Fin del bloqueo
- **WHEN** termina la cuenta atrás
- **THEN** el botón «Entrar» vuelve a estar activo

### Requirement: Sesión persistente
La sesión (token, usuario y nombre del dispositivo) SHALL guardarse en almacenamiento seguro del sistema (Keystore en Android, Keychain en iOS, solo en este dispositivo) y MUST NOT guardarse en ningún otro sitio. El backup automático de Android SHALL estar desactivado.

#### Scenario: Reabrir la app
- **WHEN** se cierra y se vuelve a abrir la app tras iniciar sesión
- **THEN** se entra al inicio sin pedir credenciales

### Requirement: Validación de la sesión al arrancar
Con una sesión guardada, la app SHALL mostrar una pantalla de carga y consultar `GET /api/v1/me` antes de decidir. Con `200` SHALL entrar al inicio con usuario y dispositivo actualizados. Con `401` SHALL borrar la sesión guardada y mostrar el login. Si no hay respuesta del servidor u otro error, SHALL entrar al inicio con la sesión guardada.

#### Scenario: Token válido
- **WHEN** la app arranca con sesión guardada y `/me` responde `200`
- **THEN** se muestra el inicio

#### Scenario: Token revocado
- **WHEN** la app arranca con sesión guardada y `/me` responde `401`
- **THEN** se muestra el login y la sesión guardada se ha borrado

#### Scenario: Sin red al arrancar
- **WHEN** la app arranca con sesión guardada y `/me` falla sin respuesta
- **THEN** se muestra el inicio

### Requirement: Cierre de sesión
El menú del inicio SHALL mostrar el usuario y el dispositivo y ofrecer «Cerrar sesión», que tras confirmar SHALL llamar a `POST /api/v1/logout` y borrar la sesión guardada y la de memoria, aunque la llamada falle, y mostrar el login.

#### Scenario: Cerrar sesión
- **WHEN** se elige «Cerrar sesión» y se confirma
- **THEN** se llama a `POST /api/v1/logout`, se borra la sesión y se muestra el login

#### Scenario: Cerrar sesión sin red
- **WHEN** se confirma «Cerrar sesión» y la llamada falla sin respuesta
- **THEN** la sesión se borra igualmente y se muestra el login

#### Scenario: Cancelar
- **WHEN** se elige «Cerrar sesión» y se cancela el diálogo
- **THEN** no se llama al backend y se sigue en el inicio

### Requirement: Sesión caducada durante el uso
Un `401` en cualquier petición distinta del login SHALL borrar también la sesión guardada y llevar al login.

#### Scenario: Token revocado por consola
- **WHEN** con la app en el inicio una petición recibe `401`
- **THEN** se muestra el login y al reabrir la app no hay sesión guardada
