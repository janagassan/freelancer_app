// screens/contract/work_submissions_screen.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../l10n/app_localizations.dart';
import '../../models/work_submission_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../freelancer/work_submission_detail_screen.dart';

class WorkSubmissionsScreen extends StatefulWidget {
  final int contractId;
  final String userRole;

  const WorkSubmissionsScreen({
    super.key,
    required this.contractId,
    required this.userRole,
  });

  @override
  State<WorkSubmissionsScreen> createState() => _WorkSubmissionsScreenState();
}

class _WorkSubmissionsScreenState extends State<WorkSubmissionsScreen> {
  List<WorkSubmission> _submissions = [];
  bool _loading = true;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _fetchSubmissions();
  }

  Future<void> _fetchSubmissions() async {
    if (!mounted) return;
    
    setState(() {
      _loading = true;
      _refreshing = false;
    });

    try {
      final submissions = await ApiService.getContractSubmissions(widget.contractId);
      
      if (mounted) {
        setState(() {
          _submissions = submissions;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        Fluttertoast.showToast(msg: 'Error loading submissions: $e');
      }
    }
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    await _fetchSubmissions();
    if (mounted) {
      setState(() => _refreshing = false);
    }
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

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'pending':
        return Icons.hourglass_empty;
      case 'revision_requested':
        return Icons.edit;
      default:
        return Icons.info;
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
        title: Text(
          t.workSubmissions,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
          ),
        ),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
            onPressed: _refresh,
            tooltip: t.refresh,
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : _submissions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.gray.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.folder_open,
                          size: 40,
                          color: AppColors.gray,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        t.noSubmissionsYet,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.userRole == 'client'
                            ? t.waitingForFreelancerToSubmit
                            : t.youHaventSubmittedAnyWorkYet,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.gray,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  color: theme.colorScheme.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _submissions.length,
                    itemBuilder: (context, index) {
                      final submission = _submissions[index];
                      return _buildSubmissionCard(submission, theme, isDark, t);
                    },
                  ),
                ),
    );
  }

  Widget _buildSubmissionCard(
    WorkSubmission submission,
    ThemeData theme,
    bool isDark,
    AppLocalizations t,
  ) {
    final status = submission.status ?? 'pending';
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status, t);
    final statusIcon = _getStatusIcon(status);
    
    final files = submission.files ?? [];
    final links = submission.links ?? [];
    final hasAttachments = files.isNotEmpty || links.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkSubmissionDetailScreen(
                submission: submission.toJson(),
                userRole: widget.userRole,
                contractId: widget.contractId,
                onStatusChanged: () => _refresh(),
              ),
            ),
          );
        },
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
                      submission.title ?? t.untitledSubmission,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              if (submission.description != null &&
                  submission.description!.isNotEmpty)
                Text(
                  submission.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              
              if (submission.description != null &&
                  submission.description!.isNotEmpty)
                const SizedBox(height: 12),
              
              if (hasAttachments)
                Row(
                  children: [
                    Icon(
                      Icons.attach_file,
                      size: 14,
                      color: AppColors.gray,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${files.length + links.length} ${t.attachments}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.gray,
                      ),
                    ),
                  ],
                ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 12,
                    color: AppColors.gray,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${t.submittedOn}: ${_formatDate(submission.submittedAt?.toIso8601String())}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.gray,
                    ),
                  ),
                ],
              ),
              
              if (status == 'revision_requested' &&
                  submission.revisionRequestMessage != null &&
                  submission.revisionRequestMessage!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.danger.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.edit_note,
                          size: 14,
                          color: AppColors.danger,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            submission.revisionRequestMessage!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}