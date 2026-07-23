import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/features/reviews/presentation/widgets/review_tile.dart';
import 'package:shopify_app/shopify/models/product_review.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  setUpAll(() {
    // The widget reads brand colors that bootstrap normally initializes.
    AppColors.primary = const Color(0xFF086C4C);
    AppColors.secondary = const Color(0xFF625B71);
    AppColors.accent = const Color(0xFF7D5260);
  });

  testWidgets('renders author, title and body', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const ReviewTile(
          review: ProductReview(
            id: 'r1',
            rating: 5,
            productRef: 'p1',
            author: 'Ada',
            title: 'Excellent',
            body: 'Would buy again',
          ),
        ),
      ),
    );

    expect(find.text('Excellent'), findsOneWidget);
    expect(find.text('Would buy again'), findsOneWidget);
    expect(find.textContaining('Ada'), findsOneWidget);
  });

  testWidgets('shows the Verified badge only when verified', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const ReviewTile(
          review: ProductReview(
            id: 'r1',
            rating: 4,
            productRef: 'p1',
            verified: true,
          ),
        ),
      ),
    );
    expect(find.text('Verified'), findsOneWidget);

    await tester.pumpWidget(
      _wrap(
        const ReviewTile(
          review: ProductReview(id: 'r2', rating: 4, productRef: 'p1'),
        ),
      ),
    );
    expect(find.text('Verified'), findsNothing);
  });
}
