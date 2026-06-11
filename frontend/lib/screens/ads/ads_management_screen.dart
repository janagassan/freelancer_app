import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import 'create_ad_campaign_screen.dart';
import 'payment_screen.dart';

class AdsManagementScreen extends StatefulWidget {
  const AdsManagementScreen({super.key});

  @override
  State<AdsManagementScreen> createState() => _AdsManagementScreenState();
}

class _AdsManagementScreenState extends State<AdsManagementScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _campaigns = [];
  bool _loading = true;
  String _filter = 'all';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCampaigns();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCampaigns() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService.getMyAdCampaigns(status: _filter);
      setState(() {
        _campaigns = response['campaigns'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      final t = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${t.error}: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _pauseCampaign(int id) async {
    final t = AppLocalizations.of(context)!;
    final response = await ApiService.pauseAdCampaign(id);
    if (response['success'] == true) {
      _loadCampaigns();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.campaignPaused),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  Future<void> _activateCampaign(int id) async {
    final t = AppLocalizations.of(context)!;
    final response = await ApiService.activateAdCampaign(id);
    if (response['success'] == true) {
      _loadCampaigns();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.campaignActivated),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (response['requiresPayment'] == true) {
      final campaign = _campaigns.firstWhere((c) => c['id'] == id);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdPaymentScreen(
            campaignId: id,
            amount: _toDouble(campaign['total_budget']),
            campaignName: campaign['name'],
          ),
        ),
      ).then((_) => _loadCampaigns());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? t.failedToActivate),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.success;
      case 'paused':
        return AppColors.warning;
      case 'completed':
        return AppColors.info;
      case 'cancelled':
        return AppColors.danger;
      case 'draft':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status, AppLocalizations t) {
    switch (status) {
      case 'active':
        return t.active;
      case 'paused':
        return t.paused;
      case 'completed':
        return t.completed;
      case 'cancelled':
        return t.cancelled;
      case 'draft':
        return t.draft;
      default:
        return status;
    }
  }

  String _getPricingModelText(String? model, AppLocalizations t) {
    switch (model) {
      case 'cpc':
        return t.cpcShort;
      case 'cpm':
        return t.cpmShort;
      case 'flat':
        return t.flatShort;
      default:
        return model?.toUpperCase() ?? 'CPC';
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        automaticallyImplyLeading: false,
        elevation: 0,
        foregroundColor: isDark
            ? AppColors.darkTextPrimary
            : AppColors.lightTextPrimary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
          indicatorSize: TabBarIndicatorSize.label,
          onTap: (index) {
            setState(() {
              if (index == 0)
                _filter = 'all';
              else if (index == 1)
                _filter = 'active';
              else
                _filter = 'completed';
              _loadCampaigns();
            });
          },
          tabs: [
            Tab(text: t.all, icon: Icon(Icons.list, size: 18)),
            Tab(text: t.active, icon: Icon(Icons.play_circle, size: 18)),
            Tab(text: t.completed, icon: Icon(Icons.check_circle, size: 18)),
          ],
        ),
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t.loading,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            )
          : _campaigns.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadCampaigns,
              color: AppColors.accent,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _campaigns.length,
                itemBuilder: (_, i) => _buildCampaignCard(_campaigns[i]),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.campaign_outlined,
              size: 50,
              color: AppColors.accent.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            t.noAdCampaigns,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.createFirstCampaign,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/create-ad-campaign',
              ).then((_) => _loadCampaigns());
            },
            icon: const Icon(Icons.add, size: 18),
            label: Text(t.createCampaign),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.primaryDark,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(dynamic campaign) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final statusColor = _getStatusColor(campaign['status']);
    final spent = _toDouble(campaign['spent_amount']);
    final budget = _toDouble(campaign['total_budget']);
    final progress = budget > 0 ? spent / budget : 0.0;
    final startDate = campaign['start_date'] != null
        ? DateFormat.yMMMd(
            t.localeName,
          ).format(DateTime.parse(campaign['start_date']))
        : 'N/A';
    final endDate = campaign['end_date'] != null
        ? DateFormat.yMMMd(
            t.localeName,
          ).format(DateTime.parse(campaign['end_date']))
        : 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showStatsDialog(campaign),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            campaign['name'],
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            campaign['ad_type'] ?? t.banner,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextHint
                                  : AppColors.lightTextHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(campaign['status'], t),
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _infoChip(
                      Icons.visibility,
                      '${campaign['impressions'] ?? 0}',
                      isDark,
                    ),
                    _infoChip(
                      Icons.touch_app,
                      '${campaign['clicks'] ?? 0}',
                      isDark,
                    ),
                    _infoChip(
                      Icons.attach_money,
                      _getPricingModelText(campaign['pricing_model'], t),
                      isDark,
                    ),
                    _infoChip(
                      Icons.calendar_today,
                      '$startDate - $endDate',
                      isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          t.spent,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.darkTextHint
                                : AppColors.lightTextHint,
                          ),
                        ),
                        Text(
                          t.budget,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.darkTextHint
                                : AppColors.lightTextHint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${spent.toStringAsFixed(2)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        Text(
                          '\$${budget.toStringAsFixed(2)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildActionButtons(campaign, statusColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(dynamic campaign, Color statusColor) {
    final t = AppLocalizations.of(context)!;

    if (campaign['status'] == 'draft') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _activateCampaign(campaign['id']),
              icon: const Icon(Icons.play_arrow, size: 18),
              label: Text(t.activateAndPay),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      );
    }

    if (campaign['status'] == 'active') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _pauseCampaign(campaign['id']),
              icon: const Icon(Icons.pause, size: 18),
              label: Text(t.pause),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.warning,
                side: BorderSide(color: AppColors.warning.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showStatsDialog(campaign),
              icon: const Icon(Icons.bar_chart, size: 18),
              label: Text(t.stats),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: BorderSide(color: AppColors.accent.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (campaign['status'] == 'paused') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _activateCampaign(campaign['id']),
              icon: const Icon(Icons.play_arrow, size: 18),
              label: Text(t.resume),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _infoChip(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark ? AppColors.darkTextHint : Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  void _showStatsDialog(dynamic campaign) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final clicks = campaign['clicks'] ?? 0;
    final impressions = campaign['impressions'] ?? 0;
    final ctrPercent = impressions > 0
        ? (clicks / impressions * 100).toStringAsFixed(2)
        : '0';
    final spent = _toDouble(campaign['spent_amount']);
    final avgCpc = clicks > 0 ? spent / clicks : 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.bar_chart, color: AppColors.accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                campaign['name'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _statRow(t.impressions, impressions.toString(), isDark),
            const Divider(height: 1),
            _statRow(t.clicks, clicks.toString(), isDark),
            const Divider(height: 1),
            _statRow(t.ctr, '$ctrPercent%', isDark),
            const Divider(height: 1),
            _statRow(t.totalSpent, '\$${spent.toStringAsFixed(2)}', isDark),
            const Divider(height: 1),
            _statRow(t.avgCpc, '\$${avgCpc.toStringAsFixed(3)}', isDark),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.close, style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
