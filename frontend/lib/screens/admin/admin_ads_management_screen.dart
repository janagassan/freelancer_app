// screens/admin/admin_ads_management_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart' as AppTheme;

class AdminAdsManagementScreen extends StatefulWidget {
  const AdminAdsManagementScreen({super.key});

  @override
  State<AdminAdsManagementScreen> createState() =>
      _AdminAdsManagementScreenState();
}

class _AdminAdsManagementScreenState extends State<AdminAdsManagementScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _campaigns = [];
  bool _loading = true;
  bool _isMounted = true;
  String _selectedStatus = 'all';
  String _searchQuery = '';
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCampaigns = 0;
  Map<String, dynamic> _stats = {};
  late TabController _tabController;
  int _selectedTab = 0;
  Map<String, List<Map<String, dynamic>>> _dailyStatsData = {};

  Map<String, dynamic> _analytics = {};
  bool _loadingAnalytics = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
      if (_selectedTab == 1) {
        _loadAnalytics();
      }
    });
    _loadCampaigns();
  }

  @override
  void dispose() {
    _isMounted = false;
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCampaigns() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService.adminGetAllCampaigns(
        status: _selectedStatus,
        search: _searchQuery,
        page: _currentPage,
      );

      if (!mounted) return;

      setState(() {
        _campaigns = List<Map<String, dynamic>>.from(
          response['campaigns'] ?? [],
        );
        _totalPages = response['totalPages'] ?? 1;
        _totalCampaigns = response['total'] ?? 0;
        _stats = response['stats'] ?? {};
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final t = AppLocalizations.of(context);
      Fluttertoast.showToast(msg: '${t?.errorLoadingCampaigns}: $e');
    }
  }

  Future<void> _loadAnalytics() async {
    if (!_isMounted) return;
    setState(() => _loadingAnalytics = true);
    try {
      final response = await ApiService.adminGetAdAnalytics();
      if (_isMounted && response['success'] == true) {
        setState(() {
          _analytics = response['analytics'] ?? {};
          _loadingAnalytics = false;
        });
      } else if (_isMounted) {
        setState(() => _loadingAnalytics = false);
      }
    } catch (e) {
      if (_isMounted) {
        setState(() => _loadingAnalytics = false);
      }
      debugPrint('Error loading analytics: $e');
    }
  }

  Future<void> _changeCampaignStatus(
    int campaignId,
    String newStatus, {
    String? reason,
  }) async {
    final t = AppLocalizations.of(context);
    try {
      final response = await ApiService.adminChangeCampaignStatus(
        campaignId,
        newStatus,
        reason: reason,
      );

      if (response['success'] == true) {
        Fluttertoast.showToast(msg: t?.statusChangedTo(newStatus) ?? 'Status changed to $newStatus');
        _loadCampaigns();
        if (_selectedTab == 1) _loadAnalytics();
      } else {
        Fluttertoast.showToast(
          msg: response['message'] ?? t?.failedToChangeStatus ?? 'Failed to change status',
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '${t?.error}: $e');
    }
  }

  Future<void> _deleteCampaign(int campaignId, String campaignName) async {
    final t = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          t?.deleteCampaign ?? 'Delete Campaign',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          t?.deleteCampaignConfirmation(campaignName) ??
          'Are you sure you want to delete "$campaignName"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t?.cancel ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(t?.delete ?? 'Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await ApiService.adminDeleteCampaign(campaignId);
      if (response['success'] == true) {
        Fluttertoast.showToast(msg: t?.campaignDeleted ?? 'Campaign deleted successfully');
        _loadCampaigns();
        if (_selectedTab == 1) _loadAnalytics();
      } else {
        Fluttertoast.showToast(msg: response['message'] ?? t?.failedToDelete ?? 'Failed to delete');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '${t?.error}: $e');
    }
  }

  void _showEditDialog(Map<String, dynamic> campaign) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final nameCtrl = TextEditingController(text: campaign['name']);
    final budgetCtrl = TextEditingController(
      text: campaign['total_budget']?.toString(),
    );
    final dailyBudgetCtrl = TextEditingController(
      text: campaign['daily_budget']?.toString(),
    );
    final cpcCtrl = TextEditingController(
      text: campaign['cost_per_click']?.toString(),
    );
    final cpmCtrl = TextEditingController(
      text: campaign['cost_per_impression']?.toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B88FF), Color(0xFF5B58E2)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              t?.editCampaign ?? 'Edit Campaign',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(nameCtrl, t?.campaignName ?? 'Campaign Name', isDark),
                const SizedBox(height: 12),
                _buildTextField(budgetCtrl, t?.totalBudget ?? 'Total Budget', isDark, isNumber: true),
                const SizedBox(height: 12),
                _buildTextField(dailyBudgetCtrl, t?.dailyBudget ?? 'Daily Budget', isDark, isNumber: true),
                const SizedBox(height: 12),
                _buildTextField(cpcCtrl, t?.costPerClick ?? 'Cost Per Click', isDark, isNumber: true),
                const SizedBox(height: 12),
                _buildTextField(cpmCtrl, t?.costPerImpression ?? 'Cost Per Impression', isDark, isNumber: true),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t?.cancel ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updateData = {
                'name': nameCtrl.text.trim(),
                'total_budget': double.tryParse(budgetCtrl.text) ?? campaign['total_budget'],
                'daily_budget': double.tryParse(dailyBudgetCtrl.text),
                'cost_per_click': double.tryParse(cpcCtrl.text) ?? campaign['cost_per_click'],
                'cost_per_impression': double.tryParse(cpmCtrl.text) ?? campaign['cost_per_impression'],
              };

              final response = await ApiService.adminUpdateCampaign(
                campaign['id'],
                updateData,
              );
              if (response['success'] == true) {
                if (!mounted) return;
                Navigator.pop(ctx);
                Fluttertoast.showToast(msg: t?.campaignUpdated ?? 'Campaign updated');
                _loadCampaigns();
              } else {
                Fluttertoast.showToast(
                  msg: response['message'] ?? t?.updateFailed ?? 'Update failed',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(t?.saveChanges ?? 'Save Changes'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, bool isDark, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF5B58E2)),
        ),
      ),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(
        color: isDark ? Colors.white : AppTheme.AppColors.lightTextPrimary,
      ),
    );
  }

  void _showStatusDialog(Map<String, dynamic> campaign) {
    final t = AppLocalizations.of(context);
    final currentStatus = campaign['status'];
    final possibleStatuses = ['active', 'paused', 'completed', 'cancelled'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          t?.changeStatus ?? 'Change Status',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: possibleStatuses.map((status) {
            return ListTile(
              leading: Radio<String>(
                value: status,
                groupValue: currentStatus,
                onChanged: (value) {
                  Navigator.pop(ctx);
                  _changeCampaignStatus(campaign['id'], status);
                },
                activeColor: _getStatusColor(status),
              ),
              title: Text(_getStatusText(status, t)),
              trailing: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t?.close ?? 'Close'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return const Color(0xFF14A800);
      case 'paused':
        return const Color(0xFFF59E0B);
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return const Color(0xFFEF4444);
      case 'draft':
        return Colors.grey;
      case 'pending_approval':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status, AppLocalizations? t) {
    switch (status) {
      case 'active':
        return t?.active ?? 'Active';
      case 'paused':
        return t?.paused ?? 'Paused';
      case 'completed':
        return t?.completed ?? 'Completed';
      case 'cancelled':
        return t?.cancelled ?? 'Cancelled';
      case 'draft':
        return t?.draft ?? 'Draft';
      case 'pending_approval':
        return t?.pendingApproval ?? 'Pending Approval';
      default:
        return status;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      return DateFormat('MMM d, yyyy').format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
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
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.AppColors.darkBackground : const Color(0xFFF5F6F8),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterBar(t, isDark),
          _buildTabBar(t, isDark),
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                _buildCampaignsList(t, isDark),
                _buildAnalyticsTab(t, isDark),
                _buildStatsTab(t, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(AppLocalizations t, bool isDark) {
  return Container(
    color: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12), 
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.AppColors.darkCard : const Color(0xFFF5F6F8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(
                Icons.search,
                size: 20,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.AppColors.lightTextPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: t.searchCampaigns,
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey.shade500 : const Color(0xFFAAAAAA),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (v) {
                    _searchQuery = v;
                    _currentPage = 1;
                    _loadCampaigns();
                  },
                ),
              ),
              if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      Icons.clear,
                      size: 18,
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                    ),
                    onPressed: () {
                      _searchQuery = '';
                      _currentPage = 1;
                      _loadCampaigns();
                    },
                  ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        const SizedBox(height: 16), 
        
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 14,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${t.status}:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildStatusFilterChip(t.all, 'all', isDark),
                    const SizedBox(width: 8),
                    _buildStatusFilterChip(t.activeCampaigns, 'active', isDark),
                    const SizedBox(width: 8),
                    _buildStatusFilterChip(t.paused, 'paused', isDark),
                    const SizedBox(width: 8),
                    _buildStatusFilterChip(t.completed, 'completed', isDark),
                    const SizedBox(width: 8),
                    _buildStatusFilterChip(t.draft, 'draft', isDark),
                    const SizedBox(width: 8),
                    _buildStatusFilterChip(t.pendingApproval, 'pending_approval', isDark),
                    const SizedBox(width: 8),
                    _buildStatusFilterChip(t.cancelled, 'cancelled', isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  Widget _buildStatusFilterChip(String label, String value, bool isDark) {
  final selected = _selectedStatus == value;
  final theme = Theme.of(context);

  return GestureDetector(
    onTap: () {
      setState(() {
        _selectedStatus = value;
        _currentPage = 1;
      });
      _loadCampaigns();
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: selected
            ? theme.colorScheme.primary
            : (isDark ? AppTheme.AppColors.darkCard : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected
              ? Colors.transparent
              : (isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade300),
          width: 0.8,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: selected
              ? Colors.white
              : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
        ),
      ),
    ),
  );
}

  Widget _buildTabBar(AppLocalizations t, bool isDark) {
    final theme = Theme.of(context);

    return Container(
      color: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: theme.colorScheme.primary,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: isDark ? Colors.grey.shade500 : Colors.grey,
        tabs: [
          Tab(text: t.campaigns, icon: const Icon(Icons.campaign)),
          Tab(text: t.analytics, icon: const Icon(Icons.bar_chart)),
          Tab(text: t.statistics, icon: const Icon(Icons.analytics)),
        ],
      ),
    );
  }

  Widget _buildCampaignsList(AppLocalizations t, bool isDark) {
    final theme = Theme.of(context);

    if (_loading && _campaigns.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
        ),
      );
    }

    if (_campaigns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.AppColors.darkCard : const Color(0xFFF0F2F8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.campaign_outlined,
                size: 40,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              t.noCampaignsFound,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: isDark ? AppTheme.AppColors.darkCard : const Color(0xFFF0F2F8),
          child: Row(
            children: [
              _quickStatChip(t.total, _totalCampaigns.toString(), Colors.purple, isDark),
              const SizedBox(width: 12),
              _quickStatChip(t.activeCampaigns, _stats['active_campaigns']?.toString() ?? '0', const Color(0xFF14A800), isDark),
              const SizedBox(width: 12),
              _quickStatChip(t.revenue, '\$${(_stats['total_spent'] ?? 0).toDouble().toStringAsFixed(0)}', const Color(0xFFF59E0B), isDark),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _campaigns.length,
            itemBuilder: (_, i) => _buildCampaignCard(_campaigns[i], t, isDark),
          ),
        ),
        if (_totalPages > 1) _buildPagination(t, isDark),
      ],
    );
  }

  Widget _quickStatChip(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(Map<String, dynamic> campaign, AppLocalizations t, bool isDark) {
    final theme = Theme.of(context);
    final advertiser = campaign['advertiser'] ?? {};
    final status = campaign['status'] ?? 'draft';
    final statusColor = _getStatusColor(status);
    final spent = _toDouble(campaign['spent_amount']);
    final budget = _toDouble(campaign['total_budget']);
    final progress = budget > 0 ? spent / budget : 0.0;
    final impressions = campaign['impressions'] ?? 0;
    final clicks = campaign['clicks'] ?? 0;
    final ctr = impressions > 0 ? (clicks / impressions * 100).toStringAsFixed(2) : '0';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade100,
        ),
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade100,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [statusColor, statusColor.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.campaign, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaign['name'] ?? 'Unnamed',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1A1B3E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 12,
                            color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            advertiser['name'] ?? t.unknown,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.email_outlined,
                            size: 12,
                            color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            advertiser['email'] ?? '',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(status, t),
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _infoChip(Icons.visibility, '$impressions', t.impressions, isDark),
                    const SizedBox(width: 8),
                    _infoChip(Icons.touch_app, '$clicks', t.clicks, isDark),
                    const SizedBox(width: 8),
                    _infoChip(Icons.trending_up, '$ctr%', t.ctr, isDark),
                    const SizedBox(width: 8),
                    _infoChip(
                      Icons.attach_money,
                      campaign['pricing_model']?.toUpperCase() ?? 'CPC',
                      t.model,
                      isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(statusColor),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${t.spent}: \$${spent.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '${t.budget}: \$${budget.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1A1B3E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatDate(campaign['start_date'])} - ${_formatDate(campaign['end_date'])}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _actionButton(
                      icon: Icons.edit_outlined,
                      label: t.edit,
                      color: theme.colorScheme.primary,
                      onTap: () => _showEditDialog(campaign),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _actionButton(
                      icon: Icons.tune,
                      label: t.changeStatus,
                      color: const Color(0xFFF59E0B),
                      onTap: () => _showStatusDialog(campaign),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    if (status == 'active')
                      _actionButton(
                        icon: Icons.pause,
                        label: t.pause,
                        color: const Color(0xFFF59E0B),
                        onTap: () => _changeCampaignStatus(campaign['id'], 'paused'),
                        isDark: isDark,
                      ),
                    if (status == 'paused')
                      _actionButton(
                        icon: Icons.play_arrow,
                        label: t.resume,
                        color: const Color(0xFF14A800),
                        onTap: () => _changeCampaignStatus(campaign['id'], 'active'),
                        isDark: isDark,
                      ),
                    const Spacer(),
                    _actionButton(
                      icon: Icons.delete_outline,
                      label: t.delete,
                      color: Colors.red,
                      onTap: () => _deleteCampaign(campaign['id'], campaign['name'] ?? t.campaign),
                      isOutlined: true,
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String value, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.AppColors.darkSurface : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            ' $label',
            style: TextStyle(fontSize: 10, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isOutlined = false,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isOutlined ? Colors.transparent : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: isOutlined ? Border.all(color: color.withOpacity(0.3)) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination(AppLocalizations t, bool isDark) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pageBtn(
            Icons.chevron_left,
            _currentPage > 1
                ? () {
                    setState(() => _currentPage--);
                    _loadCampaigns();
                  }
                : null,
            isDark,
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.AppColors.darkCard : const Color(0xFFF0F2F8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${t.page} $_currentPage ${t.ofWord} $_totalPages',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1A1B3E),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _pageBtn(
            Icons.chevron_right,
            _currentPage < _totalPages
                ? () {
                    setState(() => _currentPage++);
                    _loadCampaigns();
                  }
                : null,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _pageBtn(IconData icon, VoidCallback? onTap, bool isDark) {
    final theme = Theme.of(context);
    final isEnabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isEnabled
              ? theme.colorScheme.primary.withOpacity(0.1)
              : (isDark ? AppTheme.AppColors.darkCard : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isEnabled
                ? theme.colorScheme.primary.withOpacity(0.2)
                : (isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade200),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isEnabled
              ? theme.colorScheme.primary
              : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab(AppLocalizations t, bool isDark) {
    final theme = Theme.of(context);

    if (_loadingAnalytics) {
      return Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
        ),
      );
    }

    final summary = _convertToMapString(_analytics['summary']) ?? {};
  final typeStats = _convertToListOfMaps(_analytics['type_stats']) ?? [];
  final topAdvertisers = _convertToListOfMaps(_analytics['top_advertisers']) ?? [];
  final dailyStats = _convertToListOfMaps(_analytics['daily_stats']) ?? [];

    final Map<String, Map<String, double>> chartData = {};
    for (var stat in dailyStats) {
      final date = stat['date']?.toString() ?? '';
      final type = stat['type'] ?? 'impression';
      final count = _toDouble(stat['count']);

      if (!chartData.containsKey(date)) {
        chartData[date] = {
          'impressions': 0,
          'clicks': 0,
          'conversions': 0,
          'revenue': 0,
        };
      }

      if (type == 'impression') chartData[date]!['impressions'] = count;
      if (type == 'click') chartData[date]!['clicks'] = count;
      if (type == 'conversion') chartData[date]!['conversions'] = count;
    }

    final dates = chartData.keys.toList()..sort();
    final impressionsData = dates.map((d) => chartData[d]!['impressions']!.toDouble()).toList();
    final clicksData = dates.map((d) => chartData[d]!['clicks']!.toDouble()).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.keyPerformanceIndicators,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _kpiCard(t.totalRevenue, '\$${_toDouble(summary['total_revenue']).toStringAsFixed(0)}', Icons.monetization_on, const Color(0xFF14A800), '+12%', isDark),
              _kpiCard(t.platformCommission, '\$${_toDouble(summary['platform_commission']).toStringAsFixed(0)}', Icons.percent, const Color(0xFFF59E0B), '+8%', isDark),
              _kpiCard(t.activeCampaignsCount, summary['active_campaigns']?.toString() ?? '0', Icons.play_circle, theme.colorScheme.primary, '${(summary['active_campaigns'] ?? 0) * 100 ~/ (summary['total_campaigns'] ?? 1)}%', isDark),
              _kpiCard(t.ctrAverage, '${_computeAvgCTR(typeStats).toStringAsFixed(1)}%', Icons.trending_up, Colors.blue, '+2.3%', isDark),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade100,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.show_chart,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      t.dailyPerformanceTrends,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: _buildLineChart(dates, impressionsData, clicksData, isDark, t),
                ),
                const SizedBox(height: 16),
                _buildChartLegend(isDark, t),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade100,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.pie_chart, color: Colors.blue, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      t.performanceByAdType,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(height: 200, child: _buildPieChart(typeStats, isDark, t)),
                const SizedBox(height: 16),
                _buildTypeStatsTable(typeStats, t, isDark),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade100,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.leaderboard, color: Color(0xFFF59E0B), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      t.topAdvertisers,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(height: 250, child: _buildBarChart(topAdvertisers, isDark, t)),
                const SizedBox(height: 16),
                _buildTopAdvertisersTable(topAdvertisers, t, isDark),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildMetricsGrid(summary, t, isDark),
        ],
      ),
    );
  }

  double _computeAvgCTR(List typeStats) {
    if (typeStats.isEmpty) return 0.0;
    double totalCTR = 0;
    int count = 0;
    for (var stat in typeStats) {
      final impressions = _toDouble(stat['total_impressions']);
      final clicks = _toDouble(stat['total_clicks']);
      if (impressions > 0) {
        totalCTR += (clicks / impressions) * 100;
        count++;
      }
    }
    return count > 0 ? totalCTR / count : 0.0;
  }

Map<String, dynamic>? _convertToMapString(dynamic data) {
  if (data == null) return null;
  if (data is Map<String, dynamic>) return data;
  if (data is Map) {
    return Map<String, dynamic>.fromEntries(
      data.entries.map((entry) => MapEntry(entry.key.toString(), entry.value))
    );
  }
  return null;
}

List<Map<String, dynamic>> _convertToListOfMaps(dynamic data) {
  if (data == null) return [];
  if (data is List) {
    return data.map((item) {
      if (item is Map<String, dynamic>) return item;
      if (item is Map) {
        return Map<String, dynamic>.fromEntries(
          item.entries.map((entry) => MapEntry(entry.key.toString(), entry.value))
        );
      }
      return <String, dynamic>{};
    }).toList();
  }
  return [];
}

  Widget _kpiCard(String title, String value, IconData icon, Color color, String trend, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 4)],
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
                child: Icon(icon, size: 16, color: color),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: trend.startsWith('+') ? const Color(0xFF14A800).withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trend.startsWith('+') ? Icons.trending_up : Icons.trending_down,
                      size: 10,
                      color: trend.startsWith('+') ? const Color(0xFF14A800) : Colors.red,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      trend,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: trend.startsWith('+') ? const Color(0xFF14A800) : Colors.red,
                      ),
                    ),
                  ],
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
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<String> dates, List<double> impressions, List<double> clicks, bool isDark, dynamic t) {
    if (dates.isEmpty) {
      return Center(
        child: Text(
          t?.noDataAvailable ?? 'No data available',
          style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < dates.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      dates[value.toInt()].substring(5, 10),
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade200),
        ),
        minX: 0,
        maxX: (dates.length - 1).toDouble(),
        minY: 0,
        maxY: impressions.isEmpty ? 10 : impressions.reduce((a, b) => a > b ? a : b) * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(impressions.length, (i) => FlSpot(i.toDouble(), impressions[i])),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(radius: 4, color: Colors.blue);
              },
            ),
            belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.1)),
          ),
          LineChartBarData(
            spots: List.generate(clicks.length, (i) => FlSpot(i.toDouble(), clicks[i])),
            isCurved: true,
            color: const Color(0xFF14A800),
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(radius: 4, color: const Color(0xFF14A800));
              },
            ),
            belowBarData: BarAreaData(show: true, color: const Color(0xFF14A800).withOpacity(0.1)),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) => LineTooltipItem(
                '${spot.y.toInt()}',
                TextStyle(color: spot.bar.color),
              )).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildChartLegend(bool isDark, AppLocalizations t) {  
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _legendItem(Colors.blue, t.impressions ?? 'Impressions', isDark),  
      const SizedBox(width: 16),
      _legendItem(const Color(0xFF14A800), t.clicks ?? 'Clicks', isDark), 
    ],
  );
}
  Widget _legendItem(Color color, String label, bool isDark) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildPieChart(List typeStats, bool isDark, dynamic t) {
    final theme = Theme.of(context);
    final data = <Map<String, dynamic>>[];
    for (var stat in typeStats) {
      final spent = _toDouble(stat['total_spent']);
      if (spent > 0) {
        data.add({
          'type': stat['ad_type']?.toString().toUpperCase() ?? 'Unknown',
          'value': spent,
        });
      }
    }

    if (data.isEmpty) {
      return Center(
        child: Text(
          t?.noDataAvailable ?? 'No data available',
          style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        ),
      );
    }

    final total = data.fold(0.0, (sum, item) => sum + item['value']);
    final colors = [Colors.blue, const Color(0xFF14A800), const Color(0xFFF59E0B), theme.colorScheme.primary, Colors.purple];

    return PieChart(
      PieChartData(
        sections: List.generate(data.length, (i) {
          final percentage = ((data[i]['value'] / total) * 100);
          final title = '${percentage.toStringAsFixed(0)}%';
          return PieChartSectionData(
            color: colors[i % colors.length],
            value: data[i]['value'],
            title: title,
            radius: 80,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }

  Widget _buildBarChart(List topAdvertisers, bool isDark, dynamic t) {
    if (topAdvertisers.isEmpty) {
      return Center(
        child: Text(
          t?.noDataAvailable ?? 'No data available',
          style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        ),
      );
    }

    final top5 = topAdvertisers.take(5).toList();
    final maxSpent = top5.fold(0.0, (max, adv) => _toDouble(adv['total_spent']) > max ? _toDouble(adv['total_spent']) : max);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxSpent,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < top5.length) {
                  final name = (top5[value.toInt()]['name']?.substring(0, (top5[value.toInt()]['name'].length > 3 ? 3 : top5[value.toInt()]['name'].length)) ?? '?');
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 50)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: List.generate(top5.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: _toDouble(top5[i]['total_spent']),
                color: const Color(0xFFF59E0B),
                width: 30,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTypeStatsTable(List typeStats, AppLocalizations t, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DataTable(
        columnSpacing: 16,
        headingRowColor: WidgetStateProperty.resolveWith<Color>(
          (states) => isDark ? AppTheme.AppColors.darkSurface : const Color(0xFFF0F2F8),
        ),
        headingTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
        ),
        columns: [
          DataColumn(label: Text(t.type, style: const TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text(t.impressions, style: const TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text(t.clicks, style: const TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text(t.ctr, style: const TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text(t.spent, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: typeStats.map((stat) {
          final impressions = _toDouble(stat['total_impressions']);
          final clicks = _toDouble(stat['total_clicks']);
          final ctr = impressions > 0 ? (clicks / impressions) * 100 : 0;
          return DataRow(
            cells: [
              DataCell(Text(stat['ad_type']?.toString().toUpperCase() ?? t.unknown)),
              DataCell(Text(impressions.toInt().toString())),
              DataCell(Text(clicks.toInt().toString())),
              DataCell(Text('${ctr.toStringAsFixed(2)}%')),
              DataCell(Text('\$${_toDouble(stat['total_spent']).toStringAsFixed(2)}')),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopAdvertisersTable(List topAdvertisers, AppLocalizations t, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DataTable(
        columnSpacing: 16,
        headingRowColor: WidgetStateProperty.resolveWith<Color>(
          (states) => isDark ? AppTheme.AppColors.darkSurface : const Color(0xFFF0F2F8),
        ),
        headingTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
        ),
        columns: [
          DataColumn(label: Text(t.advertiser, style: const TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text(t.campaignsCount, style: const TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text(t.totalSpentCap, style: const TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text(t.commission, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: topAdvertisers.take(10).map((adv) {
          return DataRow(
            cells: [
              DataCell(Text(adv['name'] ?? t.unknown)),
              DataCell(Text(adv['campaign_count']?.toString() ?? '0')),
              DataCell(Text('\$${_toDouble(adv['total_spent']).toStringAsFixed(2)}')),
              DataCell(Text('\$${_toDouble(adv['platform_commission']).toStringAsFixed(2)}')),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMetricsGrid(Map<String, dynamic> summary, AppLocalizations t, bool isDark) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            t.additionalMetrics,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _metricChip(t.avgCtr, '${_computeAvgCTR(_analytics['type_stats'] ?? []).toStringAsFixed(2)}%', Icons.trending_up, isDark),
              const SizedBox(width: 12),
              _metricChip(t.estRoi, '250%', Icons.trending_up, isDark),
              const SizedBox(width: 12),
              _metricChip(t.conversionRate, '3.2%', Icons.analytics, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricChip(String label, String value, IconData icon, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsTab(AppLocalizations t, bool isDark) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade100,
              ),
            ),
            child: Column(
              children: [
                _statListItem(t.totalCampaigns, _stats['total_campaigns']?.toString() ?? '0', Icons.campaign, Colors.purple, isDark),
                _statListItem(t.activeCampaigns, _stats['active_campaigns']?.toString() ?? '0', Icons.play_circle, const Color(0xFF14A800), isDark),
                _statListItem(t.pausedCampaigns, _stats['paused_campaigns']?.toString() ?? '0', Icons.pause, const Color(0xFFF59E0B), isDark),
                _statListItem(t.completedCampaigns, _stats['completed_campaigns']?.toString() ?? '0', Icons.check_circle, Colors.blue, isDark),
                _statListItem(t.draftCampaigns, _stats['draft_campaigns']?.toString() ?? '0', Icons.edit_note, Colors.grey, isDark),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade100,
              ),
            ),
            child: Column(
              children: [
                _statListItem(t.totalImpressions, _stats['total_impressions']?.toString() ?? '0', Icons.visibility, Colors.blue, isDark),
                _statListItem(t.totalClicks, _stats['total_clicks']?.toString() ?? '0', Icons.touch_app, const Color(0xFF14A800), isDark),
                _statListItem(t.clickThroughRate, '${_stats['click_through_rate'] ?? 0}%', Icons.trending_up, const Color(0xFFF59E0B), isDark),
                _statListItem(t.totalSpend, '\$${(_stats['total_spent'] ?? 0).toDouble().toStringAsFixed(2)}', Icons.attach_money, Colors.red, isDark),
                _statListItem(t.totalBudgetSum, '\$${(_stats['total_budget'] ?? 0).toDouble().toStringAsFixed(2)}', Icons.account_balance_wallet, Colors.teal, isDark),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if ((_stats['pending_payments'] ?? 0) > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.payment, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.pendingPayments,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_stats['pending_payments']} ${t.campaignsWaitingForPayment}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.warning_amber, color: Color(0xFFF59E0B)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _statListItem(String title, String value, IconData icon, Color color, bool isDark) {
    String displayValue = value;
    if (value.startsWith('\$')) {
      final numValue = _toDouble(value.replaceAll('\$', ''));
      displayValue = '\$${numValue.toStringAsFixed(2)}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
          Text(
            displayValue,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}