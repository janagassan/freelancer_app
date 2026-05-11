// screens/admin/disputes_management_screen.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../l10n/app_localizations.dart';
import '../../models/dispute_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart' as AppTheme;

class DisputesManagementScreen extends StatefulWidget {
  const DisputesManagementScreen({super.key});

  @override
  State<DisputesManagementScreen> createState() =>
      _DisputesManagementScreenState();
}

class _DisputesManagementScreenState extends State<DisputesManagementScreen> {
  List<Dispute> disputes = [];
  bool loading = true;
  String selectedStatus = 'all';
  int currentPage = 1;
  int totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadDisputes();
  }

  Future<void> _loadDisputes() async {
    setState(() => loading = true);
    try {
      final response = await ApiService.getAdminDisputes(
        status: selectedStatus,
        page: currentPage,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        setState(() {
          disputes = (response['disputes'] as List)
              .map((d) => Dispute.fromJson(d))
              .toList();
          totalPages = response['totalPages'] ?? 1;
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      if (!mounted) return;
      final t = AppLocalizations.of(context);
      Fluttertoast.showToast(msg: '${t?.errorLoadingDisputes}: $e');
      setState(() => loading = false);
    }
  }

  Future<void> _resolveDispute(
    int disputeId,
    String resolution, {
    double? refundAmount,
    String? adminNotes,
  }) async {
    final t = AppLocalizations.of(context);
    try {
      final response = await ApiService.resolveDispute(
        disputeId: disputeId,
        resolution: resolution,
        refundAmount: refundAmount,
        adminNotes: adminNotes,
      );

      if (response['success'] == true) {
        Fluttertoast.showToast(msg: t?.disputeResolvedSuccess ?? 'Dispute resolved successfully');
        _loadDisputes();
      } else {
        Fluttertoast.showToast(
          msg: response['message'] ?? t?.failedToResolveDispute ?? 'Failed to resolve dispute',
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '${t?.error}: $e');
    }
  }

  Future<void> _rejectDispute(int disputeId, String adminNotes) async {
    final t = AppLocalizations.of(context);
    try {
      final response = await ApiService.rejectDispute(
        disputeId: disputeId,
        adminNotes: adminNotes,
      );

      if (response['success'] == true) {
        Fluttertoast.showToast(msg: t?.disputeRejectedSuccess ?? 'Dispute rejected successfully');
        _loadDisputes();
      } else {
        Fluttertoast.showToast(
          msg: response['message'] ?? t?.failedToRejectDispute ?? 'Failed to reject dispute',
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '${t?.error}: $e');
    }
  }

  void _showResolveDialog(Dispute dispute) {
    final t = AppLocalizations.of(context)!;
    String resolution = 'no_refund';
    double? refundAmount;
    final TextEditingController notesController = TextEditingController();
    final TextEditingController refundController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            t.resolveDispute,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(t.contract, dispute.contract?.project?.title ?? t.notSpecified),
                const SizedBox(height: 8),
                _buildInfoRow(t.initiatedBy, '${dispute.initiatedBy} (${_getUserName(dispute, t)})'),
                const SizedBox(height: 8),
                _buildInfoRow(t.disputeTitle, dispute.title),
                const SizedBox(height: 16),
                Text(
                  t.resolution,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: resolution,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(value: 'full_refund', child: Text(t.fullRefundToClient)),
                    DropdownMenuItem(value: 'partial_refund', child: Text(t.partialRefundToClient)),
                    DropdownMenuItem(value: 'no_refund', child: Text(t.noRefund)),
                  ],
                  onChanged: (value) => setState(() => resolution = value!),
                ),
                if (resolution == 'partial_refund') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: refundController,
                    decoration: InputDecoration(
                      labelText: t.refundAmount,
                      prefixText: '\$',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => refundAmount = double.tryParse(value),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: t.adminNotesOptional,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resolveDispute(
                  dispute.id!,
                  resolution,
                  refundAmount: refundAmount,
                  adminNotes: notesController.text.trim().isNotEmpty
                      ? notesController.text.trim()
                      : null,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(t.resolve),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(Dispute dispute) {
    final t = AppLocalizations.of(context)!;
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          t.rejectDispute,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.rejectDisputeConfirmation),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: t.rejectionReason,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _rejectDispute(dispute.id!, notesController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(t.reject),
          ),
        ],
      ),
    );
  }

 String _getUserName(Dispute dispute, AppLocalizations t) {
    if (dispute.initiatedBy == 'client') {
      return dispute.client?.name ?? t.notSpecified;
    } else {
      return dispute.freelancer?.name ?? t.notSpecified;
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status, AppLocalizations t, bool isDark) {
    Color color;
    String text;

    switch (status) {
      case 'open':
        color = Colors.orange;
        text = t.disputeStatusOpen;
        break;
      case 'resolved':
        color = Colors.green;
        text = t.disputeStatusResolved;
        break;
      case 'rejected':
        color = Colors.red;
        text = t.disputeStatusRejected;
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDisputeCard(Dispute dispute, AppLocalizations t, bool isDark) {
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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
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
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: isDark ? Colors.white : const Color(0xFF1A1B3E),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(dispute.status, t, isDark),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${t.contract}: ${dispute.contract?.project?.title ?? t.notSpecified}',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${t.initiatedBy}: ${dispute.initiatedBy} (${_getUserName(dispute,t)})',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dispute.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(dispute.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (dispute.status == 'open')
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showResolveDialog(dispute),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(t.resolve),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showRejectDialog(dispute),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(t.reject),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showDisputeDetails(dispute, t, isDark),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(t.viewDetails),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showDisputeDetails(Dispute dispute, AppLocalizations t, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
        title: Text(
          dispute.title,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1A1B3E),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(t.status, dispute.status, isDark),
              const SizedBox(height: 8),
              _buildDetailRow(t.contract, dispute.contract?.project?.title ?? t.notSpecified, isDark),
              const SizedBox(height: 8),
              _buildDetailRow(t.initiatedBy, dispute.initiatedBy, isDark),
              const SizedBox(height: 12),
              Text(
                '${t.description}:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1A1B3E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dispute.description,
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                ),
              ),
              if (dispute.evidenceFiles.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '${t.evidenceFiles}:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A1B3E),
                  ),
                ),
                ...dispute.evidenceFiles.map((file) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Text('• $file', style: TextStyle(fontSize: 12)),
                )),
              ],
              if (dispute.resolution != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(t.resolution, dispute.resolution!, isDark),
                if (dispute.refundAmount != null)
                  _buildDetailRow(t.refundAmount, '\$${dispute.refundAmount}', isDark),
                if (dispute.adminNotes != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${t.adminNotes}:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1A1B3E),
                    ),
                  ),
                  Text(
                    dispute.adminNotes!,
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.close),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1A1B3E),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.AppColors.darkBackground : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          t.disputesManagement,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildHeader(t, isDark),
          _buildStatsBar(t, isDark),
          Expanded(
            child: loading && disputes.isEmpty
                ? Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  )
                : disputes.isEmpty
                    ? _buildEmptyState(t, isDark)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: disputes.length,
                        itemBuilder: (_, i) => _buildDisputeCard(disputes[i], t, isDark),
                      ),
          ),
          if (totalPages > 1) _buildPagination(t, isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations t, bool isDark) {
    return Container(
      color: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.disputes,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1B3E),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.AppColors.darkCard : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Text(
                  '${t.status}:',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: selectedStatus,
                  underline: const SizedBox(),
                  dropdownColor: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  items: [
                    DropdownMenuItem(value: 'all', child: Text(t.allDisputes)),
                    DropdownMenuItem(value: 'open', child: Text(t.disputeStatusOpen)),
                    DropdownMenuItem(value: 'resolved', child: Text(t.disputeStatusResolved)),
                    DropdownMenuItem(value: 'rejected', child: Text(t.disputeStatusRejected)),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedStatus = value);
                      currentPage = 1;
                      _loadDisputes();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(AppLocalizations t, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: isDark ? AppTheme.AppColors.darkCard : const Color(0xFFF8F9FA),
      child: Row(
        children: [
          Text(
            '${disputes.length} ${t.disputes}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1A1B3E),
            ),
          ),
          if (loading) ...[
            const SizedBox(width: 12),
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations t, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.AppColors.darkCard : const Color(0xFFF8F9FA),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.gavel,
              size: 40,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t.noDisputesFound,
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

  Widget _buildPagination(AppLocalizations t, bool isDark) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: currentPage > 1
                ? () {
                    setState(() => currentPage--);
                    _loadDisputes();
                  }
                : null,
            icon: Icon(
              Icons.chevron_left,
              color: currentPage > 1
                  ? theme.colorScheme.primary
                  : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.AppColors.darkCard : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${t.page} $currentPage ${t.ofWord} $totalPages',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1A1B3E),
              ),
            ),
          ),
          IconButton(
            onPressed: currentPage < totalPages
                ? () {
                    setState(() => currentPage++);
                    _loadDisputes();
                  }
                : null,
            icon: Icon(
              Icons.chevron_right,
              color: currentPage < totalPages
                  ? theme.colorScheme.primary
                  : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
            ),
          ),
        ],
      ),
    );
  }
}