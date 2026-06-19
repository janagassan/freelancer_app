// screens/freelancer/freelancer_home_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:freelancer_platform/l10n/app_localizations.dart';
import 'package:freelancer_platform/screens/affiliate/affiliate_screen.dart';
import 'package:freelancer_platform/screens/chat/chats_list_screen.dart';
import 'package:freelancer_platform/screens/contract/my_contracts_screen.dart';
import 'package:freelancer_platform/screens/features/features_shop_screen.dart';
import 'package:freelancer_platform/screens/disputes/my_disputes_screen.dart';
import 'package:freelancer_platform/screens/freelancer/advanced_search_screen.dart';
import 'package:freelancer_platform/screens/freelancer/edit_profile_screen.dart';
import 'package:freelancer_platform/screens/freelancer/favorites_screen.dart';
import 'package:freelancer_platform/screens/freelancer/financial_dashboard_screen.dart';
import 'package:freelancer_platform/screens/freelancer/offers_screen.dart';
import 'package:freelancer_platform/screens/notifications/notifications_screen.dart';
import 'package:freelancer_platform/screens/rating/reviews_screen.dart';
import 'package:freelancer_platform/screens/skill_tests/skill_tests_screen.dart';
import 'package:freelancer_platform/services/socket_service.dart';
import 'package:freelancer_platform/widgets/ad_banner.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../theme/app_theme.dart' as AppTheme;

import '../../models/calendar_event.dart';
import '../../models/contract_model.dart';
import '../../models/freelancer_model.dart';
import '../../models/interview_model.dart';
import '../../models/project_model.dart';
import '../../models/usage_limits_model.dart';
import '../../services/api_service.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import '../../services/profile_api_service.dart';
import 'project_details_screen.dart';
import 'my_proposals_screen.dart';
import 'my_projects_screen.dart';
import 'projects_tab.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum ProjectFilter { bestMatches, mostRecent, saved }

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final bool showNumber;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.showNumber = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          final fill = (rating >= index + 1)
              ? 1.0
              : (rating > index ? rating - index : 0.0);
          return Icon(
            fill >= 0.5 ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: size,
          );
        }),
        if (showNumber) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.8,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ],
    );
  }
}

class PortfolioCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onTap;

  const PortfolioCard({super.key, required this.item, this.onTap});

  List<String> _parseTechnologies(dynamic techs) {
    if (techs == null) return [];
    if (techs is List) return List<String>.from(techs);
    if (techs is String) {
      try {
        final decoded = jsonDecode(techs);
        if (decoded is List) return List<String>.from(decoded);
        return [];
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  List<String> _parseImages(dynamic images) {
    if (images == null) return [];
    if (images is List) return List<String>.from(images);
    if (images is String) {
      try {
        final decoded = jsonDecode(images);
        if (decoded is List) return List<String>.from(decoded);
        return [];
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final images = _parseImages(item['images']);
    final technologies = _parseTechnologies(item['technologies']);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (images.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: images.length == 1
                    ? CachedNetworkImage(
                        imageUrl: images[0],
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          height: 180,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          height: 180,
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 40,
                          ),
                        ),
                      )
                    : SizedBox(
                        height: 180,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: images.length,
                          itemBuilder: (_, i) => CachedNetworkImage(
                            imageUrl: images[i],
                            width: 180,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
              )
            else
              Container(
                height: 120,
                width: double.infinity,
                color: theme.colorScheme.primary.withOpacity(0.1),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 40,
                        color: theme.colorScheme.primary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t?.noImage ?? 'No image',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] ?? 'Untitled',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['description'] ?? '',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (technologies.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: technologies
                          .map(
                            (tech) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                tech,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.primary,
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
          ],
        ),
      ),
    );
  }
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
  final FreelancerProfile? profile;
  final String avatarUrl;
  final VoidCallback onEditProfile;
  final Map<String, dynamic>? stats;

  const _Sidebar({
    required this.selectedIndex,
    required this.onItemTap,
    required this.profile,
    required this.avatarUrl,
    required this.onEditProfile,
    this.stats,
  });

  List<_SidebarItem> get _items {
    final totalProposals = stats?['totalProposals'] ?? 0;
    final activeProjects = stats?['activeProjects'] ?? 0;
    final pendingOffers = stats?['pendingOffers'] ?? 0;

    return [
      _SidebarItem(icon: Icons.person_outline, labelKey: 'home'),
      _SidebarItem(icon: Icons.search, labelKey: 'findWork'),
      _SidebarItem(icon: Icons.send_outlined, labelKey: 'myProposals', badge: totalProposals > 0 ? totalProposals : null),
      _SidebarItem(icon: Icons.work_outline, labelKey: 'myProjects'),
      _SidebarItem(
        icon: Icons.description_outlined,
        labelKey: 'contracts',
        badge: activeProjects > 0 ? activeProjects : null,
        badgeGreen: true,
      ),
      _SidebarItem(icon: Icons.gavel_outlined, labelKey: 'disputes'),
      _SidebarItem(icon: Icons.attach_money, labelKey: 'financial'),
      _SidebarItem(icon: Icons.mail_outline, labelKey: 'offers', badge: pendingOffers > 0 ? pendingOffers : null),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sidebarColor = isDark
        ? AppTheme.AppColors.darkSidebar
        : AppTheme.AppColors.lightSidebar;

    final sidebarTextColor = isDark
        ? AppTheme.AppColors.darkTextSecondary
        : Colors.white70;

    final sidebarTextColorActive = Colors.white;
    final badgeColor = AppTheme.AppColors.accent;

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

          GestureDetector(
            onTap: onEditProfile,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.AppColors.accent,
                    backgroundImage:
                      profile?.avatar != null &&
                          profile!.avatar!.isNotEmpty
                      ? NetworkImage(_getAvatarUrl(profile!.avatar!))
                      : null,
                  child: profile?.avatar == null
                      ? Text(
                          profile?.name?.isNotEmpty == true
                              ? profile!.name![0].toUpperCase()
                              : 'F',
                          style: const TextStyle(
                            color: AppTheme.AppColors.primaryDark,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.name ?? t!.freelancer ?? 'Freelancer',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          profile?.title ?? 'Developer',
                          style: TextStyle(
                            color: AppTheme.AppColors.accent,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
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
                final isActive = selectedIndex == i;
                final label = _getLabel(t!, item.labelKey);
                return GestureDetector(
                  onTap: () => onItemTap(i),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.AppColors.accent.withOpacity(0.25)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isActive
                          ? Border(
                              left: BorderSide(
                                color: AppTheme.AppColors.accent,
                                width: 3,
                              ),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          size: 18,
                          color: isActive
                              ? sidebarTextColorActive
                              : sidebarTextColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 13,
                              color: isActive
                                  ? sidebarTextColorActive
                                  : sidebarTextColor,
                              fontWeight: isActive
                                  ? FontWeight.w500
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
                                  ? AppTheme.AppColors.secondary
                                  : badgeColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${item.badge}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
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
              placement: 'home_bottom',
              height: 150,
              margin: EdgeInsets.zero,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _sidebarActionBtn(
                  context,
                  Icons.logout,
                  'logout',
                  color: Colors.red.shade300,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getAvatarUrl(String? avatar) {
    if (avatar == null || avatar.isEmpty) return '';
    if (avatar.startsWith('http')) return avatar;
    if (avatar.startsWith('/uploads')) {
      return 'http://localhost:5001$avatar';
    }
    return avatar;
  }

  String _getLabel(AppLocalizations t, String key) {
    switch (key) {
      case 'home':
        return t.home;
      case 'findWork':
        return t.findWork;
      case 'myProposals':
        return t.myProposals;
      case 'myProjects':
        return t.myProjects;
      case 'contracts':
        return t.contracts;
      case 'disputes':
        return t.disputes;
      case 'favorites':
        return t.favorites;
      case 'financial':
        return t.financial;
      case 'advancedSearch':
        return t.advancedSearch;
      case 'offers':
        return t.offers;
      default:
        return key;
    }
  }

  Widget _sidebarActionBtn(
    BuildContext context,
    IconData icon,
    String labelKey, {
    Color? color,
  }) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultColor = isDark
        ? AppTheme.AppColors.darkTextSecondary
        : Colors.white70;

    final label = labelKey == 'settings' ? t!.settings : t!.logout;
    final finalColor = color ?? defaultColor;

    return Row(
      children: [
        Icon(icon, size: 16, color: finalColor),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 12, color: finalColor)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String labelKey;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.labelKey,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    String label;
    switch (labelKey) {
      case 'active':
        label = t!.activeProjects;
        break;
      case 'proposals':
        label = t!.proposals;
        break;
      case 'rating':
        label = t!.rating;
        break;
      case 'jss':
        label = t!.jobSuccessScore;
        break;
      default:
        label = labelKey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _FreelancerHomeScheduleCard extends StatefulWidget {
  const _FreelancerHomeScheduleCard();

  @override
  State<_FreelancerHomeScheduleCard> createState() =>
      _FreelancerHomeScheduleCardState();
}

class _FreelancerHomeScheduleCardState
    extends State<_FreelancerHomeScheduleCard> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<CalendarEvent> _milestones = [];
  List<InterviewInvitation> _interviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final y = _focusedDay.year;
      final m = _focusedDay.month;
      final raw = await ApiService.getCalendarEvents(y, m);
      final invRes = await ApiService.getUserInterviews();

      final events = <CalendarEvent>[];
      if (raw is List) {
        for (final e in raw) {
          try {
            events.add(
              CalendarEvent.fromJson(Map<String, dynamic>.from(e as Map)),
            );
          } catch (_) {}
        }
      }

      List<InterviewInvitation> inv = [];
      if (invRes['invitations'] != null) {
        for (final j in invRes['invitations'] as List) {
          try {
            inv.add(
              InterviewInvitation.fromJson(Map<String, dynamic>.from(j as Map)),
            );
          } catch (_) {}
        }
      }

      inv = inv
          .where(
            (i) =>
                i.selectedTime != null &&
                (i.status == 'accepted' ||
                    i.status == 'pending' ||
                    i.status == 'rescheduled'),
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _milestones = events;
        _interviews = inv;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> _markersForDay(DateTime day) {
    final out = <dynamic>[];
    for (final e in _milestones) {
      if (isSameDay(e.date, day)) out.add(e);
    }
    for (final i in _interviews) {
      if (i.selectedTime != null && isSameDay(i.selectedTime!, day)) {
        out.add(i);
      }
    }
    return out;
  }

  List<_ScheduleListItem> _itemsForSelectedDay() {
    final out = <_ScheduleListItem>[];
    for (final e in _milestones) {
      if (isSameDay(e.date, _selectedDay)) {
        out.add(
          _ScheduleListItem(
            time: e.date,
            title: e.title,
            subtitle: e.projectTitle ?? e.type,
            color: e.color,
            icon: e.type == 'reminder' ? Icons.alarm : Icons.flag_outlined,
          ),
        );
      }
    }
    for (final i in _interviews) {
      if (i.selectedTime != null && isSameDay(i.selectedTime!, _selectedDay)) {
        out.add(
          _ScheduleListItem(
            time: i.selectedTime!,
            title: 'Interview',
            subtitle: i.project?.title ?? 'Project #${i.projectId}',
            color: Colors.deepPurple,
            icon: Icons.video_call_outlined,
          ),
        );
      }
    }
    out.sort((a, b) => a.time.compareTo(b.time));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final dayItems = _itemsForSelectedDay();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              Icon(
                Icons.calendar_month,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  t!.schedule,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: _load,
                  tooltip: 'Refresh',
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
  t.milestonesRemindersInterviews,
  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
),
          const SizedBox(height: 8),
          TableCalendar<dynamic>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2032, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
            calendarFormat: CalendarFormat.twoWeeks,
            availableCalendarFormats: const {CalendarFormat.twoWeeks: '2w'},
            startingDayOfWeek: StartingDayOfWeek.monday,
            rowHeight: 30,
            daysOfWeekHeight: 16,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              leftChevronIcon: const Icon(Icons.chevron_left, size: 20),
              rightChevronIcon: const Icon(Icons.chevron_right, size: 20),
              headerPadding: EdgeInsets.zero,
              headerMargin: const EdgeInsets.only(bottom: 4),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade700,
              ),
              weekendStyle: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade700,
              ),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              cellMargin: const EdgeInsets.all(2),
              markersMaxCount: 3,
              markerDecoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              defaultTextStyle: const TextStyle(fontSize: 11),
              weekendTextStyle: const TextStyle(fontSize: 11),
            ),
            eventLoader: _markersForDay,
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            onPageChanged: (focused) {
              _focusedDay = focused;
              _load();
            },
          ),
          const Divider(height: 16),
          Text(
            DateFormat.yMMMd().format(_selectedDay),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 6),
          if (dayItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                t.nothingOnThisDay,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            )
          else
            ...dayItems
                .take(4)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(item.icon, size: 14, color: item.color),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                item.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                  height: 1.2,
                                ),
                              ),
                              Text(
                                DateFormat.jm().format(item.time),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: item.color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          if (dayItems.length > 4)
            Text(
              '+${dayItems.length - 4} ${t.more}',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/calendar'),
              icon: Icon(
                Icons.open_in_new,
                size: 14,
                color: theme.colorScheme.primary,
              ),
              label: Text(
                t.fullCalendar,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.colorScheme.primary),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleListItem {
  final DateTime time;
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;

  _ScheduleListItem({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });
}

class _PremiumCard extends StatelessWidget {
  final VoidCallback onSubscribe;

  const _PremiumCard({required this.onSubscribe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark
        ? AppTheme.AppColors.darkSurface
        : AppTheme.AppColors.lightSidebar;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t!.premium,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t.individualSubscription,
            style: TextStyle(color: theme.colorScheme.primary, fontSize: 11),
          ),
          const SizedBox(height: 12),
          ...[
            t.oneMonthFree,
            t.twoMonthsStudentDiscount,
            t.cancelAnytime,
            t.bestDealsMonthly,
          ].map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.check, color: theme.colorScheme.primary, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.AppColors.darkTextSecondary
                            : AppTheme.AppColors.lightTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSubscribe,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: bgColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                t.subscribe,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FreelancerProposalUsageBanner extends StatelessWidget {
  final UsageLimits usage;
  final VoidCallback onUpgrade;

  const _FreelancerProposalUsageBanner({
    required this.usage,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final rem = usage.remainingProposals;
    final lim = usage.proposalsLimit;
    if (lim == null || rem < 0) return const SizedBox.shrink();

    final isMax = rem <= 0;
    final bg = isMax ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB);
    final border = isMax ? const Color(0xFFFECACA) : const Color(0xFFFDE68A);
    final fg = isMax ? const Color(0xFFB91C1C) : const Color(0xFFB45309);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(
            isMax ? Icons.block : Icons.warning_amber_rounded,
            color: fg,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMax ? t!.proposalLimitReached : t!.proposalsRunningLow,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isMax
                      ? '$lim ${t.proposalsPerMonth}'
                      : '$rem ${t.proposalsLeftThisMonth}',
                  style: TextStyle(fontSize: 11, color: fg.withOpacity(0.9)),
                ),
              ],
            ),
          ),
          if (isMax)
            TextButton(
              onPressed: onUpgrade,
              style: TextButton.styleFrom(foregroundColor: fg),
              child: Text(t?.upgrade ?? 'Upgrade'),
            ),
        ],
      ),
    );
  }
}

class FreelancerHomeScreen extends StatefulWidget {
  const FreelancerHomeScreen({super.key});

  @override
  State<FreelancerHomeScreen> createState() => _FreelancerHomeScreenState();
}

class _FreelancerHomeScreenState extends State<FreelancerHomeScreen> {
  FreelancerProfile? profile;
  List<Map<String, dynamic>> recentCompletedProjects = [];
  List<Project> recommendedProjects = [];
  List<Project> aiSuggestedProjects = [];
  List<Contract> activeContracts = [];
  Map<String, dynamic>? stats;
  List<Map<String, dynamic>> portfolioItems = [];
  int _unreadNotificationsCount = 0;
  int _selectedNavIndex = 0;
  int _unreadOffersCount = 0;

  bool loadingProfile = true;
  bool loadingProjects = true;
  bool loadingSuggestions = true;
  bool loadingContracts = true;
  bool loadingPortfolio = true;

  final int _unreadMessages = 3;
  ProjectFilter _projectFilter = ProjectFilter.bestMatches;
  List<Project> _savedProjects = [];
  bool _loadingSaved = false;
  UsageLimits? _usage;

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _loadUnreadNotificationsCount();
  }

  Future<void> _loadUnreadOffersCount() async {
    try {
      final count = await ApiService.getUnreadOffersCount();
      setState(() {
        _unreadOffersCount = count;
      });
    } catch (e) {
      debugPrint('Error loading offers count: $e');
    }
  }

  Future<void> _loadUnreadNotificationsCount() async {
    try {
      final result = await ApiService.getUnreadCount();
      setState(() {
        _unreadNotificationsCount = result['unreadCount'] ?? 0;
      });
    } catch (e) {
      debugPrint('Error loading unread count: $e');
    }
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      fetchProfile(),
      fetchRecommendedProjects(),
      fetchAISuggestions(),
      fetchStats(),
      fetchActiveContracts(),
      fetchPortfolio(),
      _loadUsage(),
      _loadUnreadOffersCount(),
    ]);
  }

  Future<void> _loadUsage() async {
    try {
      final r = await ApiService.getUserUsage();
      if (!mounted) return;
      if (r['usage'] != null) {
        setState(() {
          _usage = UsageLimits.fromJson(
            Map<String, dynamic>.from(r['usage'] as Map),
          );
        });
      }
    } catch (_) {}
  }

  Future<void> _loadSavedProjects() async {
    setState(() => _loadingSaved = true);
    try {
      final response = await ApiService.getUserFavorites();
      if (response.success) {
        setState(() {
          _savedProjects = response.favorites.map((f) => f.project).toList();
          _loadingSaved = false;
        });
      }
    } catch (e) {
      setState(() => _loadingSaved = false);
    }
  }

  List<Project> get _filteredProjects {
    switch (_projectFilter) {
      case ProjectFilter.bestMatches:
        return aiSuggestedProjects;
      case ProjectFilter.mostRecent:
        return [...recommendedProjects]
          ..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
      case ProjectFilter.saved:
        return _savedProjects;
    }
  }

  String _getFilterTitle(AppLocalizations t) {
    switch (_projectFilter) {
      case ProjectFilter.bestMatches:
        return t.bestMatches;
      case ProjectFilter.mostRecent:
        return t.mostRecent;
      case ProjectFilter.saved:
        return t.savedJobs;
    }
  }

  Widget _buildProjectFilterTabs() {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _buildFilterTab(theme, ProjectFilter.bestMatches, t!.bestMatches),
          const SizedBox(width: 16),
          _buildFilterTab(theme, ProjectFilter.mostRecent, t!.mostRecent),
          const SizedBox(width: 16),
          _buildFilterTab(theme, ProjectFilter.saved, t!.savedJobs),
        ],
      ),
    );
  }

  Widget _buildFilterTab(ThemeData theme, ProjectFilter filter, String label) {
    final isSelected = _projectFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() => _projectFilter = filter);
        if (filter == ProjectFilter.saved && _savedProjects.isEmpty) {
          _loadSavedProjects();
        }
      },
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? theme.colorScheme.secondary
                  : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 40,
            color: isSelected
                ? theme.colorScheme.secondary
                : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsSection() {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final projects = _filteredProjects;

    if (_projectFilter == ProjectFilter.saved &&
        _savedProjects.isEmpty &&
        !_loadingSaved) {
      _loadSavedProjects();
    }

    final isLoading = _projectFilter == ProjectFilter.bestMatches
        ? loadingSuggestions
        : _projectFilter == ProjectFilter.saved
        ? _loadingSaved
        : false;

    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (projects.isEmpty) {
      if (_projectFilter == ProjectFilter.saved) {
        return Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.favorite_border,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                t!.noSavedJobsYet,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    setState(() => _projectFilter = ProjectFilter.bestMatches),
                child: Text(
                  t!.findWork,
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
        );
      }

      if (_projectFilter == ProjectFilter.bestMatches &&
          loadingSuggestions == false) {
        return Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.auto_awesome, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                t!.noAISuggestionsYet,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: fetchAISuggestions,
                child: Text(
                  t!.refreshSuggestions,
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
        );
      }

      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getFilterTitle(t!),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (projects.length > 3)
                TextButton(
                  onPressed: () => setState(() => _selectedNavIndex = 1),
                  child: Text(
                    t.viewAll,
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...projects.take(3).map((project) => _buildProjectCard(project)),
      ],
    );
  }

  Future<void> fetchProfile() async {
    setState(() => loadingProfile = true);
    try {
      final results = await Future.wait([
        ApiService.getProfile(),
        ProfileApiService.getMyFreelancerProfile(),
      ]);
      final res = Map<String, dynamic>.from(results[0] as Map);
      final detailedProfile = Map<String, dynamic>.from(results[1] as Map);
      final recentProjectsRaw =
          detailedProfile['recent_completed_projects'] as List<dynamic>? ?? [];

      setState(() {
        profile = FreelancerProfile.fromJson(res);
        recentCompletedProjects = recentProjectsRaw
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        loadingProfile = false;
      });
    } catch (e) {
      setState(() => loadingProfile = false);
      Fluttertoast.showToast(msg: 'Error loading profile: $e');
    }
  }

  Future<void> fetchRecommendedProjects() async {
    setState(() => loadingProjects = true);
    try {
      final data = await ApiService.getAllProjects();
      setState(() {
        recommendedProjects = data
            .map((j) => Project.fromJson(j))
            .take(5)
            .toList();
        loadingProjects = false;
      });
    } catch (e) {
      setState(() => loadingProjects = false);
    }
  }

  Future<void> fetchAISuggestions() async {
    setState(() => loadingSuggestions = true);
    try {
      final response = await ApiService.getAISuggestedProjects();
      if (response['success'] == true && response['suggestions'] != null) {
        setState(() {
          aiSuggestedProjects = (response['suggestions'] as List).map((j) {
            final project = Project.fromJson(j);
            if (j['matchScore'] != null) {
              project.matchScore = j['matchScore'];
            }
            return project;
          }).toList();
          loadingSuggestions = false;
        });
      } else {
        setState(() => loadingSuggestions = false);
      }
    } catch (e) {
      setState(() => loadingSuggestions = false);
    }
  }

  Future<void> fetchActiveContracts() async {
    setState(() => loadingContracts = true);
    try {
      final data = await ApiService.getFreelancerContracts();
      setState(() {
        activeContracts = data
            .map((j) => Contract.fromJson(j))
            .where(
              (c) =>
                  c.status == 'active' ||
                  c.status == 'pending_freelancer' ||
                  c.status == 'pending_client',
            )
            .toList();
        loadingContracts = false;
      });
    } catch (e) {
      setState(() {
        activeContracts = [];
        loadingContracts = false;
      });
    }
  }

  Future<void> fetchStats() async {
    try {
      final response = await ApiService.getFreelancerStats();
      setState(() => stats = response['stats']);
    } catch (e) {
      debugPrint('Error fetching stats: $e');
    }
  }

  Future<void> fetchPortfolio() async {
    setState(() => loadingPortfolio = true);
    try {
      final response = await ApiService.getPortfolio(profile?.id);
      print('📦 Portfolio API Response: $response');
      print('📦 Response type: ${response.runtimeType}');
      print('📦 Response length: ${response.length}');

      if (response is List && response.isNotEmpty) {
        print('📦 First item: ${response[0]}');
      }

      setState(() {
        portfolioItems = List<Map<String, dynamic>>.from(response);
        loadingPortfolio = false;
      });
    } catch (e) {
      print('❌ Error fetching portfolio: $e');
      setState(() => loadingPortfolio = false);
    }
  }

  void navigateToEditProfile() async {
    if (profile == null) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditProfileScreen(profile: profile!)),
    );
    if (result == true) {
      await fetchProfile();
      await fetchPortfolio();
    }
  }

  Future<void> _openChatWithClient(
    int? clientId,
    String clientName,
    String? clientAvatar,
  ) async {
    if (clientId == null || clientId == 0) {
      Fluttertoast.showToast(msg: 'Cannot start chat: Client ID is missing');
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final result = await ChatService.createChat(clientId);
      if (mounted) Navigator.pop(context);
      final chatId = result['success'] == true
          ? (result['chat']?['id'])
          : result['id'];
      if (chatId == null || chatId == 0) {
        Fluttertoast.showToast(msg: 'Failed to create chat.');
        return;
      }
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/chat',
          arguments: {
            'chatId': chatId,
            'otherUserId': clientId,
            'otherUserName': clientName.isNotEmpty ? clientName : 'Client',
            'otherUserAvatar': clientAvatar,
          },
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      Fluttertoast.showToast(msg: 'Error opening chat: $e');
    }
  }

  double get profileCompletion {
    int completed = 0;
    const int total = 9;
    if (profile?.name?.isNotEmpty == true) completed++;
    if (profile?.title?.isNotEmpty == true) completed++;
    if (profile?.bio?.isNotEmpty == true) completed++;
    if (profile?.avatar?.isNotEmpty == true) completed++;
    if (profile?.skills?.isNotEmpty == true) completed++;
    if (profile?.cvUrl?.isNotEmpty == true) completed++;
    if (portfolioItems.isNotEmpty) completed++;
    if ((profile?.hourlyRate ?? 0) > 0) completed++;
    if (profile?.location?.isNotEmpty == true) completed++;
    return completed / total * 100;
  }

  String _getAvatarUrl(String? avatar) {
    if (avatar == null || avatar.isEmpty) return '';
    if (avatar.startsWith('http')) return avatar;
    return 'http://localhost:5001$avatar';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'Just now';
  }

  Color _getMatchScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.blue;
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'pending_freelancer':
      case 'pending_client':
        return Colors.orange;
      case 'completed':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status, AppLocalizations t) {
    switch (status) {
      case 'active':
        return t.inProgress;
      case 'pending_freelancer':
        return t.pendingYourSignature;
      case 'pending_client':
        return t.pendingClient;
      case 'completed':
        return t.completed;
      default:
        return status ?? 'Unknown';
    }
  }

  Future<bool> _showLogoutDialog() async {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    return await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(t!.logout),
            content: Text(t!.logoutConfirmation),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(t!.cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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

                  Navigator.pop(context);

                  if (mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                child: Text(t.logout),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildTopBar() {
  final theme = Theme.of(context);
  final t = AppLocalizations.of(context);
  final isDark = theme.brightness == Brightness.dark;

  final topBarColor = isDark
      ? AppTheme.AppColors.darkBackground
      : AppTheme.AppColors.lightSidebar;

  final textColor = Colors.white;
  final iconColor = Colors.white70;

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    decoration: BoxDecoration(
      color: topBarColor,
      border: Border(
        bottom: BorderSide(color: theme.dividerColor, width: 0.5),
      ),
    ),
    child: Row(
      children: [
        Text(
          t!.profile,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: Icon(Icons.search, color: iconColor),
          onPressed: () => setState(() => _selectedNavIndex = 1),
        ),
        IconButton(
          icon: Icon(Icons.star_border, color: iconColor),
          tooltip: t.upgrade,
          onPressed: () => Navigator.pushNamed(context, '/subscription/my'),
        ),
        Stack(
          children: [
            IconButton(
              icon: Icon(Icons.chat_bubble_outline, color: iconColor),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatsListScreen()),
              ),
            ),
            if (_unreadMessages > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppTheme.AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 15,
                    minHeight: 15,
                  ),
                  child: Text(
                    '$_unreadMessages',
                    style: const TextStyle(color: Colors.white, fontSize: 9),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        Stack(
          children: [
            IconButton(
              icon: Icon(Icons.notifications_none, color: iconColor),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(),
                ),
              ).then((_) => _loadUnreadNotificationsCount()),
            ),
            if (_unreadNotificationsCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 15,
                    minHeight: 15,
                  ),
                  child: Text(
                    _unreadNotificationsCount > 99
                        ? '99+'
                        : '$_unreadNotificationsCount',
                    style: const TextStyle(color: Colors.white, fontSize: 9),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: iconColor),
          onSelected: (value) {
            switch (value) {
              case 'wallet':
                Navigator.pushNamed(
                  context,
                  '/wallet',
                  arguments: 'freelancer',
                );
                break;
             
              case 'interviews':
                Navigator.pushNamed(context, '/interviews');
                break;
              case 'share':
                final shareUrl =
                    '${dotenv.env['FRONTEND_URL']}/freelancer/${profile?.id}';
                Share.share('${t.shareProfileText} $shareUrl');
                break;
              case 'affiliate':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AffiliateScreen()),
                );
                break;
              case 'settings':
                Navigator.pushNamed(context, '/settings');
                break;
              case 'subscription':
                Navigator.pushNamed(context, '/subscription/plans');
                break;
              case 'logout':
                _showLogoutDialog();
                break;
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'wallet',
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet),
                  const SizedBox(width: 12),
                  Text(t.wallet),
                ],
              ),
            ),
           
            PopupMenuItem(
              value: 'interviews',
              child: Row(
                children: [
                  const Icon(Icons.interpreter_mode),
                  const SizedBox(width: 12),
                  Text(t.interviews),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  const Icon(Icons.share),
                  const SizedBox(width: 12),
                  Text(t.shareProfile),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  const Icon(Icons.settings),
                  const SizedBox(width: 12),
                  Text(t.settings),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'subscription',
              child: Row(
                children: [
                  const Icon(Icons.subscriptions),
                  const SizedBox(width: 12),
                  Text(t.plans),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  const Icon(Icons.logout, color: Colors.red),
                  const SizedBox(width: 12),
                  Text(t.logout, style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}


  Widget _buildProfileHeaderCard() {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final avatarUrl = _getAvatarUrl(profile?.avatar);
    final totalProposals = stats?['totalProposals'] ?? 0;
    final acceptedProposals = stats?['acceptedProposals'] ?? 0;
    final jss = totalProposals > 0
        ? (acceptedProposals / totalProposals * 100).toInt()
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: theme.colorScheme.primary,
                backgroundImage: avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl.isEmpty
                    ? Text(
                        profile?.name?.isNotEmpty == true
                            ? profile!.name![0].toUpperCase()
                            : 'F',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),

              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.name ?? t!.freelancer,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (profile?.title?.isNotEmpty == true)
                      Text(
                        profile!.title!,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (profile?.location?.isNotEmpty == true)
                      _infoRow(Icons.location_on_outlined, profile!.location!),
                    if (profile?.email?.isNotEmpty == true)
                      _infoRow(Icons.email_outlined, profile!.email!),
                  ],
                ),
              ),
              GestureDetector(
                onTap: navigateToEditProfile,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),

          _buildRatingSection(t!),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.work_outline,
                  value: stats?['activeProjects']?.toString() ?? '0',
                  labelKey: 'active',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  icon: Icons.send_outlined,
                  value: stats?['totalProposals']?.toString() ?? '0',
                  labelKey: 'proposals',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  icon: Icons.star_outline,
                  value: profile?.rating?.toStringAsFixed(1) ?? '0.0',
                  labelKey: 'rating',
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  icon: Icons.trending_up,
                  value: '$jss%',
                  labelKey: 'jss',
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),

          if (profileCompletion < 100) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t!.profileCompletion,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  '${profileCompletion.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: profileCompletion / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingSection(AppLocalizations t) {
    final theme = Theme.of(context);
    if (profile == null) {
      return const SizedBox.shrink();
    }

    final userId = profile!.id;
    final rating = profile!.rating;

    if (userId == null || rating == null) {
      return const SizedBox.shrink();
    }

    final userName = profile!.name ?? 'Freelancer';

    return GestureDetector(
      onTap: () {
        if (userId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReviewsScreen(
                userId: userId,
                userName: userName,
                userRole: 'freelancer',
              ),
            ),
          );
        } else {
          Fluttertoast.showToast(msg: 'Unable to load reviews');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.star, color: Colors.amber),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${rating.toStringAsFixed(1)} ★',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    t.tapToSeeAllReviews,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.grey.shade500),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveProjectsList() {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    if (loadingContracts) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (activeContracts.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              Text(
                t!.activeProjectsFire,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedNavIndex = 4),
                child: Text(
                  t.viewAll,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...activeContracts.take(3).map((contract) => _buildContractListItem(contract, t)),
        ],
      ),
    );
  }

  Widget _buildContractListItem(Contract contract, AppLocalizations t) {
    final theme = Theme.of(context);
    final project = contract.project;
    if (project == null) return const SizedBox.shrink();

    double progress = 0;
    if (contract.milestones?.isNotEmpty == true) {
      final completed = contract.milestones!
          .where((m) => m['status'] == 'completed')
          .length;
      progress = completed / contract.milestones!.length;
    } else {
      progress = contract.status == 'active' ? 0.5 : 0.2;
    }

    final statusColor = _getStatusColor(contract.status);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/contract',
        arguments: {'contractId': contract.id, 'userRole': 'freelancer'},
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title ?? 'Untitled',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    project.skills?.take(3).join(' · ') ?? '',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusText(contract.status, t),
                    style: TextStyle(
                      fontSize: 9,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _openChatWithClient(
                    project.client?.id ?? 0,
                    project.client?.name ?? 'Client',
                    project.client?.avatar,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      size: 12,
                      color: theme.colorScheme.secondary,
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

  Widget _buildTrendingSkills() {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final skills = [
      {'name': 'Flutter', 'color': Colors.blue},
      {'name': 'React', 'color': Colors.cyan},
      {'name': 'Python', 'color': Colors.green},
      {'name': 'UI/UX', 'color': Colors.purple},
      {'name': 'Node.js', 'color': Colors.orange},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t!.trendingSkills,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills.map((s) {
              final color = s['color'] as Color;
              final isMySkill = profile?.skills?.contains(s['name']) == true;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isMySkill
                      ? color.withOpacity(0.15)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isMySkill
                        ? color.withOpacity(0.4)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  s['name'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: isMySkill ? color : Colors.grey.shade700,
                    fontWeight: isMySkill ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveredProjectsSection() {
    final t = AppLocalizations.of(context);
    if (recentCompletedProjects.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t!.recentlyDeliveredProjects,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...recentCompletedProjects.take(5).map((item) {
            final title = item['title']?.toString() ?? 'Delivered project';
            final category = item['category']?.toString() ?? '';
            final budget =
                double.tryParse((item['budget'] ?? '').toString()) ?? 0;
            final deliveredAt = DateTime.tryParse(
              (item['delivered_at'] ?? '').toString(),
            );

            return ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(Icons.task_alt, color: theme.colorScheme.secondary),
              title: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                [
                  if (category.isNotEmpty) category,
                  if (budget > 0) '\$${budget.toStringAsFixed(0)}',
                  if (deliveredAt != null) _formatDate(deliveredAt),
                ].join(' · '),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    if (loadingProfile) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: theme.colorScheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeaderCard(),
            const SizedBox(height: 12),
            AdBanner(placement: 'home_top', height: 100),
            const SizedBox(height: 12),
            if (_usage != null &&
                _usage!.hasProposalLimit &&
                (_usage!.remainingProposals <= 2))
              _FreelancerProposalUsageBanner(
                usage: _usage!,
                onUpgrade: () =>
                    Navigator.pushNamed(context, '/subscription/plans'),
              ),
            const SizedBox(height: 16),
            _buildActiveProjectsList(),
            const SizedBox(height: 16),

            _buildProjectFilterTabs(),
            const SizedBox(height: 12),
            _buildProjectsSection(),

            const SizedBox(height: 16),
            _buildDeliveredProjectsSection(),

            const SizedBox(height: 20),

            if (portfolioItems.isNotEmpty) ...[
              Text(
                t!.myPortfolio,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ...portfolioItems
                  .take(2)
                  .map((item) => PortfolioCard(item: item, onTap: () {})),
              const SizedBox(height: 4),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProjectDetailsScreen(projectId: project.id!),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    project.title ?? 'Untitled',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (project.matchScore != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _getMatchScoreColor(
                        project.matchScore!,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${project.matchScore}% Match',
                      style: TextStyle(
                        fontSize: 10,
                        color: _getMatchScoreColor(project.matchScore!),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              project.description ?? '',
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${project.duration} days',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.location_on,
                      size: 12,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Remote',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Text(
                  '\$${project.budget?.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightColumn() {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const _FreelancerHomeScheduleCard(),
          const SizedBox(height: 14),
          AdBanner(placement: 'sidebar_top', height: 120),
          const SizedBox(height: 14),
          _PremiumCard(
            onSubscribe: () =>
                Navigator.pushNamed(context, '/subscription/plans'),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t!.skillTests,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _skillTestRow(Icons.code, 'Programming', Colors.blue),
                _skillTestRow(Icons.design_services, 'Design', Colors.purple),
                _skillTestRow(Icons.trending_up, 'Marketing', Colors.orange),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SkillTestsScreen(),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.colorScheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      t.viewAllTests,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.primary,
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

  Widget _skillTestRow(IconData icon, String title, Color color) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SkillTestsScreen()),
      ),
    );
  }

  Widget _buildBody() {
    print('🟢 _buildBody called, index: $_selectedNavIndex');
    switch (_selectedNavIndex) {
      case 0:
        return _buildHomeTabWithRightPanel();
      case 1:
        return const ProjectsTab();
      case 2:
        return const MyProposalsScreen();
      case 3:
        return const MyProjectsScreen();
      case 4:
        return const MyContractsScreen(userRole: 'freelancer');
      case 5:
        return const MyDisputesScreen();
      case 6:
        return const FinancialDashboardScreen();
      case 7:
        print('🟢 Going to OffersScreen');
        return const OffersScreen();
      case 8:
        return const SkillTestsScreen();
      default:
        return _buildHomeTabWithRightPanel();
    }
  }

  Widget _buildHomeTabWithRightPanel() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildHomeContent()),
              SizedBox(width: 280, child: _buildRightColumn()),
            ],
          );
        }
        return _buildHomeContent();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loadingProfile) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final avatarUrl = _getAvatarUrl(profile?.avatar);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          _Sidebar(
            selectedIndex: _selectedNavIndex,
            onItemTap: (i) {
              print('🟡 onItemTap called with index: $i');
              print('🟡 Current _selectedNavIndex: $_selectedNavIndex');
              setState(() {
                _selectedNavIndex = i;
              });
              print('🟡 New _selectedNavIndex: $_selectedNavIndex');
            },
            profile: profile,
            avatarUrl: avatarUrl,
            onEditProfile: navigateToEditProfile,
            stats: stats,
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
}