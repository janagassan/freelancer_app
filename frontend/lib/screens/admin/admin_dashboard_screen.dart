// lib/screens/admin/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:freelancer_platform/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:freelancer_platform/screens/admin/disputes_management_screen.dart';
import 'package:freelancer_platform/screens/admin/subscription_management_screen.dart';
import 'package:freelancer_platform/screens/admin/users_management_screen.dart';
import 'package:freelancer_platform/screens/admin/contracts_management_screen.dart';
import 'package:freelancer_platform/screens/admin/projects_management_screen.dart';
import 'package:freelancer_platform/screens/admin/admin_ads_management_screen.dart';
import 'package:freelancer_platform/screens/admin/settings_screen.dart';
import 'package:freelancer_platform/theme/app_theme.dart' as AppTheme;
import '../../../models/admin_stats.dart';
import '../../../services/api_service.dart';
import 'package:freelancer_platform/widgets/ad_banner.dart';

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class _AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTap;

  const _AdminSidebar({required this.selectedIndex, required this.onItemTap});

  static const _items = [
    _NavItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Dashboard',
    ),
    _NavItem(
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      label: 'Users',
    ),
    _NavItem(
      icon: Icons.work_outline,
      selectedIcon: Icons.work,
      label: 'Projects',
    ),
    _NavItem(
      icon: Icons.description_outlined,
      selectedIcon: Icons.description,
      label: 'Contracts',
    ),
    _NavItem(
      icon: Icons.gavel_outlined,
      selectedIcon: Icons.gavel,
      label: 'Disputes',
    ),
    _NavItem(
      icon: Icons.subscriptions_outlined,
      selectedIcon: Icons.subscriptions,
      label: 'Subscriptions',
    ),
    _NavItem(
      icon: Icons.campaign_outlined,
      selectedIcon: Icons.campaign,
      label: 'Ads',
    ),
    _NavItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sidebarColor = isDark
        ? AppTheme.AppColors.darkSidebar
        : AppTheme.AppColors.lightSidebar;

    final sidebarTextColor = isDark
        ? AppTheme.AppColors.darkTextSecondary
        : Colors.white70;

    final sidebarTextColorActive = Colors.white;
    final accentColor = isDark ? AppTheme.AppColors.accentLight : AppTheme.AppColors.accent;

    return Container(
      width: 220,
      color: sidebarColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(27, 15, 20, 2),
            child: Row(
              children: [
                Image.asset('assets/images/logoo.png', height: 50, width: 50),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Divider(
            color: Colors.white.withOpacity(0.1),
            height: 1,
            indent: 20,
            endIndent: 20,
          ),

          const SizedBox(height: 12),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final item = _items[i];
                final isActive = selectedIndex == i;
                return GestureDetector(
                  onTap: () => onItemTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? accentColor.withOpacity(0.25)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isActive
                          ? Border(
                              left: BorderSide(
                                color: accentColor,
                                width: 3,
                              ),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isActive ? item.selectedIcon : item.icon,
                          size: 19,
                          color: isActive
                              ? sidebarTextColorActive
                              : sidebarTextColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 13,
                            color: isActive
                                ? sidebarTextColorActive
                                : sidebarTextColor,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: AdBanner(
              placement: 'sidebar_bottom',
              height: 200,
              margin: EdgeInsets.zero,
            ),
          ),

          Divider(
            color: Colors.white.withOpacity(0.1),
            height: 1,
            indent: 20,
            endIndent: 20,
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _sidebarActionBtn(
                  context,
                  Icons.settings_outlined,
                  'settings',
                  onTap: () => Navigator.pushNamed(context, '/settings'),
                ),
                const SizedBox(height: 8),
                _sidebarActionBtn(
                  context,
                  Icons.logout,
                  'logout',
                  color: Colors.red.shade300,
                  onTap: () => _showLogoutDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getLabel(String key) {
    switch (key) {
      case 'settings':
        return 'Settings';
      case 'logout':
        return 'Logout';
      default:
        return key;
    }
  }

  Widget _sidebarActionBtn(
    BuildContext context,
    IconData icon,
    String labelKey, {
    Color? color,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultColor = isDark
        ? AppTheme.AppColors.darkTextSecondary
        : Colors.white70;

    final label = _getLabel(labelKey);
    final finalColor = color ?? defaultColor;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 16, color: finalColor),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 12, color: finalColor)),
        ],
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t?.logout ?? 'Logout'),
        content: Text(t?.logoutConfirmation ?? 'Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t?.cancel ?? 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ApiService.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            child: Text(t?.logout ?? 'Logout'),
          ),
        ],
      ),
    );
  }
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  AdminStats? stats;
  bool loading = true;
  List<Map<String, dynamic>> monthlyStats = [];
  int _selectedIndex = 0;
  int _dashboardTab = 0;
  String? errorMessage;
  double _adRevenue = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiService.getAdminDashboardStats();
      print('📊 Dashboard response: $response');

      if (response != null && response.isNotEmpty) {
        final statsData = response['stats'] ?? {};
        final monthlyStatsData = response['monthlyStats'] ?? [];

        final adRevenue = response['stats']?['adRevenue'] ?? 0;

        setState(() {
          stats = AdminStats.fromJson(statsData);
          monthlyStats = List<Map<String, dynamic>>.from(monthlyStatsData);
          _adRevenue = adRevenue.toDouble();
          loading = false;
        });
      } else {
        setState(() {
          stats = AdminStats(
            totalUsers: 0,
            totalFreelancers: 0,
            totalClients: 0,
            totalProjects: 0,
            totalContracts: 0,
            totalEarnings: 0,
            pendingProjects: 0,
            activeContracts: 0,
            completedContracts: 0,
            pendingDisputes: 0,
          );
          monthlyStats = [];
          _adRevenue = 0;
          loading = false;
          errorMessage = 'No data available';
        });
      }
    } catch (e) {
      print('❌ Error loading stats: $e');
      setState(() {
        loading = false;
        errorMessage = 'Failed to load dashboard data: $e';
        stats = AdminStats(
          totalUsers: 0,
          totalFreelancers: 0,
          totalClients: 0,
          totalProjects: 0,
          totalContracts: 0,
          totalEarnings: 0,
          pendingProjects: 0,
          activeContracts: 0,
          completedContracts: 0,
          pendingDisputes: 0,
        );
        _adRevenue = 0;
        monthlyStats = [];
      });
    }
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.AppColors.darkCard : AppTheme.AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppTheme.AppColors.primaryDark : AppTheme.AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : const Color(0x0A000000),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Icon(Icons.trending_up, size: 14, color: Colors.grey.shade400),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppTheme.AppColors.darkTextPrimary
                  : const Color(0xFF2D2B55),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: isDark ? AppTheme.AppColors.darkTextSecondary : Colors.grey.shade500,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = isDark ? AppTheme.AppColors.accentLight : AppTheme.AppColors.accent;

    final titles = [
      'Dashboard',
      'Users',
      'Projects',
      'Contracts',
      'Disputes',
      'Subscriptions',
      'Ads',
      'Settings',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.AppColors.darkSurface : AppTheme.AppColors.lightCard,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.AppColors.grayDark : const Color(0xFFEEEEEE),
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            titles[_selectedIndex],
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppTheme.AppColors.darkTextPrimary
                  : const Color(0xFF2D2B55),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: accentColor,
                ),
                const SizedBox(width: 6),
                Text(
                  _getCurrentDate(),
                  style: TextStyle(
                    fontSize: 12,
                    color: accentColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: _loadStats,
            icon: Icon(
              Icons.refresh_rounded,
              color: accentColor,
              size: 22,
            ),
            tooltip: 'Refresh',
          ),
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_none_rounded,
                  color: isDark
                      ? AppTheme.AppColors.darkTextPrimary
                      : const Color(0xFF2D2B55),
                ),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final greeting = _getGreeting();
    
    final totalUsers = stats?.totalUsers ?? 0;
    final activeContracts = stats?.activeContracts ?? 0;
    final pendingDisputes = stats?.pendingDisputes ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppTheme.AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            top: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -28,
            child: Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withOpacity(0.18),
                ),
                child: const Center(
                  child: Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting, Admin! 👋',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$totalUsers total users · $activeContracts active contracts · $pendingDisputes pending disputes',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.78),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  _bannerBtn('Manage Users', () => setState(() => _selectedIndex = 1)),
                  const SizedBox(height: 6),
                  _bannerBtn('View Reports', () {}),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bannerBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.28)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          const SizedBox(height: 20),
          Text(
            errorMessage ?? 'Failed to load dashboard data',
            style: TextStyle(
              color: isDark ? AppTheme.AppColors.darkTextSecondary : Colors.grey.shade600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadStats,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.AppColors.accent,
              foregroundColor: AppTheme.AppColors.primaryDark,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = isDark ? AppTheme.AppColors.accentLight : AppTheme.AppColors.accent;
    final textPrimaryColor = isDark
        ? AppTheme.AppColors.darkTextPrimary
        : const Color(0xFF2D2B55);

    final totalUsers = (stats?.totalUsers ?? 0).toDouble();
    final freelancers = (stats?.totalFreelancers ?? 0).toDouble();
    final clients = (stats?.totalClients ?? 0).toDouble();
    final completedContracts = (stats?.completedContracts ?? 0).toDouble();
    final activeContracts = (stats?.activeContracts ?? 0).toDouble();
    final pendingProjects = (stats?.pendingProjects ?? 0).toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeBanner(),
          const SizedBox(height: 20),

          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: _getCrossAxisCount(context),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.35,
            children: [
              _buildStatCard(
                'Total Users',
                stats!.totalUsers.toString(),
                Icons.people_alt,
                Colors.blue,
              ),
              _buildStatCard(
                'Freelancers',
                stats!.totalFreelancers.toString(),
                Icons.work,
                AppTheme.AppColors.success,
              ),
              _buildStatCard(
                'Clients',
                stats!.totalClients.toString(),
                Icons.business,
                Colors.orange,
              ),
              _buildStatCard(
                'Projects',
                stats!.totalProjects.toString(),
                Icons.folder_open,
                accentColor,
              ),
              _buildStatCard(
                'Contracts',
                stats!.totalContracts.toString(),
                Icons.description,
                Colors.teal,
              ),
              _buildStatCard(
                'Earnings',
                '\$${stats!.totalEarnings.toStringAsFixed(0)}',
                Icons.attach_money,
                AppTheme.AppColors.success,
              ),
              _buildStatCard(
                'Ad Revenue',
                '\$${_adRevenue.toStringAsFixed(0)}',
                Icons.ads_click,
                Colors.teal,
              ),
              _buildStatCard(
                'Pending Projects',
                stats!.pendingProjects.toString(),
                Icons.pending_actions,
                Colors.orange,
              ),
              _buildStatCard(
                'Active Contracts',
                stats!.activeContracts.toString(),
                Icons.play_circle,
                Colors.blue,
              ),
              _buildStatCard(
                'Completed',
                stats!.completedContracts.toString(),
                Icons.check_circle,
                AppTheme.AppColors.success,
              ),
              _buildStatCard(
                'Disputes',
                stats!.pendingDisputes.toString(),
                Icons.warning_amber,
                Colors.red,
              ),
            ],
          ),

          const SizedBox(height: 28),

          Row(
            children: [
              _insightTabChip('Overview', 0),
              const SizedBox(width: 10),
              _insightTabChip('Performance', 1),
              const SizedBox(width: 10),
              _insightTabChip('Trends', 2),
            ],
          ),
          const SizedBox(height: 14),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _buildDashboardTabPanel(
              totalUsers: totalUsers,
              freelancers: freelancers,
              clients: clients,
              completedContracts: completedContracts,
              activeContracts: activeContracts,
              pendingProjects: pendingProjects,
            ),
          ),

          const SizedBox(height: 28),

          if (monthlyStats.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'User Growth Analytics',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimaryColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Total Users',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.AppColors.darkCard : AppTheme.AppColors.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppTheme.AppColors.primaryDark : AppTheme.AppColors.borderLight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.2)
                        : const Color(0x0A000000),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SizedBox(
                height: 300,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 20,
                      getDrawingHorizontalLine: (value) =>
                          FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() < monthlyStats.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  monthlyStats[value.toInt()]['month'] ?? '',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? AppTheme.AppColors.darkTextSecondary
                                        : Colors.grey.shade500,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) => Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? AppTheme.AppColors.darkTextSecondary
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.grey.shade100, width: 1),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: monthlyStats.asMap().entries.map((entry) {
                          final users =
                              entry.value['users'] ??
                              entry.value['freelancers'] ??
                              0;
                          return FlSpot(entry.key.toDouble(), users.toDouble());
                        }).toList(),
                        isCurved: true,
                        color: accentColor,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) =>
                              FlDotCirclePainter(
                                radius: 4,
                                color: Colors.white,
                                strokeWidth: 2,
                                strokeColor: accentColor,
                              ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              accentColor.withOpacity(0.15),
                              accentColor.withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else if (!loading)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.AppColors.darkCard : AppTheme.AppColors.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppTheme.AppColors.primaryDark : AppTheme.AppColors.borderLight,
                ),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: 48,
                      color: isDark
                          ? AppTheme.AppColors.darkTextSecondary
                          : Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No chart data available',
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.AppColors.darkTextSecondary
                            : Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 20),
          AdBanner(placement: 'home_bottom', height: 100),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _insightTabChip(String label, int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = isDark ? AppTheme.AppColors.accentLight : AppTheme.AppColors.accent;
    final selected = _dashboardTab == index;
    
    return InkWell(
      onTap: () => setState(() => _dashboardTab = index),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? accentColor.withOpacity(0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? accentColor : (isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade200),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? accentColor : (isDark ? AppTheme.AppColors.darkTextSecondary : Colors.grey.shade700),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardTabPanel({
    required double totalUsers,
    required double freelancers,
    required double clients,
    required double completedContracts,
    required double activeContracts,
    required double pendingProjects,
  }) {
    if (_dashboardTab == 1) {
      return _buildPerformancePanel(
        completedContracts: completedContracts,
        activeContracts: activeContracts,
        pendingProjects: pendingProjects,
      );
    }

    if (_dashboardTab == 2) {
      return _buildTrendPanel();
    }

    return _buildOverviewPanel(
      totalUsers: totalUsers,
      freelancers: freelancers,
      clients: clients,
    );
  }

  Widget _buildOverviewPanel({
    required double totalUsers,
    required double freelancers,
    required double clients,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = isDark ? AppTheme.AppColors.accentLight : AppTheme.AppColors.accent;
    
    final freelancerPct = totalUsers > 0 ? (freelancers / totalUsers) * 100 : 0;
    final clientPct = totalUsers > 0 ? (clients / totalUsers) * 100 : 0;

    return Container(
      key: const ValueKey('overview'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.AppColors.darkCard : AppTheme.AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.AppColors.primaryDark : AppTheme.AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : const Color(0x0A000000),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 38,
                sections: [
                  PieChartSectionData(
                    value: freelancers <= 0 ? 0.01 : freelancers,
                    color: AppTheme.AppColors.success,
                    title: '${freelancerPct.toStringAsFixed(0)}%',
                    radius: 50,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  PieChartSectionData(
                    value: clients <= 0 ? 0.01 : clients,
                    color: accentColor,
                    title: '${clientPct.toStringAsFixed(0)}%',
                    radius: 50,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User Distribution',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppTheme.AppColors.darkTextPrimary
                        : const Color(0xFF2D2B55),
                  ),
                ),
                const SizedBox(height: 10),
                _legendRow('Freelancers', AppTheme.AppColors.success, freelancers.toInt()),
                const SizedBox(height: 8),
                _legendRow('Clients', accentColor, clients.toInt()),
                const SizedBox(height: 12),
                Text(
                  'Balanced marketplace with ${totalUsers.toInt()} total accounts.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppTheme.AppColors.darkTextSecondary                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformancePanel({
    required double completedContracts,
    required double activeContracts,
    required double pendingProjects,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final maxY =
        [
          completedContracts,
          activeContracts,
          pendingProjects,
        ].reduce((a, b) => a > b ? a : b) +
        2;

    return Container(
      key: const ValueKey('performance'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.AppColors.darkCard : AppTheme.AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.AppColors.primaryDark : AppTheme.AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : const Color(0x0A000000),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Operational Performance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppTheme.AppColors.darkTextPrimary
                  : const Color(0xFF2D2B55),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 210,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? AppTheme.AppColors.darkTextSecondary
                              : Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const labels = ['Completed', 'Active', 'Pending'];
                        final i = value.toInt();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            i >= 0 && i < labels.length ? labels[i] : '',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? AppTheme.AppColors.darkTextSecondary
                                  : Colors.grey.shade600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: completedContracts,
                        color: AppTheme.AppColors.success,
                        width: 24,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: activeContracts,
                        color: AppTheme.AppColors.accent,
                        width: 24,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: pendingProjects,
                        color: Colors.orange,
                        width: 24,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendPanel() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = isDark ? AppTheme.AppColors.accentLight : AppTheme.AppColors.accent;
    
    final lastMonth = monthlyStats.isNotEmpty ? monthlyStats.last : {};
    final monthUsers = (lastMonth['users'] ?? lastMonth['freelancers'] ?? 0)
        .toInt();
    final monthRevenue = (lastMonth['earnings'] ?? 0).toDouble();

    return Container(
      key: const ValueKey('trend'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.AppColors.darkCard : AppTheme.AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.AppColors.primaryDark : AppTheme.AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : const Color(0x0A000000),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _microInsightCard(
              title: 'Last Month Users',
              value: monthUsers.toString(),
              icon: Icons.person_add_alt_1,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _microInsightCard(
              title: 'Last Month Revenue',
              value: '\$${monthRevenue.toStringAsFixed(0)}',
              icon: Icons.payments_outlined,
              color: AppTheme.AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _microInsightCard(
              title: 'Health Score',
              value: _platformHealthScore(),
              icon: Icons.favorite_outline,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _microInsightCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppTheme.AppColors.darkTextSecondary : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendRow(String label, Color color, int value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppTheme.AppColors.darkTextSecondary : Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.AppColors.darkTextPrimary : const Color(0xFF2D2B55),
          ),
        ),
      ],
    );
  }

  String _platformHealthScore() {
    final total = (stats?.totalContracts ?? 0);
    final completed = (stats?.completedContracts ?? 0);
    if (total <= 0) return 'N/A';
    final pct = ((completed / total) * 100).round();
    return '$pct%';
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1400) return 5;
    if (width > 1100) return 4;
    if (width > 800) return 3;
    return 2;
  }

  Widget _buildContent() {
    if (stats == null && loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppTheme.AppColors.accent,
              ),
            ),
            SizedBox(height: 16),
            Text('Loading dashboard...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    switch (_selectedIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return const UsersManagementScreen();
      case 2:
        return const ProjectsManagementScreen();
      case 3:
        return const ContractsManagementScreen();
      case 4:
        return const DisputesManagementScreen();
      case 5:
        return const SubscriptionManagementScreen();
      case 6:
        return const AdminAdsManagementScreen();
      case 7:
        return const AdminSettingsScreen();
      default:
        return _buildDashboardContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (errorMessage != null && stats?.totalUsers == 0 && !loading) {
      return Scaffold(
        backgroundColor: isDark ? AppTheme.AppColors.darkBackground : AppTheme.AppColors.lightBackground,
        body: _buildErrorWidget(),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.AppColors.darkBackground : AppTheme.AppColors.lightBackground,
      body: Row(
        children: [
          _AdminSidebar(
            selectedIndex: _selectedIndex,
            onItemTap: (i) => setState(() => _selectedIndex = i),
          ),

          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}