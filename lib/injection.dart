import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:listillify/features/auth/domain/repositories/auth_repository.dart';
import 'package:listillify/features/auth/domain/usecases/get_current_session_use_case.dart';
import 'package:listillify/features/auth/domain/usecases/login_use_case.dart';
import 'package:listillify/features/auth/domain/usecases/logout_use_case.dart';
import 'package:listillify/features/auth/infrastructure/repositories/spotify_auth_repository.dart';
import 'package:listillify/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:listillify/features/config/domain/repositories/config_repository.dart';
import 'package:listillify/features/config/domain/usecases/get_api_config_use_case.dart';
import 'package:listillify/features/config/domain/usecases/save_api_config_use_case.dart';
import 'package:listillify/features/config/infrastructure/repositories/secure_config_repository.dart';
import 'package:listillify/features/config/presentation/cubit/config_cubit.dart';
import 'package:listillify/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:listillify/features/playlist/domain/services/playlist_text_parser.dart';
import 'package:listillify/features/playlist/domain/usecases/create_spotify_playlist_use_case.dart';
import 'package:listillify/features/playlist/domain/usecases/parse_and_search_tracks_use_case.dart';
import 'package:listillify/features/playlist/infrastructure/repositories/spotify_playlist_repository.dart';
import 'package:listillify/features/playlist/presentation/cubit/playlist_cubit.dart';

/// PATRÓN DE DISEÑO: Service Locator / Composition Root / Dependency Injection
/// Gestiona la creación e inyección de dependencias para asegurar bajo acoplamiento (SOLID D).
class DependencyInjection {
  DependencyInjection._();

  static late final FlutterSecureStorage secureStorage;
  static late final http.Client httpClient;

  // Config feature
  static late final ConfigRepository configRepository;
  static late final GetApiConfigUseCase getApiConfigUseCase;
  static late final SaveApiConfigUseCase saveApiConfigUseCase;

  // Auth feature
  static late final AuthRepository authRepository;
  static late final LoginUseCase loginUseCase;
  static late final GetCurrentSessionUseCase getCurrentSessionUseCase;
  static late final LogoutUseCase logoutUseCase;

  // Playlist feature
  static late final PlaylistRepository playlistRepository;
  static late final ParseAndSearchTracksUseCase parseAndSearchTracksUseCase;
  static late final CreateSpotifyPlaylistUseCase createSpotifyPlaylistUseCase;

  /// Inicializa los adaptadores de infraestructura y casos de uso.
  static void init({
    FlutterSecureStorage? storage,
    http.Client? client,
    AuthRepository? authRepo,
    ConfigRepository? configRepo,
    PlaylistRepository? playlistRepo,
  }) {
    secureStorage = storage ?? const FlutterSecureStorage();
    httpClient = client ?? http.Client();

    // Config
    configRepository = configRepo ?? SecureConfigRepository(storage: secureStorage);
    getApiConfigUseCase = GetApiConfigUseCase(configRepository);
    saveApiConfigUseCase = SaveApiConfigUseCase(configRepository);

    // Auth
    authRepository = authRepo ??
        SpotifyAuthRepository(
          httpClient: httpClient,
          storage: secureStorage,
        );
    loginUseCase = LoginUseCase(authRepository);
    getCurrentSessionUseCase = GetCurrentSessionUseCase(authRepository);
    logoutUseCase = LogoutUseCase(authRepository);

    // Playlist
    playlistRepository = playlistRepo ?? SpotifyPlaylistRepository(httpClient: httpClient);
    parseAndSearchTracksUseCase = ParseAndSearchTracksUseCase(
      playlistRepository: playlistRepository,
      textParser: PlaylistTextParser(),
    );
    createSpotifyPlaylistUseCase = CreateSpotifyPlaylistUseCase(
      playlistRepository: playlistRepository,
    );
  }

  /// Crea una nueva instancia de [ConfigCubit] con sus dependencias inyectadas.
  static ConfigCubit createConfigCubit() {
    return ConfigCubit(
      getApiConfigUseCase: getApiConfigUseCase,
      saveApiConfigUseCase: saveApiConfigUseCase,
    );
  }

  /// Crea una nueva instancia de [AuthCubit] con sus dependencias inyectadas.
  static AuthCubit createAuthCubit() {
    return AuthCubit(
      loginUseCase: loginUseCase,
      getCurrentSessionUseCase: getCurrentSessionUseCase,
      logoutUseCase: logoutUseCase,
    );
  }

  /// Crea una nueva instancia de [PlaylistCubit] con sus dependencias inyectadas.
  static PlaylistCubit createPlaylistCubit() {
    return PlaylistCubit(
      parseAndSearchTracksUseCase: parseAndSearchTracksUseCase,
      createSpotifyPlaylistUseCase: createSpotifyPlaylistUseCase,
    );
  }
}
