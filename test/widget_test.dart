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

  testWidgets('ListillifyApp starts on LoginPage with User/Password form and Hive config',
      (WidgetTester tester) async {
    // Definimos tamaño de pantalla adecuado para desktop
    tester.view.physicalSize = const Size(1024, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const ListillifyApp());
    await tester.pumpAndSettle();

    // Verificamos pantalla inicial de bienvenida / login
    expect(find.text('Bienvenido a Listillify'), findsOneWidget);
    expect(find.byKey(const Key('username_field')), findsOneWidget);
    expect(find.byKey(const Key('password_field')), findsOneWidget);
    expect(find.byKey(const Key('login_button')), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);

    // Verificamos validación de usuario y contraseña si se pulsa Iniciar Sesión vacíos
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pumpAndSettle();
    expect(find.text('Por favor, introduce tu usuario'), findsOneWidget);

    // Abrimos el diálogo de configuración de credenciales mediante el botón del AppBar
    await tester.tap(find.byKey(const Key('config_api_button')));
    await tester.pumpAndSettle();

    // Verificamos los campos de Client ID y Client Secret
    expect(find.text('Credenciales de Spotify API'), findsOneWidget);
    expect(find.text('Spotify Client ID'), findsOneWidget);
    expect(find.text('Spotify Client Secret'), findsOneWidget);
  });
}
