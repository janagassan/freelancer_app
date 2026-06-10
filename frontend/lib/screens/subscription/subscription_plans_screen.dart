// screens/subscription/subscription_plans_screen.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../models/subscription_plan_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  List<SubscriptionPlan> _plans = [];
  bool _loading = true;
  bool _isPurchasing = false;
  final TextEditingController _couponController = TextEditingController();
  String? _couponError;
  bool _couponApplied = false;
  Map<String, dynamic>? _appliedCoupon;
  String? _selectedPlanSlug;
  String? _activeCouponPlanSlug;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    final t = AppLocalizations.of(context)!;
    setState(() => _loading = true);
    try {
      final response = await ApiService.getSubscriptionPlans();
      print('📊 Subscription response: $response');

      if (response['success'] == true && response['plans'] != null) {
        final plansList = response['plans'] as List;
        setState(() {
          _plans = plansList.map((p) => SubscriptionPlan.fromJson(p)).toList();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
      Fluttertoast.showToast(msg: '${t.errorLoadingPlans}: $e');
    }
  }

  Future<void> _applyCoupon(String planSlug) async {
    final t = AppLocalizations.of(context)!;
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _couponError = t.enterCouponCode);
      return;
    }
    setState(() => _couponError = null);
    try {
      final result = await ApiService.validateCoupon(code, planSlug);
      if (result['valid'] == true) {
        final discount = result['discount']['value'];
        setState(() {
          _couponApplied = true;
          _appliedCoupon = result['coupon'];
          _activeCouponPlanSlug = planSlug;
          _couponError = null;
        });
        Fluttertoast.showToast(
          msg: '🎉 ${t.couponAppliedSuccess} $discount% ${t.off}',
          backgroundColor: AppColors.success,
        );
      } else {
        setState(() => _couponError = result['message'] ?? t.invalidCoupon);
      }
    } catch (e) {
      setState(() => _couponError = t.errorValidatingCoupon);
    }
  }

  void _clearCouponForDifferentPlan(String planSlug) {
    if (_couponApplied && _activeCouponPlanSlug != null && _activeCouponPlanSlug != planSlug) {
      _couponApplied = false;
      _appliedCoupon = null;
      _couponError = null;
      _couponController.clear();
      _activeCouponPlanSlug = null;
    }
  }

  Future<void> _subscribe(SubscriptionPlan plan) async {
    final t = AppLocalizations.of(context)!;
    if (plan.price == 0) {
      Fluttertoast.showToast(msg: t.alreadyOnFreePlan);
      return;
    }

    setState(() {
      _isPurchasing = true;
      _selectedPlanSlug = plan.slug;
    });

    try {
      final checkoutUrl = await ApiService.createSubscriptionCheckoutSessionDirect(
        plan.slug,
        couponCode: (_couponApplied && _activeCouponPlanSlug == plan.slug) ? _couponController.text : null,
      );

      if (checkoutUrl == null || checkoutUrl.isEmpty) throw Exception(t.failedToCreateCheckout);

      final uri = Uri.parse(checkoutUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        Fluttertoast.showToast(
          msg: t.completePaymentInBrowser,
          backgroundColor: Theme.of(context).colorScheme.primary,
        );
        if (mounted) Navigator.pop(context);
      } else {
        throw Exception(t.couldNotLaunchCheckout);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '${t.subscriptionFailed}: $e');
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  Future<void> _activateManually(SubscriptionPlan plan) async {
    final t = AppLocalizations.of(context)!;
    setState(() => _isPurchasing = true);
    try {
      final response = await ApiService.manualActivateSubscription(plan.slug);
      if (response['success'] == true) {
        Fluttertoast.showToast(msg: '✅ ${response['message']}');
        if (mounted) Navigator.pushReplacementNamed(context, '/subscription/my');
      } else {
        Fluttertoast.showToast(msg: response['message'] ?? t.errorActivating);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '${t.error}: $e');
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final cardWidth = isSmallScreen ? 280.0 : 320.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _loading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 280,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildHero(t),
                    collapseMode: CollapseMode.parallax,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverToBoxAdapter(
                    child: SizedBox(
                      height: 520,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _plans.length,
                        itemBuilder: (context, index) {
                          _clearCouponForDifferentPlan(_plans[index].slug);
                          return Container(
                            width: cardWidth,
                            margin: const EdgeInsets.only(right: 16),
                            child: _buildPlanCard(_plans[index], t),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
    );
  }

  Widget _buildHero(AppLocalizations t) {
    final theme = Theme.of(context);
    
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage('https://images.unsplash.com/photo-1529156069898-49953e39b3ac'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [theme.colorScheme.primary.withOpacity(0.75), theme.colorScheme.secondary.withOpacity(0.85)],
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                t.yourPlanYourChoice,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 10, color: Colors.black26)],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                t.chooseWhatFitsYou,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan, AppLocalizations t) {
    final theme = Theme.of(context);
    final isFree = plan.price == 0;
    final isPopular = plan.slug == 'pro';
    final isProcessing = _isPurchasing && _selectedPlanSlug == plan.slug;
    final hasCouponForThisPlan = _couponApplied && _activeCouponPlanSlug == plan.slug;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(blurRadius: 25, color: theme.shadowColor.withOpacity(0.15), offset: const Offset(0, 8))],
        border: isPopular ? Border.all(color: AppColors.warning, width: 2) : null,
      ),
      child: Column(
        children: [
          if (isPopular || isFree)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                gradient: isPopular ? const LinearGradient(colors: [Colors.amber, Colors.orange]) : LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade500]),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isPopular ? Icons.emoji_events : Icons.free_breakfast, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    isPopular ? t.mostPopular.toUpperCase() : t.freePlan.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.name, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        plan.formattedPrice,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isFree ? theme.colorScheme.onSurface.withOpacity(0.6) : theme.colorScheme.primary,
                        ),
                      ),
                      if (!isFree) Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 6),
                        child: Text(t.perMonth, style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ),
                    ],
                  ),
                  if (plan.description != null) ...[
                    const SizedBox(height: 12),
                    Text(plan.description!, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 13)),
                  ],
                  const SizedBox(height: 20),
                  Divider(color: theme.dividerColor),
                  const SizedBox(height: 12),
                  Text(t.whatsIncluded, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 12),
                  ...plan.features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                          child: Icon(Icons.check, size: 14, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_translateFeature(feature, t), style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface))),
                      ],
                    ),
                  )),
                  if (!isFree)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [theme.colorScheme.primary.withOpacity(0.1), theme.colorScheme.secondary.withOpacity(0.1)]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.rocket, size: 18, color: theme.colorScheme.primary),
                            const SizedBox(width: 10),
                            Expanded(child: Text(t.freeTrialMessage, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface))),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.dividerColor))),
            child: Column(
              children: [
                if (!isFree) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _couponController,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          decoration: InputDecoration(
                            hintText: t.couponCodeHint,
                            hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                            errorText: _couponError,
                            filled: true,
                            fillColor: theme.scaffoldBackgroundColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => _applyCoupon(plan.slug),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(14)),
                          child: Text(t.apply, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  if (hasCouponForThisPlan && _appliedCoupon != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            const Icon(Icons.local_offer, size: 14, color: AppColors.success),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${t.couponAppliedLabel} ${_appliedCoupon!['code']}',
                                style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isProcessing ? null : () => _subscribe(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFree ? theme.colorScheme.onSurface.withOpacity(0.1) : theme.colorScheme.primary,
                      foregroundColor: isFree ? theme.colorScheme.onSurface : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: isProcessing
                        ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(isFree ? t.currentPlan : t.startFreeTrial, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
                if (!isFree)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _activateManually(plan),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.developer_mode, size: 14, color: AppColors.warning),
                              const SizedBox(width: 6),
                              Text(t.devActivateManually, style: TextStyle(fontSize: 11, color: AppColors.warning)),
                            ],
                          ),
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

  String _translateFeature(String feature, AppLocalizations t) {
    switch (feature) {
      case 'Basic features':
        return t.basicFeatures;
      case 'Limited proposals':
        return t.limitedProposals;
      case '1 active project':
        return t.oneActiveProject;
      case 'Unlimited proposals':
        return t.unlimitedProposals;
      case '10 active projects':
        return t.tenActiveProjects;
      case 'AI insights':
        return t.aiInsights;
      case 'Priority support':
        return t.prioritySupport;
      case 'API access':
        return t.apiAccess;
      case 'Custom branding':
        return t.customBranding;
      case 'Advanced analytics':
        return t.advancedAnalytics;
      case 'Team management':
        return t.teamManagement;
      default:
        return feature;
    }
  }
}