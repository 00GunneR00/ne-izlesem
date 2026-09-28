import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:neizlesem/core/session/session_service.dart';
import 'package:neizlesem/main.dart';

void main() {
  testWidgets('App boots to onboarding when no user session exists', (WidgetTester tester) async {
    Get.put<SessionService>(SessionService(), permanent: true);

    await tester.pumpWidget(const NeizlesemApp());
    await tester.pump();

    expect(find.text('Ne İzlesem?'), findsOneWidget);
  });
}
