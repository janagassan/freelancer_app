// screens/freelancer/project_details_screen.dart

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/usage_limits_model.dart';
import '../../models/project_model.dart';
import '../../services/api_service.dart';
import 'submit_proposal_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../theme/app_theme.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final int projectId;
  const ProjectDetailsScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  Project? project;
  bool loading = true;
  bool hasSubmitted = false;
  int? _contractId;
  bool _loadingContract = false;

  bool loadingPricing = false;
  Map<String, dynamic>? smartPricing;
  bool showSmartPricing = false;
  UsageLimits? _usage;
  bool _isFavorite = false;

  Future<void> _toggleFavorite() async {
    final t = AppLocalizations.of(context)!;
    try {
      if (_isFavorite) {
        await ApiService.removeFromFavorites(widget.projectId);
        setState(() => _isFavorite = false);
        Fluttertoast.showToast(msg: t.removedFromFavorites);
      } else {
        await ApiService.addToFavorites(widget.projectId);
        setState(() => _isFavorite = true);
        Fluttertoast.showToast(msg: t.addedToFavorites);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '${t.error}: $e');
    }
  }

  Future<void> _checkIfFavorite() async {
    try {
      final isFav = await ApiService.isProjectFavorite(widget.projectId);
      setState(() => _isFavorite = isFav);
    } catch (e) {
      print('Error checking favorite: $e');
    }
  }

  Future<void> _loadUsage() async {
    final response = await ApiService.getUserUsage();
    if (response['success'] && response['usage'] != null) {
      setState(() {
        _usage = UsageLimits.fromJson(response['usage']);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchProjectDetails();
    checkExistingProposal();
    _loadSmartPricing();
    _loadUsage();
    _checkIfFavorite();
    _loadContractLink();
  }

  Future<void> _loadContractLink() async {
    setState(() => _loadingContract = true);
    try {
      final r = await ApiService.getFreelancerProjectContract(widget.projectId);
      if (!mounted) return;
      final c = r['contract'];
      final id = (c is Map) ? c['id'] : null;
      final parsed = id is int ? id : int.tryParse(id?.toString() ?? '');
      setState(() {
        _contractId = (parsed != null && parsed > 0) ? parsed : null;
        _loadingContract = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingContract = false);
    }
  }

  Future<void> _loadSmartPricing() async {
    if (widget.projectId == null) return;

    setState(() => loadingPricing = true);

    try {
      final response = await ApiService.getSmartPricing(widget.projectId);

      if (response['success'] == true && response['pricing'] != null) {
        setState(() {
          smartPricing = response['pricing'];
          showSmartPricing = true;
          loadingPricing = false;
        });
      } else {
        setState(() => loadingPricing = false);
      }
    } catch (e) {
      setState(() => loadingPricing = false);
    }
  }

  Future<void> fetchProjectDetails() async {
    if (!mounted) return;

    try {
      final data = await ApiService.getProjectById(widget.projectId);

      if (!mounted) return;

      setState(() {
        final rawProject = data['project'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(data['project'] as Map)
            : Map<String, dynamic>.from(data);
        project = Project.fromJson(rawProject);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      final t = AppLocalizations.of(context)!;
      Fluttertoast.showToast(msg: t.errorLoadingProjectDetails);
    }
  }

  Future<void> checkExistingProposal() async {
    if (!mounted) return;

    try {
      final proposals = await ApiService.getMyProposals();
      if (!mounted) return;

      final existing = proposals.any((p) => p['ProjectId'] == widget.projectId);
      setState(() {
        hasSubmitted = existing;
      });
    } catch (e) {
      print('Error checking proposal: $e');
    }
  }

  String _getAvatarUrl(String? avatar) {
    if (avatar == null || avatar.isEmpty) return '';
    if (avatar.startsWith('http')) return avatar;
    return 'https://freelancer-app-h6os.onrender.com$avatar';
  }

  void _navigateToSubmitProposal() {
    final t = AppLocalizations.of(context)!;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SubmitProposalScreen(project: project!, smartPricing: smartPricing),
      ),
    ).then((submitted) {
      if (submitted == true) {
        setState(() => hasSubmitted = true);
        Fluttertoast.showToast(msg: t.proposalSubmittedSuccess);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasContract = _contractId != null && _contractId! > 0;
    final isOpen = project?.status == 'open';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t.projectDetails),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : theme.iconTheme.color,
            ),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Colors.purple, Colors.blue]),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 18,
                color: Colors.white,
              ),
            ),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/ai-chat',
                arguments: {'projectId': widget.projectId},
              );
            },
            tooltip: t.aiAssistant,
          ),
        ],
      ),
      body: loading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : project == null
          ? Center(
              child: Text(
                t.projectNotFound,
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade700, Colors.blue.shade900],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project!.title ?? t.untitled,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                project!.client?.name ?? t.unknownClient,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.access_time,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(project!.createdAt),
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem(
                            icon: Icons.attach_money,
                            label: t.budget,
                            value: '\$${project!.budget?.toStringAsFixed(0)}',
                            color: AppColors.secondary,
                          ),
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade300,
                        ),
                        Expanded(
                          child: _buildInfoItem(
                            icon: Icons.access_time,
                            label: t.duration,
                            value: '${project!.duration} ${t.days}',
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (showSmartPricing && smartPricing != null)
                    if (isOpen)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    Colors.amber.shade900.withOpacity(0.3),
                                    Colors.orange.shade900.withOpacity(0.3),
                                  ]
                                : [Colors.amber.shade50, Colors.orange.shade50],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.amber.shade800
                                : Colors.amber.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.amber, Colors.orange],
                                    ),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(12),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  t.aiSmartPricingAnalysis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.recommendedPrice,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.6),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "\$${smartPricing!['recommended_price']?.toStringAsFixed(0) ?? '?'}",
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.hourlyRate,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.6),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "\$${smartPricing!['recommended_hourly_rate']?.toStringAsFixed(0) ?? '?'}/hr",
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.estHours,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.6),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${smartPricing!['estimated_hours'] ?? '?'} ${t.hours}",
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.analytics,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "${t.confidence}: ${smartPricing!['confidence_score'] ?? 85}%",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                                const Spacer(),
                                if (smartPricing!['justification'] != null)
                                  Flexible(
                                    child: Text(
                                      smartPricing!['justification'],
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.6),
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (smartPricing!['pricing_breakdown'] != null)
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkSurface
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    _buildBreakdownRow(
                                      t.baseRate,
                                      "\$${smartPricing!['pricing_breakdown']['base_rate']?.toStringAsFixed(0) ?? '?'}/hr",
                                      isDark,
                                    ),
                                    _buildBreakdownRow(
                                      t.complexity,
                                      "+${((smartPricing!['pricing_breakdown']['complexity_multiplier'] ?? 1) - 1) * 100}%",
                                      isDark,
                                    ),
                                    _buildBreakdownRow(
                                      t.experience,
                                      "+${((smartPricing!['pricing_breakdown']['experience_multiplier'] ?? 1) - 1) * 100}%",
                                      isDark,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                  Card(
                    elevation: 0,
                    color: theme.cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.description,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            project!.description ?? t.noDescription,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.6,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (project!.skills != null && project!.skills!.isNotEmpty)
                    Card(
                      elevation: 0,
                      color: theme.cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.requiredSkills,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: project!.skills!.map((skill) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.info.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.info.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    skill,
                                    style: TextStyle(
                                      color: AppColors.info,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 0,
                    color: theme.cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade300,
                            backgroundImage: project!.client?.avatar != null
                                ? NetworkImage(
                                    _getAvatarUrl(project!.client!.avatar),
                                  )
                                : null,
                            child: project!.client?.avatar == null
                                ? Text(
                                    project!.client?.name?[0].toUpperCase() ??
                                        t.client[0],
                                    style: const TextStyle(
                                      fontSize: 24,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.client,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                                Text(
                                  project!.client?.name ?? t.unknown,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  project!.client?.email ?? t.noEmail,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (isOpen &&
                      _usage != null &&
                      _usage!.proposalsLimit != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      t.proposalsRemainingThisMonth(_usage!.remainingProposals),
                      style: TextStyle(
                        color: _usage!.remainingProposals <= 0
                            ? AppColors.danger
                            : AppColors.secondary,
                        fontSize: 12,
                      ),
                    ),
                    if (_usage!.remainingProposals <= 0)
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/subscription/plans'),
                        child: Text(
                          t.upgradeToSendMoreProposals,
                          style: TextStyle(color: theme.colorScheme.primary),
                        ),
                      ),
                  ],
                  if (hasContract)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _loadingContract
                            ? null
                            : () {
                                Navigator.pushNamed(
                                  context,
                                  '/contract',
                                  arguments: {
                                    'contractId': _contractId,
                                    'userRole': 'freelancer',
                                  },
                                );
                              },
                        icon: _loadingContract
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.description_outlined),
                        label: Text(
                          t.openContract,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    )
                  else if (!hasSubmitted && isOpen)
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _navigateToSubmitProposal,
                        icon: const Icon(Icons.send, color: Colors.white),
                        label: Text(
                          t.submitProposal,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    )
                  else if (isOpen && hasSubmitted)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.secondary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: AppColors.secondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              t.alreadySubmittedProposal,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (!isOpen)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.warning.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: AppColors.warning),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              hasContract
                                  ? t.projectStatusWithContract(
                                      project!.statusText ?? '',
                                    )
                                  : t.projectStatus(project!.statusText ?? ''),
                              style: theme.textTheme.bodyMedium,
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

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownRow(String label, String value, bool isDark) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    final t = AppLocalizations.of(context);
    if (date == null) return t?.unknown ?? 'Unknown';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${t?.daysAgo ?? 'd ago'}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${t?.hoursAgo ?? 'h ago'}';
    } else {
      return t?.justNow ?? 'Just now';
    }
  }
}
