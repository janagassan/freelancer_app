// screens/admin/coupons_management_tab.dart

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../models/coupon_model.dart';
import '../../theme/app_theme.dart' as AppTheme;

class CouponsManagementTab extends StatefulWidget {
  const CouponsManagementTab({super.key});

  @override
  State<CouponsManagementTab> createState() => _CouponsManagementTabState();
}

class _CouponsManagementTabState extends State<CouponsManagementTab> {
  List<Coupon> _coupons = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final coupons = await ApiService.getAdminCoupons();
      setState(() {
        _coupons = coupons;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '${AppLocalizations.of(context)?.failedToLoadCoupons}: $e';
        _loading = false;
      });
    }
  }

  Future<void> _deleteCoupon(Coupon coupon) async {
    final t = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          t.deleteCoupon,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(t.deleteCouponConfirmation(coupon.code)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
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
            child: Text(t.delete),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final success = await ApiService.deleteCoupon(coupon.id);
    if (success) {
      _loadCoupons();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.couponDeleted),
          backgroundColor: Colors.black87,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.failedToDeleteCoupon),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCouponDialog({Coupon? coupon}) {
    showDialog(
      context: context,
      builder: (ctx) => CouponFormDialog(coupon: coupon, onSaved: _loadCoupons),
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
              onPressed: _loadCoupons,
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
                '${_coupons.length} ${_coupons.length == 1 ? t.coupon : t.coupons}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey.shade500 : const Color(0xFF888888),
                ),
              ),
              const Spacer(),
              _buildAddButton(t.newCoupon, () => _showCouponDialog(), isDark),
            ],
          ),
        ),
        Expanded(
          child: _coupons.isEmpty
              ? _buildEmpty(t, isDark)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: _coupons.length,
                  itemBuilder: (_, i) => _buildCouponCard(_coupons[i], t, isDark),
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
            colors: [Color(0xFFF59E0B), Color(0xFFB45309)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withOpacity(0.35),
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

  Widget _buildCouponCard(Coupon coupon, AppLocalizations t, bool isDark) {
    final theme = Theme.of(context);
    final isExpired = coupon.validUntil.isBefore(DateTime.now());
    final isActive = coupon.isActive && !isExpired;
    final usage = coupon.maxUses != null
        ? '${coupon.usedCount}/${coupon.maxUses} ${t.used}'
        : '${coupon.usedCount} ${t.used}';
    final isPercentage = coupon.discountType == 'percentage';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? const Color(0xFFF59E0B).withOpacity(0.3)
              : (isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade100),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 12,
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
              gradient: isActive
                  ? LinearGradient(
                      colors: [
                        const Color(0xFFF59E0B).withOpacity(0.1),
                        const Color(0xFFF59E0B).withOpacity(0.02),
                      ],
                    )
                  : LinearGradient(
                      colors: isDark
                          ? [AppTheme.AppColors.darkSurface, AppTheme.AppColors.darkSurface]
                          : [Colors.grey.shade50, Colors.grey.shade50],
                    ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFB45309)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isActive ? null : (isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_offer_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        coupon.code,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coupon.formattedDiscount,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isActive
                              ? (isDark ? Colors.white : const Color(0xFF1A1B3E))
                              : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                        ),
                      ),
                      Text(
                        isPercentage ? t.percentageDiscount : t.fixedAmountOff,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.AppColors.darkSurface : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isExpired ? t.expired : t.inactive,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                _iconBtn(
                  Icons.edit_outlined,
                  theme.colorScheme.primary,
                  () => _showCouponDialog(coupon: coupon),
                  isDark,
                ),
                const SizedBox(width: 6),
                _iconBtn(
                  Icons.delete_outline,
                  Colors.red.shade400,
                  () => _deleteCoupon(coupon),
                  isDark,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _infoItem(Icons.calendar_today_outlined, '${_fmtDate(coupon.validFrom)} - ${_fmtDate(coupon.validUntil)}', isDark),
                _infoItem(Icons.people_outline_rounded, usage, isDark),
                _infoItem(Icons.category_outlined, _getScopeLabel(coupon.applicationScope, t), isDark),
                if (coupon.applicablePlans != null && coupon.applicablePlans!.isNotEmpty)
                  ...coupon.applicablePlans!.map(
                    (plan) => Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.15),
                        ),
                      ),
                      child: Text(
                        plan,
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
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

  String _getScopeLabel(String scope, AppLocalizations t) {
    switch (scope) {
      case 'contract':
        return t.contracts;
      case 'both':
        return t.all;
      default:
        return t.subscriptions;
    }
  }

  Widget _infoItem(IconData icon, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

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
              Icons.local_offer_outlined,
              size: 40,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t.noCouponsYet,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 20),
          _buildAddButton(t.createFirstCoupon, () => _showCouponDialog(), isDark),
        ],
      ),
    );
  }
}


class CouponFormDialog extends StatefulWidget {
  final Coupon? coupon;
  final VoidCallback onSaved;

  const CouponFormDialog({super.key, this.coupon, required this.onSaved});

  @override
  State<CouponFormDialog> createState() => _CouponFormDialogState();
}

class _CouponFormDialogState extends State<CouponFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeCtrl, _discountCtrl, _maxUsesCtrl;
  late String _discountType, _applicationScope;
  late DateTime _validFrom, _validUntil;
  late List<String> _applicablePlans;
  late bool _isActive;
  final _planInputCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController(text: widget.coupon?.code ?? '');
    _discountType = widget.coupon?.discountType ?? 'percentage';
    _discountCtrl = TextEditingController(
      text: widget.coupon?.discountValue.toString() ?? '',
    );
    _validFrom = widget.coupon?.validFrom ?? DateTime.now();
    _validUntil = widget.coupon?.validUntil ?? DateTime.now().add(const Duration(days: 30));
    _maxUsesCtrl = TextEditingController(
      text: widget.coupon?.maxUses?.toString() ?? '',
    );
    _applicablePlans = List<String>.from(widget.coupon?.applicablePlans ?? []);
    _isActive = widget.coupon?.isActive ?? true;
    _applicationScope = widget.coupon?.applicationScope ?? 'subscription';
  }

  @override
  void dispose() {
    for (final c in [_codeCtrl, _discountCtrl, _maxUsesCtrl, _planInputCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final t = AppLocalizations.of(context)!;
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _validFrom : _validUntil,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      helpText: t.selectDate,
      cancelText: t.cancel,
      confirmText: t.ok,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _validFrom = picked;
          if (_validUntil.isBefore(_validFrom)) {
            _validUntil = _validFrom.add(const Duration(days: 30));
          }
        } else {
          _validUntil = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'code': _codeCtrl.text.trim().toUpperCase(),
      'discount_type': _discountType,
      'discount_value': double.parse(_discountCtrl.text),
      'valid_from': _validFrom.toIso8601String().split('T')[0],
      'valid_until': _validUntil.toIso8601String().split('T')[0],
      'max_uses': _maxUsesCtrl.text.trim().isEmpty ? null : int.parse(_maxUsesCtrl.text),
      'applicable_plans': _applicablePlans.isEmpty ? null : _applicablePlans,
      'is_active': _isActive,
      'application_scope': _applicationScope,
    };

    Coupon? result;
    if (widget.coupon != null) {
      result = await ApiService.updateCoupon(widget.coupon!.id, data);
    } else {
      result = await ApiService.createCoupon(data);
    }

    if (result != null) {
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.coupon != null ? t.couponUpdatedSuccess : t.couponCreatedSuccess),
          backgroundColor: Colors.black87,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.failedToSaveCoupon),
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
                colors: [Color(0xFFF59E0B), Color(0xFFB45309)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.local_offer_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            widget.coupon != null ? t.editCoupon : t.newCoupon,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field(_codeCtrl, t.couponCodeRequired, required: true, isDark: isDark),
                Row(
                  children: [
                    Expanded(
                      child: _dropdown(
                        t.discountType,
                        _discountType,
                        {
                          'percentage': '${t.percentage} (%)',
                          'fixed': '${t.fixedAmount} (\$)',
                        },
                        (v) => setState(() => _discountType = v!),
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _field(
                        _discountCtrl,
                        '${t.value} *',
                        keyboardType: TextInputType.number,
                        required: true,
                        validator: (v) => double.tryParse(v ?? '') == null ? t.invalidNumber : null,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                _dropdown(
                  t.appliesTo,
                  _applicationScope,
                  {
                    'subscription': t.subscriptionOnly,
                    'contract': t.contractEscrow,
                    'both': t.both,
                  },
                  (v) => setState(() => _applicationScope = v!),
                  isDark,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _datePicker(
                        t.validFrom,
                        _validFrom,
                        () => _selectDate(context, true),
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _datePicker(
                        t.validUntil,
                        _validUntil,
                        () => _selectDate(context, false),
                        isDark,
                      ),
                    ),
                  ],
                ),
                _field(
                  _maxUsesCtrl,
                  t.maxUsesEmpty,
                  keyboardType: TextInputType.number,
                  isDark: isDark,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.AppColors.darkCard : const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        t.active,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Switch.adaptive(
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                        activeColor: const Color(0xFF14A800),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t.applicablePlansOptional,
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
                      child: _field(_planInputCtrl, t.planSlugExample, isDark: isDark),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        final p = _planInputCtrl.text.trim();
                        if (p.isNotEmpty && !_applicablePlans.contains(p)) {
                          setState(() {
                            _applicablePlans.add(p);
                            _planInputCtrl.clear();
                          });
                        }
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
                if (_applicablePlans.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _applicablePlans.map((p) => Chip(
                      label: Text(p, style: const TextStyle(fontSize: 11)),
                      onDeleted: () => setState(() => _applicablePlans.remove(p)),
                      backgroundColor: isDark ? AppTheme.AppColors.darkSurface : null,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
            backgroundColor: const Color(0xFFF59E0B),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(
            t.saveCoupon,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    TextInputType? keyboardType,
    bool required = false,
    FormFieldValidator<String>? validator,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: TextStyle(color: isDark ? Colors.white : AppTheme.AppColors.lightTextPrimary),
        validator: validator ?? (required
            ? (v) => v == null || v.isEmpty ? (AppLocalizations.of(context)?.requiredField ?? 'Required') : null
            : null),
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
            borderSide: const BorderSide(color: Color(0xFFF59E0B)),
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
    Map<String, String> options,
    ValueChanged<String?> onChanged,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        value: value,
        dropdownColor: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
        style: TextStyle(
          fontSize: 13,
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
            borderSide: const BorderSide(color: Color(0xFFF59E0B)),
          ),
          filled: true,
          fillColor: isDark ? AppTheme.AppColors.darkSurface : const Color(0xFFF8F8F8),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          isDense: true,
        ),
        items: options.entries.map((e) => DropdownMenuItem(
          value: e.key,
          child: Text(e.value, style: const TextStyle(fontSize: 13)),
        )).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _datePicker(String label, DateTime date, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.AppColors.darkSurface : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${date.day}/${date.month}/${date.year}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : AppTheme.AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}