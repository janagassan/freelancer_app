// lib/screens/admin/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart' as AppTheme;
import '../../providers/theme_provider.dart';
import '../../services/language_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AdminSettingsScreen extends StatefulWidget {
  final Function(Locale)? onLocaleChange;

  const AdminSettingsScreen({super.key, this.onLocaleChange});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedTab = 0;

  bool _maintenanceMode = false;
  bool _allowNewRegistrations = true;
  bool _autoVerifyEmail = false;
  bool _sendWeeklyReports = true;
  bool _flagHighRiskPayments = true;
  
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); 
    _tabController.addListener(
      () => setState(() => _selectedTab = _tabController.index),
    );
    _loadSavedLanguage();
  }
  
  Future<void> _loadSavedLanguage() async {
    final savedLocale = await LanguageService.getSavedLocale();
    setState(() {
      _selectedLanguage = savedLocale.languageCode;
    });
  }

  Future<void> _changeLanguage(String languageCode) async {
    final newLocale = Locale(languageCode);
    await LanguageService.setLocale(newLocale);
    
    setState(() {
      _selectedLanguage = languageCode;
    });
    
    if (widget.onLocaleChange != null) {
      widget.onLocaleChange!(newLocale);
    }
    
    Fluttertoast.showToast(
      msg: languageCode == 'ar'
          ? 'تم تغيير اللغة إلى العربية'
          : 'Language changed to English',
      gravity: ToastGravity.BOTTOM,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.AppColors.darkBackground
          : const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: Text(
          t.adminSettings,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildTabBar(t, isDark),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGeneralSettings(t, isDark),
                _buildSecuritySettings(t, isDark),
                _buildNotificationSettings(t, isDark),
                _buildAppearanceSettings(t, isDark, themeProvider), 
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppLocalizations t, bool isDark) {
    return Container(
      color: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              _buildTab(
                index: 0,
                label: t.general,
                icon: Icons.tune_rounded,
                color: const Color(0xFF5B58E2),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildTab(
                index: 1,
                label: t.security,
                icon: Icons.shield_outlined,
                color: const Color(0xFF14A800),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildTab(
                index: 2,
                label: t.notifications,
                icon: Icons.notifications_outlined,
                color: const Color(0xFFF59E0B),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildTab(
                index: 3,
                label: t.appearance,
                icon: Icons.palette_outlined,
                color: const Color(0xFF9C27B0),
                isDark: isDark,
              ),
            ],
          ),
          Divider(
            height: 1,
            color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade100,
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required int index,
    required String label,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    final selected = _selectedTab == index;
    return GestureDetector(
      onTap: () => _tabController.animateTo(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                )
              : null,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          border: Border(
            top: BorderSide(color: selected ? color : Colors.transparent, width: 2),
            left: BorderSide(
              color: selected ? color.withOpacity(0.2) : Colors.transparent,
            ),
            right: BorderSide(
              color: selected ? color.withOpacity(0.2) : Colors.transparent,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? color : Colors.grey.shade500),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                color: selected ? color : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSettings(
    AppLocalizations t, 
    bool isDark, 
    ThemeProvider themeProvider
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(t.appearance, Icons.palette_outlined, const Color(0xFF9C27B0), isDark),
          const SizedBox(height: 12),
          
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade100,
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF9C27B0).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.dark_mode, size: 18, color: Color(0xFF9C27B0)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.darkMode,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF1A1B3E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              t.switchTheme,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: themeProvider.isDarkMode,
                        onChanged: (_) => themeProvider.toggleTheme(),
                        activeColor: const Color(0xFF5B58E2),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF9C27B0).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.brightness_auto, size: 18, color: Color(0xFF9C27B0)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.useSystemTheme,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF1A1B3E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              t.followSystemTheme,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: themeProvider.themeMode == ThemeMode.system,
                        onChanged: (value) {
                          if (value) {
                            themeProvider.setThemeMode(ThemeMode.system);
                          }
                        },
                        activeColor: const Color(0xFF5B58E2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          _sectionHeader(t.language, Icons.language_outlined, const Color(0xFF9C27B0), isDark),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade100,
              ),
            ),
            child: InkWell(
              onTap: () => _showLanguageDialog(context),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF9C27B0).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.language_outlined, size: 18, color: Color(0xFF9C27B0)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.language,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF1A1B3E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedLanguage == 'ar' ? 'العربية' : 'English (US)',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇺🇸'),
              title: const Text('English (US)'),
              trailing: _selectedLanguage == 'en'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _changeLanguage('en');
              },
            ),
            ListTile(
              leading: const Text('🇸🇦'),
              title: const Text('العربية'),
              trailing: _selectedLanguage == 'ar'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _changeLanguage('ar');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSettings(AppLocalizations t, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(t.platformControls, Icons.settings_suggest_rounded, const Color(0xFF5B58E2), isDark),
          const SizedBox(height: 12),
          _settingsCard(isDark, [
            _switchTile(
              t.maintenanceMode,
              t.maintenanceModeDesc,
              Icons.construction_rounded,
              Colors.orange,
              _maintenanceMode,
              (v) => setState(() => _maintenanceMode = v),
              isDark,
            ),
            _divider(isDark),
            _switchTile(
              t.allowNewRegistrations,
              t.allowNewRegistrationsDesc,
              Icons.person_add_outlined,
              const Color(0xFF14A800),
              _allowNewRegistrations,
              (v) => setState(() => _allowNewRegistrations = v),
              isDark,
            ),
          ]),

          const SizedBox(height: 20),
          _sectionHeader(t.defaultConfiguration, Icons.dashboard_customize_outlined, const Color(0xFF5B58E2), isDark),
          const SizedBox(height: 12),
          _settingsCard(isDark, [
            _arrowTile(t.defaultClientPlan, 'Starter', Icons.subscriptions_outlined, const Color(0xFF5B58E2), isDark),
            _divider(isDark),
            _arrowTile(t.defaultFreelancerVisibility, 'Public', Icons.visibility_outlined, const Color(0xFF14A800), isDark),
            _divider(isDark),
            _arrowTile(t.platformCommissionRate, '10%', Icons.percent_rounded, Colors.orange, isDark),
          ]),

          const SizedBox(height: 20),
          _sectionHeader(t.appearance, Icons.palette_outlined, const Color(0xFF5B58E2), isDark),
          const SizedBox(height: 12),
          _settingsCard(isDark, [
            _arrowTile(t.platformTheme, t.defaultTheme, Icons.color_lens_outlined, Colors.purple, isDark),
            _divider(isDark),
            _arrowTile(t.logoBranding, t.configured, Icons.image_outlined, Colors.blue, isDark),
          ]),
        ],
      ),
    );
  }

  Widget _buildSecuritySettings(AppLocalizations t, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(t.verification, Icons.verified_user_outlined, const Color(0xFF14A800), isDark),
          const SizedBox(height: 12),
          _settingsCard(isDark, [
            _switchTile(
              t.autoVerifyEmail,
              t.autoVerifyEmailDesc,
              Icons.mark_email_read_outlined,
              const Color(0xFF14A800),
              _autoVerifyEmail,
              (v) => setState(() => _autoVerifyEmail = v),
              isDark,
            ),
            _divider(isDark),
            _switchTile(
              t.flagHighRiskPayments,
              t.flagHighRiskPaymentsDesc,
              Icons.security_outlined,
              Colors.red,
              _flagHighRiskPayments,
              (v) => setState(() => _flagHighRiskPayments = v),
              isDark,
            ),
          ]),

          const SizedBox(height: 20),
          _sectionHeader(t.accessRules, Icons.admin_panel_settings_outlined, const Color(0xFF14A800), isDark),
          const SizedBox(height: 12),
          _settingsCard(isDark, [
            _arrowTile(t.adminSessionTimeout, '45 minutes', Icons.timer_outlined, Colors.orange, isDark),
            _divider(isDark),
            _arrowTile(t.twoFactorAuth, t.requiredForAdmins, Icons.phonelink_lock_outlined, const Color(0xFF5B58E2), isDark),
            _divider(isDark),
            _arrowTile(t.ipWhitelist, t.notConfigured, Icons.language_outlined, Colors.grey, isDark),
          ]),

          const SizedBox(height: 20),
          _buildSecurityStatusCard(t, isDark),
        ],
      ),
    );
  }

  Widget _buildSecurityStatusCard(AppLocalizations t, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF14A800).withOpacity(isDark ? 0.15 : 0.08),
            const Color(0xFF14A800).withOpacity(isDark ? 0.05 : 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF14A800).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF14A800), Color(0xFF0A6E00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.securityStatusGood,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1A1B3E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t.securityStatusDesc,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade500 : const Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings(AppLocalizations t, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(t.adminAlerts, Icons.notifications_active_outlined, const Color(0xFFF59E0B), isDark),
          const SizedBox(height: 12),
          _settingsCard(isDark, [
            _switchTile(
              t.weeklyPerformanceReport,
              t.weeklyPerformanceReportDesc,
              Icons.assessment_outlined,
              const Color(0xFFF59E0B),
              _sendWeeklyReports,
              (v) => setState(() => _sendWeeklyReports = v),
              isDark,
            ),
            _divider(isDark),
            _arrowTile(t.criticalIncidentAlerts, t.emailInApp, Icons.warning_amber_rounded, Colors.red, isDark),
            _divider(isDark),
            _arrowTile(t.disputeEscalationAlerts, t.instantPush, Icons.gavel_rounded, Colors.orange, isDark),
            _divider(isDark),
            _arrowTile(t.newUserRegistrations, t.dailyDigest, Icons.person_add_outlined, const Color(0xFF5B58E2), isDark),
          ]),

          const SizedBox(height: 20),
          _sectionHeader(t.emailConfiguration, Icons.email_outlined, const Color(0xFFF59E0B), isDark),
          const SizedBox(height: 12),
          _settingsCard(isDark, [
            _arrowTile(t.smtpSettings, t.configured, Icons.settings_outlined, const Color(0xFF14A800), isDark),
            _divider(isDark),
            _arrowTile(t.emailTemplates, '12 ${t.templates}', Icons.description_outlined, const Color(0xFF5B58E2), isDark),
            _divider(isDark),
            _arrowTile(t.senderNameAddress, t.platformAdmin, Icons.alternate_email_rounded, Colors.grey, isDark),
          ]),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1A1B3E),
          ),
        ),
      ],
    );
  }

  Widget _settingsCard(bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 1,
      indent: 20,
      endIndent: 20,
      color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade100,
    );
  }

  Widget _switchTile(
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
    bool value,
    ValueChanged<bool> onChanged,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A1B3E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF5B58E2),
          ),
        ],
      ),
    );
  }

  Widget _arrowTile(
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A1B3E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            size: 20,
          ),
        ],
      ),
    );
  }
}