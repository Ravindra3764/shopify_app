import 'package:flutter/material.dart';
import 'package:shopify_app/shared/widgets/custom_background.dart';
import 'package:shopify_app/shared/widgets/empty_state_view.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomBackground(
      showBackButton: false,
      title: 'Profile',
      child: EmptyStateView(
        icon: Icons.person_outline,
        message: 'Sign in to view your profile.',
      ),
    );
  }
}
