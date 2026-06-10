// lib/screens/settings/settings_screen.dart 

import 'package:flutter/material.dart';
import 'package:freelancer_platform/models/freelancer_model.dart';
import 'package:freelancer_platform/services/api_service.dart';
import 'package:freelancer_platform/services/language_service.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../freelancer/edit_profile_screen.dart';
import '../client/edit_client_profile_screen.dart';
import '../auth/login_screen.dart';
import 'package:share_plus/share_plus.dart';
import '../../utils/token_storage.dart';

class SettingsScreen extends StatefulWidget {
  final Function(Locale)? onLocaleChange;

  const SettingsScreen({super.key, this.onLocaleChange});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'en';
  String _selectedCurrency = 'USD';
  bool _isLoading = false;
  String? _userRole;
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
    _loadUserFromStorage();
  }

  Future<void> _loadUserFromStorage() async {
    try {
      final user = await TokenStorage.getUser();
      final role = await TokenStorage.getUserRole();
      setState(() {
        _currentUser = user;
        _userRole = role;
      });
      print('✅ User loaded from storage: ${user?['name']}, Role: $role');
    } catch (e) {
      print('Error loading user from storage: $e');
    }
  }

  Future<void> _loadSavedSettings() async {
    final savedLocale = await LanguageService.getSavedLocale();
    setState(() {
      _selectedLanguage = savedLocale.languageCode;
    });
  }

  Future<void> _changeLanguage(String languageCode) async {
    setState(() => _isLoading = true);

    final newLocale = Locale(languageCode);
    await LanguageService.setLocale(newLocale);

    setState(() {
      _selectedLanguage = languageCode;
      _isLoading = false;
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

  void _navigateToEditProfile() {
    if (_userRole == 'freelancer') {
      final profile = FreelancerProfile(
        id: _currentUser?['id'] ?? 0,
        name: _currentUser?['name'] ?? '',
        email: _currentUser?['email'] ?? '',
        avatar: _currentUser?['avatar'],
        title: _currentUser?['title'],
        bio: _currentUser?['bio'],
        location: _currentUser?['location'],
        hourlyRate: _currentUser?['hourly_rate']?.toDouble(),
        skills: _currentUser?['skills'] is List 
            ? List<String>.from(_currentUser!['skills']) 
            : [],
        languages: _currentUser?['languages'] is List 
            ? List<String>.from(_currentUser!['languages']) 
            : [],
        education: _currentUser?['education'] is List 
            ? List<Map<String, dynamic>>.from(_currentUser!['education']) 
            : [],
        certifications: _currentUser?['certifications'] is List 
            ? List<Map<String, dynamic>>.from(_currentUser!['certifications']) 
            : [],
        cvUrl: _currentUser?['cv_url'],
        experienceYears: _currentUser?['experience_years'],
        weeklyHours: _currentUser?['weekly_hours'],
        availability: _currentUser?['availability'],
        rating: _currentUser?['rating']?.toDouble(),
        totalEarnings: _currentUser?['total_earnings']?.toDouble(),
        completedProjectsCount: _currentUser?['completed_projects_count'],
        jobSuccessScore: _currentUser?['job_success_score'],
        responseTime: _currentUser?['response_time'],
        website: _currentUser?['website'],
        github: _currentUser?['github'],
        linkedin: _currentUser?['linkedin'],
        behance: _currentUser?['behance'],
        locationCoordinates: _currentUser?['location_coordinates'],
        tagline: _currentUser?['tagline'],
      );
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditProfileScreen(profile: profile),
        ),
      ).then((_) => _loadUserFromStorage()); 
      
    } else if (_userRole == 'client') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const EditClientProfileScreen(),
        ),
      );
    } else {
      Fluttertoast.showToast(msg: 'Unable to determine user type');
    }
  }

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Fluttertoast.showToast(msg: 'Could not open link');
    }
  }

  void _shareApp() {
    Share.share(
      'Check out Freelancer Platform - Connect with freelancers and clients worldwide!',
    );
  }

  void _sendEmail() async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: 'support@freelancerplatform.com',
      query: 'subject=Support Request',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      Fluttertoast.showToast(msg: 'Could not open email client');
    }
  }

  void _openWhatsApp() async {
    final whatsappUri = Uri.parse('https://wa.me/1234567890');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      Fluttertoast.showToast(msg: 'WhatsApp is not installed');
    }
  }

  void _showRateDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.rateUs),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('If you enjoy using our app, please take a moment to rate it.'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.star_border, size: 32),
                  onPressed: () => _rateApp(1),
                ),
                IconButton(
                  icon: const Icon(Icons.star_border, size: 32),
                  onPressed: () => _rateApp(2),
                ),
                IconButton(
                  icon: const Icon(Icons.star_border, size: 32),
                  onPressed: () => _rateApp(3),
                ),
                IconButton(
                  icon: const Icon(Icons.star_border, size: 32),
                  onPressed: () => _rateApp(4),
                ),
                IconButton(
                  icon: const Icon(Icons.star_border, size: 32),
                  onPressed: () => _rateApp(5),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.cancel),
          ),
        ],
      ),
    );
  }

  void _rateApp(int rating) {
    Navigator.pop(context);
    Fluttertoast.showToast(msg: 'Thank you for rating $rating stars!');
    _openUrl('https://play.google.com/store/apps/details?id=com.freelancer.platform');
  }

  void _showAboutDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    showAboutDialog(
      context: context,
      applicationName: 'Freelancer Platform',
      applicationVersion: 'Version 1.0.0',
      applicationLegalese: '© 2024 Freelancer Platform',
      children: [
        const SizedBox(height: 16),
        Text(t.about),
        const SizedBox(height: 8),
        const Text('Connect freelancers with clients around the world.'),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.web, color: AppColors.primary),
              onPressed: () => _openUrl('https://freelancerplatform.com'),
            ),
            IconButton(
              icon: Icon(Icons.facebook, color: Colors.blue.shade700),
              onPressed: () => _openUrl('https://facebook.com/freelancerplatform'),
            ),
            IconButton(
              icon: Icon(Icons.chat, color: Colors.green),
              onPressed: () => _openUrl('https://twitter.com/freelancerplatform'),
            ),
            IconButton(
              icon: Icon(Icons.camera_alt, color: Colors.purple),
              onPressed: () => _openUrl('https://instagram.com/freelancerplatform'),
            ),
          ],
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.logout),
        content: Text(t.logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              await ApiService.logout();
              await TokenStorage.clearAll();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(t.logout),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t.settings), centerTitle: false, elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildSectionHeader(
                  context,
                  t.appearance,
                  Icons.palette_outlined,
                ),

                _buildSettingsTile(
                  context,
                  icon: isDark ? Icons.dark_mode : Icons.light_mode,
                  title: t.darkMode,
                  subtitle: t.switchTheme,
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (_) => themeProvider.toggleTheme(),
                    activeColor: AppColors.primary,
                  ),
                ),

                _buildSettingsTile(
                  context,
                  icon: Icons.brightness_auto,
                  title: t.useSystemTheme,
                  subtitle: t.followSystemTheme,
                  trailing: Switch(
                    value: themeProvider.themeMode == ThemeMode.system,
                    onChanged: (value) {
                      if (value) {
                        themeProvider.setThemeMode(ThemeMode.system);
                      }
                    },
                    activeColor: AppColors.primary,
                  ),
                ),

                const Divider(),

                _buildSectionHeader(context, t.account, Icons.person_outline),

                _buildSettingsTile(
                  context,
                  icon: Icons.edit_outlined,
                  title: t.editProfile,
                  subtitle: t.updatePersonalInfo,
                  onTap: _navigateToEditProfile,
                ),

                _buildSettingsTile(
  context,
  icon: Icons.lock_outline,
  title: t.changePassword,
  subtitle: t.updatePassword,
  onTap: () => Navigator.pushNamed(context, '/change-password'),
),

               

                const Divider(),

                _buildSectionHeader(
                  context,
                  t.preferences,
                  Icons.tune_outlined,
                ),

                _buildSettingsTile(
                  context,
                  icon: Icons.language_outlined,
                  title: t.language,
                  subtitle: _selectedLanguage == 'ar'
                      ? 'العربية'
                      : 'English (US)',
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => _showLanguageDialog(context),
                ),

                _buildSettingsTile(
                  context,
                  icon: Icons.attach_money,
                  title: t.currency,
                  subtitle: _getCurrencyText(),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => _showCurrencyDialog(context),
                ),

                const Divider(),

                _buildSectionHeader(
                  context,
                  t.support,
                  Icons.support_agent_outlined,
                ),

                _buildSettingsTile(
                  context,
                  icon: Icons.help_outline,
                  title: t.helpCenter,
                  subtitle: t.getHelpSupport,
                  onTap: () => _showHelpDialog(context),
                ),

                _buildSettingsTile(
                  context,
                  icon: Icons.description_outlined,
                  title: t.termsOfService,
                  subtitle: t.readTerms,
                  onTap: () => _showTermsDialog(context),
                ),

                _buildSettingsTile(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  title: t.privacyPolicy,
                  subtitle: t.readPrivacy,
                  onTap: () => _showPrivacyDialog(context),
                ),

                _buildSettingsTile(
                  context,
                  icon: Icons.email_outlined,
                  title: 'Contact Support',
                  subtitle: 'support@freelancerplatform.com',
                  onTap: _sendEmail,
                ),

                _buildSettingsTile(
                  context,
                  icon: Icons.share_outlined,
                  title: 'Share App',
                  subtitle: 'Share with friends',
                  onTap: _shareApp,
                ),


                const Divider(),

                _buildSectionHeader(context, t.about, Icons.info_outline),

                _buildSettingsTile(
                  context,
                  icon: Icons.info_outline,
                  title: t.about,
                  subtitle: 'Version 1.0.0',
                  onTap: () => _showAboutDialog(context),
                ),

                _buildSettingsTile(
                  context,
                  icon: Icons.web,
                  title: 'Website',
                  subtitle: 'www.freelancerplatform.com',
                  onTap: () => _openUrl('https://freelancerplatform.com'),
                ),

                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: OutlinedButton.icon(
                    onPressed: () => _showLogoutDialog(context),
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: Text(
                      t.logout,
                      style: const TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
    );
  }

  String _getCurrencyText() {
    switch (_selectedCurrency) {
      case 'USD':
        return 'USD - US Dollar';
      case 'EUR':
        return 'EUR - Euro';
      case 'GBP':
        return 'GBP - British Pound';
      default:
        return 'USD - US Dollar';
    }
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12)) : null,
      trailing:
          trailing ??
          (onTap != null ? const Icon(Icons.chevron_right, size: 20) : null),
      onTap: onTap,
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

  void _showCurrencyDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('USD - US Dollar'),
              trailing: _selectedCurrency == 'USD'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                setState(() => _selectedCurrency = 'USD');
                Navigator.pop(context);
                Fluttertoast.showToast(msg: 'Currency changed to USD');
              },
            ),
            ListTile(
              title: const Text('EUR - Euro'),
              trailing: _selectedCurrency == 'EUR'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                setState(() => _selectedCurrency = 'EUR');
                Navigator.pop(context);
                Fluttertoast.showToast(msg: 'Currency changed to EUR');
              },
            ),
            ListTile(
              title: const Text('GBP - British Pound'),
              trailing: _selectedCurrency == 'GBP'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                setState(() => _selectedCurrency = 'GBP');
                Navigator.pop(context);
                Fluttertoast.showToast(msg: 'Currency changed to GBP');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.helpCenter),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.help_outline, color: AppColors.primary),
              title: const Text('FAQs'),
              onTap: () {
                Navigator.pop(context);
                _openUrl('https://freelancerplatform.com/faq');
              },
            ),
            ListTile(
              leading: Icon(Icons.video_library, color: AppColors.primary),
              title: const Text('Video Tutorials'),
              onTap: () {
                Navigator.pop(context);
                _openUrl('https://youtube.com/freelancerplatform');
              },
            ),
            ListTile(
              leading: Icon(Icons.forum, color: AppColors.primary),
              title: const Text('Community Forum'),
              onTap: () {
                Navigator.pop(context);
                _openUrl('https://forum.freelancerplatform.com');
              },
            ),
            ListTile(
              leading: Icon(Icons.email, color: AppColors.primary),
              title: const Text('Email Support'),
              subtitle: const Text('support@freelancerplatform.com'),
              onTap: () {
                Navigator.pop(context);
                _sendEmail();
              },
            ),
            ListTile(
              leading: Icon(Icons.chat, color: Colors.green),
              title: const Text('WhatsApp Support'),
              subtitle: const Text('+1 234 567 890'),
              onTap: () {
                Navigator.pop(context);
                _openWhatsApp();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.close),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('1. Acceptance of Terms', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('By using Freelancer Platform, you agree to these terms.'),
              SizedBox(height: 12),
              Text('2. User Responsibilities', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Users must provide accurate information and comply with all applicable laws.'),
              SizedBox(height: 12),
              Text('3. Payments', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('All payments are processed securely. Platform fees apply.'),
              SizedBox(height: 12),
              Text('4. Disputes', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Disputes will be resolved through our dispute resolution process.'),
              SizedBox(height: 12),
              Text('5. Termination', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('We reserve the right to terminate accounts that violate these terms.'),
              SizedBox(height: 12),
              Text('For full terms, visit our website.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openUrl('https://freelancerplatform.com/terms');
            },
            child: const Text('Read Full Terms'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('1. Information Collection', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('We collect personal information to provide our services.'),
              SizedBox(height: 12),
              Text('2. Data Usage', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Your data is used to improve your experience and process transactions.'),
              SizedBox(height: 12),
              Text('3. Data Protection', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('We implement security measures to protect your information.'),
              SizedBox(height: 12),
              Text('4. Third Parties', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('We do not sell your personal information to third parties.'),
              SizedBox(height: 12),
              Text('5. Your Rights', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('You have the right to access and delete your data.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openUrl('https://freelancerplatform.com/privacy');
            },
            child: const Text('Read Full Policy'),
          ),
        ],
      ),
    );
  }
}