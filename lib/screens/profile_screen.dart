import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/collage_manager.dart';
import '../services/purchase_service.dart';
import 'onboarding_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedPlanIndex = 1; // Default to monthly
  String? _lastPurchaseError;

  static const List<_PlanOption> _plans = [
    _PlanOption(
      id: 'weekly',
      productId: 'com.framelabs.customcollage.premium.weekly',
      label: 'Weekly',
      priceLabel: '€1.99 / week',
      fallbackBillingDetail: 'Renews automatically • cancel anytime',
      perks: ['Unlimited collage exports', 'Access all premium layouts'],
    ),
    _PlanOption(
      id: 'monthly',
      productId: 'com.framelabs.customcollage.premium.monthly',
      label: 'Monthly',
      priceLabel: '€5.99 / month',
      fallbackBillingDetail: 'Renews automatically • cancel anytime',
      perks: ['Unlimited collage exports', 'Access all premium layouts'],
      highlighted: true,
    ),
    _PlanOption(
      id: 'yearly',
      productId: 'com.framelabs.customcollage.premium.yearly',
      label: 'Yearly',
      priceLabel: '€39.99 / year',
      fallbackBillingDetail: 'Renews automatically • cancel anytime',
      perks: ['Unlimited collage exports', 'Access all premium layouts'],
    ),
  ];

  void _onPlanSelected(int index) {
    setState(() => _selectedPlanIndex = index);
  }

  Future<void> _handleSubscribe(
    CollageManager manager,
    PurchaseService purchaseService,
  ) async {
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

    if (!purchaseService.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'In-app purchases are unavailable on this device. Please try again later.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (purchaseService.productForId(plan.productId) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Plan "${plan.label}" is not configured yet. Please double-check the product ID ${plan.productId}.',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    print('trying to buy ${plan.productId}');
    await purchaseService.buy(plan.productId);
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

  Future<void> _openOnboardingGuide() async {
    final navigator = Navigator.of(context);
    await navigator.push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => OnboardingScreen(
          onFinished: () async {
            if (navigator.mounted) {
              navigator.pop();
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final collageManager = context.watch<CollageManager>();
    final purchaseService = context.watch<PurchaseService>();
    final bool isPremium = collageManager.isPremium;
    final String premiumName = collageManager.premiumName;
    final bool trialActive = collageManager.isTrialActive;
    final bool trialAvailable = collageManager.canStartTrial;
    final int trialDaysRemaining = collageManager.trialDaysRemaining;
    final int freeSavesRemaining = collageManager.freeSavesRemaining;

    final String? purchaseError = purchaseService.errorMessage;
    if (purchaseError != null && purchaseError != _lastPurchaseError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(purchaseError),
            duration: const Duration(seconds: 3),
          ),
        );
      });
      _lastPurchaseError = purchaseError;
    } else if (purchaseError == null && _lastPurchaseError != null) {
      _lastPurchaseError = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          if (purchaseService.isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: LinearProgressIndicator(minHeight: 3),
            ),
          if (!purchaseService.isLoading && !purchaseService.isAvailable)
            const _StoreUnavailableBanner(),
          // TODO(Ayca): remove this comment when needed
          // _UsageOverviewCard(
          //   theme: theme,
          //   isPremium: isPremium,
          //   trialAvailable: trialAvailable,
          //   trialActive: trialActive,
          //   trialDaysRemaining: trialDaysRemaining,
          //   freeSavesRemaining: freeSavesRemaining,
          //   premiumName: premiumName,
          //   onStartTrial: trialAvailable
          //       ? () => _startTrial(collageManager)
          //       : null,
          // ),
          const SizedBox(height: 18),
          _SubscriptionSection(
            theme: theme,
            isPremium: isPremium,
            purchaseService: purchaseService,
            plans: _plans,
            selectedIndex: _selectedPlanIndex,
            onPlanSelected: _onPlanSelected,
            onSubscribe: () =>
                _handleSubscribe(collageManager, purchaseService),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openOnboardingGuide,
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('How to Use'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: theme.colorScheme.primary,
                side: BorderSide(
                  color:
                      theme.colorScheme.primary.withValues(alpha: 0.35),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _LegalSection(theme: theme, purchaseService: purchaseService),
          const SizedBox(height: 18),
          // TODO(Ayca): remove this comment when needed
          // _DebugInfoSection(
          //   theme: theme,
          //   purchaseService: purchaseService,
          //   collageManager: collageManager,
          // ),
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
  final String premiumName;

  const _UsageOverviewCard({
    required this.theme,
    required this.isPremium,
    required this.trialAvailable,
    required this.trialActive,
    required this.trialDaysRemaining,
    required this.freeSavesRemaining,
    required this.onStartTrial,
    required this.premiumName,
  });

  @override
  Widget build(BuildContext context) {
    const int freeQuota = 3;
    final int remainingFree = freeSavesRemaining < 0
        ? freeQuota
        : (freeSavesRemaining > freeQuota ? freeQuota : freeSavesRemaining);
    final int usedFree = freeQuota - remainingFree;
    final double usageProgress = freeQuota == 0 ? 0.0 : usedFree / freeQuota;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
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
                ? '$premiumName - Active'
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
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.15,
                  ),
                  color: theme.colorScheme.primary,
                  minHeight: 6,
                ),
                const SizedBox(height: 6),
                Text(
                  'Used this week: $usedFree / $freeQuota',
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
                        foregroundColor: Colors.white,
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
  final PurchaseService purchaseService;
  final List<_PlanOption> plans;
  final int selectedIndex;
  final ValueChanged<int> onPlanSelected;
  final VoidCallback onSubscribe;

  const _SubscriptionSection({
    required this.theme,
    required this.isPremium,
    required this.purchaseService,
    required this.plans,
    required this.selectedIndex,
    required this.onPlanSelected,
    required this.onSubscribe,
  });

  static const double _weeksPerMonthEstimate = 4.0;
  static const double _weeksPerYearEstimate = 52.0;

  @override
  Widget build(BuildContext context) {
    final _PlanOption plan = plans[selectedIndex];
    final productDetails = purchaseService.productForId(plan.productId);
    final bool planAvailable = productDetails != null;
    final bool planMissing = purchaseService.notFoundProductIds.contains(
      plan.productId,
    );
    final String priceLabel = productDetails?.price ?? plan.priceLabel;
    _PlanOption? weeklyOption;
    for (final option in plans) {
      if (option.id == 'weekly') {
        weeklyOption = option;
        break;
      }
    }
    final ProductDetails? weeklyDetails = weeklyOption == null
        ? null
        : purchaseService.productForId(weeklyOption.productId);
    final String billingDetail = _buildBillingDetail(
      plan: plan,
      planDetails: productDetails,
      weeklyDetails: weeklyDetails,
    );

    final scheme = theme.colorScheme;
    if (isPremium) {
      return Container();
    }
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
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
                  ((constraints.maxWidth - totalSpacing) / plans.length).clamp(
                    80.0,
                    160.0,
                  );
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
                      backgroundColor: Colors.black.withValues(alpha: 0.05),
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        color: selected
                            ? Colors.white
                            : scheme.primary.withValues(alpha: 0.75),
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
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
                color: Colors.black.withValues(alpha: 0.08),
                width: 1.2,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  priceLabel,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  billingDetail,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary.withValues(alpha: 0.9),
                  ),
                ),
                if (!purchaseService.isLoading && !planAvailable)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Product ${plan.productId} is not yet available. Verify the product is created in App Store Connect and Play Console.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.redAccent.shade200,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else if (planMissing)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Product ${plan.productId} not returned by the store.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                ...plan.perks.map(
                  (perk) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('• $perk', style: theme.textTheme.bodyMedium),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isPremium || purchaseService.isProcessing
                        ? null
                        : onSubscribe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPremium
                          ? Colors.black.withValues(alpha: 0.08)
                          : scheme.primary,
                      foregroundColor: isPremium
                          ? Colors.black54
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      isPremium
                          ? 'Premium active'
                          : purchaseService.isProcessing
                          ? 'Processing...'
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

  String _buildBillingDetail({
    required _PlanOption plan,
    required ProductDetails? planDetails,
    required ProductDetails? weeklyDetails,
  }) {
    final String fallback = plan.fallbackBillingDetail;

    if (plan.id == 'weekly') {
      return fallback;
    }

    if (planDetails == null || weeklyDetails == null) {
      return fallback;
    }

    final double weeklyPrice = weeklyDetails.rawPrice;
    final double planPrice = planDetails.rawPrice;

    if (weeklyPrice <= 0 || planPrice <= 0) {
      return fallback;
    }

    double weeksEquivalent;
    switch (plan.id) {
      case 'monthly':
        weeksEquivalent = _weeksPerMonthEstimate;
        break;
      case 'yearly':
        weeksEquivalent = _weeksPerYearEstimate;
        break;
      default:
        return fallback;
    }

    final double referenceCost = weeklyPrice * weeksEquivalent;
    if (referenceCost <= 0) {
      return fallback;
    }

    final double savingsRatio =
        (referenceCost - planPrice) / referenceCost * 100;
    print('$savingsRatio');

    if (savingsRatio.abs() < 0.005) {
      return 'Same cost as weekly • renews automatically, cancel anytime';
    }

    final String percentage = savingsRatio.abs().toStringAsFixed(0);

    if (savingsRatio > 0) {
      return 'Save $percentage% vs weekly • renews automatically, cancel anytime';
    }

    return 'Costs $percentage% more vs weekly • renews automatically, cancel anytime';
  }
}

class _PlanOption {
  final String id;
  final String productId;
  final String label;
  final String priceLabel;
  final String fallbackBillingDetail;
  final List<String> perks;
  final bool highlighted;

  const _PlanOption({
    required this.id,
    required this.productId,
    required this.label,
    required this.priceLabel,
    required this.fallbackBillingDetail,
    required this.perks,
    this.highlighted = false,
  });
}

class _LegalSection extends StatelessWidget {
  static final Uri _termsOfUseUri = Uri.parse(
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
  );
  static final Uri _privacyPolicyUri = Uri.parse(
    'https://aycabadem.github.io/custom-photo-collage/privacy',
  );

  final ThemeData theme;
  final PurchaseService purchaseService;

  const _LegalSection({required this.theme, required this.purchaseService});

  @override
  Widget build(BuildContext context) {
    final tiles = <_LegalLink>[
      _LegalLink(
        title: 'Terms of Use',
        onTap: () => _openExternalUrl(context, _termsOfUseUri),
      ),
      _LegalLink(
        title: 'Privacy Policy',
        onTap: () => _openExternalUrl(context, _privacyPolicyUri),
      ),
      _LegalLink(
        title: 'Restore Purchases',
        onTap: () {
          if (purchaseService.isProcessing) return;
          purchaseService.restore();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Restore requested. If you have active purchases they will unlock shortly.',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        },
      ),
    ];

    final Uri? managementUri = purchaseService.subscriptionManagementUri;
    if (purchaseService.hasActiveSubscription && managementUri != null) {
      tiles.add(
        _LegalLink(
          title: 'Cancel Subscription',
          onTap: () => _openSubscriptionManagement(context, purchaseService),
        ),
      );
    }

    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
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
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.primary.withValues(alpha: 0.7),
                ),
                onTap: tile.onTap,
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Colors.black.withValues(alpha: 0.08),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  static Future<void> _openExternalUrl(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        _showLaunchError(messenger);
      }
    } catch (_) {
      _showLaunchError(messenger);
    }
  }

  static void _showLaunchError(ScaffoldMessengerState messenger) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Unable to open link. Please try again later.'),
      ),
    );
  }

  static Future<void> _openSubscriptionManagement(
    BuildContext context,
    PurchaseService purchaseService,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final Uri? uri = purchaseService.subscriptionManagementUri;
    if (uri == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Subscription management is not available on this platform.',
          ),
        ),
      );
      return;
    }
    try {
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        _showLaunchError(messenger);
      }
    } catch (_) {
      _showLaunchError(messenger);
    }
  }
}

class _DebugInfoSection extends StatelessWidget {
  final ThemeData theme;
  final PurchaseService purchaseService;
  final CollageManager collageManager;

  const _DebugInfoSection({
    required this.theme,
    required this.purchaseService,
    required this.collageManager,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = theme.textTheme.bodySmall?.copyWith(height: 1.4);

    final List<String> productDescriptions = purchaseService.products.isEmpty
        ? const ['No products returned from the store yet.']
        : purchaseService.products.map((product) {
            final DateTime? expiration = purchaseService.expirationForProduct(
              product.id,
            );
            final bool isActive =
                purchaseService.activePlanProductId == product.id;
            final String status = isActive
                ? 'ACTIVE'
                : purchaseService.hasActiveSubscription
                ? 'INACTIVE'
                : 'NOT PURCHASED';
            return '${product.id} • ${product.price} '
                '(${product.currencyCode}) • status: $status '
                '• expires: ${expiration == null ? '—' : expiration.toLocal()}';
          }).toList();

    final String notFoundProducts = purchaseService.notFoundProductIds.isEmpty
        ? '—'
        : purchaseService.notFoundProductIds.join(', ');

    final Uri? managementUri = purchaseService.subscriptionManagementUri;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Diagnostics (TestFlight)',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _DebugInfoRow(
            label: 'IAP available',
            value: '${purchaseService.isAvailable}',
            style: textStyle,
          ),
          _DebugInfoRow(
            label: 'Loading',
            value: '${purchaseService.isLoading}',
            style: textStyle,
          ),
          _DebugInfoRow(
            label: 'Processing',
            value: '${purchaseService.isProcessing}',
            style: textStyle,
          ),
          _DebugInfoRow(
            label: 'Active product',
            value: purchaseService.activePlanProductId ?? '—',
            style: textStyle,
          ),
          _DebugInfoRow(
            label: 'Has entitlement',
            value: '${purchaseService.hasActiveSubscription}',
            style: textStyle,
          ),
          _DebugInfoRow(
            label: 'Last error',
            value: purchaseService.errorMessage ?? '—',
            style: textStyle,
          ),
          _DebugInfoRow(
            label: 'Management URL',
            value: managementUri?.toString() ?? '—',
            style: textStyle,
          ),
          _DebugInfoRow(
            label: 'Not found products',
            value: notFoundProducts,
            style: textStyle,
          ),
          const Divider(height: 28),
          Text(
            'User details',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _DebugInfoRow(
            label: 'Premium flag',
            value: '${collageManager.isPremium}',
            style: textStyle,
          ),
          _DebugInfoRow(
            label: 'Premium name',
            value: collageManager.premiumName.isEmpty
                ? '—'
                : collageManager.premiumName,
            style: textStyle,
          ),
          _DebugInfoRow(
            label: 'Trial active',
            value: '${collageManager.isTrialActive}',
            style: textStyle,
          ),
          _DebugInfoRow(
            label: 'Trial days left',
            value: '${collageManager.trialDaysRemaining}',
            style: textStyle,
          ),
          _DebugInfoRow(
            label: 'Free saves left',
            value: collageManager.freeSavesRemaining < 0
                ? 'Unlimited'
                : '${collageManager.freeSavesRemaining}',
            style: textStyle,
          ),
          _DebugInfoRow(
            label: 'Weekly saves used',
            value: '${collageManager.weeklySavesUsed}',
            style: textStyle,
          ),
          _DebugInfoRow(
            label: 'Weekly limit',
            value: collageManager.weeklySaveLimit < 0
                ? 'Unlimited'
                : '${collageManager.weeklySaveLimit}',
            style: textStyle,
          ),
          const Divider(height: 28),
          Text(
            'Store products',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...productDescriptions.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: SelectableText(line, style: textStyle),
            ),
          ),
        ],
      ),
    );
  }
}

class _DebugInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? style;

  const _DebugInfoRow({required this.label, required this.value, this.style});

  @override
  Widget build(BuildContext context) {
    final TextStyle labelStyle =
        (style ?? Theme.of(context).textTheme.bodySmall ?? const TextStyle())
            .copyWith(fontWeight: FontWeight.w600);
    final TextStyle valueStyle =
        style ?? Theme.of(context).textTheme.bodySmall ?? const TextStyle();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: labelStyle)),
          const SizedBox(width: 8),
          Expanded(child: SelectableText(value, style: valueStyle)),
        ],
      ),
    );
  }
}

class _StoreUnavailableBanner extends StatelessWidget {
  const _StoreUnavailableBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Text(
        'In-app purchases are currently unavailable. Sign in with a store test account or finish store setup before testing purchases.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: Colors.orange.shade800,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LegalLink {
  final String title;
  final VoidCallback onTap;

  const _LegalLink({required this.title, required this.onTap});
}
