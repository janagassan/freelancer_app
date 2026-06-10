// screens/subscription/my_subscription_screen.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../l10n/app_localizations.dart';
import '../../models/subscription_plan_model.dart';
import '../../models/user_subscription_model.dart';
import '../../models/usage_limits_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class MySubscriptionScreen extends StatefulWidget {
  const MySubscriptionScreen({super.key});

  @override
  State<MySubscriptionScreen> createState() => _MySubscriptionScreenState();
}

class _MySubscriptionScreenState extends State<MySubscriptionScreen>
    with SingleTickerProviderStateMixin {
  UserSubscription? _subscription;
  UsageLimits? _usage;
  List<MonthlyUsage> _monthlyUsage = [];
  bool _loading = true;
  bool _canceling = false;
  String? _errorMessage;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final t = AppLocalizations.of(context)!;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final subscriptionFuture = ApiService.getUserSubscription();
      final usageFuture = ApiService.getUserUsage();
      
      final subscriptionRes = await subscriptionFuture;
      final usageRes = await usageFuture;
      
      await _processSubscriptionData(subscriptionRes);
      await _processUsageData(usageRes);
      
      try {
        final dashboardRes = await ApiService.getClientDashboardOverview();
        if (dashboardRes.containsKey('monthlySpending') && dashboardRes['monthlySpending'] is List) {
          final monthlyData = dashboardRes['monthlySpending'] as List;
          _monthlyUsage = monthlyData.map((e) {
            if (e is Map<String, dynamic>) {
              return MonthlyUsage(
                month: e['label']?.toString() ?? '',
                proposals: (e['total'] ?? 0).toInt(),
                projects: (e['projects'] ?? 0).toInt(),
              );
            }
            return MonthlyUsage(month: '', proposals: 0, projects: 0);
          }).where((m) => m.month.isNotEmpty).toList();
        }
      } catch (e) {
        print('⚠️ Could not load monthly usage from dashboard: $e');
      }
      
      if (_monthlyUsage.isEmpty) {
        _monthlyUsage = _getFallbackMonthlyUsage(t);
      }

      setState(() => _loading = false);
    } catch (e) {
      print('❌ Error loading data: $e');
      setState(() {
        _loading = false;
        _errorMessage = '${t.errorLoadingData}: $e';
      });
      Fluttertoast.showToast(msg: '${t.errorLoadingData}: $e');
    }
  }

  Future<void> _processSubscriptionData(Map<String, dynamic> subscriptionRes) async {
    try {
      if (subscriptionRes.isNotEmpty && subscriptionRes['success'] == true) {
        final subData = subscriptionRes['subscription'];
        
        if (subData != null && subData is Map) {
          if (subData.containsKey('plan')) {
            _subscription = UserSubscription.fromJson(subData as Map<String, dynamic>);
          } else if (subData.containsKey('name')) {
            final plan = SubscriptionPlan.fromJson(subData as Map<String, dynamic>);
            _subscription = UserSubscription(
              id: subData['id'] ?? 0,
              plan: plan,
              status: subData['status'] ?? 'active',
              currentPeriodStart: subData['current_period_start'] != null 
                  ? DateTime.parse(subData['current_period_start']) 
                  : DateTime.now(),
              currentPeriodEnd: subData['current_period_end'] != null 
                  ? DateTime.parse(subData['current_period_end']) 
                  : DateTime.now().add(const Duration(days: 30)),
              cancelAtPeriodEnd: subData['cancel_at_period_end'] ?? false,
            );
          }
        }
      }

      if (_subscription == null) {
        print('⚠️ No subscription found, using free plan');
        _subscription = _getFreePlanSubscription();
      }
    } catch (e) {
      print('❌ Error parsing subscription: $e');
      _subscription = _getFreePlanSubscription();
    }
  }

  Future<void> _processUsageData(Map<String, dynamic> usageRes) async {
  try {
    if (usageRes.isNotEmpty && usageRes['success'] == true && usageRes['usage'] != null) {
      _usage = UsageLimits.fromJson(usageRes['usage']);
    }
  } catch (e) {
    print('❌ Error parsing usage: $e');
  }

  if (_usage == null && _subscription != null) {
    _usage = UsageLimits(
      proposalsUsed: 0,
      proposalsLimit: _subscription!.plan.proposalLimit,
      activeProjectsUsed: 0,
      activeProjectsLimit: _subscription!.plan.activeProjectLimit,
      interviewsUsed: 0,
      interviewsLimit: null,
      planSlug: _subscription!.plan.slug,
      planName: _subscription!.plan.name,
    );
  }
}

  UserSubscription _getFreePlanSubscription() {
    final freePlan = SubscriptionPlan(
      id: 0,
      name: 'Free',
      slug: 'free',
      price: 0,
      billingPeriod: 'monthly',
      features: ['Basic features', 'Limited proposals', '1 active project'],
      proposalLimit: 5,
      activeProjectLimit: 1,
      aiInsights: false,
      prioritySupport: false,
      apiAccess: false,
      customBranding: false,
      trialDays: 0,
      sortOrder: 0,
      isRecommended: false,
      isActive: true,
    );
    
    return UserSubscription(
      id: 0,
      plan: freePlan,
      status: 'active',
      currentPeriodStart: DateTime.now(),
      currentPeriodEnd: DateTime.now().add(const Duration(days: 30)),
      cancelAtPeriodEnd: false,
    );
  }

  List<MonthlyUsage> _getFallbackMonthlyUsage(AppLocalizations t) {
    final now = DateTime.now();
    final months = <String>[];
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      months.add(_getMonthAbbr(date.month, t));
    }
    
    return [
      MonthlyUsage(month: months[0], proposals: 2, projects: 1),
      MonthlyUsage(month: months[1], proposals: 4, projects: 1),
      MonthlyUsage(month: months[2], proposals: 6, projects: 1),
      MonthlyUsage(month: months[3], proposals: 8, projects: 2),
      MonthlyUsage(month: months[4], proposals: 10, projects: 2),
      MonthlyUsage(month: months[5], proposals: 12, projects: 2),
    ];
  }

  String _getMonthAbbr(int month, AppLocalizations t) {
    switch (month) {
      case 1: return t.jan;
      case 2: return t.feb;
      case 3: return t.mar;
      case 4: return t.apr;
      case 5: return t.may;
      case 6: return t.jun;
      case 7: return t.jul;
      case 8: return t.aug;
      case 9: return t.sep;
      case 10: return t.oct;
      case 11: return t.nov;
      case 12: return t.dec;
      default: return '';
    }
  }

  Future<void> _cancelSubscription() async {
    final t = AppLocalizations.of(context)!;
    if (_subscription == null || _subscription!.isFree) return;

    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(t.cancelSubscription, style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Text(
          t.cancelSubscriptionConfirmation,
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.noKeepIt, style: TextStyle(color: AppColors.gray)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(t.yesCancel),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _canceling = true);
    try {
      final response = await ApiService.cancelSubscription();
      if (response['success'] == true) {
        Fluttertoast.showToast(msg: t.subscriptionCanceledSuccess);
        _loadData();
      } else {
        Fluttertoast.showToast(msg: response['message'] ?? t.errorCanceling);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '${t.error}: $e');
    } finally {
      setState(() => _canceling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t.loadingSubscription,
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ],
              ),
            )
          : _errorMessage != null
          ? _buildErrorState(t)
          : _subscription == null
          ? _buildNoSubscriptionState(t)
          : CustomScrollView(
              slivers: [
                _buildHeroSliver(t),
                SliverToBoxAdapter(child: _buildTabBar(t)),
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [_buildOverviewTab(t), _buildAnalyticsTab(t)],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildErrorState(AppLocalizations t) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _errorMessage!,
            style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text(t.tryAgain),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSliver(AppLocalizations t) {
    final theme = Theme.of(context);
    final plan = _subscription!.plan;
    final isFree = plan.price == 0;
    final gradientColors = isFree 
        ? [Colors.grey.withOpacity(0.85), Colors.grey.shade800.withOpacity(0.95)]
        : [theme.colorScheme.primary.withOpacity(0.85), theme.colorScheme.secondary.withOpacity(0.95)];

    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1554224155-8d04cb21cd6c'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradientColors,
                ),
              ),
            ),
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Icon(
                      isFree ? Icons.free_breakfast : Icons.star,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    plan.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 10, color: Colors.black26)],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    plan.formattedPrice,
                    style: const TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  if (!isFree && _subscription!.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        _subscription!.remainingDaysText,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
        collapseMode: CollapseMode.parallax,
      ),
      actions: [
        PopupMenuButton<String>(
          icon: Container(
            margin: const EdgeInsets.only(right: 16, top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(Icons.more_vert, color: theme.colorScheme.primary),
          ),
          onSelected: (value) {
            switch (value) {
              case 'invoices':
                Navigator.pushNamed(context, '/subscription/invoices');
                break;
              case 'compare':
                Navigator.pushNamed(context, '/subscription/comparison');
                break;
              case 'refresh':
                _loadData();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'invoices',
              child: Row(children: [const Icon(Icons.receipt, size: 20), const SizedBox(width: 12), Text(t.invoices)]),
            ),
            PopupMenuItem(
              value: 'compare',
              child: Row(children: [const Icon(Icons.compare_arrows, size: 20), const SizedBox(width: 12), Text(t.comparePlans)]),
            ),
            PopupMenuItem(
              value: 'refresh',
              child: Row(children: [const Icon(Icons.refresh, size: 20), const SizedBox(width: 12), Text(t.refresh)]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabBar(AppLocalizations t) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(30),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        tabs: [
          Tab(text: t.overview, icon: const Icon(Icons.dashboard)),
          Tab(text: t.analytics, icon: const Icon(Icons.analytics)),
        ],
      ),
    );
  }

  Widget _buildNoSubscriptionState(AppLocalizations t) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary.withOpacity(0.2), theme.colorScheme.secondary.withOpacity(0.2)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.star_border, size: 80, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text(
            t.noActiveSubscription,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            t.freePlanMessage,
            style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.7)),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushReplacementNamed(context, '/subscription/plans'),
            icon: const Icon(Icons.star),
            label: Text(t.viewPlans),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(AppLocalizations t) {
    final plan = _subscription!.plan;
    final isFree = plan.price == 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (!isFree && _subscription!.isActive) ...[
            _buildProgressCard(t),
            const SizedBox(height: 16),
          ],
          if (_usage != null) ...[
            _buildUsageStats(t),
            const SizedBox(height: 16),
          ],
          _buildFeaturesCard(plan, t),
          const SizedBox(height: 16),
          if (!isFree && _subscription!.isActive) _buildBillingInfoCard(t),
          const SizedBox(height: 16),
          if (isFree) _buildUpgradeCard(t),
          if (!isFree && _subscription!.isActive && !_canceling)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildCancelButton(t),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(AppLocalizations t) {
    final theme = Theme.of(context);
    final totalDays = 30;
    final remainingDays = _subscription!.daysRemaining;
    final progress = (remainingDays / totalDays).clamp(0.0, 1.0);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timer, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Billing Cycle', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white30,
            valueColor: const AlwaysStoppedAnimation(Colors.white),
            borderRadius: BorderRadius.circular(10),
            minHeight: 8,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$remainingDays ${t.daysRemaining}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Text('${(progress * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsageStats(AppLocalizations t) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📊 ${t.usageOverview}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildUsageStatItem(icon: Icons.send, label: t.proposals, used: _usage!.proposalsUsed, limit: _usage!.proposalsLimit, remaining: _usage!.remainingProposals, color: AppColors.info, t: t)),
              const SizedBox(width: 16),
              Expanded(child: _buildUsageStatItem(icon: Icons.work, label: t.activeProjects, used: _usage!.activeProjectsUsed, limit: _usage!.activeProjectsLimit, remaining: _usage!.remainingActiveProjects, color: AppColors.success, t: t)),
            ],
          ),
          if (_usage!.hasInterviewLimit) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            _buildUsageStatItem(icon: Icons.interpreter_mode, label: t.interviews, used: _usage!.interviewsUsed ?? 0, limit: _usage!.interviewsLimit, remaining: _usage!.interviewsRemaining ?? 0, color: AppColors.warning, t: t),
          ],
        ],
      ),
    );
  }

  Widget _buildUsageStatItem({required IconData icon, required String label, required int used, int? limit, required int remaining, required Color color, required AppLocalizations t}) {
    final theme = Theme.of(context);
    final isUnlimited = limit == null || limit == 0;
    final percentage = !isUnlimited ? (used / limit!).clamp(0.0, 1.0) : 0.0;
    final isNearLimit = !isUnlimited && percentage >= 0.9;
    final isAtLimit = !isUnlimited && used >= limit!;

    return Column(
      children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
        const SizedBox(height: 12),
        Text(
          isUnlimited ? '$used / ∞' : (isAtLimit ? '$used / $limit (${t.limitReached})' : '$used / $limit'),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isAtLimit ? AppColors.danger : (isNearLimit ? AppColors.warning : color)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
        if (!isUnlimited) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: theme.dividerColor,
              valueColor: AlwaysStoppedAnimation(isAtLimit ? AppColors.danger : (isNearLimit ? AppColors.warning : color)),
              minHeight: 4,
            ),
          ),
          if (remaining > 0 && remaining <= 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('$remaining ${t.remaining}', style: TextStyle(fontSize: 10, color: remaining <= 0 ? AppColors.danger : AppColors.warning, fontWeight: FontWeight.w500)),
            ),
        ],
      ],
    );
  }

  Widget _buildFeaturesCard(SubscriptionPlan plan, AppLocalizations t) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: theme.shadowColor.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(t.includedFeatures, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 16),
          ...plan.features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.check, size: 14, color: theme.colorScheme.primary)),
                const SizedBox(width: 10),
                Expanded(child: Text(_translateFeature(feature, t), style: TextStyle(color: theme.colorScheme.onSurface))),
              ],
            ),
          )),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _buildLimitRow(t.proposalsPerMonth, plan.proposalLimit, t),
                const SizedBox(height: 8),
                _buildLimitRow(t.activeProjects, plan.activeProjectLimit, t),
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

  Widget _buildLimitRow(String label, int? limit, AppLocalizations t) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
        Text(limit == null || limit == 0 ? t.unlimited : '$limit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
      ],
    );
  }

  Widget _buildBillingInfoCard(AppLocalizations t) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: theme.shadowColor.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(t.billingInformation, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(t.currentPlan, _subscription!.plan.name, theme),
          const SizedBox(height: 12),
          _buildInfoRow(t.billingPeriod, '${_formatDate(_subscription!.currentPeriodStart)} - ${_formatDate(_subscription!.currentPeriodEnd)}', theme),
          const SizedBox(height: 12),
          _buildInfoRow(t.nextBillingDate, _formatDate(_subscription!.currentPeriodEnd), theme),
          const SizedBox(height: 12),
          _buildInfoRow(t.price, _subscription!.plan.formattedPrice, theme),
          if (_subscription!.cancelAtPeriodEnd) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Icon(Icons.info, size: 16, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(child: Text(t.subscriptionEndNotice, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 13)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: theme.colorScheme.onSurface)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildCancelButton(AppLocalizations t) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: theme.shadowColor.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextButton(
        onPressed: _canceling ? null : _cancelSubscription,
        style: TextButton.styleFrom(foregroundColor: AppColors.danger, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: _canceling
            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.danger))
            : Text(t.cancelSubscription, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildUpgradeCard(AppLocalizations t) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [theme.colorScheme.primary.withOpacity(0.1), theme.colorScheme.secondary.withOpacity(0.1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.rocket, color: theme.colorScheme.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(child: Text(t.readyForMore, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary))),
            ],
          ),
          const SizedBox(height: 12),
          Text(t.upgradeMessage, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/subscription/plans'),
              style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: Text(t.upgradeNow, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(AppLocalizations t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildUsageChart(t),
          const SizedBox(height: 16),
          _buildStatsGrid(t),
          const SizedBox(height: 16),
          if (_subscription!.plan.price == 0) _buildProTipsCard(t),
        ],
      ),
    );
  }

  Widget _buildUsageChart(AppLocalizations t) {
    final theme = Theme.of(context);
    
    if (_monthlyUsage.isEmpty) {
      return Container(
        height: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: theme.shadowColor.withOpacity(0.08), blurRadius: 10)]),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, size: 48, color: theme.colorScheme.onSurface.withOpacity(0.4)),
              const SizedBox(height: 16),
              Text(t.noUsageData, style: TextStyle(color: theme.colorScheme.onSurface)),
              const SizedBox(height: 8),
              Text(t.noUsageDataSubtitle, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
            ],
          ),
        ),
      );
    }

    final maxY = _getMaxYValue();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: theme.shadowColor.withOpacity(0.08), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📈 ${t.monthlyActivity}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < _monthlyUsage.length) return Text(_monthlyUsage[index].month, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface));
                    return const Text('');
                  })),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 35, getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface)))),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: true, drawHorizontalLine: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: theme.dividerColor, strokeWidth: 0.5)),
                barGroups: List.generate(_monthlyUsage.length, (index) {
                  final usage = _monthlyUsage[index];
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(toY: usage.proposals.toDouble(), color: AppColors.info, width: 14, borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
                      BarChartRodData(toY: usage.projects.toDouble(), color: AppColors.success, width: 14, borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
                    ],
                    barsSpace: 8,
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(AppColors.info, t.proposals, theme),
              const SizedBox(width: 24),
              _buildLegendItem(AppColors.success, t.projects, theme),
            ],
          ),
        ],
      ),
    );
  }

  double _getMaxYValue() {
    double maxVal = 0;
    for (var usage in _monthlyUsage) {
      if (usage.proposals > maxVal) maxVal = usage.proposals.toDouble();
      if (usage.projects > maxVal) maxVal = usage.projects.toDouble();
    }
    return maxVal + 5;
  }

  Widget _buildLegendItem(Color color, String label, ThemeData theme) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface)),
      ],
    );
  }

  Widget _buildStatsGrid(AppLocalizations t) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: theme.shadowColor.withOpacity(0.08), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📊 ${t.quickStats}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _buildStatCard(t.proposalsUsed, '${_usage!.proposalsUsed}', Icons.send, AppColors.info, t, subtitle: _usage!.proposalsLimit != null ? '${t.off} ${_usage!.proposalsLimit}' : t.unlimited),
              _buildStatCard(t.activeProjectsUsed, '${_usage!.activeProjectsUsed}', Icons.work, AppColors.success, t, subtitle: _usage!.activeProjectsLimit != null ? '${t.off} ${_usage!.activeProjectsLimit}' : t.unlimited),
              _buildStatCard(t.remainingProposals, _usage!.remainingProposals == -1 ? '∞' : '${_usage!.remainingProposals}', Icons.assignment, AppColors.warning, t, subtitle: _usage!.remainingProposals == -1 ? t.noLimit : t.leftThisMonth),
              _buildStatCard(t.remainingProjects, _usage!.remainingActiveProjects == -1 ? '∞' : '${_usage!.remainingActiveProjects}', Icons.folder, theme.colorScheme.primary, t, subtitle: _usage!.remainingActiveProjects == -1 ? t.noLimit : t.canStart),
            ],
          ),
          if (_usage!.hasInterviewLimit) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatCard(t.interviewsUsed, '${_usage!.interviewsUsed ?? 0}', Icons.interpreter_mode, AppColors.info, t, subtitle: _usage!.interviewsLimit != null ? '${t.off} ${_usage!.interviewsLimit}' : t.unlimited)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(t.interviewsLeft, '${_usage!.interviewsRemaining ?? 0}', Icons.event_available, theme.colorScheme.secondary, t, subtitle: t.thisMonth)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, AppLocalizations t, {String? subtitle}) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.6)), textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 9, color: theme.colorScheme.onSurface.withOpacity(0.4)), textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }

  Widget _buildProTipsCard(AppLocalizations t) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [theme.colorScheme.primary.withOpacity(0.08), theme.colorScheme.secondary.withOpacity(0.08)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: theme.colorScheme.primary, size: 24),
              const SizedBox(width: 12),
              Text(t.proTips, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: theme.cardColor.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                TipItem(icon: Icons.trending_up, text: '${t.upgradeToPro} ${_getNextPlanProposalLimit()} ${t.proposalsPerMonth}', color: theme.colorScheme.primary, t: t),
                const SizedBox(height: 12),
                TipItem(icon: Icons.stars, text: t.businessPlanUnlimited, color: theme.colorScheme.primary, t: t),
                const SizedBox(height: 12),
                TipItem(icon: Icons.savings, text: t.yearlyBillingSave, color: theme.colorScheme.primary, t: t),
                const SizedBox(height: 12),
                TipItem(icon: Icons.business, text: t.contactSales, color: theme.colorScheme.primary, t: t),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/subscription/plans'),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: Text(t.viewUpgradeOptions),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                side: BorderSide(color: theme.colorScheme.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getNextPlanProposalLimit() {
    final currentLimit = _subscription?.plan.proposalLimit ?? 0;
    if (currentLimit <= 5) return '50';
    if (currentLimit <= 50) return 'unlimited';
    return 'higher';
  }
}

class TipItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final AppLocalizations t;

  const TipItem({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(fontSize: 13, height: 1.4, color: Theme.of(context).colorScheme.onSurface))),
      ],
    );
  }
}

class MonthlyUsage {
  final String month;
  final int proposals;
  final int projects;
  MonthlyUsage({required this.month, required this.proposals, required this.projects});
}