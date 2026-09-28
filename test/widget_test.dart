import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listillify/injection.dart';
import 'package:listillify/main.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    when(() => mockStorage.read(key: any(named: 'key')))
        .thenAnswer((_) async => null);

    DependencyInjection.init(storage: mockStorage);
  });

  testWidgets('ListillifyApp renders HomePage with UserSessionCard and PlaylistForm',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ListillifyApp());
    await tester.pumpAndSettle();

    // Comprobamos elementos de la pantalla principal
    expect(find.text('Listillify'), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);

    // Comprobamos la tarjeta de sesión de usuario
    expect(find.text('No has iniciado sesión'), findsOneWidget);
    expect(find.text('Conectar'), findsOneWidget);

    // Comprobamos el formulario de playlist
    expect(find.text('Crear Nueva Playlist'), findsOneWidget);
    expect(find.text('Nombre de la playlist'), findsOneWidget);
    expect(find.text('Ejemplo'), findsOneWidget);

    // Tocamos el botón de 'Ejemplo' para autocompletar canciones
    await tester.tap(find.text('Ejemplo'));
    await tester.pumpAndSettle();

    expect(find.text('Clásicos de Rock y Éxitos'), findsOneWidget);

    // Abrimos el diálogo de configuración desde el AppBar
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.text('Configuración de Spotify API'), findsOneWidget);
    expect(find.text('Spotify Client ID'), findsOneWidget);
  });
}
