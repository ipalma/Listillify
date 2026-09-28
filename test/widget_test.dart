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

  testWidgets('ListillifyApp starts on LoginPage with Spotify login and config dialog',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ListillifyApp());
    await tester.pumpAndSettle();

    // Verificamos pantalla inicial de bienvenida / login
    expect(find.text('Bienvenido a Listillify'), findsOneWidget);
    expect(find.text('Iniciar sesión con Spotify'), findsOneWidget);
    expect(find.text('Credenciales pendientes'), findsOneWidget);
    expect(find.text('Configurar'), findsOneWidget);

    // Tocamos el botón de Configurar para abrir el modal
    await tester.tap(find.text('Configurar'));
    await tester.pumpAndSettle();

    // Verificamos los campos de Client ID y Client Secret
    expect(find.text('Credenciales de Spotify API'), findsOneWidget);
    expect(find.text('Spotify Client ID'), findsOneWidget);
    expect(find.text('Spotify Client Secret'), findsOneWidget);
  });
}
