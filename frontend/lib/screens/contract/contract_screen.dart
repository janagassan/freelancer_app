// screens/contract/contract_screen.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:freelancer_platform/screens/freelancer/work_submission_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../models/contract_model.dart';
import '../../services/api_service.dart';
import 'contract_sign_screen.dart';
import '../rating/add_rating_screen.dart';
import '../workspace/connect_github_screen.dart';
import '../payment/payment_screen.dart';
import '../disputes/create_dispute_screen.dart';
import '../../theme/app_theme.dart';

class ContractScreen extends StatefulWidget {
  final int contractId;
  final String userRole;

  const ContractScreen({
    super.key,
    required this.contractId,
    required this.userRole,
  });

  @override
  State<ContractScreen> createState() => _ContractScreenState();
}

class _ContractScreenState extends State<ContractScreen> {
  Contract? contract;
  bool loading = true;
  bool signing = false;
  bool _isProcessing = false;
  bool _couponBusy = false;
  bool _canRate = false;
  final TextEditingController _couponController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        fetchContract(context);
      }
    });
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  double get _clientEscrowAmountDue {
    if (contract == null) return 0;
    final a = contract!.agreedAmount ?? 0;
    final d = contract!.couponDiscountAmount ?? 0;
    return (a - d).clamp(0.0, double.infinity);
  }

  Future<void> _applyContractCoupon() async {
    final t = AppLocalizations.of(context)!;
    final code = _couponController.text.trim();
    if (code.isEmpty) {
      Fluttertoast.showToast(msg: t.enterCouponCode);
      return;
    }
    setState(() => _couponBusy = true);
    final r = await ApiService.applyContractCoupon(
      contractId: widget.contractId,
      code: code,
    );
    if (!mounted) return;
    setState(() => _couponBusy = false);
    if (r['success'] == true) {
      Fluttertoast.showToast(msg: r['message']?.toString() ?? t.couponApplied);
      _couponController.clear();
      fetchContract(context);
    } else {
      Fluttertoast.showToast(
        msg: r['message']?.toString() ?? t.couldNotApplyCoupon,
      );
    }
  }

  Future<void> _removeContractCoupon() async {
    final t = AppLocalizations.of(context)!;
    setState(() => _couponBusy = true);
    final r = await ApiService.removeContractCoupon(widget.contractId);
    if (!mounted) return;
    setState(() => _couponBusy = false);
    if (r['success'] == true) {
      Fluttertoast.showToast(msg: r['message']?.toString() ?? t.couponRemoved);
      fetchContract(context);
    } else {
      Fluttertoast.showToast(
        msg: r['message']?.toString() ?? t.couldNotRemoveCoupon,
      );
    }
  }

  Future<void> fetchContract(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    if (!mounted) return;

    setState(() => loading = true);
    try {
      final data = await ApiService.getContract(widget.contractId);

      if (!mounted) return;

      setState(() {
        contract = Contract.fromJson(data);
        loading = false;
      });

      if (contract?.status == 'completed') {
        final canRateRes = await ApiService.checkCanRate(widget.contractId);
        if (mounted) {
          setState(() {
            _canRate = canRateRes['canRate'] ?? false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        Fluttertoast.showToast(msg: t.errorLoadingContract);
      }
    }
  }

  bool get isAIGenerated {
    return contract?.terms?.contains('AI-generated') == true ||
        contract?.contractDocument?.contains('AI-generated') == true ||
        contract?.contractDocument?.contains('🤖') == true;
  }

  bool get needsPayment {
    if (contract == null) return false;
    return contract!.status == 'active' &&
        contract!.escrowStatus == 'pending' &&
        widget.userRole == 'client';
  }

  bool get isEscrowFunded {
    return contract?.escrowStatus == 'funded';
  }

  Future<void> _initiatePayment() async {
    final t = AppLocalizations.of(context)!;
    if (contract == null) return;

    setState(() => _isProcessing = true);

    try {
      final paymentIntent = await ApiService.createEscrowPaymentIntent(
        contractId: widget.contractId,
      );

      if (paymentIntent['clientSecret'] != null) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentScreen(
              contractId: widget.contractId,
              paymentIntent: paymentIntent,
            ),
          ),
        );

        if (result == true) {
          fetchContract(context);
        }
      } else {
        Fluttertoast.showToast(
          msg: paymentIntent['message'] ?? t.errorCreatingPayment,
        );
      }
    } catch (e) {
      print('Error initiating payment: $e');
      Fluttertoast.showToast(msg: '${t.error}: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> signContract() async {
    final t = AppLocalizations.of(context)!;
    setState(() => signing = true);

    try {
      final result = await ApiService.signContract(widget.contractId);

      if (result['contract'] != null) {
        Fluttertoast.showToast(msg: t.contractSignedSuccess);
        fetchContract(context);
      } else {
        Fluttertoast.showToast(
          msg: result['message'] ?? t.errorSigningContract,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '${t.error}: $e');
    } finally {
      setState(() => signing = false);
    }
  }

  bool get canSign {
    if (contract == null) return false;

    if (widget.userRole == 'client') {
      return (contract!.status == 'draft' ||
              contract!.status == 'pending_client') &&
          contract!.clientSignedAt == null;
    } else {
      return (contract!.status == 'draft' ||
              contract!.status == 'pending_freelancer') &&
          contract!.freelancerSignedAt == null;
    }
  }

  bool get isSignedByMe {
    if (contract == null) return false;

    if (widget.userRole == 'client') {
      return contract!.clientSignedAt != null;
    } else {
      return contract!.freelancerSignedAt != null;
    }
  }

  String get contractStatusText {
    final t = AppLocalizations.of(context);
    if (contract == null) return '';
    if (t == null) return contract!.status ?? '';

    switch (contract!.status) {
      case 'draft':
        return t.awaitingSignatures;
      case 'pending_client':
        return t.waitingForClientSignature;
      case 'pending_freelancer':
        return t.waitingForFreelancerSignature;
      case 'active':
        return t.contractActive;
      case 'completed':
        return t.contractCompleted;
      case 'cancelled':
        return t.contractCancelled;
      default:
        return contract!.status ?? t.unknown;
    }
  }

  Color get contractStatusColor {
    final theme = Theme.of(context);
    switch (contract?.status) {
      case 'active':
        return theme.colorScheme.secondary;
      case 'draft':
      case 'pending_client':
      case 'pending_freelancer':
        return AppColors.warning;
      case 'completed':
        return AppColors.info;
      case 'cancelled':
        return AppColors.danger;
      default:
        return AppColors.gray;
    }
  }

  Future<void> _showConnectGithubDialog() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          t.connectGithub,
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: Text(
          t.connectGithubDescription,
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.cancel, style: TextStyle(color: AppColors.gray)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ConnectGithubScreen(contractId: widget.contractId),
                ),
              ).then((value) {
                if (value == true) {
                  fetchContract(context);
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: Text(t.connect),
          ),
        ],
      ),
    );
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0.00';

    double parsedAmount;
    if (amount is double) {
      parsedAmount = amount;
    } else if (amount is int) {
      parsedAmount = amount.toDouble();
    } else if (amount is String) {
      parsedAmount = double.tryParse(amount) ?? 0.0;
    } else {
      parsedAmount = 0.0;
    }

    return parsedAmount.toStringAsFixed(2);
  }

  String _formatAmountInt(dynamic amount) {
    if (amount == null) return '0';

    double parsedAmount;
    if (amount is double) {
      parsedAmount = amount;
    } else if (amount is int) {
      parsedAmount = amount.toDouble();
    } else if (amount is String) {
      parsedAmount = double.tryParse(amount) ?? 0.0;
    } else {
      parsedAmount = 0.0;
    }

    return parsedAmount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Text(t.contractAgreement),
            if (isAIGenerated) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple, Colors.blue],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      "AI Generated",
                      style: TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),

        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          if (contract?.status == 'active')
            TextButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/contract/progress',
                  arguments: {
                    'contractId': widget.contractId,
                    'userRole': widget.userRole,
                  },
                );
              },
              icon: Icon(
                Icons.timeline,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              label: Text(
                t.progress,
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
          if (contract?.status == 'active' && widget.userRole == 'freelancer')
            IconButton(
              icon: Icon(Icons.calendar_month, color: theme.iconTheme.color),
              onPressed: () {
                Navigator.pushNamed(context, '/calendar');
              },
              tooltip: t.calendar,
            ),
        ],
      ),
      body: loading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : contract == null
          ? Center(
              child: Text(
                t.contractNotFound,
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: contractStatusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: contractStatusColor),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          contract!.status == 'active'
                              ? Icons.check_circle
                              : contract!.status == 'draft'
                              ? Icons.edit
                              : Icons.access_time,
                          color: contractStatusColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contractStatusText,
                                style: TextStyle(
                                  color: contractStatusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (contract!.signedAt != null)
                                Text(
                                  '${t.signedOn}: ${_formatDate(contract!.signedAt)}',
                                  style: TextStyle(
                                    color: contractStatusColor.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          t.contractAmount,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${t.dollar}${_formatAmountInt(contract!.agreedAmount)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (widget.userRole == 'freelancer' &&
                      contract?.status == 'active')
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isEscrowFunded
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isEscrowFunded
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isEscrowFunded
                                ? Icons.security
                                : Icons.warning_amber,
                            color: isEscrowFunded
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEscrowFunded
                                      ? t.escrowSecuredForFreelancer
                                      : t.waitingForClientPayment,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isEscrowFunded
                                        ? AppColors.success
                                        : AppColors.warning,
                                  ),
                                ),
                                Text(
                                  isEscrowFunded
                                      ? '${t.fundsAreProtected} ${t.dollar}${_formatAmountInt(contract?.agreedAmount)} ${t.inEscrow}'
                                      : t.clientWillFundEscrowBeforeWork,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.gray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (contract!.milestones != null &&
                      contract!.milestones!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              t.paymentMilestones,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            if (isAIGenerated)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      size: 10,
                                      color: Colors.purple.shade700,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      t.aiOptimized,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.purple.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...contract!.milestones!.map((milestone) {
                          return _buildMilestoneCard(
                            milestone,
                            contract!.milestones!.indexOf(milestone),
                          );
                        }).toList(),
                        const SizedBox(height: 16),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          t.noMilestonesFound,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  if (contract!.status == 'active' &&
                      widget.userRole == 'freelancer')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.githubIntegration,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (contract!.githubRepo == null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurface
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.dividerColor),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.link,
                                  size: 48,
                                  color: AppColors.gray,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  t.connectGithubRepository,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  t.trackProgressAndShowWork,
                                  style: TextStyle(color: AppColors.gray),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _showConnectGithubDialog,
                                  icon: const Icon(Icons.link),
                                  label: Text(t.connectRepository),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurface
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.dividerColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.link,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        contract!.githubRepo!,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                FutureBuilder<List<dynamic>>(
                                  future: ApiService.getGithubCommits(
                                    contract!.id!,
                                  ),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Center(
                                        child: CircularProgressIndicator(
                                          color: theme.colorScheme.primary,
                                        ),
                                      );
                                    }

                                    final commits = snapshot.data ?? [];

                                    return Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              t.recentCommits,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.gray,
                                              ),
                                            ),
                                            Text(
                                              '${commits.length} ${t.commits}',
                                              style: TextStyle(
                                                color: AppColors.gray,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        ...commits
                                            .take(3)
                                            .map(
                                              (commit) => Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                    ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.fiber_manual_record,
                                                      size: 8,
                                                      color: theme
                                                          .colorScheme
                                                          .primary,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            commit['message'],
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: TextStyle(
                                                              color: theme
                                                                  .colorScheme
                                                                  .onSurface,
                                                            ),
                                                          ),
                                                          Text(
                                                            '${commit['author']} • ${_formatDateShort(DateTime.parse(commit['date']))}',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              color: AppColors
                                                                  .gray,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),

                  if (widget.userRole == 'client' &&
                      contract != null &&
                      (contract!.status == 'active' ||
                          contract!.status == 'completed'))
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          t.workSubmissions,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/contract/submissions',
                                arguments: {
                                  'contractId': widget.contractId,
                                  'userRole': widget.userRole,
                                },
                              );
                            },
                            icon: Icon(
                              Icons.folder_open,
                              color: theme.colorScheme.primary,
                            ),
                            label: Text(t.viewAllSubmissions),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  if (widget.userRole == 'freelancer' &&
                      contract?.status == 'active')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          t.workSubmissions,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/contract/submissions',
                                arguments: {
                                  'contractId': widget.contractId,
                                  'userRole': widget.userRole,
                                },
                              );
                            },
                            icon: Icon(
                              Icons.history,
                              color: theme.colorScheme.primary,
                            ),
                            label: Text(t.viewMySubmissions),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  Text(
                    t.contractDocument,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    height: 400,
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: contract!.contractDocument != null
                        ? _buildHtmlDocument(contract!.contractDocument!)
                        : Center(
                            child: Text(
                              t.contractDocumentNotAvailable,
                              style: TextStyle(color: AppColors.gray),
                            ),
                          ),
                  ),

                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              contract!.clientSignedAt != null
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: contract!.clientSignedAt != null
                                  ? theme.colorScheme.secondary
                                  : AppColors.gray,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.clientSignature,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  if (contract!.clientSignedAt != null)
                                    Text(
                                      _formatDate(contract!.clientSignedAt),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.gray,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Divider(height: 24, color: theme.dividerColor),
                        Row(
                          children: [
                            Icon(
                              contract!.freelancerSignedAt != null
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: contract!.freelancerSignedAt != null
                                  ? theme.colorScheme.secondary
                                  : AppColors.gray,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.freelancerSignature,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  if (contract!.freelancerSignedAt != null)
                                    Text(
                                      _formatDate(contract!.freelancerSignedAt),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.gray,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (widget.userRole == 'client' &&
                      contract?.status == 'active')
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Card(
                        elevation: 2,
                        color: theme.cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.attach_money,
                                    color: isEscrowFunded
                                        ? theme.colorScheme.secondary
                                        : AppColors.warning,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      isEscrowFunded
                                          ? t.escrowFunded
                                          : t.paymentRequired,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isEscrowFunded
                                            ? theme.colorScheme.secondary
                                            : AppColors.warning,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                isEscrowFunded
                                    ? t.escrowFundedDescription
                                    : t.paymentRequiredDescription,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.gray,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (!isEscrowFunded &&
                                  widget.userRole == 'client') ...[
                                TextField(
                                  controller: _couponController,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: t.contractCouponEscrow,
                                    hintText: t.applyBeforePaying,
                                    labelStyle: TextStyle(
                                      color: AppColors.gray,
                                    ),
                                    border: const OutlineInputBorder(),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: theme.dividerColor,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    suffixIcon: _couponBusy
                                        ? Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                            ),
                                          )
                                        : IconButton(
                                            icon: Icon(
                                              Icons.local_offer,
                                              color: theme.colorScheme.primary,
                                            ),
                                            tooltip: t.apply,
                                            onPressed: _couponBusy
                                                ? null
                                                : _applyContractCoupon,
                                          ),
                                  ),
                                  onSubmitted: (_) => _applyContractCoupon(),
                                ),
                                if (contract?.couponCode != null &&
                                    contract!.couponCode!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Chip(
                                          avatar: Icon(
                                            Icons.sell,
                                            size: 18,
                                            color: theme.colorScheme.primary,
                                          ),
                                          label: Text(
                                            '${contract!.couponCode} · -${t.dollar}${_formatAmount(contract!.couponDiscountAmount)}',
                                            style: TextStyle(
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                          ),
                                          backgroundColor: theme.cardColor,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: _couponBusy
                                            ? null
                                            : _removeContractCoupon,
                                        child: Text(
                                          t.remove,
                                          style: TextStyle(
                                            color: AppColors.danger,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 12),
                                if ((contract?.couponDiscountAmount ?? 0) > 0)
                                  Text(
                                    '${t.amountDueNow}: ${t.dollar}${_formatAmount(_clientEscrowAmountDue)} (${t.afterCoupon})',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.secondary,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                              ],
                              if (!isEscrowFunded)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _isProcessing
                                        ? null
                                        : _initiatePayment,
                                    icon: _isProcessing
                                        ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.lock_clock),
                                    label: Text(
                                      _isProcessing
                                          ? t.processing
                                          : '${t.pay} ${t.dollar}${_formatAmount(_clientEscrowAmountDue)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          theme.colorScheme.secondary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              if (isEscrowFunded)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: theme.colorScheme.secondary
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: theme.colorScheme.secondary,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          '${t.paymentSecured}: ${t.dollar}${_formatAmount(contract?.agreedAmount)} ${t.inEscrow}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: theme.colorScheme.secondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  if (contract!.status == 'completed' && _canRate == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final t = AppLocalizations.of(context)!;
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddRatingScreen(
                                contractId: widget.contractId,
                                projectTitle:
                                    contract!.project?.title ?? t.project,
                                otherPartyName: widget.userRole == 'client'
                                    ? contract!.freelancer?.name ?? t.freelancer
                                    : contract!.client?.name ?? t.client,
                                role: widget.userRole,
                              ),
                            ),
                          );
                          if (result == true) {
                            setState(() => _canRate = false);
                            Fluttertoast.showToast(msg: t.thankYouForRating);
                          }
                        },
                        icon: const Icon(Icons.star_border),
                        label: Text(t.rateThisExperience),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                  if (canSign)
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: signing ? null : _navigateToSignScreen,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: signing
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                isSignedByMe
                                    ? t.waitingForOtherParty
                                    : t.signContract,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                  if (contract!.status == 'active' ||
                      contract!.status == 'completed')
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: OutlinedButton.icon(
                          onPressed: () => _navigateToCreateDispute(),
                          icon: const Icon(Icons.gavel, color: Colors.red),
                          label: Text(
                            t.raiseDispute,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),

                  if (contract!.status == 'active')
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Center(
                        child: Text(
                          t.contractActiveMessage,
                          style: TextStyle(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildHtmlDocument(String htmlContent) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Html(
        data: htmlContent,
        style: {
          "body": Style(
            fontSize: FontSize(14.0),
            lineHeight: LineHeight(1.6),
            color: textColor,
          ),
          "h1": Style(
            fontSize: FontSize(24),
            color: isDark ? AppColors.accent : AppColors.primary,
            textAlign: TextAlign.center,
            margin: Margins.only(bottom: 20),
            fontWeight: FontWeight.bold,
          ),
          "h2": Style(
            fontSize: FontSize(18),
            fontWeight: FontWeight.bold,
            margin: Margins.only(top: 16, bottom: 8),
            color: textColor,
          ),
          "h3": Style(
            fontSize: FontSize(16),
            fontWeight: FontWeight.bold,
            margin: Margins.only(top: 12, bottom: 6),
            color: textColor,
          ),
          "p": Style(
            margin: Margins.only(bottom: 8),
            color: textColor,
            fontSize: FontSize(14),
          ),
          ".signature": Style(
            margin: Margins.only(top: 32),
            fontStyle: FontStyle.italic,
            fontSize: FontSize(16),
            color: isDark ? AppColors.accent : AppColors.secondary,
          ),
          ".terms": Style(
            backgroundColor: isDark
                ? AppColors.darkSurface
                : Colors.grey.shade100,
            padding: HtmlPaddings.all(16),
            margin: Margins.only(top: 8, bottom: 8),
          ),
          "strong": Style(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.accent : AppColors.primary,
          ),
          ".milestone-card": Style(
            backgroundColor: isDark
                ? AppColors.darkSurface
                : Colors.grey.shade50,
            padding: HtmlPaddings.all(12),
            margin: Margins.only(bottom: 12),
          ),
          ".clause": Style(
            backgroundColor: isDark
                ? AppColors.darkSurface
                : Colors.grey.shade50,
            padding: HtmlPaddings.all(12),
            margin: Margins.only(bottom: 12),
          ),
          "span": Style(color: textColor),
          "div": Style(color: textColor),
        },
      ),
    );
  }

  Widget _buildMilestoneCard(Map<String, dynamic> milestone, int index) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    double getAmount(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    final isCompleted = milestone['status'] == 'completed';
    final isApproved = milestone['status'] == 'approved';
    final isPending =
        milestone['status'] == 'pending' ||
        milestone['status'] == 'in_progress';
    final progress = getAmount(milestone['progress']);
    final amount = getAmount(milestone['amount']);

    final isEscrowFunded = contract?.escrowStatus == 'funded';

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isApproved) {
      statusColor = theme.colorScheme.secondary;
      statusIcon = Icons.check_circle;
      statusText = t.paid;
    } else if (isCompleted) {
      statusColor = AppColors.warning;
      statusIcon = Icons.pending;
      statusText = t.completedAwaitingApproval;
    } else if (isPending) {
      statusColor = AppColors.info;
      statusIcon = Icons.radio_button_unchecked;
      statusText = t.inProgress;
    } else {
      statusColor = AppColors.gray;
      statusIcon = Icons.block;
      statusText = t.notStarted;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        milestone['title'] ?? '${t.milestone} ${index + 1}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${t.dollar}${amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (milestone['description'] != null &&
                milestone['description'].toString().isNotEmpty)
              Text(
                milestone['description'],
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  height: 1.4,
                ),
              ),

            const SizedBox(height: 12),

            if (milestone['due_date'] != null)
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: AppColors.gray),
                  const SizedBox(width: 6),
                  Text(
                    '${t.due}: ${_formatDateShort(DateTime.parse(milestone['due_date']))}',
                    style: TextStyle(fontSize: 12, color: AppColors.gray),
                  ),
                ],
              ),

            const SizedBox(height: 12),

            if (!isApproved)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t.progress,
                        style: TextStyle(fontSize: 11, color: AppColors.gray),
                      ),
                      Text(
                        '${progress.toInt()}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      backgroundColor: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),

            if (widget.userRole == 'freelancer' &&
                !isCompleted &&
                !isApproved &&
                isEscrowFunded)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : () => _completeMilestone(index),
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: Text(
                          progress >= 100
                              ? t.markAsCompleted
                              : t.updateProgress,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (widget.userRole == 'freelancer' &&
                !isCompleted &&
                !isApproved &&
                !isEscrowFunded &&
                contract?.status == 'active')
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.warning,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t.waitingForClientPaymentBeforeWork,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (widget.userRole == 'client' && isCompleted && !isApproved)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : () => _approveMilestone(index),
                        icon: const Icon(Icons.attach_money, size: 18),
                        label: Text(
                          '${t.approveAndRelease} ${t.dollar}${amount.toStringAsFixed(0)}',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warning,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _requestRevision(index),
                        icon: const Icon(Icons.edit, size: 18),
                        label: Text(t.requestChanges),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: BorderSide(color: AppColors.danger),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (isApproved)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.secondary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${t.paymentReleasedOn} ${_formatDateShort(milestone['approved_at'] != null ? DateTime.parse(milestone['approved_at']) : DateTime.now())}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeMilestone(int index) async {
    final t = AppLocalizations.of(context)!;

    if (contract == null ||
        contract!.milestones == null ||
        index >= contract!.milestones!.length) {
      Fluttertoast.showToast(msg: t.errorCompletingMilestone);
      return;
    }

    if (contract?.escrowStatus != 'funded') {
      Fluttertoast.showToast(msg: t.cannotSubmitWorkEscrowNotFunded);
      return;
    }

    final milestone = contract!.milestones![index];
    final isCompleted = milestone['status'] == 'completed';

    if (isCompleted) {
      Fluttertoast.showToast(msg: t.milestoneAlreadyCompleted);
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkSubmissionScreen(
          contract: contract!,
          milestoneIndex: index,
          milestone: milestone,
        ),
      ),
    );

    if (result == true) {
      await fetchContract(context);
      Fluttertoast.showToast(msg: t.workSubmittedSuccess);
    }
  }

  Future<void> _approveMilestone(int index) async {
    final t = AppLocalizations.of(context)!;
    final milestone = contract!.milestones![index];
    final theme = Theme.of(context);
    double getAmount(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    final amount = getAmount(milestone['amount']);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          t.approveMilestone,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.approveMilestoneConfirmation(milestone['title']),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    t.amountWillBeReleased(amount.toStringAsFixed(2)),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.thisActionCannotBeUndone,
              style: TextStyle(fontSize: 12, color: AppColors.gray),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel, style: TextStyle(color: AppColors.gray)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
            child: Text(t.approveAndRelease),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      final result = await ApiService.approveMilestone(
        contractId: widget.contractId,
        milestoneIndex: index,
      );

      if (result['success'] == true) {
        Fluttertoast.showToast(
          msg: result['message'] ?? t.milestoneApprovedPaymentReleased,
        );
        await fetchContract(context);
      } else {
        Fluttertoast.showToast(
          msg: result['message'] ?? t.errorApprovingMilestone,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '${t.error}: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _requestRevision(int index) async {
    final t = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          t.requestChanges,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.explainWhatNeedsToBeChanged,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: t.describeChangesNeeded,
                hintStyle: TextStyle(color: AppColors.gray),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel, style: TextStyle(color: AppColors.gray)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.sendRequest),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.isNotEmpty) {
      setState(() => _isProcessing = true);

      try {
        final result = await ApiService.requestMilestoneRevision(
          contractId: widget.contractId,
          milestoneIndex: index,
          revisionMessage: controller.text,
        );

        if (result['success'] == true) {
          Fluttertoast.showToast(msg: t.revisionRequestSent);
          await fetchContract(context);
        } else {
          Fluttertoast.showToast(
            msg: result['message'] ?? t.errorSendingRevision,
          );
        }
      } catch (e) {
        Fluttertoast.showToast(msg: '${t.error}: $e');
      } finally {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _navigateToSignScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContractSignScreen(
          contractId: widget.contractId,
          userRole: widget.userRole,
        ),
      ),
    );

    if (result == true) {
      await fetchContract(context);
    }
  }

  void _navigateToCreateDispute() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CreateDisputeScreen(contractId: widget.contractId),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    final t = AppLocalizations.of(context);
    if (date == null) return t?.notSigned ?? 'Not signed';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateShort(DateTime date) {
    return '${date.day}/${date.month}';
  }
}
