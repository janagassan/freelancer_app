// ===== frontend/lib/screens/freelancer/financial_dashboard_screen.dart =====
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../l10n/app_localizations.dart';
import '../../models/financial_model.dart';
import '../../services/api_service.dart';
import '../../widgets/financial_charts.dart';
import '../../theme/app_theme.dart';

class FinancialDashboardScreen extends StatefulWidget {
  const FinancialDashboardScreen({super.key});

  @override
  State<FinancialDashboardScreen> createState() =>
      _FinancialDashboardScreenState();
}

class _FinancialDashboardScreenState extends State<FinancialDashboardScreen>
    with SingleTickerProviderStateMixin {
  FinancialStats? _stats;
  List<Map<String, dynamic>> _periodStats = [];
  List<FinancialTransaction> _recentTransactions = [];
  Map<String, dynamic>? _analytics;
  bool _loading = true;
  String _selectedPeriod = 'monthly';
  DateTimeRange? _selectedDateRange;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData(context);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData(BuildContext context) async {
  final t = AppLocalizations.of(context)!;
  if (!mounted) return;

  setState(() => _loading = true);

  try {
    final response = await ApiService.getFinancialStats(
      period: _selectedPeriod,
    );

    if (!mounted) return;

    print('📊 Stats: ${response.stats}');
    print('📊 PeriodStats: ${response.periodStats}');
    print('📊 Transactions: ${response.recentTransactions.length}');

    setState(() {
      _stats = response.stats;
      _periodStats = response.periodStats;
      _recentTransactions = response.recentTransactions;
        print('🔍 SetState: _recentTransactions now has ${_recentTransactions.length} items'); 

      _loading = false;
    });

    _loadAnalytics();
  } catch (e) {
    if (!mounted) return;
    setState(() => _loading = false);
    print('❌ Error loading financial data: $e');
    Fluttertoast.showToast(msg: '${t.errorLoadingFinancialData}: $e');
  }
}

  Future<void> _loadAnalytics() async {
    try {
      final analytics = await ApiService.getAdvancedFinancialAnalytics();
      if (mounted) {
        setState(() => _analytics = analytics);
      }
    } catch (e) {
      print('Error loading analytics: $e');
    }
  }

  Future<void> _downloadReport(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    try {
      final endDate = _selectedDateRange?.end ?? DateTime.now();
      final startDate =
          _selectedDateRange?.start ??
          DateTime(endDate.year, endDate.month - 3, endDate.day);

      final reportUrl = await ApiService.generateFinancialReport(
        startDate: startDate,
        endDate: endDate,
      );

      if (reportUrl != null && mounted) {
        Fluttertoast.showToast(msg: t.reportGenerated);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '${t.errorGeneratingReport}: $e');
    }
  }

  Future<void> _requestWithdrawal() async {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final amountController = TextEditingController();
    String selectedMethod = 'paypal';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          t.withdrawFunds,
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: StatefulBuilder(
          builder: (context, setStateDialog) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${t.available}: \$${_stats?.netEarnings.toStringAsFixed(2) ?? '0'}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: t.amount,
                  prefixText: '\$ ',
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedMethod,
                decoration: InputDecoration(
                  labelText: t.withdrawalMethod,
                  labelStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                dropdownColor: theme.cardColor,
                style: TextStyle(color: theme.colorScheme.onSurface),
                items: [
                  DropdownMenuItem(value: 'paypal', child: Text(t.paypal)),
                  DropdownMenuItem(value: 'bank', child: Text(t.bankTransfer)),
                  DropdownMenuItem(value: 'stripe', child: Text(t.stripe)),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setStateDialog(() => selectedMethod = value);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              t.cancel,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
            ),
            child: Text(t.withdraw),
          ),
        ],
      ),
    );

    if (result == true && amountController.text.isNotEmpty) {
      final amount = double.parse(amountController.text);
      final response = await ApiService.requestWithdrawalV2(
        amount: amount,
        method: selectedMethod,
      );

      if (response['success'] == true) {
        Fluttertoast.showToast(msg: t.withdrawalRequestSubmitted);
        _loadData(context);
      } else {
        Fluttertoast.showToast(msg: response['message'] ?? t.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.secondary,
          labelColor: theme.colorScheme.onSurface,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.5),
          tabs: [
            Tab(text: t.overview, icon: const Icon(Icons.dashboard)),
            Tab(text: t.analytics, icon: const Icon(Icons.analytics)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.download, color: theme.iconTheme.color),
            onPressed: () => _downloadReport(context),
            tooltip: t.downloadReport,
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: theme.iconTheme.color),
            onPressed: () => _loadData(context),
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : _stats == null
          ? Center(
              child: Text(
                t.noFinancialData,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [_buildOverviewTab(), _buildAnalyticsTab()],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _requestWithdrawal,
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.arrow_upward),
        label: Text(t.withdraw),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatsCards(),
          const SizedBox(height: 20),
          _buildPeriodSelector(),
          const SizedBox(height: 16),
          _buildEarningsChart(),
          const SizedBox(height: 20),
          _buildRecentTransactions(),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          title: t.totalEarnings,
          value: '\$${_stats!.totalEarnings.toStringAsFixed(2)}',
          icon: Icons.trending_up,
          color: AppColors.secondary,
          subtitle: t.allTime,
        ),
        _buildStatCard(
          title: t.platformFees,
          value: '\$${_stats!.totalFees.toStringAsFixed(2)}',
          icon: Icons.receipt,
          color: AppColors.warning,
          subtitle:
              '${((_stats!.totalFees / (_stats!.totalEarnings + 0.01)) * 100).toStringAsFixed(1)}%',
        ),
        _buildStatCard(
          title: t.withdrawn,
          value: '\$${_stats!.totalWithdrawals.toStringAsFixed(2)}',
          icon: Icons.arrow_upward,
          color: AppColors.info,
          subtitle: t.totalWithdrawn,
        ),
        _buildStatCard(
          title: t.netEarnings,
          value: '\$${_stats!.netEarnings.toStringAsFixed(2)}',
          icon: Icons.account_balance_wallet,
          color: theme.colorScheme.primary,
          subtitle: t.availableToWithdraw,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final periods = ['weekly', 'monthly', 'yearly'];
    final periodLabels = [t.weekly, t.monthly, t.yearly];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: List.generate(periods.length, (index) {
          final period = periods[index];
          final label = periodLabels[index];
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedPeriod = period);
                _loadData(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.secondary : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEarningsChart() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_periodStats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            t.noDataForPeriod,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.earningsOverview,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: FinancialCharts(
              periodStats: _periodStats,
              totalEarnings: _stats!.totalEarnings,
              chartType: 'bar',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    print('🔍 _buildRecentTransactions called');
  print('🔍 _recentTransactions length: ${_recentTransactions.length}');
  print('🔍 _recentTransactions: ${_recentTransactions.map((t) => t.type).toList()}');

  if (_recentTransactions.isEmpty) {
    print('🔍 Transactions is empty, returning SizedBox.shrink()');
    return const SizedBox.shrink();
  }

  print('🔍 Building transactions list...');

   

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              t.recentTransactions,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentTransactions.length > 5
                ? 5
                : _recentTransactions.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: theme.dividerColor),
            itemBuilder: (context, index) {
              final tx = _recentTransactions[index];
              return ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: tx.typeColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      tx.typeIcon,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                title: Text(
                  _getTransactionTitle(tx.type, t),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  tx.description ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${tx.amount >= 0 ? '+' : ''}\$${tx.amount.abs().toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: tx.isIncome
                            ? AppColors.secondary
                            : AppColors.danger,
                      ),
                    ),
                    Text(
                      _formatDate(tx.transactionDate),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getTransactionTitle(String type, AppLocalizations t) {
    switch (type) {
      case 'payment_received':
        return t.paymentReceived;
      case 'payment_sent':
        return t.paymentSent;
      case 'withdrawal':
        return t.withdrawal;
      case 'deposit':
        return t.deposit;
      case 'platform_fee':
        return t.platformFee;
      case 'bonus':
        return t.bonus;
      case 'subscription':
        return t.subscription;
      default:
        return type;
    }
  }

  Widget _buildAnalyticsTab() {
  final t = AppLocalizations.of(context)!;
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  print('🔍 _analytics: $_analytics'); 

  if (_analytics == null) {
    print('🔍 _analytics is null');
    return Center(
      child: Text(
        t.noAnalyticsData,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }

  final analyticsData = _analytics?['analytics'] ?? _analytics;
  final topProjects = analyticsData?['topProjects'] ?? [];
  final categoryDistribution = analyticsData?['categoryDistribution'] ?? [];
  final projectedEarnings = analyticsData?['projectedEarnings'] ?? 0;

  print('🔍 topProjects length: ${topProjects.length}');
  print('🔍 categoryDistribution length: ${categoryDistribution.length}');
  print('🔍 projectedEarnings: $projectedEarnings');

  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        _buildTopProjectsCard(topProjects),
        const SizedBox(height: 16),
        if (categoryDistribution.isNotEmpty)
          _buildCategoryDistributionCard(categoryDistribution),
        const SizedBox(height: 16),
        _buildProjectedEarningsCard(projectedEarnings),
      ],
    ),
  );
}

  Widget _buildTopProjectsCard(List<dynamic> topProjects) {
  final t = AppLocalizations.of(context)!;
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  print('🔍 Building Top Projects Card with ${topProjects.length} projects');
  print('🔍 TopProjects data: $topProjects');

  if (topProjects.isEmpty) {
    print('🔍 TopProjects is empty, returning SizedBox.shrink()');
    return const SizedBox.shrink();
  }

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.topProjects,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...topProjects.map(
          (project) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.work, color: AppColors.info),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project['Project']?['title'] ?? t.untitled,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        _formatDate(DateTime.parse(project['createdAt'])),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${_parseAmount(project['agreed_amount'])}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

double _parseAmount(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    try {
      return double.parse(value);
    } catch (e) {
      return 0.0;
    }
  }
  return 0.0;
}

  Widget _buildCategoryDistributionCard(List<dynamic> categories) {
  final t = AppLocalizations.of(context)!;
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.earningsByCategory,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...categories.map(
          (cat) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      cat['category'] ?? t.other,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    Text(
                      '\$${_parseAmount(cat['total'])}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: (_parseAmount(cat['total']) / _stats!.totalEarnings).clamp(0.0, 1.0),
                  backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}


  Widget _buildProjectedEarningsCard(double projected) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.purple.shade900, Colors.blue.shade900]
              : [Colors.purple.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.purple.shade800 : Colors.purple.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Colors.purple, Colors.blue]),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: const Icon(Icons.trending_up, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.projectedEarnings,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  '\$${projected.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                Text(
                  t.projectedEarningsSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
