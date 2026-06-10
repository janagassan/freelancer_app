// screens/freelancer/my_projects_screen.dart

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/project_model.dart';
import '../../models/contract_model.dart';
import '../../services/api_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../theme/app_theme.dart';
import 'project_details_screen.dart';
import 'work_submission_screen.dart';

class MyProjectsScreen extends StatefulWidget {
  const MyProjectsScreen({super.key});

  @override
  State<MyProjectsScreen> createState() => _MyProjectsScreenState();
}

class _MyProjectsScreenState extends State<MyProjectsScreen> {
  List<Project> projects = [];
   Map<int, int> projectProgressMap = {};
  Map<int, bool> projectLoadingMap = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        fetchMyProjects(context);
      }
    });
  }

  Future<void> fetchMyProjects(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    if (!mounted) return;

    setState(() => loading = true);

    try {
      final data = await ApiService.getMyProjects();

      if (!mounted) return;

      final projectsList = data.map((json) => Project.fromJson(json)).toList();
      
      setState(() {
        projects = projectsList;
        loading = false;
      });

      await _fetchAllProjectsProgress(projectsList);

    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      Fluttertoast.showToast(msg: t.errorLoadingProjects);
    }
  }

  Future<void> _fetchAllProjectsProgress(List<Project> projectsList) async {
    for (var project in projectsList) {
      await _fetchProjectProgress(project);
    }
  }

  Future<void> _fetchProjectProgress(Project project) async {
    if (project.id == null) return;

    setState(() {
      projectLoadingMap[project.id!] = true;
    });

    try {
      final int progress = await _calculateRealProgress(project);
      
      if (mounted) {
        setState(() {
          projectProgressMap[project.id!] = progress;
          projectLoadingMap[project.id!] = false;
        });
      }
    } catch (e) {
      print('Error fetching progress for project ${project.id}: $e');
      if (mounted) {
        setState(() {
          projectProgressMap[project.id!] = 0;
          projectLoadingMap[project.id!] = false;
        });
      }
    }
  }

   Future<int> _calculateRealProgress(Project project) async {
    if (project.status == 'completed') return 100;
    
    if (project.status == 'cancelled' || project.status == 'draft') return 0;
    
    try {
      final contractData = await ApiService.getContractByProjectId(project.id!);
      
      if (contractData['success'] != true || contractData['contract'] == null) {
        return 0; 
      }
      
      final contract = Contract.fromJson(contractData['contract']);
      
      if (contract.status == 'completed') return 100;
      
      if (contract.status == 'cancelled') return 0;
      
      if (contract.milestones != null && contract.milestones!.isNotEmpty) {
        double totalProgress = 0;
        double totalWeight = 0; 
        
        for (var milestone in contract.milestones!) {
          double milestoneAmount = _getMilestoneAmount(milestone);
          double milestoneWeight = milestoneAmount / (contract.agreedAmount ?? 1);
          totalWeight += milestoneWeight;
          
          double milestoneProgress = 0;
          String status = milestone['status'] ?? 'pending';
          
          if (status == 'approved') {
            milestoneProgress = 100; 
          } else if (status == 'completed') {
            milestoneProgress = milestone['progress'] ?? 100;
          } else if (status == 'in_progress') {
            milestoneProgress = milestone['progress'] ?? 0;
          } else if (status == 'pending') {
            milestoneProgress = 0;
          }
          
          totalProgress += milestoneProgress * milestoneWeight;
        }
        
        if (totalWeight < 0.99 && totalWeight > 0) {
          totalProgress = totalProgress / totalWeight;
        }
        
        return totalProgress.round();
      }
      
      if (contract.status == 'active') return 50;
      
      if (contract.status == 'pending_client' || contract.status == 'pending_freelancer') return 10;
      
      return 0;
      
    } catch (e) {
      print('Error calculating real progress: $e');
      return 0;
    }
  }

  double _getMilestoneAmount(Map<String, dynamic> milestone) {
    if (milestone['amount'] == null) return 0;
    if (milestone['amount'] is double) return milestone['amount'];
    if (milestone['amount'] is int) return (milestone['amount'] as int).toDouble();
    if (milestone['amount'] is String) {
      return double.tryParse(milestone['amount']) ?? 0;
    }
    return 0;
  }


  String _getStatusText(String? status, AppLocalizations t) {
    switch (status) {
      case 'in_progress':
        return t.inProgress;
      case 'completed':
        return t.completed;
      case 'pending':
        return t.pending;
      default:
        return status ?? t.unknown;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'in_progress':
        return AppColors.warning;
      case 'completed':
        return AppColors.success;
      case 'pending':
        return AppColors.info;
      default:
        return Colors.grey;
    }
  }

  int _calculateProgress(Project project) {
    if (project.status == 'completed') return 100;
    if (project.status == 'in_progress') return 50;
    return 0;
  }

  Future<void> _submitWorkForProject(Project project) async {
    final t = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(color: AppColors.secondary),
      ),
    );

    try {
      final contractData = await ApiService.getContractByProjectId(project.id!);
      
      Navigator.pop(context); 

      if (contractData['success'] == true && contractData['contract'] != null) {
        final contract = Contract.fromJson(contractData['contract']);
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkSubmissionScreen(contract: contract),
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(t.noContract),
            content: Text(t.createContractFirst),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t.ok),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); 
      Fluttertoast.showToast(msg: '${t.error}: $e');
    }
  }

  void _showMessageDialog(Project project) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.accent.withOpacity(0.1),
              child: Icon(Icons.chat, color: AppColors.accent, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              '${t.message} ${project.client?.name ?? t.client}',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
        content: TextField(
          maxLines: 4,
          decoration: InputDecoration(
            hintText: t.typeYourMessage,
            hintStyle: TextStyle(
              color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accent, width: 2),
            ),
            filled: true,
            fillColor: isDark ? AppColors.darkSurface : Colors.grey.shade50,
          ),
          style: TextStyle(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              t.cancel,
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Fluttertoast.showToast(msg: t.messageSent);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.primaryDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(t.send),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
  final t = AppLocalizations.of(context)!;
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  
  final progress = projectProgressMap[project.id] ?? 0;
  final isLoadingProgress = projectLoadingMap[project.id] == true;
  final statusColor = _getStatusColor(project.status);
  final statusText = _getStatusText(project.status, t);
  final hasContract = project.contractId != null && project.contractId! > 0;

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
          if (hasContract) {
            Navigator.pushNamed(
              context,
              '/contract',
              arguments: {
                'contractId': project.contractId,
                'userRole': 'freelancer',
              },
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProjectDetailsScreen(projectId: project.id!),
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
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (project.budget != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.attach_money,
                            size: 14,
                            color: AppColors.secondary,
                          ),
                          Text(
                            project.budget!.toStringAsFixed(0),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                project.title ?? t.untitledProject,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.transparent,
                      backgroundImage:
                          project.client?.avatar != null &&
                              project.client!.avatar!.isNotEmpty
                          ? NetworkImage(project.client!.avatar!)
                          : null,
                      child:
                          project.client?.avatar == null ||
                              project.client!.avatar!.isEmpty
                          ? Text(
                              project.client?.name?[0].toUpperCase() ??
                                  t.client[0],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.client?.name ?? t.unknownClient,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.business_center,
                              size: 12,
                              color: isDark
                                  ? AppColors.darkTextHint
                                  : AppColors.lightTextHint,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              t.client,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkTextHint
                                    : AppColors.lightTextHint,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCard
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: isDark
                              ? AppColors.darkTextHint
                              : AppColors.lightTextHint,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${project.duration} ${t.days}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextHint
                                : AppColors.lightTextHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (project.skills != null && project.skills!.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: project.skills!.take(3).map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        skill,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? AppColors.accent
                              : AppColors.primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t.projectProgress,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkTextHint
                              : AppColors.lightTextHint,
                        ),
                      ),
                      if (isLoadingProgress)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent,
                          ),
                        )
                      else
                        Text(
                          '$progress%',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: progress == 100
                                ? AppColors.success
                                : AppColors.accent,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      backgroundColor: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress == 100
                            ? AppColors.success
                            : AppColors.accent,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showMessageDialog(project),
                      icon: Icon(
                        Icons.chat_outlined,
                        size: 18,
                        color: AppColors.accent,
                      ),
                      label: Text(
                        t.message,
                        style: TextStyle(color: AppColors.accent),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        side: BorderSide(
                          color: AppColors.accent.withOpacity(0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (hasContract) {
                          final route =
                              (project.contractStatus == 'active' ||
                                  project.status == 'in_progress')
                              ? '/contract/progress'
                              : '/contract';
                          Navigator.pushNamed(
                            context,
                            route,
                            arguments: {
                              'contractId': project.contractId,
                              'userRole': 'freelancer',
                            },
                          );
                          return;
                        }
                        if (project.status == 'completed') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProjectDetailsScreen(
                                projectId: project.id!,
                              ),
                            ),
                          );
                        } else {
                          _submitWorkForProject(project);
                        }
                      },
                      icon: Icon(
                        hasContract
                            ? Icons.open_in_new
                            : project.status == 'completed'
                            ? Icons.visibility
                            : Icons.check_circle,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: Text(
                        hasContract
                            ? ((project.contractStatus == 'active' ||
                                      project.status == 'in_progress')
                                  ? t.openWorkspace
                                  : t.openContract)
                            : project.status == 'completed'
                            ? t.viewDetails
                            : t.submitWork,
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasContract
                            ? AppColors.primary
                            : project.status == 'completed'
                            ? AppColors.primary
                            : AppColors.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
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
        foregroundColor: isDark
            ? AppColors.darkTextPrimary
            : AppColors.lightTextPrimary,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: () => fetchMyProjects(context),
              icon: Icon(Icons.refresh, color: AppColors.accent),
              tooltip: t.refresh,
            ),
          ),
        ],
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
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t.loadingProjects,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            )
          : projects.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.folder_open_outlined,
                      size: 50,
                      color: AppColors.accent.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    t.noProjectsYet,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.acceptedProposalsWillAppear,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/freelancer/my-proposals');
                    },
                    icon: const Icon(Icons.send_outlined, size: 18),
                    label: Text(t.viewMyProposals),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.primaryDark,
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
          : RefreshIndicator(
              onRefresh: () => fetchMyProjects(context),
              color: AppColors.accent,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final project = projects[index];
                  return _buildProjectCard(project);
                },
              ),
            ),
    );
  }
}
