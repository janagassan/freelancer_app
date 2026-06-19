// enhanced_client_profile_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../services/profile_api_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'client_profile_screen.dart';

class EnhancedClientProfileScreen extends StatefulWidget {
  final int? targetUserId;
  const EnhancedClientProfileScreen({super.key, this.targetUserId});

  @override
  State<EnhancedClientProfileScreen> createState() =>
      _EnhancedClientProfileScreenState();
}

class _EnhancedClientProfileScreenState
    extends State<EnhancedClientProfileScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic> _data = {};
  bool _loading = true;
  bool _isOwnProfile = false;
  late TabController _tabController;
  late ScrollController _scrollController;
  bool _showAppBarTitle = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _load();
  }

  void _onScroll() {
    if (_scrollController.offset > 200 && !_showAppBarTitle) {
      setState(() => _showAppBarTitle = true);
    } else if (_scrollController.offset <= 200 && _showAppBarTitle) {
      setState(() => _showAppBarTitle = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final userId = widget.targetUserId;
    final ownIdStr = await _getOwnUserId();
    _isOwnProfile = userId == null || userId.toString() == ownIdStr;

    Map<String, dynamic> data;
    if (_isOwnProfile) {
      data = await ProfileApiService.getMyClientProfile();
    } else {
      data = await ProfileApiService.getClientPublicProfile(userId!);
    }

    if (mounted)
      setState(() {
        _data = data;
        _loading = false;
      });
  }

  Future<String?> _getOwnUserId() async {
    try {
      final profile = await ApiService.getProfile();
      return profile['id']?.toString();
    } catch (_) {
      return null;
    }
  }

  String _img(String? p) => ProfileApiService.fullImageUrl(p);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;

    if (_loading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                localizations.loading_profile,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? AppColors.darkTextHint : AppColors.gray,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final user = Map<String, dynamic>.from(_data['user'] ?? {});
    final profile = Map<String, dynamic>.from(_data['profile'] ?? {});
    final stats = Map<String, dynamic>.from(_data['stats'] ?? {});
    final jobs = List<Map<String, dynamic>>.from(
      (_data['jobs'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
    );
    final reviews = List<Map<String, dynamic>>.from(
      (_data['reviews'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
    );

    final name = user['name'] ?? 'Client';
    final companyName = profile['company_name'] ?? '';
    final title = profile['tagline'] ?? user['tagline'] ?? '';
    final bio = profile['bio'] ?? user['bio'] ?? '';
    final location = user['location'] ?? profile['location'] ?? '';
    final industry = profile['industry'] ?? '';
    final companySize = profile['company_size'] ?? '';
    final website = profile['company_website'] ?? '';
    final foundedYear = profile['founded_year'];
    final badges = List.from(profile['badges'] ?? []);

    final totalSpent = (profile['total_spent'] ?? 0) as num;
    final totalProjects = (profile['total_projects'] ?? 0) as num;
    final completedContracts = (profile['completed_contracts'] ?? 0) as num;
    final clientRating = (profile['client_rating'] ?? 0) as num;
    final totalReviewsReceived = (profile['total_reviews_received'] ?? 0) as num;
    final hireRate = (profile['hire_rate'] ?? 0) as num;

    final isPaymentVerified = profile['payment_verified'] ?? false;
    final isCompanyVerified = profile['company_verified'] ?? false;
    final isTopClient = profile['is_top_client'] ?? false;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkCard : AppColors.lightSurface).withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.arrow_back, color: isDark ? AppColors.darkTextPrimary : AppColors.dark, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (_isOwnProfile) ...[
                _buildActionButton(Icons.edit, localizations.edit, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditClientProfileScreen(),
                    ),
                  ).then((_) => _load());
                }),
                _buildActionButton(Icons.share, localizations.share, () {}),
              ] else ...[
                _buildActionButton(Icons.message, localizations.message, () {}),
                _buildActionButton(Icons.more_vert, localizations.more, () {}),
              ],
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: _showAppBarTitle
                  ? Text(
                      companyName.isNotEmpty ? companyName : name,
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  user['cover_image'] != null &&
                          user['cover_image'].toString().isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: _img(user['cover_image']),
                          fit: BoxFit.cover,
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary, AppColors.accent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: _buildQuickStats(
                      totalSpent.toDouble(),
                      totalProjects.toInt(),
                      completedContracts.toInt(),
                      hireRate.toInt(),
                      localizations,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: _buildProfileHeader(
                    user,
                    profile,
                    name,
                    companyName,
                    title,
                    location,
                    industry,
                    isPaymentVerified,
                    isCompanyVerified,
                    localizations,
                  ),
                ),
                const SizedBox(height: 24),
                if (badges.isNotEmpty || isTopClient)
                  _buildBadgesSection(badges, isTopClient, localizations),
                const SizedBox(height: 24),
                _buildCompanySection(companySize, foundedYear, website, localizations),
                const SizedBox(height: 24),
                _buildHiringStats(profile, localizations),
                const SizedBox(height: 24),
                _buildTabsSection(localizations),
              ],
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(profile, user, localizations),
                _buildJobsTab(jobs, localizations, _isOwnProfile),
                _buildReviewsTab(reviews, clientRating.toDouble(), totalReviewsReceived.toInt(), localizations),
                _buildAnalyticsTab(profile, localizations),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getClientTypeText(Map profile, AppLocalizations localizations) {
    final clientType = profile['client_type'] ?? 'individual';
    return clientType == 'company' ? localizations.verified_business : localizations.individual_client;
  }

  Widget _buildClientTypeBadge(Map profile, AppLocalizations localizations) {
    final clientType = profile['client_type'] ?? 'individual';
    final isCompany = clientType == 'company';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCompany
              ? [AppColors.success, AppColors.success.withOpacity(0.8)]
              : [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompany ? Icons.business : Icons.person,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            _getClientTypeText(profile, localizations),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String tooltip, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.darkCard : AppColors.lightSurface).withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: isDark ? AppColors.darkTextPrimary : AppColors.dark, size: 18),
        ),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildQuickStats(
    double totalSpent,
    int totalProjects,
    int completedContracts,
    int hireRate,
    AppLocalizations localizations,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickStat('\$', '\$${totalSpent.toStringAsFixed(0)}', localizations.totalSpent),
          _buildQuickStat('📋', totalProjects.toString(), localizations.projects),
          _buildQuickStat('✅', completedContracts.toString(), localizations.completed),
          if (hireRate > 0) _buildQuickStat('🎯', '$hireRate%', localizations.hire_rate),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(
    Map user,
    Map profile,
    String name,
    String companyName,
    String title,
    String location,
    String industry,
    bool isPaymentVerified,
    bool isCompanyVerified,
    AppLocalizations localizations,
  ) {
    final companySize = profile['company_size'] ?? '';
    final foundedYear = profile['founded_year'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                      border: Border.all(color: isDark ? AppColors.darkSurface : Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: profile['company_logo'] != null &&
                              profile['company_logo'].toString().isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: _img(profile['company_logo']),
                              fit: BoxFit.cover,
                            )
                          : user['avatar'] != null &&
                                  user['avatar'].toString().isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: _img(user['avatar']),
                                  fit: BoxFit.cover,
                                )
                              : Center(
                                  child: Text(
                                    (companyName.isNotEmpty ? companyName : name).isNotEmpty
                                        ? (companyName.isNotEmpty ? companyName : name)[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                    ),
                  ),
                  if (isPaymentVerified || isCompanyVerified)
                    Positioned(
                      bottom: -4,
                      right: -4,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isCompanyVerified)
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                                border: Border.all(color: isDark ? AppColors.darkSurface : Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.business, color: Colors.white, size: 14),
                            ),
                          if (isPaymentVerified)
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: isDark ? AppColors.darkSurface : Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.payment, color: Colors.white, size: 14),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            companyName.isNotEmpty ? companyName : name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
                            ),
                          ),
                        ),
                        if (companyName.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _buildClientTypeBadge(profile, localizations),
                        ],
                        if (!_isOwnProfile)
                          Container(
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.handshake, color: Colors.white, size: 16),
                              label: Text(localizations.hire, style: const TextStyle(color: Colors.white)),
                            ),
                          ),
                      ],
                    ),
                    if (title.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.gray,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    if (industry.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          industry,
                          style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkTextHint : AppColors.gray),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        if (location.isNotEmpty) _buildHeaderIcon(Icons.location_on_outlined, location),
                        if (companySize.isNotEmpty) _buildHeaderIcon(Icons.people_outline, companySize),
                        if (foundedYear != null) _buildHeaderIcon(Icons.calendar_today, '${localizations.since} $foundedYear'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!_isOwnProfile) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.message_outlined, color: AppColors.primary),
                      label: Text(localizations.message, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
                    child: TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.favorite_border, color: Colors.white),
                      label: Text(localizations.follow, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: isDark ? AppColors.darkTextHint : AppColors.gray),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkTextHint : AppColors.gray, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildBadgesSection(List badges, bool isTopClient, AppLocalizations localizations) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(localizations.achievements, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.dark)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (isTopClient) _buildBadge(localizations.top_client, Icons.star, AppColors.warning),
              ...badges.map((badge) => _buildBadge(badge['name'] ?? localizations.badge, Icons.emoji_events, AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildCompanySection(String companySize, int? foundedYear, String website, AppLocalizations localizations) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(localizations.company_information, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.dark)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildInfoCard(localizations.company_size, companySize.isNotEmpty ? companySize : localizations.notSpecified, Icons.people, AppColors.primary)),
              if (foundedYear != null) ...[
                const SizedBox(width: 12),
                Expanded(child: _buildInfoCard(localizations.founded, foundedYear.toString(), Icons.calendar_today, AppColors.secondary)),
              ],
            ],
          ),
          if (website.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.language, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(website, style: TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600))),
                  IconButton(onPressed: () => launchUrl(Uri.parse('https://$website')), icon: Icon(Icons.open_in_new, color: AppColors.primary, size: 18)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.dark)),
          Text(title, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextHint : AppColors.gray, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildHiringStats(Map profile, AppLocalizations localizations) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(localizations.hiring_statistics, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.dark)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildMetricCard(localizations.avg_budget, '\$${(profile['avg_project_budget'] ?? 0).toStringAsFixed(0)}', Icons.account_balance_wallet, AppColors.success)),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard(localizations.active_contracts, '${profile['active_contracts'] ?? 0}', Icons.assignment, AppColors.warning)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMetricCard(localizations.client_rating, '${(profile['client_rating'] ?? 0).toStringAsFixed(1)}', Icons.star, AppColors.accent)),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard(localizations.repeat_hire_rate, '${(profile['repeat_hire_rate'] ?? 0).toStringAsFixed(0)}%', Icons.repeat, AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.dark)),
          Text(title, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextHint : AppColors.gray, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTabsSection(AppLocalizations localizations) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: isDark ? AppColors.darkTextHint : AppColors.gray,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        tabs: [
          Tab(text: localizations.overview),
          Tab(text: localizations.jobs),
          Tab(text: localizations.reviews),
          Tab(text: localizations.analytics),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Map profile, Map user, AppLocalizations localizations) {
    final bio = profile['bio'] ?? user['bio'] ?? '';
    final preferredSkills = List<String>.from(profile['preferred_skills'] ?? []);
    final hiringFor = List<String>.from(profile['hiring_for'] ?? []);
    final communicationMethods = List<String>.from(profile['preferred_communication_methods'] ?? []);
    final projectTools = List<String>.from(profile['project_management_tools'] ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (bio.isNotEmpty) _buildSectionCard(localizations.about_company, Icons.business, [Text(bio, style: TextStyle(fontSize: 15, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.gray, height: 1.5))]),
          if (preferredSkills.isNotEmpty) _buildSectionCard(localizations.preferred_skills, Icons.psychology, [Wrap(spacing: 8, runSpacing: 8, children: preferredSkills.map((skill) => _buildSkillChip(skill)).toList())]),
          if (hiringFor.isNotEmpty) _buildSectionCard(localizations.currently_hiring_for, Icons.person_search, [Wrap(spacing: 8, runSpacing: 8, children: hiringFor.map((role) => _buildSkillChip(role)).toList())]),
          if (communicationMethods.isNotEmpty) _buildSectionCard(localizations.communication_methods, Icons.chat, [Wrap(spacing: 8, runSpacing: 8, children: communicationMethods.map((method) => _buildSkillChip(method)).toList())]),
          if (projectTools.isNotEmpty) _buildSectionCard(localizations.project_management_tools, Icons.settings, [Wrap(spacing: 8, runSpacing: 8, children: projectTools.map((tool) => _buildSkillChip(tool)).toList())]),
        ].where((widget) => widget != null).toList(),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: AppColors.primary, size: 20)),
                const SizedBox(width: 12),
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.dark)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)),
        ],
      ),
    );
  }

  Widget _buildSkillChip(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.1), AppColors.primaryDark.withOpacity(0.1)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Text(skill, style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildJobsTab(List jobs, AppLocalizations localizations, bool isOwnProfile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_outline, size: 64, color: isDark ? AppColors.darkTextHint : AppColors.gray),
            const SizedBox(height: 16),
            Text(localizations.no_active_jobs, style: TextStyle(fontSize: 18, color: isDark ? AppColors.darkTextHint : AppColors.gray, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(isOwnProfile ? localizations.post_job_to_start : localizations.client_no_jobs, style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkTextHint : AppColors.gray), textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: jobs.length, itemBuilder: (context, index) => _buildJobCard(jobs[index], localizations));
  }

  Widget _buildJobCard(Map job, AppLocalizations localizations) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(job['title'] ?? localizations.job_title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.dark))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(job['status'] ?? localizations.active, style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(job['description'] ?? '', style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.gray, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.attach_money, color: AppColors.primary, size: 16),
              const SizedBox(width: 4),
              Text('\$${job['budget'] ?? '0'}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const SizedBox(width: 16),
              Icon(Icons.schedule, color: isDark ? AppColors.darkTextHint : AppColors.gray, size: 16),
              const SizedBox(width: 4),
              Text(job['duration'] ?? localizations.notSpecified, style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkTextHint : AppColors.gray)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab(List reviews, double avg, int total, AppLocalizations localizations) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (total > 0) _buildRatingOverview(avg, total, localizations),
          if (reviews.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.star_outline, size: 64, color: isDark ? AppColors.darkTextHint : AppColors.gray),
                  const SizedBox(height: 16),
                  Text(localizations.noReviewsYet, style: TextStyle(fontSize: 18, color: isDark ? AppColors.darkTextHint : AppColors.gray, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(localizations.reviews_will_appear, style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkTextHint : AppColors.gray)),
                ],
              ),
            )
          else
            ...reviews.map((review) => Padding(padding: const EdgeInsets.only(bottom: 16), child: _buildReviewCard(review, localizations))),
        ],
      ),
    );
  }

  Widget _buildRatingOverview(double avg, int total, AppLocalizations localizations) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.05), AppColors.primaryDark.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(avg.toStringAsFixed(1), style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: AppColors.primary)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (index) => Icon(index < avg.floor() ? Icons.star : Icons.star_border, color: AppColors.warning, size: 20))),
          Text('$total ${localizations.reviews}', style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkTextHint : AppColors.gray)),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map review, AppLocalizations localizations) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(20)),
                child: Center(child: Text((review['freelancer_name'] ?? 'F')[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review['freelancer_name'] ?? localizations.freelancer, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.dark)),
                    Row(
                      children: [
                        ...List.generate(5, (index) => Icon(index < (review['rating'] ?? 0) ? Icons.star : Icons.star_border, color: AppColors.warning, size: 14)),
                        const SizedBox(width: 8),
                        Text(review['created_at'] ?? '', style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextHint : AppColors.gray)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(review['comment'] ?? '', style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.gray, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(Map profile, AppLocalizations localizations) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAnalyticsCard(localizations.profileViews, profile['profile_views'] ?? 0, Icons.visibility),
          const SizedBox(height: 16),
          _buildAnalyticsCard(localizations.jobs_posted, profile['jobs_posted'] ?? 0, Icons.work),
          const SizedBox(height: 16),
          _buildAnalyticsCard(localizations.invitations_sent, profile['invitations_sent'] ?? 0, Icons.email),
          const SizedBox(height: 16),
          _buildAnalyticsCard(localizations.applications_received, profile['applications_received'] ?? 0, Icons.inbox),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, int value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppColors.primary, size: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: isDark ? AppColors.darkTextPrimary : AppColors.dark)),
                Text(title, style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkTextHint : AppColors.gray)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}