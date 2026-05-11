// screens/admin/projects_management_screen.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart' as AppTheme;

class ProjectsManagementScreen extends StatefulWidget {
  const ProjectsManagementScreen({super.key});

  @override
  State<ProjectsManagementScreen> createState() =>
      _ProjectsManagementScreenState();
}

class _ProjectsManagementScreenState extends State<ProjectsManagementScreen> {
  List<Map<String, dynamic>> _projects = [];
  bool _loading = true;
  String _status = 'all';
  String _search = '';
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService.getAdminProjects(
        status: _status,
        search: _search,
        page: _currentPage,
      );
      if (!mounted) return;
      setState(() {
        _projects = List<Map<String, dynamic>>.from(
          response['projects'] as List? ?? [],
        );
        _totalPages = response['totalPages'] ?? 1;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      final t = AppLocalizations.of(context);
      Fluttertoast.showToast(msg: t?.failedToLoadProjects ?? 'Failed to load projects');
    }
  }

  Future<void> _deleteProject(int projectId) async {
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          t?.deleteProject ?? 'Delete Project',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          t?.deleteProjectConfirmation ?? 'This action cannot be undone. Are you sure you want to delete this project?',
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(t?.delete ?? 'Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final res = await ApiService.deleteAdminProject(projectId);
    if (res['success'] == true) {
      Fluttertoast.showToast(msg: t?.projectDeleted ?? 'Project deleted');
      _loadProjects();
    } else {
      Fluttertoast.showToast(
        msg: res['message']?.toString() ?? t?.deleteFailed ?? 'Delete failed',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.AppColors.darkBackground : const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: Text(
          t.projectsManagement,
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
            child: _loading && _projects.isEmpty
                ? Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  )
                : _projects.isEmpty
                    ? _buildEmpty(t, isDark)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _projects.length,
                        itemBuilder: (_, i) => _buildProjectCard(_projects[i], t, isDark),
                      ),
          ),
          if (_totalPages > 1) _buildPagination(t, isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations t, bool isDark) {
    return Container(
      color: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.AppColors.darkCard : const Color(0xFFF0F2F8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade200,
                ),
              ),
              child: TextField(
                style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.AppColors.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: t.searchProjects,
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade500 : const Color(0xFFAAAAAA),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 18,
                    color: isDark ? Colors.grey.shade500 : const Color(0xFFAAAAAA),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (v) {
                  _search = v;
                  _currentPage = 1;
                  _loadProjects();
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildStatusDropdown(t, isDark),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown(AppLocalizations t, bool isDark) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.15)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _status,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: theme.colorScheme.primary,
            size: 18,
          ),
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          dropdownColor: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
          items: [
            DropdownMenuItem(value: 'all', child: Text(t.allStatus)),
            DropdownMenuItem(value: 'open', child: Text(t.open)),
            DropdownMenuItem(value: 'in_progress', child: Text(t.inProgress)),
            DropdownMenuItem(value: 'completed', child: Text(t.completed)),
            DropdownMenuItem(value: 'cancelled', child: Text(t.cancelled)),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() {
              _status = v;
              _currentPage = 1;
            });
            _loadProjects();
          },
        ),
      ),
    );
  }

  Widget _buildStatsBar(AppLocalizations t, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: isDark ? AppTheme.AppColors.darkCard : const Color(0xFFF0F2F8),
      child: Row(
        children: [
          Text(
            '${_projects.length} ${t.projects}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1A1B3E),
            ),
          ),
          if (_loading) ...[
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

  Widget _buildProjectCard(Map<String, dynamic> p, AppLocalizations t, bool isDark) {
    final theme = Theme.of(context);
    final client = Map<String, dynamic>.from(p['client'] ?? {});
    final status = p['status']?.toString() ?? 'open';
    final colors = _getStatusColors(status);
    final label = _getStatusLabel(status, t);
    final budget = p['budget'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.folder_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p['title']?.toString() ?? t.untitledProject,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isDark ? Colors.white : const Color(0xFF1A1B3E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _statusChip(label, colors, isDark),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 13,
                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        client['name']?.toString() ?? t.notAvailable,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.attach_money,
                        size: 13,
                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        budget.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.AppColors.darkSurface : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade200,
                  ),
                ),
                child: Icon(
                  Icons.more_vert,
                  size: 16,
                  color: isDark ? Colors.grey.shade400 : const Color(0xFF888888),
                ),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
              onSelected: (value) {
                if (value == 'delete') {
                  final id = p['id'] as int?;
                  if (id != null) _deleteProject(id);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        color: Colors.red.shade400,
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        t.delete,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red.shade400,
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
    );
  }

  List<Color> _getStatusColors(String status) {
    switch (status) {
      case 'open':
        return [const Color(0xFF14A800), const Color(0xFF0A6E00)];
      case 'in_progress':
        return [const Color(0xFF0EA5E9), const Color(0xFF0369A1)];
      case 'completed':
        return [const Color(0xFF10B981), const Color(0xFF047857)];
      case 'cancelled':
        return [const Color(0xFFEF4444), const Color(0xFFB91C1C)];
      default:
        return [Colors.grey, Colors.grey.shade700];
    }
  }

  String _getStatusLabel(String status, AppLocalizations t) {
    switch (status) {
      case 'open':
        return t.open;
      case 'in_progress':
        return t.inProgress;
      case 'completed':
        return t.completed;
      case 'cancelled':
        return t.cancelled;
      default:
        return status;
    }
  }

  Widget _statusChip(String label, List<Color> colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors.map((c) => c.withOpacity(0.12)).toList(),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.first.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: colors.first,
        ),
      ),
    );
  }

  Widget _buildEmpty(AppLocalizations t, bool isDark) {
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
              Icons.work_outline,
              size: 40,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t.noProjectsFound,
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
          _pageBtn(
            Icons.chevron_left,
            _currentPage > 1
                ? () {
                    setState(() => _currentPage--);
                    _loadProjects();
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
                    _loadProjects();
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
}