import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class CreateAdCampaignScreen extends StatefulWidget {
  const CreateAdCampaignScreen({super.key});

  @override
  State<CreateAdCampaignScreen> createState() => _CreateAdCampaignScreenState();
}

class _CreateAdCampaignScreenState extends State<CreateAdCampaignScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _targetUrlController = TextEditingController();
  final _ctaTextController = TextEditingController();
  final _budgetController = TextEditingController();

  String _adType = 'banner';
  String _pricingModel = 'cpc';
  String _placement = 'home_top';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  double _cpc = 0.10;
  double _cpm = 1.00;
  bool _isLoading = false;

  final List<String> _adTypes = ['banner', 'sidebar', 'popup', 'native'];
  final List<String> _pricingModels = ['cpc', 'cpm', 'flat'];
  final List<String> _placements = [
    'home_top',
    'home_bottom',
    'sidebar_top',
    'sidebar_bottom',
    'search_results',
    'project_page',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _targetUrlController.dispose();
    _ctaTextController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final t = AppLocalizations.of(context)!;
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: isStart ? t.selectStartDate : t.selectEndDate,
      cancelText: t.cancel,
      confirmText: t.ok,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 30));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _createCampaign() async {
    final t = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'ad_type': _adType,
      'placement': _placement,
      'title': _nameController.text.trim(),
      'description_text': _descriptionController.text.trim(),
      'image_url': _imageUrlController.text.trim(),
      'target_url': _targetUrlController.text.trim(),
      'cta_text': _ctaTextController.text.trim(),
      'pricing_model': _pricingModel,
      'cost_per_click': _cpc,
      'cost_per_impression': _cpm,
      'total_budget': double.parse(_budgetController.text),
      'start_date': _startDate.toIso8601String().split('T')[0],
      'end_date': _endDate.toIso8601String().split('T')[0],
    };

    try {
      final response = await ApiService.createAdCampaign(data);
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.campaignCreated),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? t.failedToCreate),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${t.error}: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getAdTypeLabel(String type, AppLocalizations t) {
    switch (type) {
      case 'banner':
        return t.banner;
      case 'sidebar':
        return t.sidebar;
      case 'popup':
        return t.popup;
      case 'native':
        return t.native;
      default:
        return type;
    }
  }

  String _getPlacementLabel(String placement, AppLocalizations t) {
    switch (placement) {
      case 'home_top':
        return t.homeTop;
      case 'home_bottom':
        return t.homeBottom;
      case 'sidebar_top':
        return t.sidebarTop;
      case 'sidebar_bottom':
        return t.sidebarBottom;
      case 'search_results':
        return t.searchResults;
      case 'project_page':
        return t.projectPage;
      default:
        return placement;
    }
  }

  String _getPricingLabel(String model, AppLocalizations t) {
    switch (model) {
      case 'cpc':
        return t.cpc;
      case 'cpm':
        return t.cpm;
      case 'flat':
        return t.flat;
      default:
        return model;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: Text(t.createAdCampaign),
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(t.campaignInfo, isDark, [
                _buildTextField(
                  _nameController,
                  t.campaignName,
                  required: true,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  _descriptionController,
                  t.description,
                  maxLines: 3,
                  isDark: isDark,
                ),
              ]),
              const SizedBox(height: 16),

              _buildSection(t.adContent, isDark, [
                _buildTextField(
                  _imageUrlController,
                  t.imageUrl,
                  hint: 'https://...',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  _targetUrlController,
                  t.targetUrl,
                  hint: 'https://...',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  _ctaTextController,
                  t.buttonText,
                  isDark: isDark,
                ),
              ]),
              const SizedBox(height: 16),

              _buildSection(t.adSettings, isDark, [
                _buildDropdown(t.adType, _adType, _adTypes, (newValue) {
                  if (newValue != null) {
                    setState(() => _adType = newValue);
                  }
                }, isDark),
                const SizedBox(height: 12),
                _buildDropdown(t.placement, _placement, _placements, (
                  newValue,
                ) {
                  if (newValue != null) {
                    setState(() => _placement = newValue);
                  }
                }, isDark),
                const SizedBox(height: 12),
                _buildDropdown(t.pricingModel, _pricingModel, _pricingModels, (
                  newValue,
                ) {
                  if (newValue != null) {
                    setState(() => _pricingModel = newValue);
                  }
                }, isDark),
              ]),
              const SizedBox(height: 16),

              if (_pricingModel == 'cpc')
                _buildSection(t.cpcSettings, isDark, [
                  _buildSlider(
                    '${t.costPerClick} (\$)',
                    _cpc,
                    0.05,
                    2.0,
                    (v) => setState(() => _cpc = v),
                    isDark,
                  ),
                ]),
              if (_pricingModel == 'cpm')
                _buildSection(t.cpmSettings, isDark, [
                  _buildSlider(
                    '${t.costPerThousand} (\$)',
                    _cpm,
                    0.50,
                    20.0,
                    (v) => setState(() => _cpm = v),
                    isDark,
                  ),
                ]),
              const SizedBox(height: 16),

              _buildSection(t.budgetAndDates, isDark, [
                _buildTextField(
                  _budgetController,
                  t.totalBudget,
                  keyboardType: TextInputType.number,
                  required: true,
                  prefix: '\$',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildDatePicker(
                  t.startDate,
                  _startDate,
                  () => _selectDate(context, true),
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildDatePicker(
                  t.endDate,
                  _endDate,
                  () => _selectDate(context, false),
                  isDark,
                ),
              ]),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createCampaign,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.primaryDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          t.createCampaign,
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t.paymentInfoMessage,
                        style: TextStyle(fontSize: 12, color: AppColors.info),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : Colors.black87,
              ),
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.primaryDark : Colors.grey.shade200,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label, {
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool required = false,
    String? prefix,
    required bool isDark,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: required
          ? (v) => v == null || v.isEmpty
                ? '${AppLocalizations.of(context)!.required}'
                : null
          : null,
      style: TextStyle(
        color: isDark ? AppColors.darkTextPrimary : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
        ),
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade400,
        ),
        prefixText: prefix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.primaryDark : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.primaryDark : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : Colors.white,
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
    bool isDark,
  ) {
    final t = AppLocalizations.of(context)!;

    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.primaryDark : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.primaryDark : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : Colors.white,
      ),
      dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
      style: TextStyle(
        color: isDark ? AppColors.darkTextPrimary : Colors.black87,
      ),
      items: items.map((item) {
        String displayText;
        if (items == _adTypes) {
          displayText = _getAdTypeLabel(item, t);
        } else if (items == _placements) {
          displayText = _getPlacementLabel(item, t);
        } else {
          displayText = _getPricingLabel(item, t);
        }
        return DropdownMenuItem<String>(value: item, child: Text(displayText));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: \$${value.toStringAsFixed(3)}',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : Colors.black87,
          ),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: 100,
          activeColor: AppColors.accent,
          inactiveColor: isDark ? AppColors.primaryDark : Colors.grey.shade300,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDatePicker(
    String label,
    DateTime date,
    VoidCallback onTap,
    bool isDark,
  ) {
    final t = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? AppColors.primaryDark : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isDark ? AppColors.darkSurface : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 18,
              color: isDark ? AppColors.darkTextSecondary : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                DateFormat.yMMMd(t.localeName).format(date),
                style: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: isDark ? AppColors.darkTextSecondary : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
