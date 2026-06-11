import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class HireFreelancerDialog extends StatefulWidget {
  final int freelancerId;
  final String freelancerName;
  final int? preselectedProjectId;
  final VoidCallback? onSuccess;

  const HireFreelancerDialog({
    super.key,
    required this.freelancerId,
    required this.freelancerName,
    this.preselectedProjectId,
    this.onSuccess,
  });

  @override
  State<HireFreelancerDialog> createState() => _HireFreelancerDialogState();
}

class _HireFreelancerDialogState extends State<HireFreelancerDialog> {
  List<Map<String, dynamic>> _projects = [];
  int? _selectedProjectId;
  double? _offerAmount;
  String _message = '';
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _loading = true);
    try {
      final result = await ApiService.getOpenProjectsForHiring(
        currentProjectId: widget.preselectedProjectId,
      );

      debugPrint('📦 Projects API response: $result');
      debugPrint('🎯 Preselected project ID: ${widget.preselectedProjectId}');

      if (result['success'] == true) {
        setState(() {
          List<Map<String, dynamic>> allProjects =
              List<Map<String, dynamic>>.from(result['projects'] ?? []);

          final openProjects = allProjects
              .where((p) => p['status'] == 'open')
              .toList();

          if (widget.preselectedProjectId != null) {
            final preselectedProject = allProjects.firstWhere(
              (p) => p['id'] == widget.preselectedProjectId,
              orElse: () => <String, dynamic>{},
            );

            if (preselectedProject.isNotEmpty &&
                preselectedProject['status'] != 'open') {
              preselectedProject['is_not_open'] = true;
              openProjects.insert(0, preselectedProject);
              debugPrint(
                '⚠️ Preselected project ${widget.preselectedProjectId} is not open (status: ${preselectedProject['status']})',
              );
            }
          }

          _projects = openProjects;

          debugPrint('📋 Loaded projects count: ${_projects.length}');
          debugPrint(
            '📋 Project IDs: ${_projects.map((p) => p['id']).toList()}',
          );

          if (widget.preselectedProjectId != null) {
            final exists = _projects.any(
              (p) => p['id'] == widget.preselectedProjectId,
            );
            if (exists) {
              _selectedProjectId = widget.preselectedProjectId;
              debugPrint('✅ Selected project: $_selectedProjectId');
            } else if (_projects.isNotEmpty) {
              _selectedProjectId = _projects.first['id'];
              debugPrint('🔄 Fallback to first project: $_selectedProjectId');
            }
          } else if (_projects.isNotEmpty && _selectedProjectId == null) {
            _selectedProjectId = _projects.first['id'];
            debugPrint('🔄 Default to first project: $_selectedProjectId');
          }

          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('❌ Error loading projects: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendOffer() async {
    if (_selectedProjectId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a project')));
      return;
    }

    final selectedProject = _projects.firstWhere(
      (p) => p['id'] == _selectedProjectId,
      orElse: () => <String, dynamic>{},
    );

    if (selectedProject.isNotEmpty && selectedProject['status'] != 'open') {
      final t = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ ${t.cannotSendOffer}: "${selectedProject['title']}" ${t.projectNotOpenForOffers}',
          ),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      final result = await ApiService.sendOfferToFreelancer(
        freelancerId: widget.freelancerId,
        projectId: _selectedProjectId!,
        amount: _offerAmount,
        message: _message.isEmpty ? null : _message,
      );

      if (result['success'] == true) {
        if (mounted) {
          Navigator.pop(context);
          widget.onSuccess?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ??
                    AppLocalizations.of(context)!.offerSentSuccessfully,
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        final errorMsg = result['message'] ?? 'Failed to send offer';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMsg'),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${AppLocalizations.of(context)!.error}: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _createNewProject() {
    Navigator.pop(context);
    Navigator.pushNamed(context, '/client/create-project');
  }

  bool _isDarkMode() {
    return Theme.of(context).brightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = _isDarkMode();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxWidth: 450,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      t.sendOfferTo,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.gray,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.freelancerName,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.selectProject,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.gray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _projects.isEmpty
                        ? _buildEmptyProjects(t, isDark)
                        : DropdownButtonFormField<int>(
                            value: _selectedProjectId,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? AppColors.primaryDark
                                      : AppColors.border,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: _projects.map((project) {
                              final isNotOpen = project['is_not_open'] == true;
                              final status = project['status'] ?? 'open';

                              return DropdownMenuItem<int>(
                                value: project['id'],
                                child: Container(
                                  constraints: const BoxConstraints(
                                    maxWidth: 300,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            if (isNotOpen)
                                              Icon(
                                                Icons.warning_amber,
                                                size: 16,
                                                color: AppColors.warning,
                                              ),
                                            if (isNotOpen)
                                              const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                project['title'] ?? 'Untitled',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  color: isNotOpen
                                                      ? AppColors.warning
                                                      : (isDark
                                                            ? AppColors
                                                                  .darkTextPrimary
                                                            : AppColors
                                                                  .lightTextPrimary),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (!isNotOpen)
                                        Text(
                                          '\$${project['budget']}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.accent,
                                          ),
                                        ),
                                      if (isNotOpen)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.warning
                                                .withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            status,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: AppColors.warning,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) =>
                                setState(() => _selectedProjectId = value),
                          ),

                    if (_selectedProjectId != null)
                      Builder(
                        builder: (context) {
                          final selectedProject = _projects.firstWhere(
                            (p) => p['id'] == _selectedProjectId,
                            orElse: () => <String, dynamic>{},
                          );
                          if (selectedProject.isNotEmpty &&
                              selectedProject['status'] != 'open') {
                            return Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.warning.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning,
                                      color: AppColors.warning,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '⚠️ ${t.projectNotOpenForOffers}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.warning,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                    const SizedBox(height: 16),

                    Text(
                      t.offerAmountOptional,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.gray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      onChanged: (value) =>
                          _offerAmount = double.tryParse(value),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: t.enterAmount,
                        prefixText: '\$ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppColors.primaryDark
                                : AppColors.border,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        isDense: true,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      t.messageOptional,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.gray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      onChanged: (value) => _message = value,
                      maxLines: 2,
                      minLines: 2,
                      decoration: InputDecoration(
                        hintText: t.writeMessageHere,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppColors.primaryDark
                                : AppColors.border,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.gray,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(t.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedProjectId == null || _sending
                          ? null
                          : _sendOffer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.primaryDark,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(t.sendOffer),
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

  Widget _buildEmptyProjects(t, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightBackground,
        border: Border.all(color: AppColors.warning),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.warning_amber, color: AppColors.warning, size: 32),
          const SizedBox(height: 8),
          Text(
            t.noOpenProjects,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t.createProjectFirst,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.darkTextSecondary : AppColors.gray,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _createNewProject,
            icon: const Icon(Icons.add, size: 16),
            label: Text(t.createProject, style: const TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.primaryDark,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
