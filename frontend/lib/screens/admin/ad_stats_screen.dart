// screens/ads/ad_stats_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart' as AppTheme;

class AdStatsScreen extends StatefulWidget {
  const AdStatsScreen({super.key});

  @override
  State<AdStatsScreen> createState() => _AdStatsScreenState();
}

class _AdStatsScreenState extends State<AdStatsScreen> {
  Map<String, dynamic> _stats = {};
  List<dynamic> _campaigns = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final revenueStats = await ApiService.getAdRevenueStats();
      final campaigns = await ApiService.getMyAdCampaigns();
      if (!mounted) return;
      setState(() {
        _stats = revenueStats['stats'] ?? {};
        _campaigns = campaigns['campaigns'] ?? [];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.AppColors.darkBackground : const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: Text(
          t.adRevenueStats,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: t.refresh,
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatsGrid(t, isDark),
                  const SizedBox(height: 16),
                  _buildCampaignsList(t, isDark),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsGrid(AppLocalizations t, bool isDark) {
    final totalRevenue = (_stats['total_ad_revenue'] ?? 0).toDouble();
    final activeCampaigns = _stats['active_campaigns'] ?? 0;
    final totalSpend = (_stats['total_campaign_spend'] ?? 0).toDouble();
    final commissionRate = (_stats['platform_commission_rate'] ?? 0.2) * 100;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _statCard(
          t.totalAdRevenue,
          '\$${totalRevenue.toStringAsFixed(2)}',
          Icons.monetization_on,
          const Color(0xFF14A800),
          isDark,
        ),
        _statCard(
          t.activeCampaigns,
          activeCampaigns.toString(),
          Icons.campaign,
          Colors.blue,
          isDark,
        ),
        _statCard(
          t.totalAdSpend,
          '\$${totalSpend.toStringAsFixed(2)}',
          Icons.attach_money,
          const Color(0xFFF59E0B),
          isDark,
        ),
        _statCard(
          t.platformCommission,
          '${commissionRate.toStringAsFixed(0)}%',
          Icons.percent,
          Colors.purple,
          isDark,
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color, bool isDark) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignsList(AppLocalizations t, bool isDark) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.03),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              t.recentCampaigns,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.AppColors.lightTextPrimary,
              ),
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade200,
          ),
          if (_campaigns.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  t.noCampaignsYet,
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _campaigns.length > 10 ? 10 : _campaigns.length,
              itemBuilder: (_, i) => _campaignRow(_campaigns[i], t, isDark),
            ),
        ],
      ),
    );
  }

  Widget _campaignRow(dynamic campaign, AppLocalizations t, bool isDark) {
    final revenue = (campaign['spent_amount'] ?? 0) * 0.2;
    final status = campaign['status'] ?? 'draft';
    final isActive = status == 'active';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isActive
            ? const Color(0xFF14A800)
            : (isDark ? AppTheme.AppColors.grayDark : Colors.grey),
        radius: 18,
        child: Icon(Icons.campaign, size: 16, color: Colors.white),
      ),
      title: Text(
        campaign['name'] ?? t.untitled,
        style: TextStyle(
          color: isDark ? Colors.white : AppTheme.AppColors.lightTextPrimary,
        ),
      ),
      subtitle: Text(
        '${campaign['clicks'] ?? 0} ${t.clicks} · ${campaign['impressions'] ?? 0} ${t.impressions}',
        style: TextStyle(
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
          fontSize: 12,
        ),
      ),
      trailing: Text(
        '\$${revenue.toStringAsFixed(2)}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF14A800),
        ),
      ),
    );
  }
}