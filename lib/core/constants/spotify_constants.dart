/// Constantes globales para la integración con la API Web de Spotify y configuración de la app.
abstract final class SpotifyConstants {
  // Endpoints oficiales de Spotify Accounts y Web API
  static const String accountsBaseUrl = 'https://accounts.spotify.com';
  static const String apiBaseUrl = 'https://api.spotify.com/v1';

  static const String authorizeEndpoint = '$accountsBaseUrl/authorize';
  static const String tokenEndpoint = '$accountsBaseUrl/api/token';

  // Scopes necesarios para crear playlists, modificar playlists públicas/privadas y leer perfil de usuario
  static const List<String> defaultScopes = [
    'playlist-modify-public',
    'playlist-modify-private',
    'playlist-read-private',
    'user-read-private',
    'user-read-email',
  ];

  static String get scopesJoined => defaultScopes.join(' ');

  // Redirect URIs según plataforma
  static const String androidRedirectUri = 'listillify://callback';
  static const int windowsLocalServerPort = 8888;
  static const String windowsRedirectUri = 'http://127.0.0.1:8888/callback';

  // Límite máximo de pistas que Spotify permite añadir por llamada batch
  static const int maxTracksPerBatch = 100;

  // Claves para el almacenamiento seguro local
  static const String secureStorageClientIdKey = 'spotify_client_id';
  static const String secureStorageClientSecretKey = 'spotify_client_secret';
  static const String secureStorageAccessTokenKey = 'spotify_access_token';
  static const String secureStorageRefreshTokenKey = 'spotify_refresh_token';
  static const String secureStorageTokenExpiresAtKey = 'spotify_token_expires_at';
  static const String secureStorageUserIdKey = 'spotify_user_id';
  static const String secureStorageUserDisplayNameKey = 'spotify_user_display_name';
}
