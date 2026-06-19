// lib/screens/client/client_dashboard_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:freelancer_platform/screens/ads/ads_management_screen.dart';
import 'package:freelancer_platform/screens/disputes/my_disputes_screen.dart';
import 'package:freelancer_platform/services/socket_service.dart';
import 'package:freelancer_platform/widgets/ad_banner.dart';
import '../../l10n/app_localizations.dart';
import 'package:freelancer_platform/models/usage_limits_model.dart';
import 'package:freelancer_platform/screens/client/compare_freelancers_screen.dart';
import 'package:freelancer_platform/screens/freelancer/favorites_screen.dart';
import 'package:freelancer_platform/screens/freelancer/profile_screen.dart'
    hide RatingStars;
import 'package:freelancer_platform/screens/rating/reviews_screen.dart';
import 'enhanced_client_profile_screen.dart';
import 'client_analytics_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:freelancer_platform/screens/client/client_profile_screen.dart';
import 'package:lottie/lottie.dart';
import '../../models/contract_model.dart';
import '../../models/project_model.dart';
import '../../models/proposal_model.dart';
import '../../models/notification_model.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/draft_local_storage.dart';
import '../../widgets/avatar_widget.dart';
import '../chat/chats_list_screen.dart';
import '../contract/my_contracts_screen.dart';
import '../notifications/notifications_screen.dart';
import 'create_project_screen.dart';
import 'project_proposals_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'freelancer_profile_preview_screen.dart';
import '../interview/interviews_screen.dart';
import '../../theme/app_theme.dart';
import 'find_freelancers_screen.dart';

class DashboardOverview {
  final _Stats stats;
  final List<_MonthlyPoint> monthlySpending;
  final List<_StatusSlice> statusBreakdown;
  final List<_ProposalItem> recentProposals;
  final List<_ContractItem> activeContracts;
  final List<NotificationModel> recentActivity;
  final List<_FreelancerChip> topFreelancers;

  DashboardOverview({
    required this.stats,
    required this.monthlySpending,
    required this.statusBreakdown,
    required this.recentProposals,
    required this.activeContracts,
    required this.recentActivity,
    required this.topFreelancers,
  });

  factory DashboardOverview.fromJson(Map<String, dynamic> j) {
    final trendData =
        j['spending_trend'] ?? {'percentage': 0, 'direction': 'up'};
    return DashboardOverview(
      stats: _Stats.fromJson(
        j['stats'] ??
            {
              'spendingTrend': trendData['percentage'],
              'trendDirection': trendData['direction'],
            },
      ),
      monthlySpending: ((j['monthlySpending'] ?? []) as List)
          .map((e) => _MonthlyPoint.fromJson(e))
          .toList(),
      statusBreakdown: ((j['statusBreakdown'] ?? []) as List)
          .map((e) => _StatusSlice.fromJson(e))
          .toList(),
      recentProposals: ((j['recentProposals'] ?? []) as List)
          .map((e) => _ProposalItem.fromJson(e))
          .toList(),
      activeContracts: ((j['activeContracts'] ?? []) as List)
          .map((e) => _ContractItem.fromJson(e))
          .toList(),
      recentActivity: ((j['recentActivity'] ?? []) as List)
          .map((e) => NotificationModel.fromJson(e))
          .toList(),
      topFreelancers: ((j['topFreelancers'] ?? []) as List)
          .map((e) => _FreelancerChip.fromJson(e))
          .toList(),
    );
  }
}

class _Stats {
  final int totalProjects, openProjects, inProgressProjects, completedProjects;
  final int totalProposals, pendingProposals, acceptedProposals;
  final double totalSpent, escrowHeld, totalReleased;
  final int proposalAcceptRate;
  final double spendingTrend;
  final String trendDirection;

  _Stats({
    this.totalProjects = 0,
    this.openProjects = 0,
    this.inProgressProjects = 0,
    this.completedProjects = 0,
    this.totalProposals = 0,
    this.pendingProposals = 0,
    this.acceptedProposals = 0,
    this.totalSpent = 0,
    this.escrowHeld = 0,
    this.totalReleased = 0,
    this.proposalAcceptRate = 0,
    this.spendingTrend = 0,
    this.trendDirection = 'up',
  });

  factory _Stats.fromJson(Map<String, dynamic> j) => _Stats(
    totalProjects: j['totalProjects'] ?? 0,
    openProjects: j['openProjects'] ?? 0,
    inProgressProjects: j['inProgressProjects'] ?? 0,
    completedProjects: j['completedProjects'] ?? 0,
    totalProposals: j['totalProposals'] ?? 0,
    pendingProposals: j['pendingProposals'] ?? 0,
    acceptedProposals: j['acceptedProposals'] ?? 0,
    totalSpent: _d(j['totalSpent']),
    escrowHeld: _d(j['escrowHeld']),
    totalReleased: _d(j['totalReleased']),
    proposalAcceptRate: j['proposalAcceptRate'] ?? 0,
    spendingTrend: _d(j['spendingTrend'] ?? 0),
    trendDirection: j['trendDirection'] ?? 'up',
  );

  static double _d(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) {
      final match = RegExp(r'\d+(?:\.\d+)?').firstMatch(v);
      if (match != null) return double.tryParse(match.group(0)!) ?? 0;
      return double.tryParse(v) ?? 0;
    }
    return double.tryParse(v.toString()) ?? 0;
  }
}

class _MonthlyPoint {
  final String label;
  final double total;
  _MonthlyPoint({required this.label, required this.total});
  factory _MonthlyPoint.fromJson(Map<String, dynamic> j) =>
      _MonthlyPoint(label: j['label'] ?? '', total: _d(j['total']));
  static double _d(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) {
      final m = RegExp(r'\d+(?:\.\d+)?').firstMatch(v);
      if (m != null) return double.tryParse(m.group(0)!) ?? 0;
      return double.tryParse(v) ?? 0;
    }
    return double.tryParse(v.toString()) ?? 0;
  }
}

class _StatusSlice {
  final String label, color;
  final int value;
  _StatusSlice({required this.label, required this.value, required this.color});
  factory _StatusSlice.fromJson(Map<String, dynamic> j) => _StatusSlice(
    label: j['label'] ?? '',
    value: j['value'] ?? 0,
    color: j['color'] ?? '#888',
  );
}

class _ProposalItem {
  final int id;
  final int? freelancerId;
  final String status;
  final double price;
  final int deliveryTime;
  final String proposalText;
  final String? projectTitle, freelancerName, freelancerAvatar, freelancerTitle;
  final int? projectId;
  final double? freelancerRating;
  final List<String> skills;

  _ProposalItem({
    required this.id,
    this.freelancerId,
    required this.status,
    required this.price,
    required this.deliveryTime,
    required this.proposalText,
    this.projectTitle,
    this.projectId,
    this.freelancerName,
    this.freelancerAvatar,
    this.freelancerTitle,
    this.freelancerRating,
    this.skills = const [],
  });

  factory _ProposalItem.fromJson(Map<String, dynamic> j) {
    final fp = j['freelancerProfile'];
    final f = j['freelancer'];
    final p = j['project'];

    List<String> skills = [];
    if (fp?['skills'] is List) {
      skills = (fp!['skills'] as List).map((e) => e.toString()).toList();
    } else if (fp?['skills'] is String && (fp['skills'] as String).isNotEmpty) {
      try {
        final parsed = jsonDecode(fp['skills']);
        if (parsed is List) {
          skills = parsed.map((e) => e.toString()).toList();
        }
      } catch (e) {}
    }

    int? freelancerId;
    if (j['freelancerId'] != null) {
      freelancerId = j['freelancerId'];
    } else if (f != null && f['id'] != null) {
      freelancerId = f['id'];
    }

    String? freelancerName;
    if (j['freelancerName'] != null) {
      freelancerName = j['freelancerName'];
    } else if (f != null && f['name'] != null) {
      freelancerName = f['name'];
    }

    if (freelancerName == null || freelancerName.isEmpty) {
      freelancerName = 'Freelancer';
    }

    print(
      '📊 Parsing proposal: id=${j['id']}, freelancerId=$freelancerId, name=$freelancerName',
    );

    return _ProposalItem(
      id: j['id'] ?? 0,
      freelancerId: freelancerId,
      status: j['status'] ?? 'pending',
      price: (j['price'] ?? 0).toDouble(),
      deliveryTime: j['deliveryTime'] ?? 0,
      proposalText: j['proposalText'] ?? '',
      projectTitle: p?['title'] ?? j['projectTitle'],
      projectId: p?['id'] ?? j['projectId'],
      freelancerName: freelancerName,
      freelancerAvatar: j['freelancerAvatar'] ?? f?['avatar'],
      freelancerTitle: fp?['title'] ?? j['freelancerTitle'],
      freelancerRating: (fp?['rating'] ?? j['freelancerRating'] ?? 0)
          .toDouble(),
      skills: skills,
    );
  }
}

class _ContractItem {
  final int id;
  final String status, escrowStatus;
  final double agreedAmount, releasedAmount;
  final int progress, milestonesTotal, milestonesDone;
  final String? projectTitle,
      projectCategory,
      freelancerName,
      freelancerAvatar,
      nextMilestoneTitle;
  final int? projectId;

  _ContractItem({
    required this.id,
    required this.status,
    required this.escrowStatus,
    required this.agreedAmount,
    required this.releasedAmount,
    required this.progress,
    required this.milestonesTotal,
    required this.milestonesDone,
    this.projectTitle,
    this.projectCategory,
    this.projectId,
    this.freelancerName,
    this.freelancerAvatar,
    this.nextMilestoneTitle,
  });

  factory _ContractItem.fromJson(Map<String, dynamic> j) {
    final p = j['project'];
    final f = j['freelancer'];
    final nm = j['nextMilestone'];
    return _ContractItem(
      id: j['id'] ?? 0,
      status: j['status'] ?? '',
      escrowStatus: j['escrowStatus'] ?? 'pending',
      agreedAmount: (j['agreedAmount'] ?? 0).toDouble(),
      releasedAmount: (j['releasedAmount'] ?? 0).toDouble(),
      progress: j['progress'] ?? 0,
      milestonesTotal: j['milestonesTotal'] ?? 0,
      milestonesDone: j['milestonesDone'] ?? 0,
      projectTitle: p?['title'],
      projectCategory: p?['category'],
      projectId: p?['id'],
      freelancerName: f?['name'],
      freelancerAvatar: f?['avatar'],
      nextMilestoneTitle: nm?['title'],
    );
  }
}

class _FreelancerChip {
  final int id;
  final String name;
  final String? avatar;
  final double? rating;
  _FreelancerChip({
    required this.id,
    required this.name,
    this.avatar,
    this.rating,
  });
  factory _FreelancerChip.fromJson(Map<String, dynamic> j) => _FreelancerChip(
    id: j['id'] ?? 0,
    name: j['name'] ?? '',
    avatar: j['avatar'],
    rating: j['rating']?.toDouble(),
  );
}

class _AIFreelancerSuggestion {
  final int id;
  final String name;
  final String? avatar, title;
  final double rating;
  final int experience, matchScore;
  final List<String> skills;

  _AIFreelancerSuggestion({
    required this.id,
    required this.name,
    this.avatar,
    this.title,
    this.rating = 0,
    this.experience = 0,
    this.matchScore = 0,
    this.skills = const [],
  });

  factory _AIFreelancerSuggestion.fromJson(Map<String, dynamic> j) =>
      _AIFreelancerSuggestion(
        id: j['id'] ?? 0,
        name: j['name'] ?? '',
        avatar: j['avatar'],
        title: j['title'],
        rating: (j['rating'] ?? 0).toDouble(),
        experience: j['experience'] ?? 0,
        matchScore: j['matchScore'] ?? 0,
        skills: (j['skills'] as List?)?.map((e) => e.toString()).toList() ?? [],
      );
}

class ClientProfile {
  final int id;
  final String name;
  final String? avatar, email, company, phone;

  ClientProfile({
    required this.id,
    required this.name,
    this.avatar,
    this.email,
    this.company,
    this.phone,
  });

  factory ClientProfile.fromJson(Map<String, dynamic> j) => ClientProfile(
    id: j['id'] ?? 0,
    name: j['name'] ?? 'Client',
    avatar: j['avatar'],
    email: j['email'],
    company: j['company'],
    phone: j['phone'],
  );
}

class _SidebarItem {
  final IconData icon;
  final String labelKey;
  final int? badge;
  final bool badgeGreen;
  const _SidebarItem({
    required this.icon,
    required this.labelKey,
    this.badge,
    this.badgeGreen = false,
  });
}

class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTap;
  final ClientProfile? profile;
  final String avatarUrl;
  final VoidCallback onProfile;
  final VoidCallback? onSettings;
  final DashboardOverview? dashboardData;

  const _Sidebar({
    required this.selectedIndex,
    required this.onItemTap,
    required this.profile,
    required this.avatarUrl,
    required this.onProfile,
    this.onSettings,
    this.dashboardData,
  });

  List<_SidebarItem> get _items {
    final stats = dashboardData?.stats;
    return [
      _SidebarItem(icon: Icons.dashboard_outlined, labelKey: 'overview'),
      _SidebarItem(
        icon: Icons.folder_open_outlined,
        labelKey: 'myProjects',
        badge: stats?.openProjects,
      ),
      _SidebarItem(
        icon: Icons.send_outlined,
        labelKey: 'proposals',
        badge: stats?.pendingProposals,
      ),
      _SidebarItem(
        icon: Icons.description_outlined,
        labelKey: 'contracts',
        badge: stats?.inProgressProjects,
        badgeGreen: true,
      ),
      _SidebarItem(icon: Icons.gavel_outlined, labelKey: 'disputes'),
      _SidebarItem(icon: Icons.interpreter_mode, labelKey: 'interviews'),
      _SidebarItem(icon: Icons.campaign_outlined, labelKey: 'ads'),
      _SidebarItem(icon: Icons.people_outline, labelKey: 'findFreelancers'),
      _SidebarItem(icon: Icons.bar_chart_outlined, labelKey: 'analytics'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 220,
      color: isDark ? AppColors.darkSidebar : AppColors.lightSidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Text(
              'CLIENT',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),

          GestureDetector(
            onTap: onProfile,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : AppColors.border.withOpacity(0.5),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  _buildAvatar(profile?.name ?? 'C', avatarUrl, 42, isDark),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.name ?? 'Client',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : AppColors.lightTextPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          profile?.company ?? 'Business Owner',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.accentLight
                                : AppColors.accentDark,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.edit_outlined,
                    size: 13,
                    color: isDark
                        ? AppColors.accentLight
                        : AppColors.accentDark,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final item = _items[i];
                final active = selectedIndex == i;
                final label = _getLabel(t, item.labelKey);
                return GestureDetector(
                  onTap: () => onItemTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    padding: EdgeInsets.only(
                      left: active ? 11 : 14,
                      right: 12,
                      top: 11,
                      bottom: 11,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.accent.withOpacity(isDark ? 0.22 : 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: active
                          ? Border(
                              left: BorderSide(
                                color: AppColors.accent,
                                width: 3,
                              ),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          size: 17,
                          color: active
                              ? (isDark
                                    ? Colors.white
                                    : AppColors.lightTextPrimary)
                              : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              color: active
                                  ? (isDark
                                        ? Colors.white
                                        : AppColors.lightTextPrimary)
                                  : (isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary),
                              fontWeight: active
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (item.badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: item.badgeGreen
                                  ? AppColors.success
                                  : AppColors.accent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${item.badge}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                              ),
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
              placement: 'sidebar_top',
              height: 200,
              margin: EdgeInsets.zero,
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

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _footerBtn(
                  Icons.settings_outlined,
                  t.settings,
                  isDark,
                  onTap: () {
                    if (onSettings != null) {
                      onSettings!();
                    } else {
                      Navigator.pushNamed(context, '/settings');
                    }
                  },
                ),
                const SizedBox(height: 8),
                _footerBtn(
                  Icons.logout,
                  t.logout,
                  isDark,
                  isDanger: true,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getLabel(AppLocalizations t, String key) {
    switch (key) {
      case 'overview':
        return t.home;
      case 'myProjects':
        return t.myProjects;
      case 'proposals':
        return t.proposals;
      case 'contracts':
        return t.contracts;
      case 'disputes':
        return t.disputes;
      case 'interviews':
        return t.interviews;
      case 'wallet':
        return t.myWallet;
      case 'ads':
        return t.ads;
      case 'findFreelancers':
        return t.findWork;
      case 'analytics':
        return t.analytics;
      default:
        return key;
    }
  }

  Widget _buildAvatar(String name, String url, double size, bool isDark) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: LinearGradient(
          colors: [AppColors.accent, AppColors.accentLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: url.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.28),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initialText(name, size),
              ),
            )
          : _initialText(name, size),
    );
  }

  Widget _initialText(String name, double size) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'C';
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _footerBtn(
    IconData icon,
    String label,
    bool isDark, {
    bool isDanger = false,
    VoidCallback? onTap,
  }) {
    final color = isDanger
        ? AppColors.danger
        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  final ClientProfile? profile;
  final String avatarUrl;
  final int pendingProposals;
  final int activeContracts;
  final VoidCallback onNewProject;
  final VoidCallback onFindFreelancers;
  final VoidCallback? onSettings;

  const _WelcomeBanner({
    required this.profile,
    required this.avatarUrl,
    required this.pendingProposals,
    required this.activeContracts,
    required this.onNewProject,
    required this.onFindFreelancers,
    this.onSettings,
  });

  String _getGreeting(AppLocalizations t) {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final firstName = profile?.name?.split(' ').first ?? 'there';
    final greeting = _getGreeting(t);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
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
                child: avatarUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _avatarFallback(firstName),
                        ),
                      )
                    : _avatarFallback(firstName),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting, $firstName 👋',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'You have $pendingProposals new proposals · $activeContracts active contracts',
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
                  _bannerBtn(t.postNewProject, onNewProject),
                  const SizedBox(height: 6),
                  _bannerBtn(t.findWork, onFindFreelancers),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(String name) {
    return Center(
      child: Text(
        name[0].toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
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
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;
  final String sub;
  final String trend;
  final bool trendUp;
  final double progress;
  final double trendValue;

  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.sub,
    this.trend = '',
    this.trendUp = true,
    this.progress = 0.5,
    this.trendValue = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.primaryDark : AppColors.borderLight,
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
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 17),
              ),
              const Spacer(),
              if (trendValue != 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: trendUp ? AppColors.successBg : AppColors.warningBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trendUp ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 10,
                        color: trendUp ? AppColors.success : AppColors.warning,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${trendValue.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: trendUp
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: AppColors.gray)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: isDark
                  ? AppColors.primaryDark
                  : AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(iconColor),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            sub,
            style: const TextStyle(fontSize: 9, color: AppColors.gray),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.bg,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.primaryDark : AppColors.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : const Color(0x08000000),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.gray,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final Widget child;

  const _SectionCard({
    required this.title,
    this.action,
    this.onAction,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.primaryDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : const Color(0x08000000),
            blurRadius: 10,
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
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              if (action != null && onAction != null)
                GestureDetector(
                  onTap: onAction,
                  child: Text(
                    action!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.accent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  final VoidCallback onTap;
  const _PremiumCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1B4B), const Color(0xFF312E81)]
              : [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.premium,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            t.upgrade,
            style: TextStyle(fontSize: 10, color: AppColors.accentLight),
          ),
          const SizedBox(height: 12),
          for (final f in [
            'Unlimited active projects',
            'Priority freelancer matching',
            'Advanced analytics & reports',
            'Dedicated support',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  Icon(Icons.check, color: AppColors.accentLight, size: 12),
                  const SizedBox(width: 6),
                  Text(
                    f,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF312E81),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                t.upgrade,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCompletionCard extends StatelessWidget {
  final double completion;
  final VoidCallback onTap;
  const _ProfileCompletionCard({required this.completion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = completion.clamp(0.0, 100.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.primaryDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : const Color(0x08000000),
            blurRadius: 10,
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
              Text(
                t.profileCompletion,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              Text(
                '${pct.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 6,
              backgroundColor: isDark
                  ? AppColors.primaryDark
                  : AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
          const SizedBox(height: 12),
          _checkRow(true, 'Name & email verified', isDark),
          _checkRow(true, 'First project posted', isDark),
          _checkRow(false, 'Add company info', isDark),
          _checkRow(false, 'Upload profile photo', isDark),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.primaryDark,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                t.editProfile,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkRow(bool done, String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.circle_outlined,
            size: 14,
            color: done ? AppColors.success : Colors.grey.shade300,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: done
                  ? (isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary)
                  : AppColors.gray,
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageLimitBanner extends StatelessWidget {
  final UsageLimits usage;
  final VoidCallback onUpgrade;
  const _UsageLimitBanner({required this.usage, required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final remaining = usage.remainingActiveProjects;
    final used = usage.activeProjectsUsed;
    final limit = usage.activeProjectsLimit!;
    final isMax = remaining <= 0;
    final bgColor = isMax ? AppColors.dangerBg : AppColors.warningBg;
    final bdColor = isMax ? AppColors.danger : AppColors.warning;
    final mainColor = isMax ? AppColors.danger : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bdColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: mainColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isMax ? Icons.block : Icons.warning_amber_rounded,
              size: 20,
              color: mainColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMax ? 'Active Projects Limit Reached' : 'Approaching Limit',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: mainColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isMax
                      ? 'Max $limit active projects on your plan.'
                      : '$remaining of $limit projects remaining.',
                  style: TextStyle(
                    fontSize: 11,
                    color: mainColor.withOpacity(0.8),
                  ),
                ),
                if (isMax) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: used / limit,
                      minHeight: 4,
                      backgroundColor: mainColor.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(mainColor),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isMax) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onUpgrade,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: mainColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  t.upgrade,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InterviewLimitBanner extends StatelessWidget {
  final UsageLimits usage;
  final VoidCallback onUpgrade;
  const _InterviewLimitBanner({required this.usage, required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (!usage.hasInterviewLimit) return const SizedBox.shrink();
    final rem = usage.interviewsRemaining;
    final lim = usage.interviewsLimit;
    if (rem == null || lim == null) return const SizedBox.shrink();
    if (rem > 2) return const SizedBox.shrink();

    final isMax = rem <= 0;
    final bgColor = isMax ? AppColors.dangerBg : const Color(0xFFF5F3FF);
    final bdColor = isMax ? AppColors.danger : AppColors.accent;
    final mainColor = isMax ? AppColors.danger : AppColors.accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bdColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: mainColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isMax ? Icons.event_busy : Icons.interpreter_mode,
              size: 20,
              color: mainColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMax
                      ? 'Interview invitations limit reached'
                      : 'Interview invitations running low',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: mainColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isMax
                      ? '$lim interviews per month on your plan.'
                      : '$rem of $lim interview invitations left this month.',
                  style: TextStyle(
                    fontSize: 11,
                    color: mainColor.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          if (isMax) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onUpgrade,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: mainColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  t.upgrade,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompletePublishReminderBanner extends StatelessWidget {
  final Future<void> Function() onContinue;
  final Future<void> Function() onLater;

  const _CompletePublishReminderBanner({
    required this.onContinue,
    required this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note, color: AppColors.info, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t.postNewProject,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.info,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'لديك مسودة محفوظة على هذا الجهاز. أكمل النشر ليظهر مشروعك للمستقلين.',
            style: TextStyle(fontSize: 12, height: 1.35, color: AppColors.info),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => onContinue(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(t.postProject),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(onPressed: () => onLater(), child: Text(t.maybeLater)),
            ],
          ),
        ],
      ),
    );
  }
}

class ClientDashboard extends StatefulWidget {
  const ClientDashboard({super.key});

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard> {
  DashboardOverview? _data;
  List<Project> _myProjects = [];
  List<_AIFreelancerSuggestion> _aiSuggestions = [];
  ClientProfile? _clientProfile;
  UsageLimits? _usage;

  bool _loading = true;
  bool _loadingProfile = true;
  bool _loadingSuggestions = true;
  bool _loadingUsage = false;

  int _unread = 0;
  int _selectedNav = 0;
  Timer? _refreshTimer;
  bool _showPublishDraftReminder = false;

  @override
  void initState() {
    super.initState();
    _loadClientProfile();
    _loadDashboard();
    _loadMyProjects();
    _loadUnread();
    _loadUsage();
    _checkPublishDraftReminder();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _loadDashboard(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadClientProfile() async {
    setState(() => _loadingProfile = true);
    try {
      final r = await ApiService.getClientProfile();
      if (mounted)
        setState(() {
          _clientProfile = ClientProfile.fromJson(r);
          _loadingProfile = false;
        });
    } catch (_) {
      try {
        final r = await ApiService.getProfile();
        if (mounted)
          setState(() {
            _clientProfile = ClientProfile.fromJson(r);
            _loadingProfile = false;
          });
      } catch (_) {
        if (mounted) setState(() => _loadingProfile = false);
      }
    }
  }

  Future<void> _loadDashboard({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final j = await ApiService.getClientDashboardOverview();
      if (mounted)
        setState(() {
          _data = DashboardOverview.fromJson(j);
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMyProjects() async {
    try {
      final data = await ApiService.getMyProjects2();
      setState(() {
        _myProjects = data
            .map((j) {
              try {
                return Project.fromJson(j);
              } catch (_) {
                return null;
              }
            })
            .whereType<Project>()
            .toList();
      });
      await _loadAISuggestions();
    } catch (_) {
      setState(() => _myProjects = []);
    }
  }

  Future<void> _loadAISuggestions() async {
    setState(() => _loadingSuggestions = true);
    try {
      final open = _myProjects.firstWhere(
        (p) => p.status == 'open',
        orElse: () => Project(),
      );
      if (open.id != null) {
        final r = await ApiService.getSuggestedFreelancers(open.id!);
        if (mounted) {
          final list = r['suggestions'];
          setState(() {
            _aiSuggestions = list is List
                ? list.map((e) => _AIFreelancerSuggestion.fromJson(e)).toList()
                : [];
            _loadingSuggestions = false;
          });
        }
      } else {
        if (mounted)
          setState(() {
            _aiSuggestions = [];
            _loadingSuggestions = false;
          });
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _aiSuggestions = [];
          _loadingSuggestions = false;
        });
    }
  }

  Future<void> _loadUnread() async {
    try {
      final r = await ApiService.getUnreadCount();
      if (mounted) setState(() => _unread = r['unreadCount'] ?? 0);
    } catch (_) {}
  }

  Future<void> _loadUsage() async {
    setState(() => _loadingUsage = true);
    try {
      final r = await ApiService.getUserUsage();
      if (r['usage'] != null && mounted)
        setState(() {
          _usage = UsageLimits.fromJson(r['usage']);
          _loadingUsage = false;
        });
      else if (mounted)
        setState(() => _loadingUsage = false);
    } catch (_) {
      if (mounted) setState(() => _loadingUsage = false);
    }
  }

  Future<void> _checkPublishDraftReminder() async {
    final show = await DraftLocalStorage.shouldShowPublishReminder();
    if (mounted) setState(() => _showPublishDraftReminder = show);
  }

  String _getAvatarUrl(String? avatar) {
    if (avatar == null || avatar.isEmpty) return '';
    if (avatar.startsWith('http')) return avatar;
    if (avatar.startsWith('/uploads')) {
      return 'http://localhost:5001$avatar';
    }
    return avatar;
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inDays > 0) return '${d.inDays}d ago';
    if (d.inHours > 0) return '${d.inHours}h ago';
    if (d.inMinutes > 0) return '${d.inMinutes}m ago';
    return 'Just now';
  }

  double _profileCompletion() {
    int done = 0;
    if (_clientProfile?.name.isNotEmpty == true) done++;
    if (_clientProfile?.avatar?.isNotEmpty == true) done++;
    if (_clientProfile?.email?.isNotEmpty == true) done++;
    if (_clientProfile?.company?.isNotEmpty == true) done++;
    if (_myProjects.isNotEmpty) done++;
    return done / 5 * 100;
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'active':
        return AppColors.success;
      case 'open':
        return AppColors.info;
      case 'pending_freelancer':
      case 'pending_client':
      case 'draft':
        return AppColors.warning;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
      case 'disputed':
        return AppColors.danger;
      default:
        return AppColors.gray;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'active':
        return 'Active';
      case 'open':
        return 'Open';
      case 'pending_freelancer':
        return 'Pending';
      case 'pending_client':
        return 'Action Needed';
      case 'draft':
        return 'Draft';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return s;
    }
  }

  Color _matchColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.info;
  }

  Color _hexColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.gray;
    }
  }

  IconData _activityIcon(String type) {
    switch (type) {
      case 'proposal_received':
        return Icons.inbox;
      case 'proposal_accepted':
        return Icons.check_circle_outline;
      case 'contract_created':
        return Icons.description_outlined;
      case 'contract_signed':
        return Icons.draw_outlined;
      case 'milestone_completed':
        return Icons.flag_outlined;
      case 'payment_received':
        return Icons.payments_outlined;
      case 'payment_released':
        return Icons.send_outlined;
      case 'message':
        return Icons.chat_bubble_outline;
      case 'new_review':
        return Icons.star_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  void _navigateToProfile() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const EnhancedClientProfileScreen()),
  ).then((_) => _loadClientProfile());

  void _navigateToCreateProject() =>
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateProjectScreen()),
      ).then((_) {
        _loadMyProjects();
        _loadDashboard();
        _checkPublishDraftReminder();
      });

  void _navigateToContracts() => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const MyContractsScreen(userRole: 'client'),
    ),
  );

  void _navigateToFreelancerProfile(int id, {String? projectId}) =>
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FreelancerProfilePreviewScreen(
            freelancerId: id,
            projectId: projectId,
          ),
        ),
      );
  Future<void> _logout() async {
    final t = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.logout),
        content: Text(t.logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              print('🚪 Logging out, cleaning up socket...');
              try {
                await SocketService.instance.logoutAndClear();
                print('✅ Socket cleaned up');
              } catch (e) {
                print('⚠️ Error cleaning socket: $e');
              }

              try {
                await ApiService.logout();
                print('✅ API logout completed');
              } catch (e) {
                print('⚠️ Error in API logout: $e');
              }

              Navigator.pop(context, true);
            },
            child: Text(t.logout),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      print('✅ Navigating to login screen...');
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _loadingProfile) {
      return Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        body: const Center(
          child: CircularProgressIndicator(
            color: AppColors.accent,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    final avatarUrl = _getAvatarUrl(_clientProfile?.avatar);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: Row(
        children: [
          _Sidebar(
            selectedIndex: _selectedNav,
            onItemTap: (i) => setState(() => _selectedNav = i),
            profile: _clientProfile,
            avatarUrl: avatarUrl,
            onProfile: _navigateToProfile,
            onSettings: () => Navigator.pushNamed(context, '/settings'),
            dashboardData: _data,
          ),

          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final t = AppLocalizations.of(context)!;
    final titles = [
      t.home,
      t.myProjects,
      t.proposals,
      t.contracts,
      t.disputes,
      t.interviews,
      t.ads,
      t.findWork,
      t.analytics,
    ];

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.lightCard,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Text(
            titles[_selectedNav],
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const Spacer(),

          _topBarBtn(
            Icons.star_border,
            () => Navigator.pushNamed(context, '/subscription/plans'),
          ),
          _topBarBtn(
            Icons.account_balance_wallet_outlined,
            () => Navigator.pushNamed(context, '/wallet', arguments: 'client'),
          ),
          _topBarBtn(Icons.compare_arrows, _handleCompare),

          _topBarBtnBadge(
            Icons.chat_bubble_outline,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChatsListScreen()),
            ),
            3,
          ),

          _topBarBtnBadge(
            Icons.notifications_none,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ).then((_) => _loadUnread()),
            _unread,
          ),

          _topBarMenuBtn(),
        ],
      ),
    );
  }

  Widget _topBarBtn(IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      icon: Icon(
        icon,
        size: 20,
        color: isDark ? AppColors.darkTextSecondary : AppColors.gray,
      ),
      onPressed: onTap,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      splashRadius: 18,
    );
  }

  Widget _topBarBtnBadge(IconData icon, VoidCallback onTap, int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        _topBarBtn(icon, onTap),
        if (count > 0)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: icon == Icons.chat_bubble_outline
                    ? AppColors.accent
                    : AppColors.danger,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _topBarMenuBtn() {
    final t = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        size: 20,
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkTextSecondary
            : AppColors.gray,
      ),
      onSelected: (v) {
        if (v == 'profile') _navigateToProfile();
        if (v == 'plans') Navigator.pushNamed(context, '/subscription/plans');
        if (v == 'mysub') Navigator.pushNamed(context, '/subscription/my');
        if (v == 'compare')
          Navigator.pushNamed(context, '/subscription/comparison');
        if (v == 'interviews')
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InterviewsScreen()),
          );
        if (v == 'logout') _logout();
      },
      itemBuilder: (_) => [
        _menuItem('profile', Icons.person_outline, t.profile),
        _menuItem('mysub', Icons.subscriptions, 'My Subscription'),
        const PopupMenuDivider(),
        _menuItem('logout', Icons.logout, t.logout, color: AppColors.danger),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(
    String v,
    IconData icon,
    String label, {
    Color? color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopupMenuItem(
      value: v,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color:
                color ??
                (isDark ? AppColors.darkTextSecondary : AppColors.gray),
          ),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  void _handleCompare() {
    final top = _data?.topFreelancers ?? [];
    if (top.length >= 2) {
      final openId =
          _myProjects
              .firstWhere((p) => p.status == 'open', orElse: () => Project())
              .id ??
          0;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CompareFreelancersScreen(
            projectId: openId,
            freelancerIds: top.map((f) => f.id).toList(),
          ),
        ),
      );
    } else {
      Fluttertoast.showToast(msg: 'Not enough freelancers to compare');
    }
  }

  Widget _buildBody() {
    final t = AppLocalizations.of(context)!;
    switch (_selectedNav) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildProjectsTab();
      case 2:
        return _buildProposalsTab();
      case 3:
        return const MyContractsScreen(userRole: 'client');
      case 4:
        return const MyDisputesScreen();
      case 5:
        return const InterviewsScreen();
      case 6:
        return const AdsManagementScreen();
      case 7:
        return const FindFreelancersScreen();
      case 8:
        return const ClientAnalyticsScreen();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildPlaceholder(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Text(
        label,
        style: TextStyle(
          fontSize: 18,
          color: isDark ? AppColors.darkTextSecondary : AppColors.gray,
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final t = AppLocalizations.of(context)!;

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () => Future.wait([
        _loadDashboard(),
        _loadMyProjects(),
        _loadClientProfile(),
        _loadUnread(),
        _loadUsage(),
        _checkPublishDraftReminder(),
      ]),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final wide = constraints.maxWidth > 900;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_usage?.activeProjectsLimit != null &&
                    (_usage!.remainingActiveProjects <= 2))
                  _UsageLimitBanner(
                    usage: _usage!,
                    onUpgrade: () =>
                        Navigator.pushNamed(context, '/subscription/plans'),
                  ),

                if (_usage != null)
                  _InterviewLimitBanner(
                    usage: _usage!,
                    onUpgrade: () =>
                        Navigator.pushNamed(context, '/subscription/plans'),
                  ),

                if (_showPublishDraftReminder)
                  _CompletePublishReminderBanner(
                    onContinue: () async {
                      await Navigator.pushNamed(
                        context,
                        '/client/create-project',
                      );
                      if (mounted) await _checkPublishDraftReminder();
                    },
                    onLater: () async {
                      await DraftLocalStorage.snoozePublishReminder();
                      await _checkPublishDraftReminder();
                    },
                  ),

                _WelcomeBanner(
                  profile: _clientProfile,
                  avatarUrl: _getAvatarUrl(_clientProfile?.avatar),
                  pendingProposals: _data?.stats.pendingProposals ?? 0,
                  activeContracts: _data?.stats.inProgressProjects ?? 0,
                  onNewProject: _navigateToCreateProject,
                  onFindFreelancers: () => setState(() => _selectedNav = 6),
                ),
                const SizedBox(height: 16),
                AdBanner(placement: 'home_top', height: 120),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.add_circle_outline,
                        bg: AppColors.accentBg,
                        color: AppColors.accent,
                        label: t.postNewProject,
                        onTap: _navigateToCreateProject,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.person_outline,
                        bg: AppColors.infoBg,
                        color: AppColors.info,
                        label: t.profile,
                        onTap: _navigateToProfile,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.description_outlined,
                        bg: AppColors.warningBg,
                        color: AppColors.warning,
                        label: t.contracts,
                        onTap: _navigateToContracts,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.interpreter_mode,
                        bg: const Color(0xFFF5F3FF),
                        color: AppColors.accent,
                        label: t.interviews,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const InterviewsScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.subscriptions,
                        bg: const Color(0xFFF3E8FF),
                        color: const Color(0xFF7C3AED),
                        label: t.mySubscription,
                        onTap: () =>
                            Navigator.pushNamed(context, '/subscription/my'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_data != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.folder_open_outlined,
                          iconBg: AppColors.accentBg,
                          iconColor: AppColors.accent,
                          value: '${_data!.stats.totalProjects}',
                          label: t.myProjects,
                          sub:
                              '${_data!.stats.inProgressProjects} active · ${_data!.stats.completedProjects} done',
                          trend: '+${_data!.stats.openProjects}',
                          progress:
                              _data!.stats.completedProjects /
                              math.max(_data!.stats.totalProjects, 1),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.send_outlined,
                          iconBg: AppColors.warningBg,
                          iconColor: AppColors.warning,
                          value: '${_data!.stats.totalProposals}',
                          label: t.proposals,
                          sub:
                              '${_data!.stats.pendingProposals} pending · ${_data!.stats.acceptedProposals} accepted',
                          trend: '+${_data!.stats.pendingProposals}',
                          trendUp: false,
                          progress:
                              _data!.stats.acceptedProposals /
                              math.max(_data!.stats.totalProposals, 1),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.payments_outlined,
                          iconBg: AppColors.successBg,
                          iconColor: AppColors.success,
                          value:
                              '\$${_data!.stats.totalSpent.toStringAsFixed(0)}',
                          label: t.totalSpent,
                          sub:
                              'Escrow: \$${_data!.stats.escrowHeld.toStringAsFixed(0)}',
                          trendValue: _data!.stats.spendingTrend,
                          trendUp: _data!.stats.trendDirection == 'up',
                          progress: 0.75,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.trending_up,
                          iconBg: const Color(0xFFFEF9C3),
                          iconColor: const Color(0xFFCA8A04),
                          value: '${_data!.stats.proposalAcceptRate}%',
                          label: t.acceptanceRate,
                          sub:
                              '${_data!.stats.acceptedProposals} of ${_data!.stats.totalProposals}',
                          trendUp: _data!.stats.proposalAcceptRate >= 40,
                          progress: _data!.stats.proposalAcceptRate / 100,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _buildAnalyticsMini(),
                  const SizedBox(height: 14),

                  if (!_loadingSuggestions && _aiSuggestions.isNotEmpty) ...[
                    _buildAISuggestions(),
                    const SizedBox(height: 14),
                  ],

                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildActiveContractsList()),
                        const SizedBox(width: 12),
                        Expanded(flex: 2, child: _buildTopFreelancersList()),
                        const SizedBox(width: 12),
                        if (_data?.topFreelancers.isNotEmpty == true)
                          Expanded(
                            flex: 2,
                            child: _buildFreelancerWithRating(
                              _data!.topFreelancers.first,
                            ),
                          ),
                      ],
                    )
                  else ...[
                    _buildActiveContractsList(),
                    const SizedBox(height: 12),
                    _buildTopFreelancersList(),
                  ],
                  const SizedBox(height: 14),

                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildSpendingChart(_data!.monthlySpending),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _buildStatusDonut(_data!.statusBreakdown),
                        ),
                      ],
                    )
                  else ...[
                    _buildSpendingChart(_data!.monthlySpending),
                    const SizedBox(height: 12),
                    _buildStatusDonut(_data!.statusBreakdown),
                  ],
                  const SizedBox(height: 14),

                  _buildActivityFeed(),
                  const SizedBox(height: 14),
                  AdBanner(placement: 'home_bottom', height: 100),
                  const SizedBox(height: 14),

                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _PremiumCard(
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/subscription/plans',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ProfileCompletionCard(
                            completion: _profileCompletion(),
                            onTap: _navigateToProfile,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _PremiumCard(
                      onTap: () =>
                          Navigator.pushNamed(context, '/subscription/plans'),
                    ),
                    const SizedBox(height: 12),
                    _ProfileCompletionCard(
                      completion: _profileCompletion(),
                      onTap: _navigateToProfile,
                    ),
                  ],
                ],
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnalyticsMini() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.primaryDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : const Color(0x06000000),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _analyticItem('98%', 'Response Rate', AppColors.accent, isDark),
          _divider(isDark),
          _analyticItem('2.5h', 'Avg Response', AppColors.info, isDark),
          _divider(isDark),
          _analyticItem('100%', 'Success Rate', AppColors.success, isDark),
        ],
      ),
    );
  }

  Widget _analyticItem(String val, String lbl, Color color, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Text(
            val,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            lbl,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? AppColors.darkTextSecondary : AppColors.gray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) => Container(
    width: 0.5,
    height: 36,
    color: isDark ? AppColors.primaryDark : AppColors.border,
  );

  Widget _buildAISuggestions() {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: const LinearGradient(
                colors: [AppColors.accent, AppColors.accentDark],
              ).toBoxDecoration(),
              child: const Icon(
                Icons.auto_awesome,
                size: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              t.aiRecommendations,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '${_aiSuggestions.length} freelancers',
              style: const TextStyle(fontSize: 11, color: AppColors.gray),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _aiSuggestions.length,
            itemBuilder: (_, i) => _buildAICard(_aiSuggestions[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildAICard(_AIFreelancerSuggestion fl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final matchC = _matchColor(fl.matchScore);
    return GestureDetector(
      onTap: () {
        final open = _myProjects.firstWhere(
          (p) => p.status == 'open',
          orElse: () => Project(),
        );
        _navigateToFreelancerProfile(fl.id, projectId: open.id?.toString());
      },
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.primaryDark : AppColors.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : const Color(0x08000000),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _avatarWidget(fl.name, _getAvatarUrl(fl.avatar), 40),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fl.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        fl.title ?? 'Freelancer',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.gray,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: matchC.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${fl.matchScore}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: matchC,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: fl.skills
                  .take(3)
                  .map(
                    (s) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        s,
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const Spacer(),
            const Divider(height: 14),
            Row(
              children: [
                const Icon(Icons.star, size: 12, color: AppColors.warning),
                const SizedBox(width: 3),
                Text(
                  fl.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.work_outline, size: 12, color: AppColors.gray),
                const SizedBox(width: 3),
                Text(
                  '${fl.experience}y',
                  style: const TextStyle(fontSize: 11, color: AppColors.gray),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text(
                    'View',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveContractsList() {
    final t = AppLocalizations.of(context)!;
    final contracts = _data?.activeContracts ?? [];
    if (contracts.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      title: 'Active Contracts 🔥',
      action: t.viewAll,
      onAction: _navigateToContracts,
      child: Column(
        children: contracts.take(3).map((c) => _buildContractRow(c)).toList(),
      ),
    );
  }

  Widget _buildContractRow(_ContractItem c) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sc = _statusColor(c.status);
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/contract',
        arguments: {'contractId': c.id, 'userRole': 'client'},
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.primaryDark.withOpacity(0.3)
              : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.primaryDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _avatarWidget(
                  c.freelancerName ?? 'F',
                  _getAvatarUrl(c.freelancerAvatar),
                  38,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.projectTitle ?? 'Project',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        c.freelancerName ?? 'Freelancer',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.gray,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: sc.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusLabel(c.status),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: sc,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '\$${c.agreedAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: c.progress / 100,
                      minHeight: 4,
                      backgroundColor: isDark
                          ? AppColors.primaryDark
                          : AppColors.borderLight,
                      valueColor: AlwaysStoppedAnimation<Color>(sc),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${c.progress}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: sc,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStatGradient(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accent, AppColors.accentDark],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.primaryDark),
          ),
        ],
      ),
    );
  }

  Widget _buildFreelancerWithRating(_FreelancerChip freelancer) {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _SectionCard(
      title: 'Top Rated ⭐',
      action: t.viewAll,
      onAction: () => setState(() => _selectedNav = 6),
      child: GestureDetector(
        onTap: () => _navigateToFreelancerProfile(freelancer.id),
        child: Row(
          children: [
            _avatarWidget(
              freelancer.name,
              _getAvatarUrl(freelancer.avatar),
              40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    freelancer.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      RatingStars(rating: freelancer.rating ?? 0, size: 12),
                      const SizedBox(width: 8),
                      Text(
                        '(${freelancer.rating?.toStringAsFixed(1) ?? "0.0"})',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.gray,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.star_border, color: Colors.amber),
              onPressed: () {
                _showFreelancerReviews(freelancer.id, freelancer.name);
              },
              tooltip: t.reviews,
            ),
          ],
        ),
      ),
    );
  }

  void _showFreelancerReviews(int freelancerId, String freelancerName) {
    final t = AppLocalizations.of(context)!;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewsScreen(
          userId: freelancerId,
          userName: freelancerName,
          userRole: 'freelancer',
        ),
      ),
    );
  }

  Widget _buildTopFreelancersList() {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final list = _data?.topFreelancers ?? [];
    if (list.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      title: 'Top Freelancers 👥',
      action: t.findWork,
      onAction: () => setState(() => _selectedNav = 6),
      child: Column(
        children: list.take(4).map((f) {
          return GestureDetector(
            onTap: () => _navigateToFreelancerProfile(f.id),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  _avatarWidget(f.name, _getAvatarUrl(f.avatar), 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      f.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (f.rating != null) ...[
                    const Icon(Icons.star, size: 12, color: AppColors.warning),
                    const SizedBox(width: 3),
                    Text(
                      f.rating!.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.gray,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSpendingChart(List<_MonthlyPoint> pts) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clean = pts.map((p) {
      final t = (p.total.isNaN || p.total.isInfinite || p.total < 0)
          ? 0.0
          : p.total;
      return _MonthlyPoint(label: p.label, total: t);
    }).toList();
    final hasData = clean.any((p) => p.total > 0);
    final maxY = hasData
        ? clean.map((p) => p.total).reduce(math.max) * 1.2
        : 100.0;

    return _SectionCard(
      title: 'Monthly Spending 📊',
      child: SizedBox(
        height: 110,
        child: !hasData
            ? Center(
                child: Text(
                  'No spending data yet',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.gray,
                    fontSize: 12,
                  ),
                ),
              )
            : BarChart(
                BarChartData(
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (g, gi, r, ri) => BarTooltipItem(
                        '\$${r.toY.toStringAsFixed(0)}',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, m) {
                          final i = v.toInt();
                          if (i < 0 || i >= clean.length)
                            return const SizedBox();
                          return Text(
                            clean[i].label,
                            style: TextStyle(
                              fontSize: 8,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.gray,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(
                    clean.length,
                    (i) => BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: clean[i].total,
                          gradient: const LinearGradient(
                            colors: [AppColors.accentLight, AppColors.accent],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: 18,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStatusDonut(List<_StatusSlice> slices) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (slices.isEmpty) return const SizedBox.shrink();
    return _SectionCard(
      title: 'Project Status',
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 26,
                sections: slices
                    .map(
                      (s) => PieChartSectionData(
                        value: s.value.toDouble(),
                        color: _hexColor(s.color),
                        radius: 34,
                        showTitle: false,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: slices
                  .take(4)
                  .map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _hexColor(s.color),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              s.label,
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.gray,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${s.value}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityFeed() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final acts = _data?.recentActivity ?? [];
    if (acts.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      title: 'Recent Activity',
      child: Column(
        children: acts
            .take(5)
            .map(
              (n) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.accentBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _activityIcon(n.type),
                        size: 15,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n.title,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            n.body,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.gray,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _timeAgo(n.createdAt),
                      style: TextStyle(
                        fontSize: 9,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.gray,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildProposalsTab() {
    final t = AppLocalizations.of(context)!;
    final proposals = _data?.recentProposals ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  t.total,
                  '${_data?.stats.totalProposals ?? 0}',
                  AppColors.accent,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _miniStat(
                  t.pending,
                  '${_data?.stats.pendingProposals ?? 0}',
                  AppColors.warning,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _miniStatGradient(
                  '${_data?.stats.proposalAcceptRate ?? 0}%',
                  t.acceptanceRate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (proposals.isEmpty)
            _buildEmptyState()
          else
            ...proposals.map((p) => _buildProposalCard(p)),
        ],
      ),
    );
  }

  Widget _buildProposalCard(_ProposalItem p) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accepted = p.status == 'accepted';

    print('📊 Proposal Card Data:');
    print('   - ID: ${p.id}');
    print('   - Freelancer ID: ${p.freelancerId}');
    print('   - Freelancer Name: ${p.freelancerName}');
    print('   - Status: ${p.status}');

    return GestureDetector(
      onTap: () {
        print('🖱️ Tapped on proposal card');
        print('   - Freelancer ID to navigate: ${p.freelancerId}');

        if (p.freelancerId != null && p.freelancerId! > 0) {
          _navigateToFreelancerProfile(p.freelancerId!);
        } else {
          Fluttertoast.showToast(
            msg: 'Cannot open freelancer profile: No valid ID',
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.primaryDark : AppColors.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : const Color(0x06000000),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _avatarWidget(
              p.freelancerName ?? 'Freelancer',
              p.freelancerAvatar,
              42,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.freelancerName ?? 'Freelancer',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${p.price.toStringAsFixed(0)} · ${p.deliveryTime} days',
                    style: const TextStyle(fontSize: 11, color: AppColors.gray),
                  ),
                  if (p.skills.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 4,
                      children: p.skills
                          .take(3)
                          .map(
                            (s) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                s,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: accepted ? AppColors.successBg : AppColors.warningBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                accepted ? 'Accepted' : 'Pending',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: accepted ? AppColors.success : AppColors.warning,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectsTab() {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  t.open,
                  '${_data?.stats.openProjects ?? 0}',
                  AppColors.info,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _miniStat(
                  t.inProgress,
                  '${_data?.stats.inProgressProjects ?? 0}',
                  AppColors.warning,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _miniStat(
                  t.completed,
                  '${_data?.stats.completedProjects ?? 0}',
                  AppColors.success,
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'My Projects',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _navigateToCreateProject,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add_circle_outline,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          t.postNewProject,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_myProjects.isEmpty)
            _buildEmptyState()
          else
            ..._myProjects.map((p) => _buildProjectCard(p)),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Project p) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color sc;
    String sl;
    switch (p.status) {
      case 'open':
        sc = AppColors.info;
        sl = 'Open';
        break;
      case 'in_progress':
        sc = AppColors.warning;
        sl = 'Active';
        break;
      case 'completed':
        sc = AppColors.success;
        sl = 'Done';
        break;
      default:
        sc = AppColors.gray;
        sl = p.status ?? '';
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.primaryDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : const Color(0x06000000),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  p.title ?? 'Untitled',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: sc.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  sl,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: sc,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            p.description ?? '',
            style: const TextStyle(fontSize: 11, color: AppColors.gray),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.attach_money, size: 13, color: AppColors.gray),
              Text(
                '\$${p.budget?.toStringAsFixed(0) ?? '0'}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(width: 14),
              const Icon(Icons.access_time, size: 12, color: AppColors.gray),
              Text(
                ' ${p.duration ?? 0}d',
                style: const TextStyle(fontSize: 11, color: AppColors.gray),
              ),
              const Spacer(),
              if (p.id != null)
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProjectProposalsScreen(projectId: p.id!),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: AppColors.accentBg,
                  ),
                  child: const Text(
                    'View Proposals',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.primaryDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : const Color(0x06000000),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? AppColors.darkTextSecondary : AppColors.gray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarWidget(String name, String? url, double size) {
    final fullUrl = _getAvatarUrl(url);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.accent, AppColors.accentDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: fullUrl.isNotEmpty
          ? ClipOval(
              child: Image.network(
                fullUrl,
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (context, error, stackTrace) {
                  print('❌ Avatar load error for $name: $error');
                  return _buildAvatarFallback(name, size);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: size * 0.5,
                      height: size * 0.5,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
              ),
            )
          : _buildAvatarFallback(name, size),
    );
  }

  Widget _buildAvatarFallback(String name, double size) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 56,
            color: isDark ? AppColors.darkTextSecondary : AppColors.gray,
          ),
          const SizedBox(height: 14),
          Text(
            'Nothing here yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create your first project to get started',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.gray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _navigateToCreateProject,
            icon: const Icon(Icons.add, size: 16),
            label: Text(t.postNewProject),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.primaryDark,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension _GradientToBoxDecoration on Gradient {
  BoxDecoration toBoxDecoration() => BoxDecoration(gradient: this);
}
