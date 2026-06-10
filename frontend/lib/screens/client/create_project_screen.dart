// screens/client/create_project_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import '../../data/project_post_templates.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../services/draft_local_storage.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ai_analysis_card.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../models/usage_limits_model.dart'; 

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final budgetController = TextEditingController();
  final durationController = TextEditingController();
  final categoryController = TextEditingController();

  List<String> selectedSkills = [];
  bool loading = false;
  bool analyzing = false;
  bool _checkingLimits = false;
  UsageLimits? _usageLimits; 
  Map<String, dynamic>? aiAnalysis;
  bool showAIAnalysis = false;

  Timer? _draftSaveTimer;
  DateTime? _draftSavedAt;
  bool _restoringDraft = false;

  final List<String> availableSkills = [
    'Flutter',
    'React',
    'Node.js',
    'Python',
    'UI/UX',
    'Graphic Design',
    'Content Writing',
    'SEO',
    'Marketing',
    'WordPress',
    'PHP',
    'Java',
    'Swift',
    'Django',
    'AWS',
    'Docker',
    'Kubernetes',
    'MongoDB',
    'PostgreSQL',
  ];

  final List<String> categories = [
    'Mobile Development',
    'Web Development',
    'Backend Development',
    'UI/UX Design',
    'Graphic Design',
    'Content Writing',
    'Digital Marketing',
    'DevOps',
    'Database',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _checkProjectLimits(); 
    titleController.addListener(_debounceAnalysis);
    descriptionController.addListener(_debounceAnalysis);
    titleController.addListener(_scheduleProjectDraftSave);
    descriptionController.addListener(_scheduleProjectDraftSave);
    budgetController.addListener(_scheduleProjectDraftSave);
    durationController.addListener(_scheduleProjectDraftSave);
    categoryController.addListener(_scheduleProjectDraftSave);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _loadSavedProjectDraft(),
    );
  }

  Future<void> _checkProjectLimits() async {
    setState(() => _checkingLimits = true);
    try {
      final response = await ApiService.getUserUsage();
      if (response['success'] == true && response['usage'] != null) {
        _usageLimits = UsageLimits.fromJson(response['usage']);
      }
    } catch (e) {
      print('Error checking limits: $e');
    } finally {
      if (mounted) setState(() => _checkingLimits = false);
    }
  }

  Future<bool> _canCreateProject() async {
    if (_usageLimits == null) {
      await _checkProjectLimits();
    }
    
    if (_usageLimits?.activeProjectsLimit == null || _usageLimits!.activeProjectsLimit == 0) {
      return true;
    }
    
    final remaining = _usageLimits!.remainingActiveProjects;
    if (remaining <= 0) {
      final t = AppLocalizations.of(context);
      final limit = _usageLimits!.activeProjectsLimit;
      
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(t?.limitReached ?? 'Project Limit Reached'),
            content: Text(
              t?.projectLimitMessage(limit.toString()) ??
              'You have reached the maximum of $limit active projects on your current plan.\n\n'
              'Upgrade your plan to create more projects or wait for existing projects to complete.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t?.cancel ?? 'Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/subscription/plans');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                ),
                child: Text(t?.upgrade ?? 'Upgrade Plan'),
              ),
            ],
          ),
        );
      }
      return false;
    }
    
    return true;
  }

  Map<String, dynamic> _projectDraftSnapshot() {
    return {
      'title': titleController.text,
      'description': descriptionController.text,
      'budget': budgetController.text,
      'duration': durationController.text,
      'category': categoryController.text,
      'skills': List<String>.from(selectedSkills),
    };
  }

  bool _hasDraftPayload() {
    return titleController.text.trim().isNotEmpty ||
        descriptionController.text.trim().isNotEmpty ||
        budgetController.text.trim().isNotEmpty ||
        selectedSkills.isNotEmpty;
  }

  void _scheduleProjectDraftSave() {
    if (_restoringDraft) return;
    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(const Duration(milliseconds: 1200), () async {
      if (!mounted || !_hasDraftPayload()) return;
      await DraftLocalStorage.saveProjectCreateDraft(_projectDraftSnapshot());
      if (mounted) setState(() => _draftSavedAt = DateTime.now());
    });
  }

  Future<void> _loadSavedProjectDraft() async {
    final d = await DraftLocalStorage.getProjectCreateDraft();
    if (!mounted || d == null) return;
    if (!DraftLocalStorage.isMeaningfulProjectDraft(d)) return;
    _restoringDraft = true;
    setState(() {
      titleController.text = d['title']?.toString() ?? '';
      descriptionController.text = d['description']?.toString() ?? '';
      budgetController.text = d['budget']?.toString() ?? '';
      durationController.text = d['duration']?.toString() ?? '';
      categoryController.text = d['category']?.toString() ?? '';
      final sk = d['skills'];
      if (sk is List) {
        selectedSkills = sk.map((e) => e.toString()).toList();
      }
    });
    _restoringDraft = false;
    if (!mounted) return;
    final t = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t?.draftRestored ?? 'Continued from your saved draft'),
        action: SnackBarAction(
          label: t?.clear ?? 'Clear',
          onPressed: _confirmClearProjectDraft,
        ),
      ),
    );
  }

  void _applyTemplate(ProjectPostTemplate t) {
    setState(() {
      titleController.text = t.title;
      descriptionController.text = t.description;
      categoryController.text = t.category;
      budgetController.text = t.budgetHint;
      durationController.text = t.durationHint;
      selectedSkills = t.skills
          .where((s) => availableSkills.contains(s))
          .toList();
    });
    _scheduleProjectDraftSave();
    _debounceAnalysis();
    final tLocal = AppLocalizations.of(context);
    Fluttertoast.showToast(
      msg:
          tLocal?.templateApplied ??
          'Template applied — edit and post when ready',
    );
  }

  Future<void> _confirmClearProjectDraft() async {
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          t?.clearDraft ?? 'Clear draft?',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: Text(
          t?.clearDraftConfirmation ??
              'Remove the saved project draft from this device?',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              t?.cancel ?? 'Cancel',
              style: TextStyle(color: AppColors.accent),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              t?.clear ?? 'Clear',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await DraftLocalStorage.clearProjectCreateDraft();
    setState(() {
      titleController.clear();
      descriptionController.clear();
      budgetController.clear();
      durationController.clear();
      categoryController.clear();
      selectedSkills.clear();
      aiAnalysis = null;
      showAIAnalysis = false;
      _draftSavedAt = null;
    });
    Fluttertoast.showToast(msg: t?.draftCleared ?? 'Draft cleared');
  }

  void _openTemplatesSheet() {
    final t = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              t?.projectTemplates ?? 'Project templates',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t?.templateHint ?? 'Prefill fields — still edit before posting.',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            ...ProjectPostTemplates.all.map((template) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: Theme.of(context).cardColor,
                child: ListTile(
                  title: Text(
                    template.name,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  subtitle: Text(
                    template.subtitle,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  trailing: Icon(Icons.chevron_right, color: AppColors.accent),
                  onTap: () {
                    Navigator.pop(ctx);
                    _applyTemplate(template);
                  },
                ),
              );
            }),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _confirmClearProjectDraft();
              },
              icon: Icon(Icons.delete_outline, color: Colors.red),
              label: Text(
                t?.clearSavedDraft ?? 'Clear saved draft',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Timer? _debounceTimer;
  void _debounceAnalysis() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      if (titleController.text.length > 10 &&
          descriptionController.text.length > 30) {
        _analyzeProject();
      }
    });
  }

  Future<void> _analyzeProject() async {
    if (analyzing) return;

    setState(() {
      analyzing = true;
      showAIAnalysis = false;
    });

    try {
      final analysis = await ApiService.analyzeProject(
        title: titleController.text,
        description: descriptionController.text,
        category: categoryController.text,
        skills: selectedSkills,
        budget: double.tryParse(budgetController.text),
      );

      setState(() {
        aiAnalysis = analysis;
        showAIAnalysis = true;
        analyzing = false;

        if (analysis['price_range']?['recommended'] != null &&
            budgetController.text.isEmpty) {
          budgetController.text = analysis['price_range']['recommended']
              .toString();
        }
        if (analysis['estimated_duration_days'] != null &&
            durationController.text.isEmpty) {
          durationController.text = analysis['estimated_duration_days']
              .toString();
        }
      });
    } catch (e) {
      setState(() => analyzing = false);
      debugPrint('Analysis error: $e');
    }
  }

  Future<void> _createProject() async {
    final t = AppLocalizations.of(context);
    
    if (!_formKey.currentState!.validate()) return;
    
    final canCreate = await _canCreateProject();
    if (!canCreate) return;
    
    setState(() => loading = true);

    final result = await ApiService.createProject(
      title: titleController.text,
      description: descriptionController.text,
      budget: double.parse(budgetController.text),
      duration: int.parse(durationController.text),
      category: categoryController.text.isNotEmpty
          ? categoryController.text
          : 'other',
      skills: selectedSkills,
    );

    setState(() => loading = false);

    if (result['project'] != null) {
      await DraftLocalStorage.clearProjectCreateDraft();
      await DraftLocalStorage.clearPublishReminderSnooze();
      Fluttertoast.showToast(
        msg: t?.projectCreatedSuccess ?? "✅ Project created successfully",
      );
      
      await _checkProjectLimits();
      
      if (mounted) Navigator.pop(context, true);
    } else {
      Fluttertoast.showToast(
        msg:
            result['message'] ??
            t?.errorCreatingProject ??
            "Error creating project",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          t?.postNewProject ?? "Post New Project",
          style: TextStyle(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: isDark
            ? AppColors.darkTextPrimary
            : AppColors.lightTextPrimary,
        elevation: 0,
        actions: [
          if (_draftSavedAt != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  t?.draftSaved ?? 'Draft saved',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: t?.templates ?? 'Templates',
            icon: Icon(Icons.article_outlined, color: AppColors.accent),
            onPressed: _openTemplatesSheet,
          ),
          if (analyzing)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_usageLimits != null && _usageLimits!.activeProjectsLimit != null)
                _buildLimitWarningCard(),
              
              Text(
                t?.projectDetails ?? "Project Details",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t?.projectDetailsHint ??
                    "Fill in the details below. AI will analyze and suggest improvements.",
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_done_outlined,
                      size: 18,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t?.autoSaveHint ??
                            'Your progress is saved automatically on this device.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (showAIAnalysis && aiAnalysis != null)
                AIAnalysisCard(
                  analysis: aiAnalysis!,
                  onApplySuggestion: (key, value) {
                    setState(() {
                      if (key == 'budget')
                        budgetController.text = value.toString();
                      if (key == 'duration')
                        durationController.text = value.toString();
                      if (key == 'milestones') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              t?.milestonesAddedHint ??
                                  "Suggested milestones added to proposal",
                            ),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    });
                  },
                ),

              const SizedBox(height: 16),

              Text(
                t?.projectTitle ?? "Project Title",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: titleController,
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText:
                      t?.projectTitleHint ?? "e.g., Build an E-commerce App",
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppColors.darkTextHint
                        : AppColors.lightTextHint,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                ),
                validator: (value) => value?.isEmpty == true
                    ? t?.requiredField ?? 'Please enter project title'
                    : null,
              ),
              const SizedBox(height: 16),

              Text(
                t?.projectDescription ?? "Project Description",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: descriptionController,
                maxLines: 6,
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText:
                      t?.projectDescriptionHint ??
                      "Describe your project in detail...\n- What do you need?\n- What are your expectations?\n- Any specific requirements?",
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppColors.darkTextHint
                        : AppColors.lightTextHint,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                  alignLabelWithHint: true,
                ),
                validator: (value) => value?.isEmpty == true
                    ? t?.requiredField ?? 'Please enter description'
                    : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t?.budget ?? "Budget (\$)",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: budgetController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                          decoration: InputDecoration(
                            prefixText: '\$ ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: theme.cardColor,
                          ),
                          validator: (value) {
                            if (value?.isEmpty == true)
                              return t?.requiredField ?? 'Required';
                            if (double.tryParse(value!) == null)
                              return t?.invalidNumber ?? 'Invalid number';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t?.durationDays ?? "Duration (days)",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: durationController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                          decoration: InputDecoration(
                            suffixText: t?.days ?? 'days',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: theme.cardColor,
                          ),
                          validator: (value) {
                            if (value?.isEmpty == true)
                              return t?.requiredField ?? 'Required';
                            if (int.tryParse(value!) == null)
                              return t?.invalidNumber ?? 'Invalid number';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                t?.category ?? "Category",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: categoryController.text.isNotEmpty
                    ? categoryController.text
                    : null,
                hint: Text(
                  t?.selectCategory ?? "Select a category",
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextHint
                        : AppColors.lightTextHint,
                  ),
                ),
                dropdownColor: theme.cardColor,
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                ),
                items: categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => categoryController.text = value ?? '');
                  _analyzeProject();
                },
              ),
              const SizedBox(height: 16),

              Text(
                t?.requiredSkills ?? "Required Skills",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableSkills.map((skill) {
                  final isSelected = selectedSkills.contains(skill);
                  return FilterChip(
                    label: Text(
                      skill,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          selectedSkills.add(skill);
                        } else {
                          selectedSkills.remove(skill);
                        }
                      });
                      _analyzeProject();
                      _scheduleProjectDraftSave();
                    },
                    backgroundColor: isDark
                        ? AppColors.darkCard
                        : Colors.grey.shade100,
                    selectedColor: AppColors.secondary,
                    checkmarkColor: Colors.white,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: (loading || _checkingLimits) ? null : _createProject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          t?.postProject ?? "Post Project",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLimitWarningCard() {
    final t = AppLocalizations.of(context);
    final limit = _usageLimits!.activeProjectsLimit!;
    final used = _usageLimits!.activeProjectsUsed;
    final remaining = limit - used;
    final percentage = used / limit;
    
    if (percentage < 0.8) return const SizedBox.shrink(); 
    
    final isCritical = remaining <= 1;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCritical ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCritical ? Colors.red.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCritical ? Icons.warning : Icons.info_outline,
            color: isCritical ? Colors.red : Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCritical 
                      ? '⚠️ Only $remaining project slot remaining!'
                      : '📊 $used of $limit active projects used',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCritical ? Colors.red : Colors.orange,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isCritical
                      ? 'Complete existing projects or upgrade your plan to create more.'
                      : 'You have $remaining project slot${remaining > 1 ? 's' : ''} remaining.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isCritical ? Colors.red.shade700 : Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
          if (remaining <= 1)
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/subscription/plans'),
              child: Text(
                t?.upgrade ?? 'Upgrade',
                style: TextStyle(
                  color: isCritical ? Colors.red : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _draftSaveTimer?.cancel();
    titleController.removeListener(_debounceAnalysis);
    descriptionController.removeListener(_debounceAnalysis);
    titleController.removeListener(_scheduleProjectDraftSave);
    descriptionController.removeListener(_scheduleProjectDraftSave);
    budgetController.removeListener(_scheduleProjectDraftSave);
    durationController.removeListener(_scheduleProjectDraftSave);
    categoryController.removeListener(_scheduleProjectDraftSave);
    titleController.dispose();
    descriptionController.dispose();
    budgetController.dispose();
    durationController.dispose();
    categoryController.dispose();
    super.dispose();
  }
}