// lib/screens/wallet/wallet_screen.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../models/wallet_model.dart';
import '../../models/transaction_model.dart';
import '../../theme/app_theme.dart';
import '../freelancer/financial_dashboard_screen.dart';
import 'transaction_history_screen.dart';

class WalletScreen extends StatefulWidget {
  final String userRole;
  const WalletScreen({super.key, required this.userRole});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  WalletModel? wallet;
  List<TransactionModel> transactions = [];
  bool loading = true;
  bool withdrawing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadWallet(context);
      }
    });
  }

  Future<void> _loadWallet(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    if (!mounted) return;

    setState(() => loading = true);

    try {
      Map<String, dynamic> result;
      if (widget.userRole == 'client') {
        result = await ApiService.getWallet();
      } else {
        result = await ApiService.getFreelancerWallet();
      }

      print('📱 Wallet result: $result');

      if (result['success'] == true) {
        setState(() {
          if (result['wallet'] != null) {
            wallet = WalletModel.fromJson(result['wallet']);
            print('✅ Wallet model created: ${wallet?.balance}');
          }
          if (result['transactions'] != null) {
            transactions = (result['transactions'] as List)
                .map((json) => TransactionModel.fromJson(json))
                .toList();
            print('✅ Transactions loaded: ${transactions.length}');
          }
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
          wallet = null;
          transactions = [];
        });

        final errorMsg = result['message'] ?? t.errorLoadingWallet;
        Fluttertoast.showToast(msg: errorMsg);

        if (errorMsg.contains('no wallet') || errorMsg.contains('not found')) {
          _showCreateWalletDialog();
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      Fluttertoast.showToast(msg: t.errorLoadingWallet);
      print('❌ Error loading wallet: $e');
    }
  }

  void _showCreateWalletDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Wallet'),
        content: const Text(
          'You don\'t have a wallet yet. Would you like to create one?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await ApiService.createWallet();
              if (result['success'] == true) {
                _loadWallet(context);
              } else {
                Fluttertoast.showToast(msg: 'Failed to create wallet');
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestWithdrawal(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          t.withdrawFunds,
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${t.availableBalance}: ${t.dollar}${wallet?.balance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: t.amount,
                  prefixText: '${t.dollar} ',
                  labelStyle: TextStyle(color: AppColors.gray),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return t.pleaseEnterAmount;
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return t.invalidAmount;
                  }
                  if (amount > (wallet?.balance ?? 0)) {
                    return t.insufficientBalance;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel, style: TextStyle(color: AppColors.gray)),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.secondary,
            ),
            child: Text(t.withdraw),
          ),
        ],
      ),
    );

    if (result == true && amountController.text.isNotEmpty) {
      setState(() => withdrawing = true);

      final amount = double.parse(amountController.text);
      final response = widget.userRole == 'client'
          ? await ApiService.requestWithdrawal(amount)
          : await ApiService.requestFreelancerWithdrawal(amount);

      setState(() => withdrawing = false);

      if (response['success'] == true) {
        Fluttertoast.showToast(msg: t.withdrawalRequestSubmitted);
        _loadWallet(context);
      } else if (response['requiresOnboarding'] == true) {
        Fluttertoast.showToast(msg: t.completeStripeAccountSetup);
      } else {
        Fluttertoast.showToast(msg: response['message'] ?? t.error);
      }
    }
  }

  String _formatDate(DateTime date) {
    final t = AppLocalizations.of(context);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${t?.daysAgo ?? 'd ago'}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${t?.hoursAgo ?? 'h ago'}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${t?.minutesAgo ?? 'm ago'}';
    } else {
      return t?.justNow ?? 'Just now';
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
           leading: IconButton(
        icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
        onPressed: () => Navigator.pop(context),
        tooltip: 'Back',
      ),
        title: Text(t.myWallet),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.iconTheme.color),
            onPressed: () => _loadWallet(context),
          ),
          IconButton(
            icon: Icon(Icons.analytics, color: theme.iconTheme.color),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FinancialDashboardScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: loading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : wallet == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 64,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t.noWalletFound,
                    style: TextStyle(
                      fontSize: 18,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _loadWallet(context),
              color: theme.colorScheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildBalanceCard(),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                    const SizedBox(height: 24),
                    _buildTransactionsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActionButtons() {
  final t = AppLocalizations.of(context)!;
  final theme = Theme.of(context);

  return Row(
    children: [
      Expanded(
        child: _buildActionCard(
          icon: Icons.arrow_downward,
          label: t.withdraw,
          color: AppColors.warning,
          onTap: () => _requestWithdrawal(context),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _buildActionCard(
          icon: Icons.history,
          label: t.history,
          color: AppColors.info,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TransactionHistoryScreen(
                  userRole: widget.userRole,
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.secondary, AppColors.secondaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.secondary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            t.availableBalance,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '${t.dollar}${wallet!.balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBalanceStat(
                t.pendingPayments,
                '${t.dollar}${wallet!.pendingBalance.toStringAsFixed(2)}',
                Colors.white70,
              ),
              _buildBalanceStat(
                t.earned,
                '${t.dollar}${wallet!.totalEarned.toStringAsFixed(2)}',
                Colors.white70,
              ),
              _buildBalanceStat(
                t.withdrawn,
                '${t.dollar}${wallet!.totalWithdrawn.toStringAsFixed(2)}',
                Colors.white70,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsSection() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.receipt,
              size: 48,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              t.noTransactionsYet,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.recentTransactions,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length > 10 ? 10 : transactions.length,
          separatorBuilder: (context, index) =>
              Divider(color: theme.dividerColor),
          itemBuilder: (context, index) {
            final tx = transactions[index];
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tx.typeColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(tx.typeIcon, style: const TextStyle(fontSize: 20)),
              ),
              title: Text(
                tx.typeText,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                tx.description ?? '',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${tx.amount >= 0 ? '+' : ''}${t.dollar}${tx.amount.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: tx.type == 'withdraw'
                          ? AppColors.danger
                          : theme.colorScheme.secondary,
                    ),
                  ),
                  Text(
                    _formatDate(tx.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (transactions.length > 10)
          TextButton(
            onPressed: () {
              // TODO: Show all transactions
            },
            child: Text(
              t.viewAll,
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
      ],
    );
  }
}