import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/shared/widgets/custom_text_box.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  setUpAll(() {
    // The widget reads brand colors that bootstrap normally initializes.
    AppColors.primary = const Color(0xFF086C4C);
    AppColors.secondary = const Color(0xFF625B71);
    AppColors.accent = const Color(0xFF7D5260);
  });

  group('CustomTextBox', () {
    testWidgets('renders label and error text', (tester) async {
      await tester.pumpWidget(
        _wrap(const CustomTextBox(label: 'City', errorText: 'Required')),
      );

      expect(find.text('City'), findsOneWidget);
      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('search variant shows a leading search icon', (tester) async {
      await tester.pumpWidget(_wrap(const CustomTextBox.search()));
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('password variant toggles obscure state', (tester) async {
      await tester.pumpWidget(
        _wrap(const CustomTextBox.password(label: 'Password')),
      );

      // Starts obscured → shows the "reveal" (visibility_off) affordance.
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      var field = tester.widget<TextField>(find.byType(TextField));
      expect(field.obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      field = tester.widget<TextField>(find.byType(TextField));
      expect(field.obscureText, isFalse);
    });
  });
}
