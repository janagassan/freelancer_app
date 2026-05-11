// screens/admin/contracts_management_screen.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart' as AppTheme;

class ContractsManagementScreen extends StatefulWidget {
  const ContractsManagementScreen({super.key});

  @override
  State<ContractsManagementScreen> createState() =>
      _ContractsManagementScreenState();
}

class _ContractsManagementScreenState extends State<ContractsManagementScreen> {
  List<Map<String, dynamic>> _contracts = [];
  bool _loading = true;
  String _status = 'all';
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadContracts();
  }

  Future<void> _loadContracts() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService.getAdminContracts(
        status: _status,
        page: _currentPage,
      );
      if (!mounted) return;
      setState(() {
        _contracts = List<Map<String, dynamic>>.from(
          response['contracts'] as List? ?? [],
        );
        _totalPages = response['totalPages'] ?? 1;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      final t = AppLocalizations.of(context);
      Fluttertoast.showToast(msg: t?.failedToLoadContracts ?? 'Failed to load contracts');
    }
  }

  Future<void> _resolveDispute(int contractId) async {
    final t = AppLocalizations.of(context)!;
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.gavel_rounded,
                color: Colors.red.shade600,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              t.resolveDispute,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.resolutionNotes,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: t.resolutionHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(t.resolve),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final res = await ApiService.resolveAdminDispute(
      contractId: contractId,
      resolution: ctrl.text.trim(),
    );
    if (res['success'] == true) {
      Fluttertoast.showToast(msg: t.disputeResolved);
      _loadContracts();
    } else {
      Fluttertoast.showToast(
        msg: res['message']?.toString() ?? t.actionFailed,
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
          t.contractsManagement,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterBar(t, isDark),
          _buildStatsBar(t, isDark),
          Expanded(
            child: _loading && _contracts.isEmpty
                ? Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  )
                : _contracts.isEmpty
                    ? _buildEmpty(t, isDark)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _contracts.length,
                        itemBuilder: (_, i) => _buildContractCard(_contracts[i], t, isDark),
                      ),
          ),
          if (_totalPages > 1) _buildPagination(t, isDark),
        ],
      ),
    );
  }

  Widget _buildFilterBar(AppLocalizations t, bool isDark) {
    final statuses = [
      'all', 'draft', 'pending_client', 'pending_freelancer',
      'active', 'completed', 'disputed', 'cancelled'
    ];

    return Container(
      color: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Text(
            '${t.filterByStatus}:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1A1B3E),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: statuses.map((s) => _filterChip(
                  s == 'all' ? t.all : _getStatusLabel(s, t),
                  s,
                  isDark,
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(String status, AppLocalizations t) {
    switch (status) {
      case 'draft': return t.draft;
      case 'pending_client': return t.pendingClient;
      case 'pending_freelancer': return t.pendingFreelancer;
      case 'active': return t.active;
      case 'completed': return t.completed;
      case 'disputed': return t.disputed;
      case 'cancelled': return t.cancelled;
      default: return status;
    }
  }

  Widget _filterChip(String label, String value, bool isDark) {
    final selected = _status == value;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        setState(() {
          _status = value;
          _currentPage = 1;
        });
        _loadContracts();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [theme.colorScheme.primary.withOpacity(0.7), theme.colorScheme.primary],
                )
              : null,
          color: selected ? null : (isDark ? AppTheme.AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : (isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade200),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
          ),
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
            '${_contracts.length} ${t.contracts}',
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

  Widget _buildContractCard(Map<String, dynamic> c, AppLocalizations t, bool isDark) {
    final theme = Theme.of(context);
    final project = Map<String, dynamic>.from(c['project'] ?? {});
    final client = Map<String, dynamic>.from(c['client'] ?? {});
    final freelancer = Map<String, dynamic>.from(c['freelancer'] ?? {});
    final status = c['status']?.toString() ?? 'draft';
    final id = c['id'] as int?;
    final amount = c['agreed_amount'] ?? 0;
    final isDisputed = status == 'disputed';

    final statusConfig = _getStatusConfig(status, theme);
    final color = statusConfig['color'] as Color;
    final bgColor = statusConfig['bg'] as Color;
    final icon = statusConfig['icon'] as IconData;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDisputed
              ? Colors.red.withOpacity(0.2)
              : (isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade100),
          width: isDisputed ? 1.5 : 1,
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
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
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
                          project['title']?.toString() ?? '${t.contract} #${c['id']}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isDark ? Colors.white : const Color(0xFF1A1B3E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _statusBadge(_getStatusLabel(status, t), color, bgColor, isDark),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 12, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                      const SizedBox(width: 3),
                      Text(
                        client['name'] ?? t.notSpecified,
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      ),
                      Text(' → ', style: TextStyle(color: isDark ? Colors.grey.shade600 : Colors.grey.shade400, fontSize: 11)),
                      Icon(Icons.work_outline, size: 12, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                      const SizedBox(width: 3),
                      Text(
                        freelancer['name'] ?? t.notSpecified,
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14A800).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '\$$amount',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF14A800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isDisputed && id != null) ...[
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _resolveDispute(id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade400, Colors.red.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.gavel_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        t.resolve,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusConfig(String status, ThemeData theme) {
    switch (status) {
      case 'draft':
        return {
          'color': Colors.grey,
          'bg': Colors.grey.shade100,
          'icon': Icons.edit_note_rounded,
        };
      case 'pending_client':
        return {
          'color': const Color(0xFFF59E0B),
          'bg': const Color(0xFFFEF3C7),
          'icon': Icons.pending_rounded,
        };
      case 'pending_freelancer':
        return {
          'color': const Color(0xFFF97316),
          'bg': const Color(0xFFFED7AA),
          'icon': Icons.schedule_rounded,
        };
      case 'active':
        return {
          'color': const Color(0xFF0EA5E9),
          'bg': const Color(0xFFE0F2FE),
          'icon': Icons.play_circle_rounded,
        };
      case 'completed':
        return {
          'color': const Color(0xFF14A800),
          'bg': const Color(0xFFDCFCE7),
          'icon': Icons.check_circle_rounded,
        };
      case 'cancelled':
        return {
          'color': const Color(0xFFEF4444),
          'bg': const Color(0xFFFEE2E2),
          'icon': Icons.cancel_rounded,
        };
      case 'disputed':
        return {
          'color': const Color(0xFFDC2626),
          'bg': const Color(0xFFFEE2E2),
          'icon': Icons.warning_rounded,
        };
      default:
        return {
          'color': Colors.grey,
          'bg': Colors.grey.shade100,
          'icon': Icons.help_outline,
        };
    }
  }

  Widget _statusBadge(String label, Color color, Color bg, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
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
              Icons.description_outlined,
              size: 40,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t.noContractsFound,
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
                    _loadContracts();
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
                    _loadContracts();
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