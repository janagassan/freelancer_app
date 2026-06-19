// screens/freelancer/my_proposals_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/proposal_model.dart';
import '../../models/usage_limits_model.dart';
import '../../services/api_service.dart';
import 'project_details_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../theme/app_theme.dart';
import '../../providers/theme_provider.dart';

class MyProposalsScreen extends StatefulWidget {
  const MyProposalsScreen({super.key});

  @override
  State<MyProposalsScreen> createState() => _MyProposalsScreenState();
}

class _MyProposalsScreenState extends State<MyProposalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Proposal> proposals = [];
  List<Proposal> pendingProposals = [];
  List<Proposal> acceptedProposals = [];
  List<Proposal> rejectedProposals = [];

  bool loading = true;
  bool _loadingUsage = true;
  UsageLimits? _usage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUsage();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchProposals(context);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsage() async {
    setState(() => _loadingUsage = true);
    try {
      final response = await ApiService.getUserUsage();
      if (response['usage'] != null) {
        setState(() {
          _usage = UsageLimits.fromJson(response['usage']);
          _loadingUsage = false;
        });
      } else {
        setState(() => _loadingUsage = false);
      }
    } catch (e) {
      print('Error loading usage: $e');
      setState(() => _loadingUsage = false);
    }
  }

  Future<void> fetchProposals(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    setState(() => loading = true);

    try {
      final data = await ApiService.getMyProposals();

      setState(() {
        proposals = data.map((json) => Proposal.fromJson(json)).toList();
        pendingProposals = proposals
            .where((p) => p.status == 'pending')
            .toList();
        acceptedProposals = proposals
            .where((p) => p.status == 'accepted')
            .toList();
        rejectedProposals = proposals
            .where((p) => p.status == 'rejected')
            .toList();
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      Fluttertoast.showToast(msg: t.errorLoadingProposals);
    }
  }

  Widget _buildProposalsLimitIndicator() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_loadingUsage || _usage == null) return const SizedBox.shrink();
    if (_usage!.proposalsLimit == null) return const SizedBox.shrink();

    final percentage = _usage!.proposalsProgress;
    final remaining = _usage!.remainingProposals;
    final isLimitReached = remaining <= 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLimitReached
            ? (isDark
                  ? Colors.red.shade900.withOpacity(0.3)
                  : Colors.red.shade50)
            : theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLimitReached
              ? (isDark ? Colors.red.shade800 : Colors.red.shade200)
              : theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.production_quantity_limits,
                    size: 18,
                    color: isLimitReached
                        ? Colors.red
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    t.proposalsThisMonth,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isLimitReached
                          ? Colors.red
                          : theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isLimitReached
                      ? Colors.red.withOpacity(0.1)
                      : theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_usage!.proposalsUsed} / ${_usage!.proposalsLimit}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isLimitReached
                        ? Colors.red
                        : theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percentage.clamp(0.0, 1.0),
              backgroundColor: isDark
                  ? Colors.grey.shade800
                  : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(
                isLimitReached ? Colors.red : theme.colorScheme.primary,
              ),
              minHeight: 6,
            ),
          ),
          if (isLimitReached)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.warning,
                      size: 14,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.proposalLimitReached,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.red.shade300
                            : Colors.red.shade700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/subscription/plans');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      t.upgrade,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (remaining <= 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                t.proposalsRemaining(remaining),
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'pending':
        statusColor = AppColors.warning;
        statusIcon = Icons.hourglass_empty;
        statusText = t.pending;
        break;
      case 'accepted':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        statusText = t.accepted;
        break;
      case 'rejected':
        statusColor = AppColors.danger;
        statusIcon = Icons.cancel;
        statusText = t.rejected;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = t.unknown;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 12, color: statusColor),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
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

  Widget _buildProposalCard(Proposal proposal) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (proposal.project != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ProjectDetailsScreen(projectId: proposal.project!.id!),
                ),
              );
            }
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
                        proposal.project?.title ?? t.unknownProject,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildStatusBadge(proposal.status),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.transparent,
                        backgroundImage:
                      proposal.project?.client?.avatar != null &&
                          proposal.project!.client!.avatar!.isNotEmpty
                      ? NetworkImage(_getAvatarUrl(proposal.project!.client!.avatar!))
                      : null,
                  child: proposal.project?.client?.avatar == null
                      ? Text(
                          proposal.project?.client?.name?[0]
                                  .toUpperCase() ??
                              'C',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        )
                      : null,
                      )
                ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            proposal.project?.client?.name ?? t.unknownClient,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(proposal.createdAt),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface.withOpacity(0.5)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        proposal.proposalText ?? t.noMessageProvided,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.attach_money,
                                    size: 14,
                                    color: AppColors.secondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '\$${proposal.price?.toStringAsFixed(0) ?? '0'}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${proposal.deliveryTime} ${t.days}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (proposal.status == 'accepted' && proposal.project != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/contract',
                          arguments: {
                            'contractId': proposal.contractId,
                            'userRole': 'freelancer',
                          },
                        );
                      },
                      icon: const Icon(
                        Icons.work_outline,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: Text(
                        t.startWorking,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 44),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProposalsList(List<Proposal> proposalsList) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (proposalsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 40,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              t.noProposalsInCategory,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => fetchProposals(context),
      color: theme.colorScheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: proposalsList.length,
        itemBuilder: (context, index) {
          final proposal = proposalsList[index];
          return _buildProposalCard(proposal);
        },
      ),
    );
  }

  String _getAvatarUrl(String? avatar) {
    if (avatar == null || avatar.isEmpty) return '';
    if (avatar.startsWith('http')) return avatar;
    if (avatar.startsWith('/uploads')) {
      return 'http://localhost:5001$avatar';
    }
    return avatar;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        centerTitle: false,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
            color: theme.cardColor,
            child: TabBar(
              controller: _tabController,
              indicatorColor: theme.colorScheme.primary,
              indicatorWeight: 3,
              labelColor: theme.colorScheme.onSurface,
              unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(
                0.5,
              ),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 13,
              ),
              tabs: [
                Tab(text: "${t.all} (${proposals.length})"),
                Tab(text: "${t.pending} (${pendingProposals.length})"),
                Tab(text: "${t.accepted} (${acceptedProposals.length})"),
                Tab(text: "${t.rejected} (${rejectedProposals.length})"),
              ],
            ),
          ),
        ),
      ),
      body: loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t.loadingProposals,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            )
          : proposals.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.send_outlined,
                      size: 50,
                      color: theme.colorScheme.primary.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    t.noProposalsYet,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.browseProjectsAndSubmitProposal,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/projects');
                    },
                    icon: const Icon(Icons.search, size: 18),
                    label: Text(t.findProjects),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                _buildProposalsLimitIndicator(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildProposalsList(proposals),
                      _buildProposalsList(pendingProposals),
                      _buildProposalsList(acceptedProposals),
                      _buildProposalsList(rejectedProposals),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
