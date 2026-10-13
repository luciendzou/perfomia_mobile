import 'package:flutter_test/flutter_test.dart';
import 'package:perfomia_mobile/app/app.dart';
import 'package:perfomia_mobile/features/auth/presentation/login_page.dart';

void main() {
  testWidgets('Perfomia splash screen is displayed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PerfomiaApp());
    expect(find.text('Perfomia'), findsOneWidget);
    expect(find.text('La gestion simple de votre activite.'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1700));
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Choisissez votre langue'), findsNothing);
  });
}
