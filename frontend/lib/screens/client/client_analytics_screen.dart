// lib/screens/client/client_analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:freelancer_platform/services/api_service.dart';
import 'package:freelancer_platform/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class ClientAnalyticsScreen extends StatefulWidget {
  const ClientAnalyticsScreen({super.key});

  @override
  State<ClientAnalyticsScreen> createState() => _ClientAnalyticsScreenState();
}

class _ClientAnalyticsScreenState extends State<ClientAnalyticsScreen> {
  bool _isLoading = true;
  DashboardOverview? _overview;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.getClientDashboardOverview();
      setState(() {
        _overview = DashboardOverview.fromJson(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        elevation: 0,
        title: Text(
          t.analytics,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading analytics',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(color: AppColors.gray, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadAnalytics,
                    child: Text(t.retry),
                  ),
                ],
              ),
            )
          : _overview == null
          ? const Center(child: Text('No data available'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, 'Overview'),
                  const SizedBox(height: 12),
                  _buildOverviewStats(context, _overview!.stats),
                  const SizedBox(height: 24),

                  _buildSectionTitle(context, 'Project Status'),
                  const SizedBox(height: 12),
                  _buildProjectStatusChart(context, _overview!.statusBreakdown),
                  const SizedBox(height: 24),

                  _buildSectionTitle(context, 'Monthly Spending'),
                  const SizedBox(height: 12),
                  _buildMonthlySpendingChart(
                    context,
                    _overview!.monthlySpending,
                    _overview!.spendingTrend,
                  ),
                  const SizedBox(height: 24),

                  _buildSectionTitle(context, 'Proposal Statistics'),
                  const SizedBox(height: 12),
                  _buildProposalStats(context, _overview!.stats),
                  const SizedBox(height: 24),

                  _buildSectionTitle(context, 'Financial Overview'),
                  const SizedBox(height: 12),
                  _buildFinancialStats(context, _overview!.stats),
                  const SizedBox(height: 24),

                  _buildSectionTitle(context, 'Active Contracts'),
                  const SizedBox(height: 12),
                  _buildActiveContracts(context, _overview!.activeContracts),
                  const SizedBox(height: 24),

                  _buildSectionTitle(context, 'Recent Proposals'),
                  const SizedBox(height: 12),
                  _buildRecentProposals(context, _overview!.recentProposals),
                  const SizedBox(height: 24),

                  _buildSectionTitle(context, 'Top Freelancers'),
                  const SizedBox(height: 12),
                  _buildTopFreelancers(context, _overview!.topFreelancers),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : AppColors.lightTextPrimary,
      ),
    );
  }

  Widget _buildOverviewStats(BuildContext context, _Stats stats) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          context,
          Icons.folder_open,
          AppColors.accent,
          stats.totalProjects.toString(),
          'Total Projects',
          '${stats.openProjects} open',
        ),
        _buildStatCard(
          context,
          Icons.description,
          AppColors.success,
          stats.totalProposals.toString(),
          'Total Proposals',
          '${stats.pendingProposals} pending',
        ),
        _buildStatCard(
          context,
          Icons.account_balance_wallet,
          AppColors.warning,
          '\$${stats.totalSpent.toStringAsFixed(0)}',
          'Total Spent',
          '\$${stats.escrowHeld.toStringAsFixed(0)} in escrow',
        ),
        _buildStatCard(
          context,
          Icons.check_circle,
          AppColors.info,
          '${stats.proposalAcceptRate}%',
          'Accept Rate',
          '${stats.acceptedProposals} accepted',
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    IconData icon,
    Color color,
    String value,
    String label,
    String sub,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.primaryDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.gray)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }

  Widget _buildProjectStatusChart(
    BuildContext context,
    List<_StatusSlice> statusBreakdown,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (statusBreakdown.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.primaryDark : AppColors.borderLight,
          ),
        ),
        child: Center(
          child: Text(
            'No project data available',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
        ),
      );
    }

    final total = statusBreakdown.fold<int>(0, (sum, item) => sum + item.value);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.primaryDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                sections: statusBreakdown.map((slice) {
                  final percentage = total > 0 ? (slice.value / total) : 0.0;
                  return PieChartSectionData(
                    value: slice.value.toDouble(),
                    title: '${(percentage * 100).toStringAsFixed(0)}%',
                    color: _hexColor(slice.color),
                    radius: 50,
                    titleStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: statusBreakdown.map((slice) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _hexColor(slice.color),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${slice.label} (${slice.value})',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _hexColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.gray;
    }
  }

  Widget _buildMonthlySpendingChart(
    BuildContext context,
    List<_MonthlyPoint> monthlySpending,
    _SpendingTrend trend,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final maxValue = monthlySpending.fold<double>(
      0,
      (max, point) => point.total > max ? point.total : max,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.primaryDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last 6 Months',
                style: TextStyle(fontSize: 14, color: AppColors.gray),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: trend.direction == 'up'
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      trend.direction == 'up'
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 16,
                      color: trend.direction == 'up'
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${trend.percentage}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: trend.direction == 'up'
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue > 0 ? maxValue * 1.2 : 100,
                barGroups: monthlySpending.asMap().entries.map((entry) {
                  final index = entry.key;
                  final point = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: point.total,
                        color: AppColors.accent,
                        width: 16,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < monthlySpending.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              monthlySpending[value.toInt()].label,
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.gray,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProposalStats(BuildContext context, _Stats stats) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.primaryDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ProposalStatItem(
                  label: 'Total',
                  value: stats.totalProposals,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ProposalStatItem(
                  label: 'Pending',
                  value: stats.pendingProposals,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ProposalStatItem(
                  label: 'Accepted',
                  value: stats.acceptedProposals,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ProposalStatItem(
                  label: 'Rejected',
                  value:
                      stats.totalProposals -
                      stats.acceptedProposals -
                      stats.pendingProposals,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialStats(BuildContext context, _Stats stats) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.primaryDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          _FinancialStatRow(
            label: 'Total Spent',
            value: '\$${stats.totalSpent.toStringAsFixed(2)}',
            icon: Icons.payments_outlined,
            color: AppColors.accent,
            isDark: isDark,
          ),
          const Divider(height: 24),
          _FinancialStatRow(
            label: 'Escrow Held',
            value: '\$${stats.escrowHeld.toStringAsFixed(2)}',
            icon: Icons.lock_outline,
            color: AppColors.warning,
            isDark: isDark,
          ),
          const Divider(height: 24),
          _FinancialStatRow(
            label: 'Total Released',
            value: '\$${stats.totalReleased.toStringAsFixed(2)}',
            icon: Icons.check_circle_outline,
            color: AppColors.success,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveContracts(
    BuildContext context,
    List<_ContractItem> contracts,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (contracts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.primaryDark : AppColors.borderLight,
          ),
        ),
        child: Center(
          child: Text(
            'No active contracts',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
        ),
      );
    }

    return Column(
      children: contracts.map((contract) {
        final projectTitle = contract.projectTitle?.isNotEmpty == true
            ? contract.projectTitle!
            : 'Untitled Project';

        final freelancerName = contract.freelancerName?.isNotEmpty == true
            ? contract.freelancerName!
            : 'Unknown Freelancer';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.primaryDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          projectTitle,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          freelancerName,
                          style: TextStyle(fontSize: 12, color: AppColors.gray),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(contract.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      contract.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(contract.status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ContractProgress(
                      label: 'Progress',
                      value: contract.progress.toDouble(),
                      total: contract.milestonesTotal.toDouble(),
                      done: contract.milestonesDone.toDouble(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ContractProgress(
                      label: 'Budget',
                      value: contract.agreedAmount > 0
                          ? (contract.releasedAmount /
                                contract.agreedAmount *
                                100)
                          : 0,
                      total: contract.agreedAmount,
                      done: contract.releasedAmount,
                      isCurrency: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentProposals(
    BuildContext context,
    List<_ProposalItem> proposals,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (proposals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.primaryDark : AppColors.borderLight,
          ),
        ),
        child: Center(
          child: Text(
            'No recent proposals',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
        ),
      );
    }

    return Column(
      children: proposals.take(5).map((proposal) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.primaryDark : AppColors.borderLight,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    proposal.freelancerName?.substring(0, 1).toUpperCase() ??
                        '?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proposal.freelancerName ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      proposal.projectTitle ?? 'Unknown Project',
                      style: TextStyle(fontSize: 12, color: AppColors.gray),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${proposal.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getProposalStatusColor(
                        proposal.status,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      proposal.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getProposalStatusColor(proposal.status),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopFreelancers(
    BuildContext context,
    List<_FreelancerChip> freelancers,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (freelancers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.primaryDark : AppColors.borderLight,
          ),
        ),
        child: Center(
          child: Text(
            'No freelancer data yet',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: freelancers.map((freelancer) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.primaryDark : AppColors.borderLight,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    freelancer.name.isNotEmpty
                        ? freelancer.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    freelancer.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                  if (freelancer.rating != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 10,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          freelancer.rating!.toStringAsFixed(1),
                          style: TextStyle(fontSize: 10, color: AppColors.gray),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.success;
      case 'completed':
        return AppColors.info;
      case 'pending':
      case 'draft':
        return AppColors.warning;
      case 'cancelled':
        return AppColors.danger;
      default:
        return AppColors.gray;
    }
  }

  Color _getProposalStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'contracted':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'rejected':
        return AppColors.danger;
      default:
        return AppColors.gray;
    }
  }
}

class _ProposalStatItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _ProposalStatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialStatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _FinancialStatRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: AppColors.gray),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContractProgress extends StatelessWidget {
  final String label;
  final double value;
  final double total;
  final double done;
  final bool isCurrency;

  const _ContractProgress({
    required this.label,
    required this.value,
    required this.total,
    required this.done,
    this.isCurrency = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: AppColors.gray)),
            Text(
              isCurrency
                  ? '\$${done.toStringAsFixed(0)} / \$${total.toStringAsFixed(0)}'
                  : '$done / $total',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 6,
            backgroundColor: isDark ? AppColors.primaryDark : AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(0)}%',
          style: TextStyle(fontSize: 10, color: AppColors.gray),
        ),
      ],
    );
  }
}

class DashboardOverview {
  final _Stats stats;
  final List<_MonthlyPoint> monthlySpending;
  final List<_StatusSlice> statusBreakdown;
  final List<_ProposalItem> recentProposals;
  final List<_ContractItem> activeContracts;
  final List<_FreelancerChip> topFreelancers;
  final _SpendingTrend spendingTrend;

  DashboardOverview({
    required this.stats,
    required this.monthlySpending,
    required this.statusBreakdown,
    required this.recentProposals,
    required this.activeContracts,
    required this.topFreelancers,
    required this.spendingTrend,
  });

  factory DashboardOverview.fromJson(Map<String, dynamic> json) {
    final trendData =
        json['spending_trend'] ?? {'percentage': 0, 'direction': 'up'};
    return DashboardOverview(
      stats: _Stats.fromJson(json['stats'] ?? {}),
      monthlySpending:
          (json['monthlySpending'] as List?)
              ?.map((e) => _MonthlyPoint.fromJson(e))
              .toList() ??
          [],
      statusBreakdown:
          (json['statusBreakdown'] as List?)
              ?.map((e) => _StatusSlice.fromJson(e))
              .toList() ??
          [],
      recentProposals:
          (json['recentProposals'] as List?)
              ?.map((e) => _ProposalItem.fromJson(e))
              .toList() ??
          [],
      activeContracts:
          (json['activeContracts'] as List?)
              ?.map((e) => _ContractItem.fromJson(e))
              .toList() ??
          [],
      topFreelancers:
          (json['topFreelancers'] as List?)
              ?.map((e) => _FreelancerChip.fromJson(e))
              .toList() ??
          [],
      spendingTrend: _SpendingTrend.fromJson(trendData),
    );
  }
}

class _Stats {
  final int totalProjects;
  final int openProjects;
  final int inProgressProjects;
  final int completedProjects;
  final int cancelledProjects;
  final int totalProposals;
  final int pendingProposals;
  final int acceptedProposals;
  final int rejectedProposals;
  final double totalSpent;
  final double escrowHeld;
  final double totalReleased;
  final int proposalAcceptRate;

  _Stats({
    this.totalProjects = 0,
    this.openProjects = 0,
    this.inProgressProjects = 0,
    this.completedProjects = 0,
    this.cancelledProjects = 0,
    this.totalProposals = 0,
    this.pendingProposals = 0,
    this.acceptedProposals = 0,
    this.rejectedProposals = 0,
    this.totalSpent = 0,
    this.escrowHeld = 0,
    this.totalReleased = 0,
    this.proposalAcceptRate = 0,
  });

  factory _Stats.fromJson(Map<String, dynamic> json) {
    return _Stats(
      totalProjects: json['totalProjects'] ?? 0,
      openProjects: json['openProjects'] ?? 0,
      inProgressProjects: json['inProgressProjects'] ?? 0,
      completedProjects: json['completedProjects'] ?? 0,
      cancelledProjects: json['cancelledProjects'] ?? 0,
      totalProposals: json['totalProposals'] ?? 0,
      pendingProposals: json['pendingProposals'] ?? 0,
      acceptedProposals: json['acceptedProposals'] ?? 0,
      rejectedProposals: json['rejectedProposals'] ?? 0,
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0,
      escrowHeld: (json['escrowHeld'] as num?)?.toDouble() ?? 0,
      totalReleased: (json['totalReleased'] as num?)?.toDouble() ?? 0,
      proposalAcceptRate: json['proposalAcceptRate'] ?? 0,
    );
  }
}

class _MonthlyPoint {
  final String label;
  final double total;

  _MonthlyPoint({required this.label, required this.total});

  factory _MonthlyPoint.fromJson(Map<String, dynamic> json) {
    return _MonthlyPoint(
      label: json['label'] ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0,
    );
  }
}

class _StatusSlice {
  final String label;
  final String color;
  final int value;

  _StatusSlice({required this.label, required this.color, required this.value});

  factory _StatusSlice.fromJson(Map<String, dynamic> json) {
    return _StatusSlice(
      label: json['label'] ?? '',
      color: json['color'] ?? '#888',
      value: json['value'] ?? 0,
    );
  }
}

class _ProposalItem {
  final int id;
  final String status;
  final double price;
  final String? projectTitle;
  final String? freelancerName;

  _ProposalItem({
    required this.id,
    required this.status,
    required this.price,
    this.projectTitle,
    this.freelancerName,
  });

  factory _ProposalItem.fromJson(Map<String, dynamic> json) {
    return _ProposalItem(
      id: json['id'] ?? 0,
      status: json['status'] ?? 'pending',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      projectTitle: json['projectTitle'] ?? json['project']?['title'],
      freelancerName: json['freelancerName'] ?? json['freelancer']?['name'],
    );
  }
}

class _ContractItem {
  final int id;
  final String status;
  final double agreedAmount;
  final double releasedAmount;
  final int progress;
  final int milestonesTotal;
  final int milestonesDone;
  final String? projectTitle;
  final String? freelancerName;
  final String? freelancerAvatar;

  _ContractItem({
    required this.id,
    required this.status,
    required this.agreedAmount,
    required this.releasedAmount,
    required this.progress,
    required this.milestonesTotal,
    required this.milestonesDone,
    this.projectTitle,
    this.freelancerName,
    this.freelancerAvatar,
  });

  factory _ContractItem.fromJson(Map<String, dynamic> json) {
    String? projectTitle;

    if (json['project'] != null && json['project']['title'] != null) {
      projectTitle = json['project']['title'];
    } else if (json['Project'] != null && json['Project']['title'] != null) {
      projectTitle = json['Project']['title'];
    } else if (json['projectTitle'] != null) {
      projectTitle = json['projectTitle'];
    } else if (json['title'] != null) {
      projectTitle = json['title'];
    } else if (json['project'] != null && json['project']['name'] != null) {
      projectTitle = json['project']['name'];
    } else if (json['project_name'] != null) {
      projectTitle = json['project_name'];
    }

    String? freelancerName;
    String? freelancerAvatar;

    if (json['freelancer'] != null) {
      freelancerName = json['freelancer']['name'];
      freelancerAvatar = json['freelancer']['avatar'];
    } else if (json['Freelancer'] != null) {
      freelancerName = json['Freelancer']['name'];
      freelancerAvatar = json['Freelancer']['avatar'];
    } else if (json['freelancerName'] != null) {
      freelancerName = json['freelancerName'];
    } else if (json['freelancer_name'] != null) {
      freelancerName = json['freelancer_name'];
    } else if (json['user'] != null && json['user']['name'] != null) {
      freelancerName = json['user']['name'];
      freelancerAvatar = json['user']['avatar'];
    }

    if (freelancerAvatar == null) {
      if (json['freelancerAvatar'] != null) {
        freelancerAvatar = json['freelancerAvatar'];
      } else if (json['freelancer_avatar'] != null) {
        freelancerAvatar = json['freelancer_avatar'];
      } else if (json['avatar'] != null) {
        freelancerAvatar = json['avatar'];
      }
    }

    return _ContractItem(
      id: json['id'] ?? 0,
      status: json['status'] ?? 'active',
      agreedAmount:
          (json['agreedAmount'] as num?)?.toDouble() ??
          (json['agreed_amount'] as num?)?.toDouble() ??
          0,
      releasedAmount:
          (json['releasedAmount'] as num?)?.toDouble() ??
          (json['released_amount'] as num?)?.toDouble() ??
          0,
      progress: json['progress'] ?? 0,
      milestonesTotal: json['milestonesTotal'] ?? json['milestones_total'] ?? 0,
      milestonesDone: json['milestonesDone'] ?? json['milestones_done'] ?? 0,
      projectTitle: projectTitle,
      freelancerName: freelancerName,
      freelancerAvatar: freelancerAvatar,
    );
  }
}

class _FreelancerChip {
  final int id;
  final String name;
  final double? rating;

  _FreelancerChip({required this.id, required this.name, this.rating});

  factory _FreelancerChip.fromJson(Map<String, dynamic> json) {
    return _FreelancerChip(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }
}

class _SpendingTrend {
  final int percentage;
  final String direction;

  _SpendingTrend({required this.percentage, required this.direction});

  factory _SpendingTrend.fromJson(Map<String, dynamic> json) {
    return _SpendingTrend(
      percentage: json['percentage'] ?? 0,
      direction: json['direction'] ?? 'up',
    );
  }
}
