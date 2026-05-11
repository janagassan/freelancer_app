// screens/admin/plans_management_tab.dart

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../models/subscription_plan_model.dart';
import '../../theme/app_theme.dart' as AppTheme;

class PlansManagementTab extends StatefulWidget {
  const PlansManagementTab({super.key});

  @override
  State<PlansManagementTab> createState() => _PlansManagementTabState();
}

class _PlansManagementTabState extends State<PlansManagementTab> {
  List<SubscriptionPlan> _plans = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plans = await ApiService.getAdminPlans();
      setState(() {
        _plans = plans;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '${AppLocalizations.of(context)?.failedToLoadPlans}: $e';
        _loading = false;
      });
    }
  }

  Future<void> _deletePlan(SubscriptionPlan plan) async {
    final t = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          t?.deletePlan ?? 'Delete Plan',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          t?.deletePlanConfirmation(plan.name) ?? 'Are you sure you want to delete "${plan.name}"? This cannot be undone.',
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
              elevation: 0,
            ),
            child: Text(t?.delete ?? 'Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final success = await ApiService.deletePlan(plan.id);
    if (success) {
      _loadPlans();
      final t = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t?.planDeletedSuccess ?? 'Plan deleted successfully'),
          backgroundColor: Colors.black87,
        ),
      );
    } else {
      final t = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t?.failedToDeletePlan ?? 'Failed to delete plan'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPlanDialog({SubscriptionPlan? plan}) {
    showDialog(
      context: context,
      builder: (ctx) => PlanFormDialog(plan: plan, onSaved: _loadPlans),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    if (_loading) {
      return Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadPlans,
              icon: const Icon(Icons.refresh),
              label: Text(t.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(
                '${_plans.length} ${_plans.length == 1 ? t.plansConfigured : t.plansConfigured_plural}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey.shade500 : const Color(0xFF888888),
                ),
              ),
              const Spacer(),
              _buildAddButton(t.newPlan, () => _showPlanDialog(), isDark),
            ],
          ),
        ),
        Expanded(
          child: _plans.isEmpty
              ? _buildEmpty(t, isDark)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: _plans.length,
                  itemBuilder: (_, i) => _buildPlanCard(_plans[i], t, isDark),
                ),
        ),
      ],
    );
  }

  Widget _buildAddButton(String label, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF14A800), Color(0xFF0A6E00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF14A800).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan, AppLocalizations t, bool isDark) {
    final theme = Theme.of(context);
    final isRecommended = plan.isRecommended;
    final isFree = plan.price == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isRecommended
            ? Border.all(color: const Color(0xFF14A800), width: 2)
            : Border.all(
                color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade100,
              ),
        boxShadow: [
          BoxShadow(
            color: isRecommended
                ? const Color(0xFF14A800).withOpacity(0.12)
                : Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isRecommended
                  ? const Color(0xFF14A800).withOpacity(0.05)
                  : (isDark ? AppTheme.AppColors.darkSurface : Colors.grey.shade50),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade100,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: isFree
                        ? const LinearGradient(
                            colors: [Color(0xFF888888), Color(0xFF555555)],
                          )
                        : isRecommended
                            ? const LinearGradient(
                                colors: [Color(0xFF14A800), Color(0xFF0A6E00)],
                              )
                            : const LinearGradient(
                                colors: [Color(0xFF5B58E2), Color(0xFF3D35CC)],
                              ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isFree
                        ? Icons.card_giftcard_rounded
                        : isRecommended
                            ? Icons.stars_rounded
                            : Icons.subscriptions_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            plan.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1A1B3E),
                            ),
                          ),
                          if (isRecommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF14A800), Color(0xFF0A6E00)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                t.recommended,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isFree
                            ? t.free
                            : '${t.currency}${plan.price.toStringAsFixed(2)} / ${_getBillingPeriodText(plan.billingPeriod, t)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isFree
                              ? (isDark ? Colors.grey.shade500 : Colors.grey.shade500)
                              : const Color(0xFF14A800),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _iconBtn(
                      Icons.edit_outlined,
                      theme.colorScheme.primary,
                      () => _showPlanDialog(plan: plan),
                      isDark,
                    ),
                    const SizedBox(width: 6),
                    _iconBtn(
                      Icons.delete_outline,
                      Colors.red.shade400,
                      () => _deletePlan(plan),
                      isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (plan.description != null && plan.description!.isNotEmpty) ...[
                  Text(
                    plan.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _featureChip(
                      '${plan.proposalLimit == null ? '∞' : plan.proposalLimit} ${t.proposals}',
                      isDark,
                    ),
                    _featureChip(
                      '${plan.activeProjectLimit == null ? '∞' : plan.activeProjectLimit} ${t.projects}',
                      isDark,
                    ),
                    _featureChip('${plan.trialDays}d ${t.trial}', isDark),
                    if (plan.aiInsights)
                      _featureChip(t.aiInsights, isDark, highlight: true),
                    if (plan.prioritySupport)
                      _featureChip(t.prioritySupport, isDark, highlight: true),
                    if (plan.apiAccess)
                      _featureChip(t.apiAccess, isDark, highlight: true),
                    if (plan.customBranding)
                      _featureChip(t.customBranding, isDark, highlight: true),
                  ],
                ),
                if (plan.features.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: plan.features.map((f) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: const Color(0xFF14A800),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          f,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getBillingPeriodText(String period, AppLocalizations t) {
    switch (period) {
      case 'monthly':
        return t.monthly;
      case 'yearly':
        return t.yearly;
      default:
        return period;
    }
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _featureChip(String label, bool isDark, {bool highlight = false}) {
    final theme = Theme.of(context);
    final color = highlight ? theme.colorScheme.primary : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: highlight
            ? theme.colorScheme.primary.withOpacity(0.08)
            : (isDark ? AppTheme.AppColors.darkSurface : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(8),
        border: highlight
            ? Border.all(color: theme.colorScheme.primary.withOpacity(0.2))
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: highlight
              ? theme.colorScheme.primary
              : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
          fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
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
              Icons.subscriptions_outlined,
              size: 40,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t.noPlansConfigured,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 20),
          _buildAddButton(t.addFirstPlan, () => _showPlanDialog(), isDark),
        ],
      ),
    );
  }
}


class PlanFormDialog extends StatefulWidget {
  final SubscriptionPlan? plan;
  final VoidCallback onSaved;

  const PlanFormDialog({super.key, this.plan, required this.onSaved});

  @override
  State<PlanFormDialog> createState() => _PlanFormDialogState();
}

class _PlanFormDialogState extends State<PlanFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl,
      _slugCtrl,
      _descCtrl,
      _priceCtrl,
      _proposalLimitCtrl,
      _activeProjectLimitCtrl,
      _trialCtrl,
      _sortCtrl;
  late String _billingPeriod;
  late bool _aiInsights,
      _prioritySupport,
      _apiAccess,
      _customBranding,
      _isRecommended;
  late List<String> _features;
  final _featureInputCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.plan?.name ?? '');
    _slugCtrl = TextEditingController(text: widget.plan?.slug ?? '');
    _descCtrl = TextEditingController(text: widget.plan?.description ?? '');
    _priceCtrl = TextEditingController(
      text: widget.plan?.price.toString() ?? '0',
    );
    _billingPeriod = widget.plan?.billingPeriod ?? 'monthly';
    _proposalLimitCtrl = TextEditingController(
      text: widget.plan?.proposalLimit?.toString() ?? '',
    );
    _activeProjectLimitCtrl = TextEditingController(
      text: widget.plan?.activeProjectLimit?.toString() ?? '',
    );
    _aiInsights = widget.plan?.aiInsights ?? false;
    _prioritySupport = widget.plan?.prioritySupport ?? false;
    _apiAccess = widget.plan?.apiAccess ?? false;
    _customBranding = widget.plan?.customBranding ?? false;
    _trialCtrl = TextEditingController(
      text: widget.plan?.trialDays.toString() ?? '14',
    );
    _sortCtrl = TextEditingController(
      text: widget.plan?.sortOrder.toString() ?? '0',
    );
    _isRecommended = widget.plan?.isRecommended ?? false;
    _features = List<String>.from(widget.plan?.features ?? []);
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _slugCtrl,
      _descCtrl,
      _priceCtrl,
      _proposalLimitCtrl,
      _activeProjectLimitCtrl,
      _trialCtrl,
      _sortCtrl,
      _featureInputCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'name': _nameCtrl.text.trim(),
      'slug': _slugCtrl.text.trim(),
      'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      'price': double.parse(_priceCtrl.text),
      'billing_period': _billingPeriod,
      'features': _features,
      'proposal_limit': _proposalLimitCtrl.text.trim().isEmpty
          ? null
          : int.parse(_proposalLimitCtrl.text),
      'active_project_limit': _activeProjectLimitCtrl.text.trim().isEmpty
          ? null
          : int.parse(_activeProjectLimitCtrl.text),
      'ai_insights': _aiInsights,
      'priority_support': _prioritySupport,
      'api_access': _apiAccess,
      'custom_branding': _customBranding,
      'trial_days': int.parse(_trialCtrl.text),
      'sort_order': int.parse(_sortCtrl.text),
      'is_recommended': _isRecommended,
      'is_active': true,
    };

    SubscriptionPlan? result;
    if (widget.plan != null) {
      result = await ApiService.updatePlan(widget.plan!.id, data);
    } else {
      final newPlan = SubscriptionPlan(
        id: 0,
        name: data['name'] as String,
        slug: data['slug'] as String,
        description: data['description'] as String?,
        price: data['price'] as double,
        billingPeriod: data['billing_period'] as String,
        features: data['features'] as List<String>,
        proposalLimit: data['proposal_limit'] as int?,
        activeProjectLimit: data['active_project_limit'] as int?,
        aiInsights: data['ai_insights'] as bool,
        prioritySupport: data['priority_support'] as bool,
        apiAccess: data['api_access'] as bool,
        customBranding: data['custom_branding'] as bool,
        trialDays: data['trial_days'] as int,
        sortOrder: data['sort_order'] as int,
        isRecommended: data['is_recommended'] as bool,
        isActive: true,
      );
      result = await ApiService.createPlan(newPlan);
    }

    if (result != null) {
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.plan != null ? t.planUpdatedSuccess : t.planCreatedSuccess,
          ),
          backgroundColor: Colors.black87,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.failedToSavePlan),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B88FF), Color(0xFF5B58E2)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.subscriptions_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            widget.plan != null ? t.editPlan : t.newPlan,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row([
                  _field(_nameCtrl, t.planName, required: true, isDark: isDark),
                  _field(_slugCtrl, t.slugExample, required: true, isDark: isDark),
                ]),
                _field(_descCtrl, t.description, maxLines: 2, isDark: isDark),
                _row([
                  _field(
                    _priceCtrl,
                    t.price,
                    keyboardType: TextInputType.number,
                    required: true,
                    validator: (v) => double.tryParse(v ?? '') == null
                        ? t.invalidNumber
                        : null,
                    isDark: isDark,
                  ),
                  _dropdown(
                    t.billingPeriod,
                    _billingPeriod,
                    ['monthly', 'yearly'],
                    (v) => setState(() => _billingPeriod = v!),
                    isDark,
                  ),
                ]),
                _row([
                  _field(
                    _proposalLimitCtrl,
                    t.proposalLimitEmpty,
                    keyboardType: TextInputType.number,
                    isDark: isDark,
                  ),
                  _field(
                    _activeProjectLimitCtrl,
                    t.projectLimitEmpty,
                    keyboardType: TextInputType.number,
                    isDark: isDark,
                  ),
                ]),
                _row([
                  _field(
                    _trialCtrl,
                    t.trialDays,
                    keyboardType: TextInputType.number,
                    isDark: isDark,
                  ),
                  _field(
                    _sortCtrl,
                    t.sortOrder,
                    keyboardType: TextInputType.number,
                    isDark: isDark,
                  ),
                ]),
                const SizedBox(height: 8),
                Text(
                  t.features,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.grey.shade400 : const Color(0xFF555555),
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    ..._switches(t,isDark),
                    _switchChip(
                      t.recommended,
                      _isRecommended,
                      (v) => setState(() => _isRecommended = v),
                      isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  t.customFeatures,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.grey.shade400 : const Color(0xFF555555),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: _field(_featureInputCtrl, t.addFeature, isDark: isDark),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        final f = _featureInputCtrl.text.trim();
                        if (f.isNotEmpty) {
                          setState(() {
                            _features.add(f);
                            _featureInputCtrl.clear();
                          });
                        }
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_features.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _features.asMap().entries.map((e) => Chip(
                      label: Text(
                        e.value,
                        style: const TextStyle(fontSize: 11),
                      ),
                      onDeleted: () => setState(() => _features.removeAt(e.key)),
                      deleteIconColor: Colors.grey.shade500,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: isDark ? AppTheme.AppColors.darkSurface : null,
                    )).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            t.cancel,
            style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(
            t.savePlan,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
  
  List<Widget> _switches(AppLocalizations t, bool isDark) => [
    _switchChip(t.aiInsights, _aiInsights, (v) => setState(() => _aiInsights = v), isDark),
    _switchChip(t.prioritySupport, _prioritySupport, (v) => setState(() => _prioritySupport = v), isDark),
    _switchChip(t.apiAccess, _apiAccess, (v) => setState(() => _apiAccess = v), isDark),
    _switchChip(t.customBranding, _customBranding, (v) => setState(() => _customBranding = v), isDark),
  ];

  Widget _switchChip(String label, bool value, ValueChanged<bool> onChange, bool isDark) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => onChange(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: value
              ? theme.colorScheme.primary.withOpacity(0.1)
              : (isDark ? AppTheme.AppColors.darkSurface : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value ? theme.colorScheme.primary.withOpacity(0.3) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              size: 14,
              color: value ? theme.colorScheme.primary : Colors.grey.shade400,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: value ? theme.colorScheme.primary : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                fontWeight: value ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: children
            .map((w) => Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: w,
            )))
            .toList(),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    int? maxLines,
    TextInputType? keyboardType,
    bool required = false,
    FormFieldValidator<String>? validator,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines ?? 1,
        keyboardType: keyboardType,
        validator: validator ?? (required
            ? (v) => v == null || v.isEmpty ? (AppLocalizations.of(context)?.requiredField ?? 'Required') : null
            : null),
        style: TextStyle(
          color: isDark ? Colors.white : AppTheme.AppColors.lightTextPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF5B58E2)),
          ),
          filled: true,
          fillColor: isDark ? AppTheme.AppColors.darkSurface : const Color(0xFFF8F8F8),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          isDense: true,
        ),
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
    bool isDark,
  ) {
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF5B58E2)),
          ),
          filled: true,
          fillColor: isDark ? AppTheme.AppColors.darkSurface : const Color(0xFFF8F8F8),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          isDense: true,
        ),
        dropdownColor: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.white : AppTheme.AppColors.lightTextPrimary,
        ),
        items: options.map((o) => DropdownMenuItem(
          value: o,
          child: Text(
            o == 'monthly' ? t.monthly : t.yearly,
            style: const TextStyle(fontSize: 13),
          ),
        )).toList(),
        onChanged: onChanged,
      ),
    );
  }
}