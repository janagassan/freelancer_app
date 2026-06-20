import 'package:flutter/material.dart';
import 'package:freelancer_platform/models/project_model.dart';
import 'package:freelancer_platform/models/usage_limits_model.dart';
import 'package:freelancer_platform/models/user_model.dart';
import 'package:freelancer_platform/screens/client/hire_freelancer_dialog.dart';
import 'package:freelancer_platform/screens/client/sow_generator_screen.dart';
import '../../services/api_service.dart';
import '../../models/proposal_model.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../interview/interviews_screen.dart';
import 'compare_freelancers_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class ProjectProposalsScreen extends StatefulWidget {
  final int projectId;
  const ProjectProposalsScreen({super.key, required this.projectId});

  @override
  State<ProjectProposalsScreen> createState() => _ProjectProposalsScreenState();
}

class _ProjectProposalsScreenState extends State<ProjectProposalsScreen> {
  List<Proposal> proposals = [];
  List<Map<String, dynamic>> suggestedFreelancers = [];
  bool loading = true;
  bool loadingSuggestions = true;
  bool _isProcessing = false;
  bool _isGeneratingSOW = false;
  UsageLimits? _usage;

  @override
  void initState() {
    super.initState();
    fetchProposals();
    fetchSuggestedFreelancers();
    _loadUsage();
  }

  bool _isDarkMode() {
    return Theme.of(context).brightness == Brightness.dark;
  }

  Future<void> _loadUsage() async {
    final r = await ApiService.getUserUsage();
    if (!mounted) return;
    if (r['success'] == true && r['usage'] != null) {
      setState(() {
        _usage = UsageLimits.fromJson(Map<String, dynamic>.from(r['usage']));
      });
    }
  }

  bool _consumeInterviewLimit(Map<String, dynamic> result, AppLocalizations t) {
    if (result['error']?.toString() == 'interview_limit') {
      Fluttertoast.showToast(
        msg: result['message']?.toString() ?? t.interviewLimitReached,
        backgroundColor: AppColors.danger,
        timeInSecForIosWeb: 5,
      );
      _loadUsage();
      return true;
    }
    return false;
  }

  Widget _interviewUsageStrip(AppLocalizations t) {
    final u = _usage;
    final isDark = _isDarkMode();
    if (u == null || !u.hasInterviewLimit) return const SizedBox.shrink();
    final rem = u.interviewsRemaining;
    final lim = u.interviewsLimit;
    if (rem == null || lim == null) return const SizedBox.shrink();

    final isLow = rem <= 2;
    final isZero = rem <= 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isLow
            ? (isDark
                  ? AppColors.warningBg.withOpacity(0.2)
                  : AppColors.warningBg)
            : (isDark ? AppColors.darkSurface : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isZero
              ? AppColors.danger.withOpacity(0.3)
              : AppColors.accent.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.interpreter_mode,
            color: isZero ? AppColors.danger : AppColors.accent,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isZero
                  ? t.noInterviewInvitationsLeft(lim)
                  : t.interviewInvitationsLeft(rem, lim),
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: isDark ? AppColors.darkTextSecondary : AppColors.gray,
              ),
            ),
          ),
          if (isLow)
            TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/subscription/plans'),
              child: Text(t.upgrade, style: TextStyle(color: AppColors.accent)),
            ),
        ],
      ),
    );
  }

  Future<void> fetchProposals() async {
    setState(() => loading = true);
    final data = await ApiService.getProjectProposals(widget.projectId);
    setState(() {
      proposals = data.map((json) => Proposal.fromJson(json)).toList();
      loading = false;
    });
  }

  Future<void> fetchSuggestedFreelancers() async {
    setState(() => loadingSuggestions = true);
    final result = await ApiService.getSuggestedFreelancers(widget.projectId);
    setState(() {
      if (result['success'] == true && result['suggestions'] != null) {
        suggestedFreelancers = List<Map<String, dynamic>>.from(
          result['suggestions'],
        );
      }
      loadingSuggestions = false;
    });
  }

  Future<void> handleAcceptProposal(
    Proposal proposal,
    AppLocalizations t,
  ) async {
    setState(() => _isProcessing = true);

    try {
      final result = await ApiService.updateProposalStatus(
        proposalId: proposal.id!,
        status: 'accepted',
      );

      if (result['success'] == true && result['contract'] != null) {
        final contractId = result['contract']['id'];

        final shouldGenerateSOW = await _showSOWDialog(t);

        if (shouldGenerateSOW) {
          await _generateAndSaveSOW(proposal, contractId, t);
        } else {
          Fluttertoast.showToast(msg: t.contractCreatedSuccess);
          _navigateToContract(contractId);
        }
      } else {
        Fluttertoast.showToast(
          msg: result['message'] ?? t.errorAcceptingProposal,
          backgroundColor: AppColors.danger,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: '${t.error}: $e',
        backgroundColor: AppColors.danger,
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<bool> _showSOWDialog(AppLocalizations t) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(t.generateSOW),
              ],
            ),
            content: Text(t.askGenerateSOW),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(t.skip),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                ),
                child: Text(t.generate),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _generateAndSaveSOW(
    Proposal proposal,
    int contractId,
    AppLocalizations t,
  ) async {
    setState(() => _isGeneratingSOW = true);

    try {
      final projectResponse = await ApiService.getProjectById(widget.projectId);
      if (projectResponse['project'] == null)
        throw Exception(t.projectNotFound);

      final projectData = Project.fromJson(projectResponse['project']);

      User? freelancerData = proposal.freelancer;
      if (freelancerData == null && proposal.userId != null) {
        final freelancerResponse = await ApiService.getFreelancerPublicProfile(
          proposal.userId!,
        );
        if (freelancerResponse['user'] != null) {
          freelancerData = User.fromJson(freelancerResponse['user']);
        }
      }
      if (freelancerData == null) throw Exception(t.freelancerNotFound);

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SOWGeneratorScreen(
            project: projectData,
            freelancer: freelancerData!,
            agreedAmount: proposal.price ?? 0,
            contractId: contractId,
            proposalId: proposal.id!,
          ),
        ),
      );

      if (result == true) {
        _navigateToContract(contractId);
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: '${t.error}: $e',
        backgroundColor: AppColors.danger,
      );
    } finally {
      setState(() => _isGeneratingSOW = false);
    }
  }

  void _navigateToContract(int contractId) {
    Navigator.pushNamed(
      context,
      '/contract',
      arguments: {'contractId': contractId, 'userRole': 'client'},
    );
  }

  Future<void> handleRejectProposal(int proposalId, AppLocalizations t) async {
    setState(() => _isProcessing = true);
    try {
      final result = await ApiService.updateProposalStatus(
        proposalId: proposalId,
        status: 'rejected',
      );
      if (result['success'] == true) {
        Fluttertoast.showToast(msg: t.proposalRejected);
        fetchProposals();
        fetchSuggestedFreelancers();
      } else {
        Fluttertoast.showToast(
          msg: result['message'] ?? t.errorRejectingProposal,
          backgroundColor: AppColors.danger,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: '${t.error}: $e',
        backgroundColor: AppColors.danger,
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Color _getMatchColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.info;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = _isDarkMode();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Proposals'),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        foregroundColor: isDark ? AppColors.darkTextPrimary : Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? AppColors.primaryDark : Colors.grey.shade200,
            height: 1,
          ),
        ),
        actions: [
          if (suggestedFreelancers.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.compare_arrows, color: AppColors.accent),
              onSelected: (value) {
                if (value == 'compare') {
                  final freelancerIds = suggestedFreelancers
                      .map((f) => f['id'] as int)
                      .toList();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CompareFreelancersScreen(
                        projectId: widget.projectId,
                        freelancerIds: freelancerIds,
                      ),
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'compare',
                  child: Row(
                    children: [
                      Icon(Icons.compare_arrows, color: AppColors.accent),
                      SizedBox(width: 8),
                      Text('Compare Freelancers'),
                    ],
                  ),
                ),
              ],
            ),
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : Colors.grey.shade600,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _interviewUsageStrip(t)),
                if (!loadingSuggestions)
                  SliverToBoxAdapter(child: _buildAIProjectHint(t, isDark)),
                if (!loadingSuggestions && suggestedFreelancers.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildSuggestedFreelancersSection(t, isDark),
                  ),
                if (!loadingSuggestions && suggestedFreelancers.isEmpty)
                  SliverToBoxAdapter(
                    child: _buildNoAISuggestionsNotice(t, isDark),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          'Proposals',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${proposals.length}',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (proposals.isEmpty)
                  SliverFillRemaining(child: _buildEmptyState(t, isDark))
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: _buildProposalCard(proposals[index], t, isDark),
                      ),
                      childCount: proposals.length,
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildSuggestedFreelancersSection(AppLocalizations t, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: AppColors.accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI Recommended Freelancers',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.dark,
                    ),
                  ),
                ),
                if (suggestedFreelancers.length >= 2)
                  TextButton.icon(
                    onPressed: () {
                      final freelancerIds = suggestedFreelancers
                          .map((f) => f['id'] as int)
                          .toList();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CompareFreelancersScreen(
                            projectId: widget.projectId,
                            freelancerIds: freelancerIds,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.compare_arrows),
                    label: const Text('Compare'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'These AI recommendations are based on this project only.',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: suggestedFreelancers.length,
              itemBuilder: (context, index) {
                final f = suggestedFreelancers[index];
                return _buildSuggestedFreelancerCard(f, t, isDark);
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSuggestedFreelancerCard(
    Map<String, dynamic> f,
    AppLocalizations t,
    bool isDark,
  ) {
    final matchScore = f['matchScore'] ?? 0;
    final matchColor = _getMatchColor(matchScore);
    final freelancerId = f['id'] as int;
    final freelancerName = f['name'] as String? ?? t.freelancer;
    final freelancerAvatar = f['avatar'] as String?;

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: matchColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: matchColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 12, color: matchColor),
                  const SizedBox(width: 4),
                  Text(
                    '${matchScore}% ${t.match}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: matchColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: isDark
                          ? AppColors.primaryDark
                          : Colors.blueGrey.shade100,
                      backgroundImage: freelancerAvatar != null
                          ? NetworkImage(
                              'https://freelancer-app-h6os.onrender.com$freelancerAvatar',
                            )
                          : null,
                      child: freelancerAvatar == null
                          ? Text(
                              freelancerName[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            freelancerName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.dark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (f['title'] != null)
                            Text(
                              f['title'],
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (f['skills'] != null)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: (f['skills'] as List)
                        .take(3)
                        .map(
                          (skill) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              skill,
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                const Spacer(),
                Row(
                  children: [
                    _buildStatChip(
                      icon: Icons.star,
                      value:
                          (f['rating'] as double?)?.toStringAsFixed(1) ?? '0.0',
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 12),
                    _buildStatChip(
                      icon: Icons.work_outline,
                      value: '${f['experience'] ?? 0} ${t.years}',
                      color: Colors.blue,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _showHireDialogFromSuggestion(
                      freelancerId: freelancerId,
                      freelancerName: freelancerName,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.success,
                      side: BorderSide(color: AppColors.success),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(
                      t.hireForProject,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations t, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.inbox,
          size: 80,
          color: isDark ? AppColors.darkTextHint : Colors.grey.shade300,
        ),
        const SizedBox(height: 16),
        Text(
          'No proposals yet',
          style: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'When freelancers submit proposals, they\'ll appear here',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? AppColors.darkTextHint : Colors.grey.shade500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIProjectHint(AppLocalizations t, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: isDark ? AppColors.accent : AppColors.accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'AI analyzes your project to recommend the best-matched freelancers.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAISuggestionsNotice(AppLocalizations t, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.hourglass_empty,
            color: isDark ? AppColors.warning : AppColors.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'AI suggestions will appear here. Check back later or browse all freelancers.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProposalCard(
    Proposal proposal,
    AppLocalizations t,
    bool isDark,
  ) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (proposal.status) {
      case 'pending':
        statusColor = AppColors.warning;
        statusText = 'Pending';
        statusIcon = Icons.hourglass_empty;
        break;
      case 'contracted':
      case 'accepted':
        statusColor = AppColors.success;
        statusText = 'Contract Created';
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = AppColors.danger;
        statusText = 'Rejected';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = AppColors.gray;
        statusText = proposal.status ?? 'Unknown';
        statusIcon = Icons.help;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  proposal.status == 'accepted' ||
                      proposal.status == 'contracted'
                  ? AppColors.successBg.withOpacity(isDark ? 0.15 : 1)
                  : proposal.status == 'rejected'
                  ? AppColors.dangerBg.withOpacity(isDark ? 0.15 : 1)
                  : null,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: isDark
                          ? AppColors.primaryDark
                          : Colors.blueGrey.shade100,
                      backgroundImage: proposal.freelancer?.avatar != null
                          ? NetworkImage(proposal.freelancer!.avatar!)
                          : null,
                      child: proposal.freelancer?.avatar == null
                          ? Text(
                              proposal.freelancer?.name?[0].toUpperCase() ??
                                  'F',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
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
                            proposal.freelancer?.name ?? 'Unknown',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.dark,
                            ),
                          ),
                          if (proposal.freelancerProfile?.title != null)
                            Text(
                              proposal.freelancerProfile!.title!,
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : Colors.grey.shade600,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildStatChip(
                                icon: Icons.star,
                                value:
                                    proposal.freelancerProfile?.rating
                                        ?.toStringAsFixed(1) ??
                                    '0.0',
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 8),
                              _buildStatChip(
                                icon: Icons.work_outline,
                                value:
                                    '${proposal.freelancerProfile?.experienceYears ?? 0} years',
                                color: Colors.blue,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (proposal.status == 'pending') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/negotiation',
                              arguments: proposal,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.info,
                            side: BorderSide(color: AppColors.info),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.handshake, size: 18),
                              SizedBox(width: 8),
                              Text('Negotiate'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'manual') {
                              _showInterviewTimePicker(proposal, t);
                            } else if (value == 'smart') {
                              _sendSmartInterviewInvitation(proposal, t);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.interpreter_mode,
                                  size: 18,
                                  color: AppColors.primaryDark,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Interview',
                                  style: TextStyle(
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: AppColors.primaryDark,
                                ),
                              ],
                            ),
                          ),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'manual',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 18,
                                    color: AppColors.info,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Manual choose times'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'smart',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    size: 18,
                                    color: AppColors.accent,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Smart AI optimized'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isProcessing
                              ? null
                              : () => handleAcceptProposal(proposal, t),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isProcessing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle, size: 18),
                                    SizedBox(width: 8),
                                    Text('Accept'),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isProcessing
                              ? null
                              : () => handleRejectProposal(proposal.id!, t),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: BorderSide(color: AppColors.danger),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cancel, size: 18),
                              SizedBox(width: 8),
                              Text('Reject'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          _buildProposalContent(proposal, t, isDark, statusColor),
        ],
      ),
    );
  }

  Widget _buildProposalContent(
    Proposal proposal,
    AppLocalizations t,
    bool isDark,
    Color statusColor,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              proposal.proposalText ?? 'No description provided',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.successBg.withOpacity(isDark ? 0.15 : 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Budget',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.attach_money,
                            size: 18,
                            color: AppColors.success,
                          ),
                          Text(
                            '\$${proposal.price?.toStringAsFixed(0) ?? '0'}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.infoBg.withOpacity(isDark ? 0.15 : 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 18,
                            color: AppColors.info,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${proposal.deliveryTime ?? 0} days',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.info,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (proposal.status == 'contracted' ||
              proposal.status == 'accepted') ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successBg.withOpacity(isDark ? 0.15 : 1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contract Created ✓',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                        Text(
                          'The contract has been created. Click below to view details.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.success.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _navigateToContractFromProposal(proposal),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View Contract'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.info,
                      side: BorderSide(color: AppColors.info),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (proposal.status == 'rejected') ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.dangerBg.withOpacity(isDark ? 0.15 : 1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.danger.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: AppColors.danger),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Proposal Rejected',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.danger,
                          ),
                        ),
                        Text(
                          'This proposal was not selected for this project.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.danger.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _navigateToContractFromProposal(Proposal proposal) async {
    try {
      final result = await ApiService.getContractByProjectId(widget.projectId);
      if (result['success'] == true && result['contract'] != null) {
        _navigateToContract(result['contract']['id']);
      } else {
        Fluttertoast.showToast(
          msg: 'Contract not found',
          backgroundColor: AppColors.danger,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error: $e',
        backgroundColor: AppColors.danger,
      );
    }
  }

  Future<void> _sendSmartInterviewInvitation(
    Proposal proposal,
    AppLocalizations t,
  ) async {
    setState(() => _isProcessing = true);
    final result = await ApiService.createSmartInterviewInvitation(
      proposalId: proposal.id!,
      message: 'AI-suggested interview times based on availability analysis.',
      durationMinutes: 30,
    );
    setState(() => _isProcessing = false);
    if (result['success'] == true) {
      Fluttertoast.showToast(msg: 'Smart interview invitation sent!');
      final suggestedTimes = result['suggestedTimes'] as List?;
      if (suggestedTimes != null && suggestedTimes.isNotEmpty) {
        _showSuggestedTimesDialog(suggestedTimes, t);
      }
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const InterviewsScreen()),
      );
    } else {
      if (!_consumeInterviewLimit(Map<String, dynamic>.from(result), t)) {
        Fluttertoast.showToast(
          msg: result['message'] ?? 'Error sending invitation',
          backgroundColor: AppColors.danger,
        );
      }
    }
  }

  void _showSuggestedTimesDialog(List<dynamic> times, AppLocalizations t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.accent),
            const SizedBox(width: 8),
            Text('AI Suggested Times Sent'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Suggested interview times have been sent to the freelancer.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ...times.map((time) {
              final dateTime = DateTime.parse(time.toString());
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Text(
                      _formatDateTime(dateTime, t),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _showInterviewTimePicker(
    Proposal proposal,
    AppLocalizations t,
  ) async {
    final List<DateTime> selectedTimes = [];
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.calendar_month, color: AppColors.accent),
                const SizedBox(width: 8),
                Text('Schedule Interview'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Select preferred times for the interview'),
                  const SizedBox(height: 16),
                  ...selectedTimes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final time = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accentBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _formatDateTime(time, t),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () =>
                                setState(() => selectedTimes.removeAt(index)),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (selectedTimes.length < 3)
                    ElevatedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(
                            const Duration(days: 2),
                          ),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 30),
                          ),
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 10, minute: 0),
                          );
                          if (time != null) {
                            final fullDateTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                            setState(() => selectedTimes.add(fullDateTime));
                          }
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Time'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentBg,
                        foregroundColor: AppColors.accent,
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Optional message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: selectedTimes.isEmpty
                    ? null
                    : () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                ),
                child: const Text('Send Invitation'),
              ),
            ],
          );
        },
      ),
    );
    if (result == true && selectedTimes.isNotEmpty) {
      await _sendInterviewInvitation(proposal, selectedTimes, t);
    }
  }

  void _showHireDialogFromSuggestion({
    required int freelancerId,
    required String freelancerName,
  }) {
    final t = AppLocalizations.of(context)!;

    if (widget.projectId == null) {
      Fluttertoast.showToast(
        msg: t.noActiveProjectForHiring,
        backgroundColor: AppColors.danger,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => HireFreelancerDialog(
        freelancerId: freelancerId,
        freelancerName: freelancerName,
        preselectedProjectId: widget.projectId,
        onSuccess: () {
          Fluttertoast.showToast(
            msg: t.offerSentSuccessfully,
            backgroundColor: AppColors.success,
          );
          fetchProposals();
          fetchSuggestedFreelancers();
        },
      ),
    );
  }

  Future<void> _sendInterviewInvitation(
    Proposal proposal,
    List<DateTime> times,
    AppLocalizations t,
  ) async {
    setState(() => _isProcessing = true);
    final result = await ApiService.createInterviewInvitation(
      proposalId: proposal.id!,
      suggestedTimes: times,
      message:
          'Interview invitation for project: ${proposal.project?.title ?? "Project"}',
      durationMinutes: 30,
    );
    setState(() => _isProcessing = false);
    if (result['success'] == true) {
      Fluttertoast.showToast(msg: 'Interview invitation sent!');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const InterviewsScreen()),
      );
    } else {
      if (!_consumeInterviewLimit(Map<String, dynamic>.from(result), t)) {
        Fluttertoast.showToast(
          msg: result['message'] ?? 'Error sending invitation',
          backgroundColor: AppColors.danger,
        );
      }
    }
  }

  String _formatDateTime(DateTime date, AppLocalizations t) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
