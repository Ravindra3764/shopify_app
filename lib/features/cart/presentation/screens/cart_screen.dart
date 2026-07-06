import 'package:flutter/material.dart';
import 'package:shopify_app/shared/widgets/custom_background.dart';
import 'package:shopify_app/shared/widgets/empty_state_view.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomBackground(
      showBackButton: false,
      title: 'Cart',
      child: EmptyStateView(
        icon: Icons.shopping_bag_outlined,
        message: 'Your cart is empty.',
      ),
    );
  }
}
