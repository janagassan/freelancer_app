// screens/freelancer/submit_proposal_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/usage_limits_model.dart';
import '../../models/project_model.dart';
import '../../services/api_service.dart';
import '../../services/draft_local_storage.dart';
import '../../widgets/milestone_editor.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../theme/app_theme.dart';

class SubmitProposalScreen extends StatefulWidget {
  final Project project;
  final Map<String, dynamic>? smartPricing;
  const SubmitProposalScreen({
    super.key,
    required this.project,
    this.smartPricing,
  });

  @override
  State<SubmitProposalScreen> createState() => _SubmitProposalScreenState();
}

class _SubmitProposalScreenState extends State<SubmitProposalScreen> {
  final _formKey = GlobalKey<FormState>();
  final priceController = TextEditingController();
  final deliveryController = TextEditingController();
  final messageController = TextEditingController();
  List<Map<String, dynamic>> milestones = [];

  bool loading = false;
  double? calculatedPrice;

  bool loadingPricing = false;
  Map<String, dynamic>? smartPricing;
  bool showSmartPricing = false;

  bool loadingMilestones = false;
  Map<String, dynamic>? projectAnalysis;
  bool showAIMilestones = false;
  bool _checkingLimits = false;
  bool _analyzingProposal = false;
  Map<String, dynamic>? _proposalQuality;

  Timer? _proposalDraftTimer;
  DateTime? _proposalDraftSavedAt;
  bool _ignoreProposalDraftListeners = false;

  @override
  void initState() {
    super.initState();
    priceController.text = widget.project.budget?.toStringAsFixed(0) ?? '';
    deliveryController.text = widget.project.duration?.toString() ?? '';
    priceController.addListener(_scheduleProposalDraftSave);
    deliveryController.addListener(_scheduleProposalDraftSave);
    messageController.addListener(_scheduleProposalDraftSave);

    if (widget.smartPricing != null) {
      smartPricing = widget.smartPricing;
      showSmartPricing = true;

      final recommendedPrice = widget.smartPricing!['recommended_price'];
      if (recommendedPrice != null) {
        priceController.text = recommendedPrice.toStringAsFixed(0);
        calculatedPrice = recommendedPrice.toDouble();
      }
    }
    _loadAllAIData();
  }

  Future<void> _loadAllAIData() async {
    await Future.wait([_loadSmartPricing(), _loadProjectAnalysis()]);
    if (!mounted) return;
    await _restoreProposalDraftIfAny();
  }

  void _scheduleProposalDraftSave() {
    if (_ignoreProposalDraftListeners) return;
    final id = widget.project.id;
    if (id == null) return;
    _proposalDraftTimer?.cancel();
    _proposalDraftTimer = Timer(const Duration(milliseconds: 1300), () {
      _persistProposalDraft(id);
    });
  }

  Future<void> _persistProposalDraft(int projectId) async {
    if (_ignoreProposalDraftListeners) return;
    final price = priceController.text.trim();
    final del = deliveryController.text.trim();
    final msg = messageController.text.trim();
    if (price.isEmpty && del.isEmpty && msg.isEmpty && milestones.isEmpty) {
      return;
    }
    await DraftLocalStorage.saveProposalDraft(projectId, {
      'price': price,
      'delivery': del,
      'message': msg,
      'milestones': milestones
          .map((m) => Map<String, dynamic>.from(m))
          .toList(),
    });
    if (mounted) setState(() => _proposalDraftSavedAt = DateTime.now());
  }

  Future<void> _restoreProposalDraftIfAny() async {
    final t = AppLocalizations.of(context)!;
    final id = widget.project.id;
    if (id == null) return;
    final d = await DraftLocalStorage.getProposalDraft(id);
    if (d == null || !mounted) return;

    _ignoreProposalDraftListeners = true;
    setState(() {
      final p = d['price']?.toString();
      if (p != null && p.isNotEmpty) priceController.text = p;
      final del = d['delivery']?.toString();
      if (del != null && del.isNotEmpty) deliveryController.text = del;
      final msg = d['message']?.toString();
      if (msg != null && msg.isNotEmpty) messageController.text = msg;
      final ms = DraftLocalStorage.milestonesFromJson(d['milestones']);
      if (ms.isNotEmpty) milestones = ms;
    });
    _ignoreProposalDraftListeners = false;

    if (mounted) {
      Fluttertoast.showToast(
        msg: t.restoredProposalDraft,
        backgroundColor: AppColors.secondary,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _loadSmartPricing() async {
    if (widget.project.id == null) return;

    setState(() => loadingPricing = true);

    try {
      final response = await ApiService.getSmartPricing(widget.project.id!);

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

  Future<void> _loadProjectAnalysis() async {
    if (widget.project.id == null) return;

    setState(() => loadingMilestones = true);

    try {
      final response = await ApiService.analyzeProject(
        title: widget.project.title ?? '',
        description: widget.project.description ?? '',
        category: widget.project.category,
        skills: widget.project.skills,
        budget: widget.project.budget,
      );

      if (response.isEmpty) {
        setState(() {
          loadingMilestones = false;
          showAIMilestones = false;
        });
        _initDefaultMilestones();
        return;
      }

      final milestones = response['suggested_milestones'];

      if (milestones != null && milestones.isNotEmpty) {
        setState(() {
          projectAnalysis = response;
          showAIMilestones = true;
          loadingMilestones = false;
        });
        _applyAIMilestones(milestones);
      } else {
        setState(() {
          loadingMilestones = false;
          showAIMilestones = false;
        });
        _initDefaultMilestones();
      }
    } catch (e) {
      setState(() => loadingMilestones = false);
      _initDefaultMilestones();
    }
  }

  void _applyAIMilestones(List<dynamic> aiMilestones) {
    final price =
        double.tryParse(priceController.text) ?? widget.project.budget ?? 1000;

    milestones = aiMilestones.map((m) {
      return {
        'title': m['title'] ?? 'Milestone',
        'description': m['description'] ?? '',
        'amount': price * (m['percentage'] / 100),
        'percentage': m['percentage'] ?? 0,
        'due_date': _calculateDueDate(m['percentage'] ?? 0, price),
        'status': 'pending',
      };
    }).toList();

    setState(() {});
  }

  String _calculateDueDate(double percentage, double price) {
    final totalDays =
        int.tryParse(deliveryController.text) ?? widget.project.duration ?? 21;

    int daysOffset;
    if (percentage <= 20) {
      daysOffset = (totalDays * 0.2).round();
    } else if (percentage <= 50) {
      daysOffset = (totalDays * 0.5).round();
    } else {
      daysOffset = totalDays;
    }

    return DateTime.now().add(Duration(days: daysOffset)).toIso8601String();
  }

  void _initDefaultMilestones() {
    final price =
        double.tryParse(priceController.text) ?? widget.project.budget ?? 1000;
    final totalDays =
        int.tryParse(deliveryController.text) ?? widget.project.duration ?? 21;

    milestones = [
      {
        'title': 'Project Setup & Planning',
        'description':
            'Initial setup, requirements analysis, and architecture design',
        'amount': price * 0.2,
        'percentage': 20,
        'due_date': DateTime.now()
            .add(Duration(days: (totalDays * 0.2).round()))
            .toIso8601String(),
        'status': 'pending',
      },
      {
        'title': 'Core Development',
        'description': 'Main features implementation',
        'amount': price * 0.5,
        'percentage': 50,
        'due_date': DateTime.now()
            .add(Duration(days: (totalDays * 0.6).round()))
            .toIso8601String(),
        'status': 'pending',
      },
      {
        'title': 'Testing & Final Delivery',
        'description': 'QA testing, bug fixes, and final deployment',
        'amount': price * 0.3,
        'percentage': 30,
        'due_date': DateTime.now()
            .add(Duration(days: totalDays))
            .toIso8601String(),
        'status': 'pending',
      },
    ];
    setState(() {});
  }

  void _applySmartPricing() {
    final t = AppLocalizations.of(context)!;
    if (smartPricing == null) return;

    final recommendedPrice = smartPricing!['recommended_price'];
    if (recommendedPrice != null) {
      setState(() {
        priceController.text = recommendedPrice.toStringAsFixed(0);
        calculatedPrice = recommendedPrice.toDouble();
      });

      if (milestones.isNotEmpty) {
        _updateMilestonesAmounts(recommendedPrice.toDouble());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.aiPriceApplied),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showAIMilestonesDialog() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (projectAnalysis == null ||
        projectAnalysis!['suggested_milestones'] == null)
      return;

    final aiMilestones = projectAnalysis!['suggested_milestones'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.warning),
            const SizedBox(width: 8),
            Text(
              t.aiSuggestedMilestones,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.aiMilestonesDescription,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(aiMilestones.length, (index) {
                final m = aiMilestones[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.warning.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              m['title'] ?? 'Milestone',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${m['percentage']}%",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        m['description'] ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              t.cancel,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _applyAIMilestones(aiMilestones);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(t.aiMilestonesApplied),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: Text(t.applyMilestones),
          ),
        ],
      ),
    );
  }

  void _updateMilestonesAmounts(double totalAmount) {
    for (int i = 0; i < milestones.length; i++) {
      final percentage = milestones[i]['percentage'] ?? 0;
      milestones[i]['amount'] = totalAmount * percentage / 100;
    }
    setState(() {});
  }

  void _updateMilestonesDueDates(int totalDays) {
    for (int i = 0; i < milestones.length; i++) {
      final percentage = milestones[i]['percentage'] ?? 0;
      int daysOffset;
      if (percentage <= 20) {
        daysOffset = (totalDays * 0.2).round();
      } else if (percentage <= 50) {
        daysOffset = (totalDays * 0.5).round();
      } else {
        daysOffset = totalDays;
      }
      final dueDate = DateTime.now().add(Duration(days: daysOffset));
      milestones[i]['due_date'] = dueDate.toIso8601String();
    }
    setState(() {});
  }

  double _calculateTotalAmount() {
    double total = 0;
    for (var milestone in milestones) {
      total += milestone['amount'] ?? 0;
    }
    return total;
  }

  Future<void> _submitProposal() async {
    final t = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    final totalMilestones = _calculateTotalAmount();
    final price = double.parse(priceController.text);

    if (milestones.isNotEmpty && (totalMilestones - price).abs() > 0.01) {
      Fluttertoast.showToast(
        msg: t.milestoneAmountMismatch(
          totalMilestones.toStringAsFixed(0),
          price.toStringAsFixed(0),
        ),
        timeInSecForIosWeb: 3,
        backgroundColor: AppColors.danger,
        textColor: Colors.white,
      );
      return;
    }

    setState(() => loading = true);
    setState(() => _checkingLimits = true);
    final usageResponse = await ApiService.getUserUsage();
    setState(() => _checkingLimits = false);

    if (usageResponse['usage'] != null) {
      final usage = UsageLimits.fromJson(usageResponse['usage']);
      if (!usage.canSubmitProposal) {
  setState(() => loading = false);

  showDialog(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.block, color: AppColors.danger),
          const SizedBox(width: 12),
          Text(t.proposalLimitReached),
        ],
      ),
      content: Text(t.proposalLimitReachedMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.maybeLater),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/subscription/plans');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
          ),
          child: Text(t.upgradeNow),
        ),
      ],
    ),
  );
  return;
}
    }

    try {
      final result = await ApiService.submitProposal(
        projectId: widget.project.id!,
        price: price,
        deliveryTime: int.parse(deliveryController.text),
        proposalText: messageController.text,
        milestones: milestones,
      );

      if (result['proposal'] != null) {
        await DraftLocalStorage.clearProposalDraft(widget.project.id!);
        Fluttertoast.showToast(
          msg: t.proposalSubmittedSuccess,
          timeInSecForIosWeb: 3,
          backgroundColor: AppColors.success,
          textColor: Colors.white,
        );
        if (mounted) Navigator.pop(context, true);
      } else {
        Fluttertoast.showToast(
          msg: result['message'] ?? t.errorSubmittingProposal,
          timeInSecForIosWeb: 3,
          backgroundColor: AppColors.danger,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: '${t.error}: $e',
        timeInSecForIosWeb: 3,
        backgroundColor: AppColors.danger,
        textColor: Colors.white,
      );
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _analyzeProposalQuality() async {
    final t = AppLocalizations.of(context)!;
    final price = double.tryParse(priceController.text);
    final delivery = int.tryParse(deliveryController.text);
    final message = messageController.text.trim();

    if (price == null || delivery == null || message.length < 20) {
      Fluttertoast.showToast(msg: t.fillProposalFieldsFirst);
      return;
    }

    setState(() => _analyzingProposal = true);
    try {
      final response = await ApiService.analyzeProposalDraft(
        projectId: widget.project.id!,
        price: price,
        deliveryTime: delivery,
        proposalText: message,
      );
      if (!mounted) return;
      if (response['success'] == true && response['analysis'] != null) {
        setState(() {
          _proposalQuality = Map<String, dynamic>.from(
            response['analysis'] as Map,
          );
        });
      } else {
        Fluttertoast.showToast(
          msg: response['message']?.toString() ?? t.couldNotAnalyzeProposal,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '${t.analysisFailed}: $e');
    } finally {
      if (mounted) setState(() => _analyzingProposal = false);
    }
  }

  Widget _buildBreakdownRow(String label, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
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
        title: Text(t.submitProposal),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          if (_proposalDraftSavedAt != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  t.draftSaved,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (loadingPricing || loadingMilestones)
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.secondary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.save_outlined,
                      size: 18,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t.proposalAutosaveMessage,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.info.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.info),
                        const SizedBox(width: 8),
                        Text(
                          t.youAreApplyingFor,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.project.title ?? t.untitledProject,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.project.description ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${t.budget}: \$${widget.project.budget?.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${t.duration}: ${widget.project.duration} ${t.days}',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (showSmartPricing && smartPricing != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
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
                            t.aiSmartPricing,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
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
                              ),
                              _buildBreakdownRow(
                                t.complexity,
                                "+${((smartPricing!['pricing_breakdown']['complexity_multiplier'] ?? 1) - 1) * 100}%",
                              ),
                              _buildBreakdownRow(
                                t.experience,
                                "+${((smartPricing!['pricing_breakdown']['experience_multiplier'] ?? 1) - 1) * 100}%",
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _applySmartPricing,
                          icon: const Icon(Icons.check_circle, size: 16),
                          label: Text(t.useRecommendedPrice),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (showAIMilestones &&
                  projectAnalysis != null &&
                  projectAnalysis!['suggested_milestones'] != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              Colors.green.shade900.withOpacity(0.3),
                              Colors.teal.shade900.withOpacity(0.3),
                            ]
                          : [Colors.green.shade50, Colors.teal.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.green.shade800
                          : Colors.green.shade200,
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
                                colors: [Colors.green, Colors.teal],
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
                            t.aiMilestoneSuggestions,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t.aiMilestonesDescription,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(
                        (projectAnalysis!['suggested_milestones'] as List)
                            .take(2)
                            .length,
                        (index) {
                          final m =
                              projectAnalysis!['suggested_milestones'][index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m['title'] ?? 'Milestone',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        m['description'] ?? '',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.6),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
                                    color: AppColors.secondary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "${m['percentage']}%",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      if ((projectAnalysis!['suggested_milestones'] as List)
                              .length >
                          2)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            t.plusMoreMilestones(
                              (projectAnalysis!['suggested_milestones'] as List)
                                      .length -
                                  2,
                            ),
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _showAIMilestonesDialog,
                          icon: const Icon(Icons.auto_awesome, size: 16),
                          label: Text(t.viewAndApplyMilestones),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.teal,
                            side: const BorderSide(color: Colors.teal),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                t.yourProposal,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t.fillProposalDetails,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                t.yourPrice,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.attach_money,
                    color: theme.colorScheme.primary,
                  ),
                  hintText: t.enterYourPrice,
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurface
                      : Colors.grey.shade50,
                  suffix: Text(
                    'USD',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    calculatedPrice = double.tryParse(value);
                    if (calculatedPrice != null && milestones.isNotEmpty) {
                      _updateMilestonesAmounts(calculatedPrice!);
                    }
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) return t.pleaseEnterPrice;
                  if (double.tryParse(value) == null) return t.invalidPrice;
                  if (double.parse(value) <= 0) return t.priceGreaterThanZero;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                t.deliveryTimeDays,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: deliveryController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.access_time,
                    color: theme.colorScheme.primary,
                  ),
                  hintText: t.howManyDays,
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurface
                      : Colors.grey.shade50,
                  suffix: Text(
                    t.days,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
                onChanged: (value) {
                  final days = int.tryParse(value);
                  if (days != null && milestones.isNotEmpty) {
                    _updateMilestonesDueDates(days);
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return t.pleaseEnterDeliveryTime;
                  if (int.tryParse(value) == null) return t.invalidNumber;
                  if (int.parse(value) <= 0)
                    return t.deliveryTimeGreaterThanZero;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    t.paymentMilestones,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (showAIMilestones)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 12,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            t.aiGenerated,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                t.defineMilestones,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 12),
              MilestoneEditor(
                milestones: milestones,
                onChanged: (newMilestones) {
                  setState(() => milestones = newMilestones);
                  _scheduleProposalDraftSave();
                },
              ),
              const SizedBox(height: 16),
              Text(
                t.coverLetter,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: messageController,
                maxLines: 6,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: t.coverLetterHint,
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurface
                      : Colors.grey.shade50,
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return t.pleaseWriteCoverLetter;
                  if (value.length < 50) return t.coverLetterMinLength;
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${messageController.text.length}/5000',
                  style: TextStyle(
                    color: messageController.text.length >= 5000
                        ? AppColors.danger
                        : theme.colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _analyzingProposal
                      ? null
                      : _analyzeProposalQuality,
                  icon: _analyzingProposal
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                  label: Text(
                    _analyzingProposal
                        ? t.analyzingProposal
                        : t.analyzeProposalQuality,
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (_proposalQuality != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.deepPurple.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.analytics_outlined,
                            color: Colors.deepPurple,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${t.proposalScore}: ${_proposalQuality!['score'] ?? 0}/100',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _proposalQuality!['summary']?.toString() ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if ((_proposalQuality!['strengths'] as List?)
                              ?.isNotEmpty ==
                          true)
                        Text(
                          '${t.strengths}: ${(List<dynamic>.from(_proposalQuality!['strengths'])).join(' • ')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.success,
                          ),
                        ),
                      const SizedBox(height: 6),
                      if ((_proposalQuality!['improvements'] as List?)
                              ?.isNotEmpty ==
                          true)
                        Text(
                          '${t.improve}: ${(List<dynamic>.from(_proposalQuality!['improvements'])).join(' • ')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.warning,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (calculatedPrice != null && widget.project.budget != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: calculatedPrice! <= widget.project.budget!
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        calculatedPrice! <= widget.project.budget!
                            ? Icons.thumb_up
                            : Icons.warning,
                        color: calculatedPrice! <= widget.project.budget!
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          calculatedPrice! <= widget.project.budget!
                              ? t.priceWithinBudget
                              : t.priceAboveBudget,
                          style: TextStyle(
                            color: calculatedPrice! <= widget.project.budget!
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (milestones.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.paymentScheduleSummary,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...milestones.asMap().entries.map((entry) {
                        final index = entry.key;
                        final milestone = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: AppColors.info.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.info,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  milestone['title'] ?? 'Milestone',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                              Text(
                                '\$${milestone['amount']?.toStringAsFixed(0) ?? '0'}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            t.total,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${_calculateTotalAmount().toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: loading ? null : _submitProposal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          t.submitProposal,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  t.agreeToTerms,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _proposalDraftTimer?.cancel();
    priceController.removeListener(_scheduleProposalDraftSave);
    deliveryController.removeListener(_scheduleProposalDraftSave);
    messageController.removeListener(_scheduleProposalDraftSave);
    priceController.dispose();
    deliveryController.dispose();
    messageController.dispose();
    super.dispose();
  }
}
