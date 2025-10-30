import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/collage_manager.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedPlanIndex = 1; // Default to monthly

  static const List<_PlanOption> _plans = [
    _PlanOption(
      id: 'weekly',
      label: 'Weekly',
      priceLabel: '€1.99 / week',
      billingDetail: 'Renews automatically • cancel anytime',
      perks: [
        'Unlimited collage exports',
        'Access all premium layouts',
      ],
    ),
    _PlanOption(
      id: 'monthly',
      label: 'Monthly',
      priceLabel: '€5.99 / month',
      billingDetail: 'Save 25% vs weekly • renews automatically, cancel anytime',
      perks: [
        'Unlimited collage exports',
        'Access all premium layouts',
      ],
      highlighted: true,
    ),
    _PlanOption(
      id: 'yearly',
      label: 'Yearly',
      priceLabel: '€39.99 / year',
      billingDetail: 'Save 61% vs weekly • renews automatically, cancel anytime',
      perks: [
        'Unlimited collage exports',
        'Access all premium layouts',
      ],
    ),
  ];

  void _onPlanSelected(int index) {
    setState(() => _selectedPlanIndex = index);
  }

  void _handleSubscribe(CollageManager manager) {
    final plan = _plans[_selectedPlanIndex];

    if (manager.isPremium) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You already have premium access.'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    manager.setPremium(true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${plan.label} plan activated! Enjoy unlimited access.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _startTrial(CollageManager manager) {
    final started = manager.startTrial();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          started
              ? 'Free trial started! Enjoy unlimited access for 3 days.'
              : 'Free trial is no longer available.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final collageManager = context.watch<CollageManager>();
    final bool isPremium = collageManager.isPremium;
    final bool trialActive = collageManager.isTrialActive;
    final bool trialAvailable = collageManager.canStartTrial;
    final int trialDaysRemaining = collageManager.trialDaysRemaining;
    final int freeSavesRemaining = collageManager.freeSavesRemaining;

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: scheme.background,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          _UsageOverviewCard(
            theme: theme,
            isPremium: isPremium,
            trialAvailable: trialAvailable,
            trialActive: trialActive,
            trialDaysRemaining: trialDaysRemaining,
            freeSavesRemaining: freeSavesRemaining,
            onStartTrial: trialAvailable ? () => _startTrial(collageManager) : null,
          ),
          const SizedBox(height: 18),
          _SubscriptionSection(
            theme: theme,
            isPremium: isPremium,
            plans: _plans,
            selectedIndex: _selectedPlanIndex,
            onPlanSelected: _onPlanSelected,
            onSubscribe: () => _handleSubscribe(collageManager),
          ),
          const SizedBox(height: 18),
          _LegalSection(theme: theme),
        ],
      ),
    );
  }
}

class _UsageOverviewCard extends StatelessWidget {
  final ThemeData theme;
  final bool isPremium;
  final bool trialAvailable;
  final bool trialActive;
  final int trialDaysRemaining;
  final int freeSavesRemaining;
  final VoidCallback? onStartTrial;

  const _UsageOverviewCard({
    required this.theme,
    required this.isPremium,
    required this.trialAvailable,
    required this.trialActive,
    required this.trialDaysRemaining,
    required this.freeSavesRemaining,
    required this.onStartTrial,
  });

  @override
  Widget build(BuildContext context) {
    const int _freeQuota = 3;
    final int remainingFree = freeSavesRemaining < 0
        ? _freeQuota
        : (freeSavesRemaining > _freeQuota ? _freeQuota : freeSavesRemaining);
    final int usedFree = _freeQuota - remainingFree;
    final double usageProgress = _freeQuota == 0 ? 0.0 : usedFree / _freeQuota;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPremium
                ? 'Premium active'
                : trialActive
                    ? 'Free trial active'
                    : 'Free plan',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (isPremium)
            Text(
              'Unlimited collage exports, premium layouts and all upcoming features are unlocked.',
              style: theme.textTheme.bodyMedium,
            )
          else if (trialActive)
            Text(
              'Enjoy unlimited exports during your free trial. ${_trialDaysLabel(trialDaysRemaining)} remaining.',
              style: theme.textTheme.bodyMedium,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You can save up to 3 collages per week. Free saves left this week: $remainingFree.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: usageProgress.clamp(0.0, 1.0),
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                  color: theme.colorScheme.primary,
                  minHeight: 6,
                ),
                const SizedBox(height: 6),
                Text(
                  'Used this week: $usedFree / $_freeQuota',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (trialAvailable) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Need more saves? Start your 3-day unlimited trial anytime.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onStartTrial,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Start 3-day trial',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

String _trialDaysLabel(int daysRemaining) {
  if (daysRemaining <= 0) return 'Less than a day';
  return daysRemaining == 1 ? '1 day' : '$daysRemaining days';
}

class _SubscriptionSection extends StatelessWidget {
  final ThemeData theme;
  final bool isPremium;
  final List<_PlanOption> plans;
  final int selectedIndex;
  final ValueChanged<int> onPlanSelected;
  final VoidCallback onSubscribe;

  const _SubscriptionSection({
    required this.theme,
    required this.isPremium,
    required this.plans,
    required this.selectedIndex,
    required this.onPlanSelected,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final _PlanOption plan = plans[selectedIndex];

    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upgrade for unlimited access',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final double totalSpacing = 16; // spacing of 8 between 3 chips
              final double chipWidth =
                  ((constraints.maxWidth - totalSpacing) / plans.length).clamp(80.0, 160.0);
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: List.generate(plans.length, (index) {
                  final option = plans[index];
                  final bool selected = index == selectedIndex;
                  return SizedBox(
                    width: chipWidth,
                    child: ChoiceChip(
                      label: Text(option.label, textAlign: TextAlign.center),
                      selected: selected,
                      onSelected: (value) {
                        if (!value) return;
                        onPlanSelected(index);
                      },
                      selectedColor: scheme.primary,
                      backgroundColor: Colors.white12,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        color: selected ? Colors.black : scheme.primary.withOpacity(0.7),
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white12,
                width: 1.2,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.priceLabel,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  plan.billingDetail,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 16),
                ...plan.perks.map(
                  (perk) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '• $perk',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isPremium ? null : onSubscribe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isPremium ? Colors.white24 : scheme.primary,
                      foregroundColor: isPremium ? Colors.black54 : Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      isPremium
                          ? 'Premium active'
                          : 'Start ${plan.label.toLowerCase()} plan',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanOption {
  final String id;
  final String label;
  final String priceLabel;
  final String billingDetail;
  final List<String> perks;
  final bool highlighted;

  const _PlanOption({
    required this.id,
    required this.label,
    required this.priceLabel,
    required this.billingDetail,
    required this.perks,
    this.highlighted = false,
  });
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
              content: Text(
                'Restore will be available when subscriptions launch.',
              ),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    ];

    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 18,
            offset: Offset(0, 10),
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
                trailing: Icon(Icons.chevron_right_rounded,
                    color: scheme.primary.withOpacity(0.7)),
                onTap: tile.onTap,
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Colors.white10,
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
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
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
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.18),
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
