// screens/disputes/my_disputes_screen.dart

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/dispute_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart' as AppTheme;
import 'dispute_details_screen.dart';

class MyDisputesScreen extends StatefulWidget {
  const MyDisputesScreen({Key? key}) : super(key: key);

  @override
  State<MyDisputesScreen> createState() => _MyDisputesScreenState();
}

class _MyDisputesScreenState extends State<MyDisputesScreen> {
  List<Dispute> _disputes = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _totalPages = 1;
  String _selectedStatus = 'all';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
     print('🔍 MyDisputesScreen initState called'); 
    _loadDisputes();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoadingMore &&
        _currentPage < _totalPages) {
      _loadMoreDisputes();
    }
  }

  Future<void> _loadDisputes({bool refresh = false}) async {
    print('🔍 _loadDisputes called, refresh: $refresh'); 
  print('🔍 _selectedStatus: $_selectedStatus');
  print('🔍 _currentPage: $_currentPage');
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _disputes = [];
        _isLoading = true;
      });
    }
     print('🔍 Before API call');


    try {
      print('🔍 Calling ApiService.getUserDisputes...'); 
      final response = await ApiService.getUserDisputes(
        status: _selectedStatus,
        page: _currentPage,
        limit: 20,
      );
       print('🔍 After API call, response received');
       print('🔍 Response: $response');

      if (!mounted) return;
      print('🔍 Response success: ${response['success']}'); 

      if (response['success'] == true) {
        final disputes = (response['disputes'] as List)
            .map((json) => Dispute.fromJson(json))
            .toList();
            print('🔍 Disputes parsed: ${disputes.length}');

        setState(() {
          if (refresh) {
            _disputes = disputes;
          } else {
            _disputes.addAll(disputes);
          }
          _totalPages = response['totalPages'] ?? 1;
          _isLoading = false;
        });
      } else {
        print('❌ Response success false: ${response['message']}');   
        setState(() => _isLoading = false);
        final t = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ??
                  t?.errorLoadingDisputes ??
                  'Error loading disputes',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('❌ Exception in _loadDisputes: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      final t = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t?.connectionError ?? 'Connection error'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _loadMoreDisputes() async {
    if (_currentPage >= _totalPages) return;

    setState(() => _isLoadingMore = true);
    _currentPage++;
    await _loadDisputes();
    if (mounted) {
      setState(() => _isLoadingMore = false);
    }
  }

  void _onStatusChanged(String? status) {
    if (status != null && status != _selectedStatus) {
      setState(() {
        _selectedStatus = status;
        _currentPage = 1;
        _disputes = [];
        _isLoading = true;
      });
      _loadDisputes();
    }
  }

  Color _getStatusColor(String status, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'under_review':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return isDark ? Colors.grey.shade600 : Colors.grey;
    }
  }

  String _getStatusText(String status, AppLocalizations t) {
    switch (status) {
      case 'pending':
        return t.disputeStatusPending;
      case 'under_review':
        return t.disputeStatusUnderReview;
      case 'resolved':
        return t.disputeStatusResolved;
      case 'rejected':
        return t.disputeStatusRejected;
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildFilterDropdown() {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.AppColors.darkSurface : Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppTheme.AppColors.darkBorder
                : Colors.grey.shade200,
            width: 0.5,
          ),
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedStatus,
        decoration: InputDecoration(
          labelText: t.filterByStatus,
          labelStyle: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark
                  ? AppTheme.AppColors.darkBorder
                  : Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
          ),
          filled: true,
          fillColor: isDark ? AppTheme.AppColors.darkCard : Colors.white,
        ),
        dropdownColor: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
        style: TextStyle(
          color: isDark ? Colors.white : AppTheme.AppColors.lightTextPrimary,
        ),
        icon: Icon(Icons.filter_list, color: theme.colorScheme.primary),
        items: [
          DropdownMenuItem(value: 'all', child: Text(t.allDisputes)),
          DropdownMenuItem(
            value: 'pending',
            child: Text(t.disputeStatusPending),
          ),
          DropdownMenuItem(
            value: 'under_review',
            child: Text(t.disputeStatusUnderReview),
          ),
          DropdownMenuItem(
            value: 'resolved',
            child: Text(t.disputeStatusResolved),
          ),
          DropdownMenuItem(
            value: 'rejected',
            child: Text(t.disputeStatusRejected),
          ),
        ],
        onChanged: _onStatusChanged,
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.gavel,
            size: 64,
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            t.noDisputes,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.noDisputesDesc,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisputeCard(Dispute dispute) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = _getStatusColor(dispute.status, context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToDisputeDetails(dispute),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        dispute.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : AppTheme.AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(isDark ? 0.15 : 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        _getStatusText(dispute.status, t),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 14,
                      color: isDark
                          ? Colors.grey.shade500
                          : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${t.contractId}: ${dispute.contract?.id ?? t.notSpecified}',
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  dispute.description.length > 120
                      ? '${dispute.description.substring(0, 120)}...'
                      : dispute.description,
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: isDark
                          ? Colors.grey.shade600
                          : Colors.grey.shade500,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${t.createdAt}: ${_formatDate(dispute.createdAt)}',
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade600
                            : Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                if (dispute.resolution != null &&
                    dispute.resolution!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.green.withOpacity(0.1)
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? Colors.green.withOpacity(0.3)
                            : Colors.green.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          dispute.status == 'resolved'
                              ? Icons.check_circle
                              : Icons.cancel,
                          size: 16,
                          color: dispute.status == 'resolved'
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            dispute.resolution!,
                            style: TextStyle(
                              color: dispute.status == 'resolved'
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToDisputeDetails(Dispute dispute) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DisputeDetailsScreen(dispute: dispute),
      ),
    );
  }

  Future<void> _onRefresh() async {
    await _loadDisputes(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          t.myDisputes,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark
            ? AppTheme.AppColors.darkSurface
            : AppTheme.AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _onRefresh,
            tooltip: t.refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterDropdown(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _disputes.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: theme.colorScheme.primary,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _disputes.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _disputes.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          );
                        }
                        final dispute = _disputes[index];
                        return _buildDisputeCard(dispute);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
