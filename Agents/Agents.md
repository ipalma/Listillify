# Listillify - Contexto y Especificaciones del Proyecto

## 1. Visión General del Proyecto
**Listillify** es una aplicación multiplataforma desarrollada en **Flutter** (con soporte inicial para **Windows** y **Android**) que permite a los usuarios generar de forma rápida y automatizada listas de reproducción en su cuenta de **Spotify**, a partir de un listado de canciones, episodios de podcasts o texto plano introducido por el usuario.

---

## 2. Requisitos Funcionales

1. **Autenticación y Gestión de Cuentas (Login)**:
   - Flujo de autenticación con Spotify mediante **OAuth 2.0 con PKCE** (Proof Key for Code Exchange) para evitar exponer secretos en el cliente.
   - **Manejo de Callback Multiplataforma**:
     - **Android**: *Deep Links / App Links* (ej. `listillify://callback`).
     - **Windows**: Servidor local temporal (ej. `http://localhost:8888/callback` o puerto dinámico/protocolo personalizado).
   - Identificación de la cuenta del usuario para asociar y crear las listas directamente en su perfil.
   - Persistencia segura de sesión (*Access Token* y *Refresh Token*) para evitar logins reiterados.

2. **Configuración de Acceso a la API (API Key / Client ID / Secrets)**:
   - Pantalla/sección de configuración para que el usuario pueda introducir y persistir sus credenciales (Client ID de la Spotify Developer Dashboard).
   - Almacenamiento seguro local mediante mecanismos nativos (ej. `flutter_secure_storage` usando Windows Credential Manager / Android KeyStore).

3. **Creación y Gestión de Playlists**:
   - **Campo de texto para el Nombre de la Playlist**: Título descriptivo de la lista a crear.
   - **Campo de texto multilínea / entrada para contenido**:
     - Admite múltiples formatos: `Artista - Canción`, `Canción - Artista`, enlaces web de Spotify (`https://open.spotify.com/track/...`), URIs (`spotify:track:...`, `spotify:episode:...`) y listas numeradas.
   - **Búsqueda y Parseo**:
     - Motor de búsqueda inteligente que consulta la API de Spotify para resolver los identificadores (URIs) de tracks y podcasts.
   - **Previsualización y Validación**:
     - Vista previa interactiva con las canciones/episodios encontrados vs. no encontrados, permitiendo desmarcar o corregir antes del envío final.
   - **Generación en Spotify**:
     - Creación de la playlist pública/privada en la cuenta del usuario.
     - **Envío por lotes (Batching)**: Manejo de inserciones en bloques de hasta 100 elementos (límite de la API de Spotify).
     - **Control de Rate Limiting**: Manejo de respuestas HTTP 429 (`Retry-After`) con reintentos automáticos.

---

## 3. Arquitectura y Principios de Diseño

### 3.1. Arquitectura Hexagonal (Ports & Adapters)
El proyecto sigue una estricta separación de capas e inversión de dependencias:

- **Dominio (`domain`)**:
  - **Entidades**: Modelos puros del negocio (`Playlist`, `Track`, `PodcastEpisode`, `UserSession`, `ApiConfig`).
  - **Puertos (Interfaces)**: Contratos de repositorios y servicios (`SpotifyRepository`, `AuthService`, `ConfigStorageService`).
  - **Casos de Uso (`use_cases`)**: Reglas de negocio puras (`CreatePlaylistUseCase`, `SearchTracksUseCase`, `AuthenticateUseCase`, `SaveApiConfigUseCase`).
  - **Manejo de Errores Funcional**: Uso de tipos de resultado (`Result<Success, Failure>` o *Sealed Classes* de Dart) para evitar excepciones no controladas.

- **Infraestructura (`infrastructure` / `adapters`)**:
  - Implementaciones concretas de los puertos:
    - Cliente HTTP para Spotify Web API (serialización JSON, interceptores de token, rate limiting).
    - Servicio de autenticación OAuth PKCE / Servidor local en Windows / Deep Link Handler en Android.
    - Adaptador de almacenamiento seguro.

- **Presentación (`presentation`)**:
  - Interfaz de usuario adaptable y responsiva para Windows y Android.
  - Gestión de estado limpia y reactiva usando **`flutter_bloc`** (Cubit/Bloc).
  - Componentes desacoplados y reutilizables.

### 3.2. Clean Code & SOLID
- **S (Single Responsibility)**: Cada clase, archivo y función tiene un único propósito claro.
- **O (Open/Closed)**: Diseñado para extenderse sin modificar código base existente mediante puertos e interfaces.
- **L (Liskov Substitution)**: Las implementaciones son intercambiables con sus abstracciones sin romper el comportamiento.
- **I (Interface Segregation)**: Interfaces pequeñas, cohesivas y específicas.
- **D (Dependency Inversion)**: Las capas superiores dependen de abstracciones (puertos), nunca de detalles de bajo nivel.
- **Legibilidad para Humanos**: Código autoexplicativo, nombres claros y directos, sin artificios innecesarios ni código ofuscado.

### 3.3. Patrones de Diseño & Documentación
- **Patrones aplicados según necesidad**: *Repository, Adapter, Factory, Strategy, Builder, Observer/State, Retry Pattern*.
- **Comentarios Obligatorios de Patrones**: Cada vez que se utilice un patrón de diseño, debe incluirse un comentario explícito en el código detallando:
  - Qué patrón de diseño se está implementando.
  - Por qué se eligió y qué problema resuelve en ese punto.
- **Comentarios Funcionales**: Documentar clases, métodos públicos y lógica no trivial para mantener trazabilidad y control.

---

## 4. Estrategia de Testing y Calidad

- **Pruebas Unitarias Exhaustivas**:
  - Cobertura de entidades de dominio, casos de uso, lógica de parseo, adaptadores y mappers.
  - Uso de Mocks/Fakes para aislar completamente las dependencias externas en las pruebas.
- **Pruebas Regresivas y Verificación en Caliente**:
  - Se deben pasar pruebas regresivas completas.
  - Se arrancará la aplicación y se realizarán las gestiones y validaciones funcionales necesarias (flujo de autenticación, creación de playlists, configuración de API, gestión de errores, etc.) para asegurar que los cambios no rompen funcionalidades preexistentes.
- **Regla de Oro (Test en Verde)**:
  - **Todos los tests unitarios y pruebas regresivas deben estar completamente en verde (100% pasando)** antes de dar por finalizada cualquier tarea y proceder con `git commit` y `git push`.

---

## 5. Control de Versiones y Despliegue

- **Repositorio**: GitHub (URL proporcionada por el usuario).
- **Flujo de Trabajo Git**:
  - Commits descriptivos, modulares y por tarea terminada.
  - Verificación previa obligatoria: ejecución de análisis estático (`flutter analyze`), suite de tests unitarios (`flutter test`) y validación de pruebas regresivas con la aplicación en ejecución.
- **Flexibilidad**: Si algún requisito o dependencia técnica genera fricción durante el desarrollo, se ajustará de forma controlada y consensuada.