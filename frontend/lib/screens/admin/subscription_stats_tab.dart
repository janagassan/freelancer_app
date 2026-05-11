// screens/admin/subscription_stats_tab.dart

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../models/subscription_stats_model.dart';
import '../../theme/app_theme.dart' as AppTheme;

class SubscriptionStatsTab extends StatefulWidget {
  const SubscriptionStatsTab({super.key});

  @override
  State<SubscriptionStatsTab> createState() => _SubscriptionStatsTabState();
}

class _SubscriptionStatsTabState extends State<SubscriptionStatsTab> {
  SubscriptionStats? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService.getAdminSubscriptionStats();
      if (!mounted) return;

      if (response['success'] == true && response['stats'] != null) {
        setState(() {
          _stats = SubscriptionStats.fromJson(response['stats']);
          _loading = false;
        });
      } else {
        setState(() {
          _error = AppLocalizations.of(context)?.failedToLoadStats ?? 'Failed to load statistics';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '${AppLocalizations.of(context)?.error}: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    if (_loading) {
      return Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
        ),
      );
    }

    if (_error != null || _stats == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? t.noDataAvailable,
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadStats,
              icon: const Icon(Icons.refresh),
              label: Text(t.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildRevenueCard(
                  t.monthlyRecurring,
                  _stats!.monthlyRecurringRevenue,
                  Icons.trending_up_rounded,
                  [theme.colorScheme.primary, const Color(0xFF3D35CC)],
                  t,
                  isDark,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildRevenueCard(
                  t.yearlyRecurring,
                  _stats!.yearlyRecurringRevenue,
                  Icons.calendar_month_rounded,
                  [const Color(0xFF14A800), const Color(0xFF0A6E00)],
                  t,
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _sectionHeader(t.subscriptionMetrics, t, isDark),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (ctx, constraints) {
              final cols = constraints.maxWidth > 600 ? 4 : 2;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: cols,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _metricCard(
                    t.total,
                    _stats!.totalSubscriptions.toString(),
                    Icons.subscriptions_rounded,
                    [const Color(0xFF6C63FF), const Color(0xFF4B45C9)],
                    isDark,
                  ),
                  _metricCard(
                    t.active,
                    _stats!.activeSubscriptions.toString(),
                    Icons.check_circle_rounded,
                    [const Color(0xFF14A800), const Color(0xFF0A6E00)],
                    isDark,
                  ),
                  _metricCard(
                    t.trialing,
                    _stats!.trialingSubscriptions.toString(),
                    Icons.free_breakfast_rounded,
                    [const Color(0xFFF59E0B), const Color(0xFFB45309)],
                    isDark,
                  ),
                  _metricCard(
                    t.canceled,
                    _stats!.canceledSubscriptions.toString(),
                    Icons.cancel_rounded,
                    [const Color(0xFFEF4444), const Color(0xFFB91C1C)],
                    isDark,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _rateCard(
                  t.upgradeRate,
                  _stats!.upgradeRate,
                  Icons.arrow_upward_rounded,
                  const Color(0xFF0EA5E9),
                  t,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _rateCard(
                  t.churnRate,
                  _stats!.churnRate,
                  Icons.arrow_downward_rounded,
                  const Color(0xFFEF4444),
                  t,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _rateCard(
                  t.expired,
                  _stats!.expiredSubscriptions.toDouble(),
                  Icons.timer_off_rounded,
                  const Color(0xFF888888),
                  t,
                  isDark,
                  isCount: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (_stats!.popularPlan != null) ...[
            _sectionHeader(t.mostPopularPlan, t, isDark),
            const SizedBox(height: 12),
            _buildPopularPlanCard(t, isDark),
            const SizedBox(height: 20),
          ],

          if (_stats!.revenueByPlan.isNotEmpty) ...[
            _sectionHeader(t.revenueByPlan, t, isDark),
            const SizedBox(height: 12),
            _buildRevenueByPlanCard(t, isDark),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, AppLocalizations t, bool isDark) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B88FF), Color(0xFF5B58E2)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1A1B3E),
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueCard(
    String title,
    double amount,
    IconData icon,
    List<Color> gradient,
    AppLocalizations t,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const Spacer(),
              Text(
                '${t.mrr}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(
    String title,
    String value,
    IconData icon,
    List<Color> gradient,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 8,
          ),
        ],
        border: Border.all(
          color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade100,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A1B3E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _rateCard(
    String title,
    double value,
    IconData icon,
    Color color,
    AppLocalizations t,
    bool isDark, {
    bool isCount = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            isCount
                ? value.toInt().toString()
                : '${value.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularPlanCard(AppLocalizations t, bool isDark) {
    final plan = _stats!.popularPlan!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF59E0B).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.1),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.star_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan['name']?.toString() ?? t.unknown,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1A1B3E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t.mostSubscribedPlan,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withOpacity(0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Text(
              '${plan['count']} ${t.subs}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueByPlanCard(AppLocalizations t, bool isDark) {
    final entries = _stats!.revenueByPlan.entries.toList();
    final total = entries.fold<double>(0, (sum, e) => sum + e.value);

    const planColors = [
      Color(0xFF5B58E2),
      Color(0xFF14A800),
      Color(0xFF0EA5E9),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF10B981),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 12,
          ),
        ],
        border: Border.all(
          color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade100,
        ),
      ),
      child: Column(
        children: entries.asMap().entries.map((e) {
          final i = e.key;
          final entry = e.value;
          final pct = total > 0 ? entry.value / total : 0.0;
          final color = planColors[i % planColors.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : const Color(0xFF1A1B3E),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '\$${entry.value.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 44,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${(pct * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}