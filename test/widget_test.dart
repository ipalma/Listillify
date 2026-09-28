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

  testWidgets('ListillifyApp renders HomePage with UserSessionCard and opens ConfigDialog from AppBar',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ListillifyApp());
    await tester.pumpAndSettle();

    // Comprobamos elementos de la pantalla principal
    expect(find.text('Listillify'), findsOneWidget);
    expect(find.text('Generador de Playlists para Spotify'), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);

    // Comprobamos la tarjeta de sesión de usuario
    expect(find.text('No has iniciado sesión'), findsOneWidget);
    expect(find.text('Conectar'), findsOneWidget);

    // Abrimos el diálogo de configuración desde el AppBar
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    // Verificamos que el modal de configuración de Spotify se muestra
    expect(find.text('Configuración de Spotify API'), findsOneWidget);
    expect(find.text('Spotify Client ID'), findsOneWidget);
  });
}
