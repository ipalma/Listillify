import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listillify/core/constants/spotify_constants.dart';
import 'package:listillify/injection.dart';
import 'package:listillify/main.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    when(() => mockStorage.read(key: SpotifyConstants.secureStorageClientIdKey))
        .thenAnswer((_) async => null);

    DependencyInjection.init(storage: mockStorage);
  });

  testWidgets('ListillifyApp smoke test renders HomePage and opens ConfigDialog',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ListillifyApp());
    await tester.pump();

    // Comprobamos elementos de la pantalla principal
    expect(find.text('Listillify'), findsOneWidget);
    expect(find.text('Generador de Playlists para Spotify'), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);

    // Tocamos el botón de Configurar API para abrir el diálogo
    await tester.tap(find.text('Configurar API'));
    await tester.pumpAndSettle();

    // Verificamos que el modal de configuración de Spotify se muestra
    expect(find.text('Configuración de Spotify API'), findsOneWidget);
    expect(find.text('Spotify Client ID'), findsOneWidget);
  });
}
