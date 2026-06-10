// lib/screens/wallet/transaction_history_screen.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../models/transaction_model.dart';
import '../../theme/app_theme.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final String userRole;

  const TransactionHistoryScreen({super.key, required this.userRole});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<TransactionModel> allTransactions = [];
  List<TransactionModel> filteredTransactions = [];
  bool loading = true;

  String selectedFilter = 'all';
  String? selectedType;
  DateTimeRange? dateRange;

  final List<String> filterOptions = [
    'all',
    'deposit',
    'withdraw',
    'payment',
    'fee',
    'bonus',
  ];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => loading = true);

    try {
      Map<String, dynamic> result;
      if (widget.userRole == 'client') {
        result = await ApiService.getWallet();
      } else {
        result = await ApiService.getFreelancerWallet();
      }

      if (result['success'] == true && result['transactions'] != null) {
        setState(() {
          allTransactions = (result['transactions'] as List)
              .map((json) => TransactionModel.fromJson(json))
              .toList();
          _applyFilters();
          loading = false;
        });
      } else {
        setState(() {
          allTransactions = [];
          filteredTransactions = [];
          loading = false;
        });
      }
    } catch (e) {
      setState(() => loading = false);
      Fluttertoast.showToast(msg: 'Error loading transactions');
    }
  }

  void _applyFilters() {
    List<TransactionModel> filtered = List.from(allTransactions);

    if (selectedFilter != 'all') {
      filtered = filtered.where((tx) => tx.type == selectedFilter).toList();
    }

    if (dateRange != null) {
      filtered = filtered.where((tx) {
        return tx.createdAt.isAfter(dateRange!.start) &&
            tx.createdAt.isBefore(dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    setState(() {
      filteredTransactions = filtered;
    });
  }

  void _showDateRangePicker() async {
    final currentLocale = Localizations.localeOf(context);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020, 1),
      lastDate: DateTime.now(),
      initialDateRange: dateRange,
      locale: currentLocale, 
    );

    if (picked != null) {
      setState(() {
        dateRange = picked;
        _applyFilters();
      });
    }
  }

  void _clearFilters() {
    setState(() {
      selectedFilter = 'all';
      dateRange = null;
      _applyFilters();
    });
  }

  String _getTypeText(String type, AppLocalizations t) {
    switch (type) {
      case 'deposit':
        return t.deposit;
      case 'withdraw':
        return t.withdrawal;
      case 'payment':
        return t.paymentReceived;
      case 'fee':
        return t.platformFee;
      case 'bonus':
        return t.bonus;
      default:
        return type;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'deposit':
        return Icons.arrow_downward;
      case 'withdraw':
        return Icons.arrow_upward;
      case 'payment':
        return Icons.payment;
      case 'fee':
        return Icons.receipt;
      case 'bonus':
        return Icons.card_giftcard;
      default:
        return Icons.history;
    }
  }

  Color _getTypeColor(String type, ThemeData theme) {
    switch (type) {
      case 'deposit':
        return theme.colorScheme.secondary;
      case 'withdraw':
        return AppColors.danger;
      case 'payment':
        return Colors.green;
      case 'fee':
        return Colors.orange;
      case 'bonus':
        return Colors.purple;
      default:
        return theme.colorScheme.primary;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) return 'Yesterday';
      if (difference.inDays < 7) return '${difference.inDays} days ago';
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  double _getTotalByType(String type) {
    return allTransactions
        .where((tx) => tx.type == type)
        .fold(0.0, (sum, tx) => sum + tx.amount.abs());
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Transaction History'),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.iconTheme.color),
            onPressed: _loadTransactions,
          ),
          if (dateRange != null || selectedFilter != 'all')
            TextButton(
              onPressed: _clearFilters,
              child: Text(
                'Clear',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
        ],
      ),
      body: loading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : Column(
              children: [
                _buildSummaryCards(theme, t),

                _buildFiltersBar(theme, t),

                Expanded(
                  child: filteredTransactions.isEmpty
                      ? _buildEmptyState(theme, t)
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredTransactions.length,
                          itemBuilder: (context, index) {
                            final tx = filteredTransactions[index];
                            return _buildTransactionTile(tx, theme, t);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryCards(ThemeData theme, AppLocalizations t) {
    final totalDeposits =
        _getTotalByType('deposit') + _getTotalByType('payment');
    final totalWithdrawals = _getTotalByType('withdraw');
    final totalFees = _getTotalByType('fee');

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              title: 'Total Received',
              value: '\$${totalDeposits.toStringAsFixed(2)}',
              icon: Icons.arrow_downward,
              color: Colors.green,
              theme: theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              title: 'Total Withdrawn',
              value: '\$${totalWithdrawals.toStringAsFixed(2)}',
              icon: Icons.arrow_upward,
              color: AppColors.danger,
              theme: theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              title: 'Fees Paid',
              value: '\$${totalFees.toStringAsFixed(2)}',
              icon: Icons.receipt,
              color: Colors.orange,
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersBar(ThemeData theme, AppLocalizations t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', 'all', theme),
            const SizedBox(width: 8),
            _buildFilterChip('Deposits', 'deposit', theme),
            const SizedBox(width: 8),
            _buildFilterChip('Withdrawals', 'withdraw', theme),
            const SizedBox(width: 8),
            _buildFilterChip('Payments', 'payment', theme),
            const SizedBox(width: 8),
            _buildFilterChip('Fees', 'fee', theme),
            const SizedBox(width: 8),
            _buildFilterChip('Bonuses', 'bonus', theme),

            const SizedBox(width: 16),

            GestureDetector(
              onTap: _showDateRangePicker,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: dateRange != null
                      ? theme.colorScheme.primary.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: dateRange != null
                          ? theme.colorScheme.primary
                          : theme.iconTheme.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dateRange != null
                          ? '${dateRange!.start.day}/${dateRange!.start.month} - ${dateRange!.end.day}/${dateRange!.end.month}'
                          : 'Select dates',
                      style: TextStyle(
                        fontSize: 12,
                        color: dateRange != null
                            ? theme.colorScheme.primary
                            : theme.iconTheme.color,
                      ),
                    ),
                    if (dateRange != null) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            dateRange = null;
                            _applyFilters();
                          });
                        },
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: theme.iconTheme.color,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String filterValue, ThemeData theme) {
    final isSelected = selectedFilter == filterValue;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = filterValue;
          _applyFilters();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected
                ? Colors.white
                : theme.colorScheme.onSurface.withOpacity(0.7),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTile(
    TransactionModel tx,
    ThemeData theme,
    AppLocalizations t,
  ) {
    final isPositive =
        tx.type == 'deposit' || tx.type == 'payment' || tx.type == 'bonus';
    final color = _getTypeColor(tx.type, theme);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_getTypeIcon(tx.type), size: 22, color: color),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTypeText(tx.type, t),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (tx.description != null && tx.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      tx.description!,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatDate(tx.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPositive ? '+' : '-'}\$${tx.amount.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? Colors.green : AppColors.danger,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: tx.status == 'completed'
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tx.status == 'completed' ? 'Completed' : 'Pending',
                  style: TextStyle(
                    fontSize: 9,
                    color: tx.status == 'completed'
                        ? Colors.green
                        : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, AppLocalizations t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          if (dateRange != null || selectedFilter != 'all')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton(
                onPressed: _clearFilters,
                child: Text(
                  'Clear filters',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
