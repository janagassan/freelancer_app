// lib/screens/client/client_profile_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../l10n/app_localizations.dart';
import '../../services/profile_api_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
//  VIEW SCREEN
// ─────────────────────────────────────────────────────────────

class ClientProfileScreen extends StatefulWidget {
  final int? targetUserId;
  const ClientProfileScreen({super.key, this.targetUserId});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> _data = {};
  bool _loading = true;
  bool _isOwnProfile = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final ownIdStr = await _getOwnUserId();
    final uid = widget.targetUserId;
    _isOwnProfile = uid == null || uid.toString() == ownIdStr;

    final data = _isOwnProfile
        ? await ProfileApiService.getMyClientProfile()
        : await ProfileApiService.getClientPublicProfile(uid!);

    if (mounted)
      setState(() {
        _data = data;
        _loading = false;
      });
  }

  Future<String?> _getOwnUserId() async {
    try {
      return (await ApiService.getProfile())['id']?.toString();
    } catch (_) {
      return null;
    }
  }

  String _img(String? p) => ProfileApiService.fullImageUrl(p);

  String _initials(String n) {
    final p = n.trim().split(' ');
    return p.length >= 2
        ? '${p[0][0]}${p[1][0]}'.toUpperCase()
        : n.isNotEmpty
        ? n[0].toUpperCase()
        : '?';
  }

  String _memberSince(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  String _formatMoney(dynamic v) {
    final n = (v ?? 0) as num;
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }

  String _formatContractType(String t) =>
      {
        'hourly': 'Hourly contracts',
        'fixed': 'Fixed-price projects',
        'both': 'Both hourly & fixed',
      }[t] ??
      t;

  // ── Avatar widget matching dashboard style ──
  Widget _avatarWidget(String name, String url, double size) {
    final colors = [
      AppColors.accent,
      AppColors.info,
      AppColors.success,
      AppColors.warning,
      const Color(0xFF7C3AED),
    ];
    final color = name.isNotEmpty
        ? colors[name.codeUnitAt(0) % colors.length]
        : AppColors.accent;
    final imgUrl = _img(url);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: imgUrl.isEmpty
            ? Center(
                child: Text(
                  _initials(name),
                  style: TextStyle(
                    fontSize: size * 0.32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              )
            : CachedNetworkImage(
                imageUrl: imgUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Center(
                  child: Text(
                    _initials(name),
                    style: TextStyle(
                      fontSize: size * 0.32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  // ── Logo widget ──
  Widget _logoWidget(String? logo, String name, double size) {
    final imgUrl = _img(logo);
    if (imgUrl.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.22),
          color: Colors.white,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.2),
          child: CachedNetworkImage(
            imageUrl: imgUrl,
            fit: BoxFit.contain,
            errorWidget: (_, __, ___) => _avatarWidget(name, '', size),
          ),
        ),
      );
    }
    return _avatarWidget(name, '', size);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading)
      return Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );

    final user = Map<String, dynamic>.from(_data['user'] ?? {});
    final profile = Map<String, dynamic>.from(_data['profile'] ?? {});
    final stats = Map<String, dynamic>.from(_data['stats'] ?? {});
    final projects = List<Map<String, dynamic>>.from(
      (_data['recent_projects'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
    );

    final name = user['name'] ?? 'Client';
    final companyName = profile['company_name'] ?? '';
    final displayTitle = companyName.isNotEmpty ? companyName : name;
    final industry = profile['industry'] ?? '';
    final bio =
        profile['bio'] ?? profile['company_description'] ?? user['bio'] ?? '';
    final location = user['location'] ?? profile['location'] ?? '';
    final memberSince = _memberSince(user['member_since']?.toString());
    final strength = (profile['profile_strength'] ?? 0) as num;
    final paymentVerified = profile['payment_verified'] ?? false;
    final preferredSkills =
        List<String>.from(profile['preferred_skills'] ?? []);
    final hiringFor = List<String>.from(profile['hiring_for'] ?? []);
    final logo = profile['company_logo'];
    final avatarUrl = ProfileApiService.fullImageUrl(user['avatar']);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: Row(
        children: [
          // ── Left content area ──
          Expanded(
            child: Column(
              children: [
                // ── Top Bar ──
                _buildTopBar(isDark, name),
                // ── Body ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: LayoutBuilder(builder: (ctx, constraints) {
                      final wide = constraints.maxWidth > 800;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Profile Header Card ──
                          _buildHeaderCard(
                            isDark: isDark,
                            user: user,
                            profile: profile,
                            stats: stats,
                            name: name,
                            companyName: companyName,
                            displayTitle: displayTitle,
                            industry: industry,
                            bio: bio,
                            location: location,
                            memberSince: memberSince,
                            strength: strength,
                            paymentVerified: paymentVerified,
                            preferredSkills: preferredSkills,
                            hiringFor: hiringFor,
                            logo: logo,
                            avatarUrl: avatarUrl,
                          ),
                          const SizedBox(height: 16),
                          // ── Tabs ──
                          if (wide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _buildProjectsSectionCard(
                                      projects, isDark),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  flex: 2,
                                  child:
                                      _buildAboutSectionCard(profile, stats, isDark),
                                ),
                              ],
                            )
                          else ...[
                            _buildProjectsSectionCard(projects, isDark),
                            const SizedBox(height: 14),
                            _buildAboutSectionCard(profile, stats, isDark),
                          ],
                          const SizedBox(height: 30),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Top Bar ──
  Widget _buildTopBar(bool isDark, String name) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightCard,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
            constraints:
                const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: const EdgeInsets.all(6),
            splashRadius: 18,
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const Spacer(),
          if (_isOwnProfile)
            _topBarIconBtn(
              Icons.edit_outlined,
              isDark,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EditClientProfileScreen(),
                ),
              ).then((_) => _load()),
            )
          else
            _topBarIconBtn(Icons.share_outlined, isDark, () {}),
        ],
      ),
    );
  }

  Widget _topBarIconBtn(
      IconData icon, bool isDark, VoidCallback onTap) {
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

  // ── Header Card ──
  Widget _buildHeaderCard({
    required bool isDark,
    required Map user,
    required Map profile,
    required Map stats,
    required String name,
    required String companyName,
    required String displayTitle,
    required String industry,
    required String bio,
    required String location,
    required String memberSince,
    required num strength,
    required bool paymentVerified,
    required List<String> preferredSkills,
    required List<String> hiringFor,
    required dynamic logo,
    required String avatarUrl,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.primaryDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.25)
                : const Color(0x0A000000),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Cover ──
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: SizedBox(
              height: 130,
              width: double.infinity,
              child: user['cover_image'] != null &&
                      user['cover_image'].toString().isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: _img(user['cover_image']),
                      fit: BoxFit.cover,
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Avatar + Name row ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Transform.translate(
                      offset: const Offset(0, -30),
                      child: logo != null && logo.toString().isNotEmpty
                          ? _logoWidget(logo.toString(), name, 80)
                          : _avatarWidget(name, avatarUrl, 80),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    displayTitle,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                ),
                                if (paymentVerified)
                                  _badgeChip(
                                    'Payment Verified',
                                    AppColors.success,
                                    Icons.verified,
                                  ),
                              ],
                            ),
                            if (companyName.isNotEmpty && companyName != name)
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.gray,
                                ),
                              ),
                            if (industry.isNotEmpty)
                              Text(
                                industry,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // ── Stats row ──
                _statsRow(stats, isDark),
                const SizedBox(height: 14),
                // ── Meta info ──
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    if (location.isNotEmpty)
                      _metaItem(
                          Icons.location_on_outlined, location, isDark),
                    if (memberSince.isNotEmpty)
                      _metaItem(Icons.calendar_today_outlined,
                          'Member since $memberSince', isDark),
                    if (profile['company_size'] != null)
                      _metaItem(Icons.people_outline,
                          '${profile['company_size']} employees', isDark),
                    if (profile['founded_year'] != null)
                      _metaItem(Icons.business_outlined,
                          'Founded ${profile['founded_year']}', isDark),
                  ],
                ),
                // ── Bio ──
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _ExpandableText(text: bio, isDark: isDark),
                ],
                // ── Hiring for ──
                if (hiringFor.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Hiring for',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children:
                        hiringFor.map((s) => _hiringChip(s, isDark)).toList(),
                  ),
                ],
                // ── Skills ──
                if (preferredSkills.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Looking for skills',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: preferredSkills
                        .take(8)
                        .map((s) => _skillChip(s, isDark))
                        .toList(),
                  ),
                ],
                // ── Social links ──
                _socialRow(profile, user, isDark),
                // ── Action buttons (public view) ──
                if (!_isOwnProfile) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _actionBtn('View Projects', Icons.folder_open_outlined, true, isDark, () {})),
                      const SizedBox(width: 10),
                      Expanded(child: _actionBtn('Message', Icons.chat_bubble_outline, false, isDark, () {})),
                    ],
                  ),
                ],
                // ── Profile strength (own profile) ──
                if (_isOwnProfile) ...[
                  const SizedBox(height: 16),
                  _profileStrengthWidget(strength.toInt(), isDark),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsRow(Map stats, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primaryDark.withOpacity(0.5)
            : const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.primaryDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem('${stats['total_projects'] ?? 0}', 'Projects',
              Icons.folder_open, isDark),
          _vDivider(isDark),
          _statItem('${stats['completed_contracts'] ?? 0}', 'Hired',
              Icons.check_circle_outline, isDark),
          _vDivider(isDark),
          _statItem('\$${_formatMoney(stats['total_spent'])}', 'Spent',
              Icons.payments_outlined, isDark),
          _vDivider(isDark),
          _statItem('${stats['active_projects'] ?? 0}', 'Active',
              Icons.work_outline, isDark),
        ],
      ),
    );
  }

  Widget _statItem(
      String value, String label, IconData icon, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14,
            color: isDark ? AppColors.darkTextSecondary : AppColors.gray),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? AppColors.darkTextSecondary : AppColors.gray,
          ),
        ),
      ],
    );
  }

  Widget _vDivider(bool isDark) => Container(
        width: 1,
        height: 32,
        color: isDark ? AppColors.primaryDark : AppColors.border,
      );

  Widget _metaItem(IconData icon, String text, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13,
            color: isDark ? AppColors.darkTextSecondary : AppColors.gray),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.darkTextSecondary : AppColors.gray,
          ),
        ),
      ],
    );
  }

  Widget _badgeChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  Widget _skillChip(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accentBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentDark.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.accentDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _hiringChip(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.warning,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _socialRow(Map profile, Map user, bool isDark) {
    final links = <MapEntry<String, String>>[];
    final website =
        (profile['company_website'] ?? user['website'] ?? '').toString();
    final linkedin =
        (profile['linkedin'] ?? user['linkedin'] ?? '').toString();
    final twitter =
        (profile['twitter'] ?? user['twitter'] ?? '').toString();
    if (website.isNotEmpty) links.add(MapEntry('website', website));
    if (linkedin.isNotEmpty) links.add(MapEntry('linkedin', linkedin));
    if (twitter.isNotEmpty) links.add(MapEntry('twitter', twitter));
    if (links.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        children: [
          Text(
            'Links',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.gray,
            ),
          ),
          const SizedBox(width: 10),
          ...links.map(
            (e) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => launchUrl(Uri.parse(
                    e.value.startsWith('http')
                        ? e.value
                        : 'https://${e.value}')),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.primaryDark
                        : AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? AppColors.primaryLight.withOpacity(0.3)
                          : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_socialIcon(e.key), size: 13, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(
                        _socialLabel(e.key),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _socialIcon(String k) =>
      {'linkedin': Icons.work, 'twitter': Icons.chat, 'website': Icons.public}[
          k] ??
      Icons.link;
  String _socialLabel(String k) =>
      {'linkedin': 'LinkedIn', 'twitter': 'Twitter', 'website': 'Website'}[k] ??
      k;

  Widget _actionBtn(
      String label, IconData icon, bool filled, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: filled ? AppColors.primaryGradient : null,
          color: filled ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: filled
              ? null
              : Border.all(
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                  width: 1.5,
                ),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: filled
                    ? AppColors.accent
                    : (isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: filled
                    ? AppColors.accent
                    : (isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileStrengthWidget(int s, bool isDark) {
    final color = s < 40
        ? AppColors.danger
        : s < 70
            ? AppColors.warning
            : AppColors.success;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Profile Strength',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color),
            ),
            Text(
              '$s%',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: s / 100,
            minHeight: 6,
            backgroundColor: isDark
                ? AppColors.primaryDark
                : AppColors.border,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        if (s < 100)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Add ${_tip(s)}',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.gray,
              ),
            ),
          ),
      ],
    );
  }

  String _tip(int s) {
    if (s < 30) return 'company name, bio and industry';
    if (s < 60) return 'company logo and location';
    return 'preferred skills and social links';
  }

  // ── Projects section card ──
  Widget _buildProjectsSectionCard(
      List<Map<String, dynamic>> projects, bool isDark) {
    return _SectionCard(
      title: 'Projects',
      icon: Icons.folder_open_outlined,
      isDark: isDark,
      child: projects.isEmpty
          ? _emptyState(Icons.folder_open, 'No projects yet',
              'Projects posted will appear here', isDark)
          : Column(
              children: projects
                  .map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _projectCard(p, isDark),
                      ))
                  .toList(),
            ),
    );
  }

  Widget _projectCard(Map p, bool isDark) {
    final status = p['status'] ?? '';
    Color statusColor = status == 'open'
        ? AppColors.success
        : status == 'in_progress'
            ? AppColors.warning
            : AppColors.gray;
    String statusText = {
          'open': 'Open',
          'in_progress': 'In Progress',
          'completed': 'Completed',
          'cancelled': 'Cancelled',
        }[status] ??
        status;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primaryDark.withOpacity(0.4)
            : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.primaryDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.accentBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.work_outline,
                size: 20, color: AppColors.accentDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p['title'] ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    if (p['category'] != null)
                      Text(
                        p['category'],
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.gray,
                        ),
                      ),
                    if (p['category'] != null && p['budget'] != null)
                      Text(
                        ' · ',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.gray,
                        ),
                      ),
                    if (p['budget'] != null)
                      Text(
                        '\$${p['budget']}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── About section card ──
  Widget _buildAboutSectionCard(Map profile, Map stats, bool isDark) {
    return Column(
      children: [
        if (profile['company_description'] != null &&
            profile['company_description'].toString().isNotEmpty)
          _SectionCard(
            title: 'About the Company',
            icon: Icons.business_outlined,
            isDark: isDark,
            child: _ExpandableText(
              text: profile['company_description'],
              isDark: isDark,
            ),
          ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Hiring Details',
          icon: Icons.work_outline,
          isDark: isDark,
          child: Column(
            children: [
              if (profile['preferred_contract_type'] != null)
                _infoRow(
                  Icons.handshake_outlined,
                  'Prefers',
                  _formatContractType(
                      profile['preferred_contract_type']),
                  isDark,
                ),
              if (profile['budget_range_min'] != null ||
                  profile['budget_range_max'] != null)
                _infoRow(
                  Icons.attach_money,
                  'Budget Range',
                  '\$${profile['budget_range_min'] ?? 0} - \$${profile['budget_range_max'] ?? '∞'}',
                  isDark,
                ),
              if (profile['timezone'] != null)
                _infoRow(Icons.schedule, 'Timezone',
                    profile['timezone'], isDark),
              _infoRow(
                Icons.check_circle_outline,
                'Total Hired',
                '${stats['completed_contracts'] ?? 0} freelancers',
                isDark,
              ),
              _infoRow(
                Icons.repeat,
                'Hire Rate',
                '${profile['hire_rate'] ?? 0}%',
                isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(
      IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon,
              size: 15,
              color: isDark ? AppColors.darkTextSecondary : AppColors.gray),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.gray,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(
      IconData icon, String title, String sub, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primaryDark
                    : AppColors.lightBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  size: 36,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.gray),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.gray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  EDIT SCREEN
// ─────────────────────────────────────────────────────────────

class EditClientProfileScreen extends StatefulWidget {
  const EditClientProfileScreen({super.key});

  @override
  State<EditClientProfileScreen> createState() =>
      _EditClientProfileScreenState();
}

class _EditClientProfileScreenState extends State<EditClientProfileScreen> {
  Map<String, dynamic> _data = {};
  bool _loading = true, _saving = false;

  final _nameCtrl = TextEditingController();
  final _taglineCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _industryCtrl = TextEditingController();
  final _companyDescCtrl = TextEditingController();
  final _companyWebCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();
  final _twitterCtrl = TextEditingController();
  final _timezoneCtrl = TextEditingController();
  final _foundedCtrl = TextEditingController();
  final _budgetMinCtrl = TextEditingController();
  final _budgetMaxCtrl = TextEditingController();

  String _companySize = '2-10';
  String _contractType = 'both';
  List<String> _preferredSkills = [];
  List<String> _hiringFor = [];
  Uint8List? _avatarBytes;
  String? _avatarName;
  Uint8List? _coverBytes;
  String? _coverName;
  Uint8List? _logoBytes;
  String? _logoName;

  final _skillInput = TextEditingController();
  final _hiringInput = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _taglineCtrl, _bioCtrl, _locationCtrl, _countryCtrl,
      _phoneCtrl, _companyCtrl, _industryCtrl, _companyDescCtrl,
      _companyWebCtrl, _linkedinCtrl, _twitterCtrl, _timezoneCtrl,
      _foundedCtrl, _budgetMinCtrl, _budgetMaxCtrl, _skillInput, _hiringInput,
    ])
      c.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ProfileApiService.getMyClientProfile();
    final u = Map<String, dynamic>.from(data['user'] ?? {});
    final p = Map<String, dynamic>.from(data['profile'] ?? {});

    _nameCtrl.text = u['name'] ?? '';
    _taglineCtrl.text = p['tagline'] ?? u['tagline'] ?? '';
    _bioCtrl.text = p['bio'] ?? u['bio'] ?? '';
    _locationCtrl.text = u['location'] ?? p['location'] ?? '';
    _countryCtrl.text = u['country'] ?? p['country'] ?? '';
    _phoneCtrl.text = u['phone'] ?? p['phone'] ?? '';
    _companyCtrl.text = p['company_name'] ?? '';
    _industryCtrl.text = p['industry'] ?? '';
    _companyDescCtrl.text = p['company_description'] ?? '';
    _companyWebCtrl.text = p['company_website'] ?? u['website'] ?? '';
    _linkedinCtrl.text = p['linkedin'] ?? u['linkedin'] ?? '';
    _twitterCtrl.text = p['twitter'] ?? u['twitter'] ?? '';
    _timezoneCtrl.text = p['timezone'] ?? '';
    _foundedCtrl.text = (p['founded_year'] ?? '').toString();
    _budgetMinCtrl.text = (p['budget_range_min'] ?? '').toString();
    _budgetMaxCtrl.text = (p['budget_range_max'] ?? '').toString();
    _companySize = p['company_size'] ?? '2-10';
    _contractType = p['preferred_contract_type'] ?? 'both';
    _preferredSkills = List<String>.from(p['preferred_skills'] ?? []);
    _hiringFor = List<String>.from(p['hiring_for'] ?? []);

    setState(() {
      _data = data;
      _loading = false;
    });
  }

  Future<void> _pickImg(String type) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: type == 'cover' ? 1920 : 600,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      if (type == 'cover') {
        _coverBytes = bytes;
        _coverName = file.name;
      } else if (type == 'logo') {
        _logoBytes = bytes;
        _logoName = file.name;
      } else {
        _avatarBytes = bytes;
        _avatarName = file.name;
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final data = {
      'name': _nameCtrl.text,
      'tagline': _taglineCtrl.text,
      'bio': _bioCtrl.text,
      'location': _locationCtrl.text,
      'country': _countryCtrl.text,
      'phone': _phoneCtrl.text,
      'company_name': _companyCtrl.text,
      'industry': _industryCtrl.text,
      'company_description': _companyDescCtrl.text,
      'company_website': _companyWebCtrl.text,
      'linkedin': _linkedinCtrl.text,
      'twitter': _twitterCtrl.text,
      'timezone': _timezoneCtrl.text,
      'founded_year': int.tryParse(_foundedCtrl.text),
      'budget_range_min': double.tryParse(_budgetMinCtrl.text),
      'budget_range_max': double.tryParse(_budgetMaxCtrl.text),
      'company_size': _companySize,
      'preferred_contract_type': _contractType,
      'preferred_skills': _preferredSkills,
      'hiring_for': _hiringFor,
    };
    final res = await ProfileApiService.updateClientProfile(
      data,
      avatarBytes: _avatarBytes,
      avatarFileName: _avatarName,
      coverBytes: _coverBytes,
      coverFileName: _coverName,
    );

    if (_logoBytes != null)
      await ProfileApiService.uploadCompanyLogo(_logoBytes!, _logoName!);

    setState(() => _saving = false);
    if (res['profile_strength'] != null ||
        res['message']?.toString().contains('✅') == true) {
      Fluttertoast.showToast(
        msg: '✅ Profile updated!',
        backgroundColor: AppColors.primary,
        textColor: AppColors.accent,
      );
      Navigator.pop(context, true);
    } else {
      Fluttertoast.showToast(
        msg: res['message'] ?? 'Error',
        backgroundColor: AppColors.danger,
        textColor: Colors.white,
      );
    }
  }

  void _addChip(List<String> list, TextEditingController ctrl) {
    final s = ctrl.text.trim();
    if (s.isNotEmpty && !list.contains(s))
      setState(() {
        list.add(s);
        ctrl.clear();
      });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: Column(
        children: [
          // ── Top Bar ──
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightCard,
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.close,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      size: 20),
                  onPressed: () => Navigator.pop(context),
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: const EdgeInsets.all(6),
                  splashRadius: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const Spacer(),
                _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accent,
                        ),
                      )
                    : GestureDetector(
                        onTap: _save,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 7),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Save',
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: LayoutBuilder(builder: (ctx, constraints) {
                      final wide = constraints.maxWidth > 800;
                      return Column(
                        children: [
                          // ── Cover & avatars ──
                          _coverAvatarSection(isDark),
                          const SizedBox(height: 16),
                          if (wide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(children: [
                                    _formSection(
                                      'Personal Info',
                                      Icons.person_outline,
                                      isDark,
                                      [
                                        _field('Full Name', _nameCtrl,
                                            isDark: isDark,
                                            hint: 'Your name'),
                                        _field('Tagline', _taglineCtrl,
                                            isDark: isDark,
                                            hint:
                                                "What you're looking for",
                                            maxLength: 160),
                                        _field('Bio', _bioCtrl,
                                            isDark: isDark,
                                            hint:
                                                'Tell freelancers about yourself...',
                                            maxLines: 4),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _formSection(
                                      'Location & Contact',
                                      Icons.location_on_outlined,
                                      isDark,
                                      [
                                        _field('Location', _locationCtrl,
                                            isDark: isDark,
                                            hint: 'City, Region'),
                                        _field('Country', _countryCtrl,
                                            isDark: isDark,
                                            hint: 'Country'),
                                        _field('Timezone', _timezoneCtrl,
                                            isDark: isDark,
                                            hint: 'e.g. GMT+3'),
                                        _field('Phone', _phoneCtrl,
                                            isDark: isDark,
                                            hint: '+1 ···',
                                            keyboardType:
                                                TextInputType.phone),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _formSection(
                                      'Social Links',
                                      Icons.link,
                                      isDark,
                                      [
                                        _field('LinkedIn', _linkedinCtrl,
                                            isDark: isDark,
                                            hint:
                                                'https://linkedin.com/company/...',
                                            prefixIcon: Icons.work),
                                        _field('Twitter', _twitterCtrl,
                                            isDark: isDark,
                                            hint:
                                                'https://twitter.com/...',
                                            prefixIcon: Icons.chat),
                                      ],
                                    ),
                                  ]),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(children: [
                                    _formSection(
                                      'Company Info',
                                      Icons.business,
                                      isDark,
                                      [
                                        _field('Company Name', _companyCtrl,
                                            isDark: isDark,
                                            hint: 'Your company name'),
                                        _field('Industry', _industryCtrl,
                                            isDark: isDark,
                                            hint:
                                                'e.g. Software, E-commerce'),
                                        _field(
                                            'Company Description',
                                            _companyDescCtrl,
                                            isDark: isDark,
                                            hint:
                                                'What does your company do?',
                                            maxLines: 3),
                                        _field(
                                            'Company Website',
                                            _companyWebCtrl,
                                            isDark: isDark,
                                            hint: 'https://company.com',
                                            prefixIcon: Icons.public),
                                        _field('Founded Year', _foundedCtrl,
                                            isDark: isDark,
                                            hint: '2020',
                                            keyboardType:
                                                TextInputType.number),
                                        _companySizePicker(isDark),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _formSection(
                                      'Hiring Preferences',
                                      Icons.work_outline,
                                      isDark,
                                      [
                                        _contractTypePicker(isDark),
                                        Row(children: [
                                          Expanded(
                                            child: _field(
                                                'Min Budget (\$)',
                                                _budgetMinCtrl,
                                                isDark: isDark,
                                                hint: '100',
                                                keyboardType:
                                                    TextInputType
                                                        .number),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _field(
                                                'Max Budget (\$)',
                                                _budgetMaxCtrl,
                                                isDark: isDark,
                                                hint: '5000',
                                                keyboardType:
                                                    TextInputType
                                                        .number),
                                          ),
                                        ]),
                                        _chipsEditor(
                                          'Skills Needed',
                                          _preferredSkills,
                                          _skillInput,
                                          'Add skill...',
                                          isDark,
                                        ),
                                        _chipsEditor(
                                          'Hiring for (Project Types)',
                                          _hiringFor,
                                          _hiringInput,
                                          'e.g. Mobile App, Website...',
                                          isDark,
                                        ),
                                      ],
                                    ),
                                  ]),
                                ),
                              ],
                            )
                          else ...[
                            _formSection('Personal Info', Icons.person_outline,
                                isDark, [
                              _field('Full Name', _nameCtrl,
                                  isDark: isDark, hint: 'Your name'),
                              _field('Tagline', _taglineCtrl,
                                  isDark: isDark,
                                  hint: "What you're looking for",
                                  maxLength: 160),
                              _field('Bio', _bioCtrl,
                                  isDark: isDark,
                                  hint:
                                      'Tell freelancers about yourself...',
                                  maxLines: 4),
                            ]),
                            const SizedBox(height: 16),
                            _formSection('Company Info', Icons.business,
                                isDark, [
                              _field('Company Name', _companyCtrl,
                                  isDark: isDark,
                                  hint: 'Your company name'),
                              _field('Industry', _industryCtrl,
                                  isDark: isDark,
                                  hint: 'e.g. Software, E-commerce'),
                              _field('Company Description', _companyDescCtrl,
                                  isDark: isDark,
                                  hint: 'What does your company do?',
                                  maxLines: 3),
                              _field('Company Website', _companyWebCtrl,
                                  isDark: isDark,
                                  hint: 'https://company.com',
                                  prefixIcon: Icons.public),
                              _field('Founded Year', _foundedCtrl,
                                  isDark: isDark,
                                  hint: '2020',
                                  keyboardType: TextInputType.number),
                              _companySizePicker(isDark),
                            ]),
                            const SizedBox(height: 16),
                            _formSection(
                                'Location & Contact',
                                Icons.location_on_outlined,
                                isDark, [
                              _field('Location', _locationCtrl,
                                  isDark: isDark, hint: 'City, Region'),
                              _field('Country', _countryCtrl,
                                  isDark: isDark, hint: 'Country'),
                              _field('Timezone', _timezoneCtrl,
                                  isDark: isDark, hint: 'e.g. GMT+3'),
                              _field('Phone', _phoneCtrl,
                                  isDark: isDark,
                                  hint: '+1 ···',
                                  keyboardType: TextInputType.phone),
                            ]),
                            const SizedBox(height: 16),
                            _formSection(
                                'Hiring Preferences', Icons.work_outline,
                                isDark, [
                              _contractTypePicker(isDark),
                              Row(children: [
                                Expanded(
                                  child: _field('Min Budget (\$)',
                                      _budgetMinCtrl,
                                      isDark: isDark,
                                      hint: '100',
                                      keyboardType: TextInputType.number),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _field('Max Budget (\$)',
                                      _budgetMaxCtrl,
                                      isDark: isDark,
                                      hint: '5000',
                                      keyboardType: TextInputType.number),
                                ),
                              ]),
                              _chipsEditor('Skills Needed', _preferredSkills,
                                  _skillInput, 'Add skill...', isDark),
                              _chipsEditor(
                                  'Hiring for (Project Types)',
                                  _hiringFor,
                                  _hiringInput,
                                  'e.g. Mobile App, Website...',
                                  isDark),
                            ]),
                            const SizedBox(height: 16),
                            _formSection(
                                'Social Links', Icons.link, isDark, [
                              _field('LinkedIn', _linkedinCtrl,
                                  isDark: isDark,
                                  hint:
                                      'https://linkedin.com/company/...',
                                  prefixIcon: Icons.work),
                              _field('Twitter', _twitterCtrl,
                                  isDark: isDark,
                                  hint: 'https://twitter.com/...',
                                  prefixIcon: Icons.chat),
                            ]),
                          ],
                          const SizedBox(height: 24),
                          // ── Save button ──
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _saving ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: _saving
                                      ? const CircularProgressIndicator(
                                          color: AppColors.accent,
                                          strokeWidth: 2,
                                        )
                                      : const Text(
                                          'Save Changes',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.accent,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      );
                    }),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Cover / Avatar / Logo section ──
  Widget _coverAvatarSection(bool isDark) {
    final u = Map<String, dynamic>.from(_data['user'] ?? {});
    final p = Map<String, dynamic>.from(_data['profile'] ?? {});
    final existingCover =
        ProfileApiService.fullImageUrl(u['cover_image']);
    final existingAvatar =
        ProfileApiService.fullImageUrl(u['avatar']);
    final existingLogo =
        ProfileApiService.fullImageUrl(p['company_logo']);
    final name = u['name'] ?? 'C';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.primaryDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.25)
                : const Color(0x08000000),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Cover ──
          GestureDetector(
            onTap: () => _pickImg('cover'),
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: SizedBox(
                height: 130,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_coverBytes != null)
                      Image.memory(_coverBytes!, fit: BoxFit.cover)
                    else if (existingCover.isNotEmpty)
                      CachedNetworkImage(
                          imageUrl: existingCover, fit: BoxFit.cover)
                    else
                      Container(
                        decoration: const BoxDecoration(
                            gradient: AppColors.primaryGradient),
                      ),
                    Container(color: Colors.black.withOpacity(0.25)),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_photo_alternate,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Change Cover',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Avatar ──
                GestureDetector(
                  onTap: () => _pickImg('avatar'),
                  child: Stack(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 2.5),
                          gradient: AppColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.25),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _avatarBytes != null
                              ? Image.memory(_avatarBytes!,
                                  fit: BoxFit.cover)
                              : existingAvatar.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: existingAvatar,
                                      fit: BoxFit.cover)
                                  : Center(
                                      child: Text(
                                        name[0].toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                    ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: isDark
                                    ? AppColors.darkCard
                                    : Colors.white,
                                width: 1.5),
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 12,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // ── Logo ──
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickImg('logo'),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      height: 68,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.primaryDark
                            : AppColors.lightBackground,
                        border: Border.all(
                          color: isDark
                              ? AppColors.primaryLight.withOpacity(0.3)
                              : AppColors.borderLight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _logoBytes != null
                          ? Image.memory(_logoBytes!, fit: BoxFit.contain)
                          : existingLogo.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: existingLogo,
                                  fit: BoxFit.contain)
                              : Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.business,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.gray,
                                        size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Upload Company Logo',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.gray,
                                      ),
                                    ),
                                  ],
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

  // ── Form section wrapper ──
  Widget _formSection(
      String title, IconData icon, bool isDark, List<Widget> children) {
    return Container(
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
                : const Color(0x06000000),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.accentBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: AppColors.accentDark),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),
          Divider(
              height: 1,
              color:
                  isDark ? AppColors.primaryDark : AppColors.borderLight),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children
                  .map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: c,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Field ──
  Widget _field(
    String label,
    TextEditingController ctrl, {
    required bool isDark,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    int? maxLength,
    IconData? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          maxLength: maxLength,
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark
                  ? AppColors.darkTextHint
                  : AppColors.lightTextHint,
              fontSize: 13,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon,
                    size: 16,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.gray)
                : null,
            filled: true,
            fillColor: isDark
                ? AppColors.primaryDark.withOpacity(0.5)
                : AppColors.lightBackground,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark
                    ? AppColors.primaryLight.withOpacity(0.3)
                    : AppColors.borderLight,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark
                    ? AppColors.primaryLight.withOpacity(0.3)
                    : AppColors.borderLight,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.accent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ── Company size picker ──
  Widget _companySizePicker(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Company Size',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: ['1', '2-10', '11-50', '51-200', '201-1000', '1000+']
              .map((s) {
            final sel = _companySize == s;
            return GestureDetector(
              onTap: () => setState(() => _companySize = s),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  gradient: sel ? AppColors.primaryGradient : null,
                  color: sel
                      ? null
                      : (isDark
                          ? AppColors.primaryDark
                          : AppColors.lightBackground),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: sel
                        ? AppColors.accent
                        : (isDark
                            ? AppColors.primaryLight.withOpacity(0.3)
                            : AppColors.borderLight),
                  ),
                ),
                child: Text(
                  s,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: sel
                        ? AppColors.accent
                        : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.gray),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Contract type picker ──
  Widget _contractTypePicker(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferred Contract Type',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _cBtn('Hourly', 'hourly', isDark),
            const SizedBox(width: 8),
            _cBtn('Fixed Price', 'fixed', isDark),
            const SizedBox(width: 8),
            _cBtn('Both', 'both', isDark),
          ],
        ),
      ],
    );
  }

  Widget _cBtn(String label, String val, bool isDark) {
    final sel = _contractType == val;
    return GestureDetector(
      onTap: () => setState(() => _contractType = val),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: sel ? AppColors.primaryGradient : null,
          color: sel
              ? null
              : (isDark
                  ? AppColors.primaryDark
                  : AppColors.lightBackground),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: sel
                ? AppColors.accent
                : (isDark
                    ? AppColors.primaryLight.withOpacity(0.3)
                    : AppColors.borderLight),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: sel
                ? AppColors.accent
                : (isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.gray),
          ),
        ),
      ),
    );
  }

  // ── Chips editor ──
  Widget _chipsEditor(
    String label,
    List<String> list,
    TextEditingController ctrl,
    String hint,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: ctrl,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppColors.darkTextHint
                        : AppColors.lightTextHint,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.primaryDark.withOpacity(0.5)
                      : AppColors.lightBackground,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.primaryLight.withOpacity(0.3)
                          : AppColors.borderLight,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.primaryLight.withOpacity(0.3)
                          : AppColors.borderLight,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppColors.accent),
                  ),
                ),
                onFieldSubmitted: (_) => _addChip(list, ctrl),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _addChip(list, ctrl),
              child: Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add,
                    color: AppColors.accent, size: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: list
              .asMap()
              .entries
              .map(
                (e) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accentBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color:
                            AppColors.accentDark.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        e.value,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.accentDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 5),
                      GestureDetector(
                        onTap: () =>
                            setState(() => list.removeAt(e.key)),
                        child: const Icon(Icons.close,
                            size: 14, color: AppColors.accentDark),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SHARED WIDGETS
// ─────────────────────────────────────────────────────────────

/// Reusable section card matching dashboard _SectionCard style
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;
  final Widget child;
  final String? action;
  final VoidCallback? onAction;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.isDark,
    required this.child,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.accentBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        Icon(icon, size: 15, color: AppColors.accentDark),
                  ),
                  const SizedBox(width: 10),
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
                ],
              ),
              if (action != null && onAction != null)
                GestureDetector(
                  onTap: onAction,
                  child: const Text(
                    'See all',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.accent),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Expandable bio text
class _ExpandableText extends StatefulWidget {
  final String text;
  final bool isDark;
  const _ExpandableText({required this.text, required this.isDark});

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _exp = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: _exp ? null : 4,
          overflow: _exp ? null : TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            color: widget.isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
            height: 1.6,
          ),
        ),
        if (widget.text.length > 200)
          GestureDetector(
            onTap: () => setState(() => _exp = !_exp),
            child: Text(
              _exp ? 'Show less' : 'Show more',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}