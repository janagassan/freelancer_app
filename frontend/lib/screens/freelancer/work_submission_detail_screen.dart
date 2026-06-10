// screens/freelancer/work_submission_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class WorkSubmissionDetailScreen extends StatefulWidget {
  final dynamic submission;
  final String userRole;
  final int contractId;
  final VoidCallback onStatusChanged;

  const WorkSubmissionDetailScreen({
    super.key,
    required this.submission,
    required this.userRole,
    required this.contractId,
    required this.onStatusChanged,
  });

  @override
  State<WorkSubmissionDetailScreen> createState() =>
      _WorkSubmissionDetailScreenState();
}

class _WorkSubmissionDetailScreenState
    extends State<WorkSubmissionDetailScreen> {
  bool _isProcessing = false;
  late Map<String, dynamic> _submission;

  @override
  void initState() {
    super.initState();
    _submission = Map<String, dynamic>.from(widget.submission);
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'revision_requested':
        return AppColors.danger;
      default:
        return AppColors.gray;
    }
  }

  String _getStatusText(String status, AppLocalizations t) {
    switch (status.toLowerCase()) {
      case 'approved':
        return t.approved;
      case 'pending':
        return t.pending;
      case 'revision_requested':
        return t.revisionRequested;
      default:
        return status;
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Fluttertoast.showToast(msg: 'Cannot open URL');
    }
  }

  Future<void> _approveWork() async {
    final t = AppLocalizations.of(context)!;
    
    setState(() => _isProcessing = true);
    
    try {
      final response = await ApiService.approveWork(_submission['id']);
      
      if (response['success'] == true) {
        Fluttertoast.showToast(msg: t.workApprovedSuccess);
        widget.onStatusChanged();
        Navigator.pop(context);
      } else {
        Fluttertoast.showToast(msg: response['message'] ?? t.errorApprovingWork);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '${t.error}: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _requestRevision() async {
    final t = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          t.requestChanges,
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.explainWhatNeedsToBeChanged,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: t.describeChangesNeeded,
                hintStyle: TextStyle(color: AppColors.gray),
                border: const OutlineInputBorder(),
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
        final response = await ApiService.requestRevision(
          submissionId: _submission['id'],
          revisionMessage: controller.text,
        );
        
        if (response['success'] == true) {
          Fluttertoast.showToast(msg: t.revisionRequestSent);
          widget.onStatusChanged();
          Navigator.pop(context);
        } else {
          Fluttertoast.showToast(msg: response['message'] ?? t.errorSendingRevision);
        }
      } catch (e) {
        Fluttertoast.showToast(msg: '${t.error}: $e');
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final status = _submission['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status, t);
    final files = _submission['files'] ?? [];
    final links = _submission['links'] ?? [];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _submission['title'] ?? t.submissionDetails,
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor),
              ),
              child: Row(
                children: [
                  Icon(
                    status == 'approved'
                        ? Icons.check_circle
                        : status == 'revision_requested'
                        ? Icons.edit
                        : Icons.hourglass_empty,
                    color: statusColor,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        Text(
                          '${t.submittedOn}: ${_formatDate(_submission['submitted_at'])}',
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (_submission['description'] != null &&
                _submission['description'].toString().isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.description,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _submission['description'],
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 20),

            if (files.isNotEmpty) ...[
              Text(
                t.files,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              ...files.map((fileUrl) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () => _openUrl(fileUrl),
                      child: Row(
                        children: [
                          Icon(
                            Icons.insert_drive_file,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              fileUrl.split('/').last,
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.open_in_new,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(height: 16),
            ],

            if (links.isNotEmpty) ...[
              Text(
                t.links,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              ...links.map((link) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () => _openUrl(link),
                      child: Row(
                        children: [
                          Icon(
                            Icons.link,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              link,
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.open_in_new,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(height: 16),
            ],

            if (status == 'revision_requested' &&
                _submission['revision_request_message'] != null &&
                _submission['revision_request_message'].toString().isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.revisionFeedback,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.danger,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                    ),
                    child: Text(
                      _submission['revision_request_message'],
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            if (widget.userRole == 'client' && status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _approveWork,
                      icon: const Icon(Icons.check_circle, size: 20),
                      label: Text(t.approveWork),  
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _requestRevision,
                      icon: const Icon(Icons.edit, size: 20),
                      label: Text(t.requestChanges),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            if (widget.userRole == 'freelancer' && status == 'revision_requested')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () {
                          Navigator.pop(context);
                        },
                  icon: const Icon(Icons.edit, size: 20),
                  label: Text(t.resubmitWork),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}