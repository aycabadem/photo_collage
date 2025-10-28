import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/collage_manager.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final collageManager = context.watch<CollageManager>();
    final bool isPremium = collageManager.isPremium;

    void handleSubscribe() {
      if (isPremium) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You already have premium access.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      collageManager.setPremium(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Premium unlocked! Enjoy unlimited layouts.'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        backgroundColor: const Color(0xFFFCFAEE),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFFCFAEE),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          _FreeUsageCard(theme: theme, isPremium: isPremium),
          const SizedBox(height: 18),
          _SubscriptionSection(
            theme: theme,
            isPremium: isPremium,
            onSubscribe: handleSubscribe,
          ),
          const SizedBox(height: 18),
          _LegalSection(theme: theme),
        ],
      ),
    );
  }
}

class _FreeUsageCard extends StatelessWidget {
  final ThemeData theme;
  final bool isPremium;

  const _FreeUsageCard({required this.theme, required this.isPremium});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPremium ? 'Premium active' : 'Free plan',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (isPremium)
            const Text(
              'Unlimited collage exports, premium layouts and future features are all unlocked.',
            )
          else ...[
            const Text(
              'You can save 1 collage per week. Upgrade to unlock unlimited saves, premium layouts and more.',
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: 1.0,
              backgroundColor: const Color(0xFFE5E7EB),
              color: theme.colorScheme.primary,
              minHeight: 6,
            ),
            const SizedBox(height: 6),
            Text(
              'Weekly saves used: 1 / 1',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubscriptionSection extends StatelessWidget {
  final ThemeData theme;
  final bool isPremium;
  final VoidCallback onSubscribe;

  const _SubscriptionSection({
    required this.theme,
    required this.isPremium,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final plans = [
      const _Plan(
        title: 'Weekly Pass',
        price: '\$3.49 / week',
        perks: [
          'Unlimited collage exports',
          'Remove weekly cap',
          'All premium layouts',
        ],
      ),
      const _Plan(
        title: 'Monthly Pass',
        price: '\$7.99 / month',
        perks: [
          'Unlimited collage exports',
          'Premium layouts & effects',
          'Priority feature previews',
        ],
        highlighted: true,
      ),
      const _Plan(
        title: 'Annual Pass',
        price: '\$49.99 / year',
        perks: [
          'Unlimited collage exports',
          'Save 48% vs monthly',
          'VIP feature previews',
        ],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upgrade for unlimited access',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ...plans.map(
          (plan) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _PlanCard(
              plan: plan,
              theme: theme,
              isPremium: isPremium,
              onSubscribe: onSubscribe,
            ),
          ),
        ),
      ],
    );
  }
}

class _Plan {
  final String title;
  final String price;
  final List<String> perks;
  final bool highlighted;

  const _Plan({
    required this.title,
    required this.price,
    required this.perks,
    this.highlighted = false,
  });
}

class _PlanCard extends StatelessWidget {
  final _Plan plan;
  final ThemeData theme;
  final bool isPremium;
  final VoidCallback onSubscribe;

  const _PlanCard({
    required this.plan,
    required this.theme,
    required this.isPremium,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = plan.highlighted
        ? theme.colorScheme.primary
        : const Color(0xFFE5E7EB);
    final backgroundColor =
        plan.highlighted ? theme.colorScheme.primary.withValues(alpha: 0.07) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.price,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (plan.highlighted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Best value',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...plan.perks.map(
            (perk) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(perk)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isPremium ? null : onSubscribe,
              style: ElevatedButton.styleFrom(
                backgroundColor: isPremium
                    ? theme.colorScheme.primary.withValues(alpha: 0.4)
                    : theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isPremium ? 'Subscribed' : 'Subscribe',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  final ThemeData theme;

  const _LegalSection({required this.theme});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _LegalLink(
        title: 'Terms of Use',
        onTap: () => _showPlaceholderDocument(
          context,
          title: 'Terms of Use',
          body: _termsOfUseText,
        ),
      ),
      _LegalLink(
        title: 'Privacy Policy',
        onTap: () => _showPlaceholderDocument(
          context,
          title: 'Privacy Policy',
          body: _privacyPolicyText,
        ),
      ),
      _LegalLink(
        title: 'Restore Purchases',
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Restore will be available when subscriptions launch.'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: tiles.map((tile) {
          final isLast = tile == tiles.last;
          return Column(
            children: [
              ListTile(
                title: Text(
                  tile.title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: tile.onTap,
              ),
              if (!isLast)
                const Divider(
                  height: 1,
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _LegalLink {
  final String title;
  final VoidCallback onTap;

  const _LegalLink({
    required this.title,
    required this.onTap,
  });
}

void _showPlaceholderDocument(
  BuildContext context, {
  required String title,
  required String body,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Text(body),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

const String _termsOfUseText = '''
Terms of Use

By downloading or using this App, you agree to the following terms:

• The App is provided for personal use only.
• Users must not misuse or modify the App.
• Free users have limited weekly usage. Premium features are available through paid subscriptions.
• All purchases and subscriptions are processed through Google Play or the App Store, following their payment terms and refund policies.
• The App may change features, prices, or terms at any time.

Version: 1.0.0.
''';

const String _privacyPolicyText = '''
Privacy Policy
Last updated: October 2025

This app (“Custom Collage”) respects your privacy. By using the App, you agree to this Privacy Policy.

1. Data Collection
The App does not collect or store any personal data. It only asks for access to your device’s photos in order to create collages. Your photos are never uploaded or shared; all processing happens locally on your device.

2. Purchases and Payments
The App uses Google Play Billing and App Store Subscriptions to manage premium features and payments. These services handle your payment information securely and follow their own privacy policies.

3. Security
The App does not transfer or store any user data on external servers.

4. Changes
This Privacy Policy may be updated from time to time. The latest version will always be available within the App or on the developer’s website.
''';
