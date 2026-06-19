// screens/client/freelancer_profile_preview_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:freelancer_platform/models/rating_model.dart';
import 'package:freelancer_platform/screens/rating/reviews_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../services/chat_service.dart';
import '../../utils/constants.dart';
import '../../theme/app_theme.dart';

class FreelancerProfilePreviewScreen extends StatefulWidget {
  final int freelancerId;
  final String? projectId;

  const FreelancerProfilePreviewScreen({
    super.key,
    required this.freelancerId,
    this.projectId,
  });

  @override
  State<FreelancerProfilePreviewScreen> createState() =>
      _FreelancerProfilePreviewScreenState();
}

class _FreelancerProfilePreviewScreenState
    extends State<FreelancerProfilePreviewScreen> {
  Map<String, dynamic> _profileData = {};
  bool _loading = true;
  bool _isHiring = false;
  List<dynamic> _recentReviews = [];
  RatingStats? _stats;

  List<dynamic> _safeList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value;
    if (value is String) {
      if (value.isEmpty || value == '[]') return [];
      if (value.startsWith('[') && value.endsWith(']')) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is List) return decoded;
        } catch (e) {
          print('Error parsing list: $e');
        }
      }
      return [];
    }
    return [];
  }

  void _loadReviews() async {
    try {
      final response = await ApiService.getUserRatings(widget.freelancerId);
      setState(() {
        _recentReviews = response['ratings'] ?? [];
        _stats = RatingStats.fromJson(response['stats']);
      });
    } catch (e) {
      print('Error loading reviews: $e');
    }
  }

  Widget _buildReviewCard(Map<String, dynamic> review, ThemeData theme) {
    final t = AppLocalizations.of(context)!;
    final rating = (review['rating'] ?? 0).toDouble();
    final comment = review['comment'] ?? '';
    final fromUser = review['fromUser'] ?? {};
    final userName = fromUser['name'] ?? t.client;
    final userAvatar = fromUser['avatar'];
    final createdAt = review['createdAt'] != null
        ? DateTime.tryParse(review['createdAt'])
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: userAvatar != null
                      ? NetworkImage(userAvatar)
                      : null,
                  child: userAvatar == null
                      ? Text(userName[0].toUpperCase())
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      _buildRatingStars(rating, theme),
                    ],
                  ),
                ),
                if (createdAt != null)
                  Text(
                    _formatDate(createdAt),
                    style: TextStyle(fontSize: 10, color: AppColors.gray),
                  ),
              ],
            ),
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                comment,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _safeMap(dynamic value) {
    if (value == null) return {};
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String) {
      if (value.isEmpty || value == '{}') return {};
      if (value.startsWith('{') && value.endsWith('}')) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is Map) return Map<String, dynamic>.from(decoded);
        } catch (e) {
          print('Error parsing map: $e');
        }
      }
      return {};
    }
    return {};
  }

  @override
  void initState() {
    super.initState();
    _loadFreelancerProfile();
    _loadReviews();
  }

  Future<void> _loadFreelancerProfile() async {
  print('🔍 === LOADING FREELANCER PROFILE ===');
  print('📌 Freelancer ID: ${widget.freelancerId}');
  
  setState(() => _loading = true);
  try {
    final data = await ApiService.getFreelancerPublicProfile(
      widget.freelancerId,
    );
    
    print('📥 Raw API Response:');
    print('  - Keys: ${data.keys}');
    print('  - User exists: ${data.containsKey('user')}');
    print('  - Profile exists: ${data.containsKey('profile')}');
    
    if (data.containsKey('user')) {
      final user = data['user'];
      print('👤 User data:');
      print('  - name: ${user['name']}');
      print('  - email: ${user['email']}');
      print('  - phone: ${user['phone']}');
      print('  - website: ${user['website']}');
      print('  - linkedin: ${user['linkedin']}');
      print('  - github: ${user['github']}');
    }
    
    if (data.containsKey('profile')) {
      final profile = data['profile'];
      print('📋 Profile data:');
      print('  - website: ${profile['website']}');
      print('  - linkedin: ${profile['linkedin']}');
      print('  - github: ${profile['github']}');
      print('  - behance: ${profile['behance']}');
    }
    
    if (mounted) {
      setState(() {
        _profileData = data;
        _loading = false;
      });
      print('✅ Profile loaded successfully');
    }
  } catch (e) {
    print('❌ Error loading profile: $e');
    if (mounted) {
      setState(() => _loading = false);
      final t = AppLocalizations.of(context)!;
      Fluttertoast.showToast(
        msg: '${t.errorLoadingProfile}: $e',
        backgroundColor: AppColors.danger,
      );
    }
  }
}

  Future<void> _startChat() async {
    final t = AppLocalizations.of(context)!;
    setState(() => _isHiring = true);
    try {
      final result = await ChatService.createChat(widget.freelancerId);
      if (!mounted) return;

      if (result['success'] == true || result['id'] != null) {
        final chatId = result['chat']?['id'] ?? result['id'];
        final freelancerName = _profileData['user']?['name'] ?? t.freelancer;
        final freelancerAvatar = _profileData['user']?['avatar'];

        Navigator.pushNamed(
          context,
          '/chat',
          arguments: {
            'chatId': chatId,
            'otherUserId': widget.freelancerId,
            'otherUserName': freelancerName,
            'otherUserAvatar': freelancerAvatar,
          },
        );
      } else {
        Fluttertoast.showToast(
          msg: result['message'] ?? t.failedToStartChat,
          backgroundColor: AppColors.danger,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: '${t.error}: $e',
        backgroundColor: AppColors.danger,
      );
    } finally {
      if (mounted) setState(() => _isHiring = false);
    }
  }

  Widget _buildRatingAndReviews(ThemeData theme) {
    final t = AppLocalizations.of(context)!;
    final stats = _profileData['stats'] ?? {};
    final reviews = _safeList(_profileData['reviews']);
    final rating = (stats['rating'] ?? 0).toDouble();
    final totalReviews = stats['total_reviews'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.ratingsAndReviews,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                    0.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    _buildRatingStars(rating, theme),
                    Text(
                      '$totalReviews ${t.reviews}',
                      style: TextStyle(fontSize: 12, color: AppColors.gray),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReviewsScreen(
                        userId: widget.freelancerId,
                        userName: _profileData['user']?['name'] ?? t.freelancer,
                        userRole: 'freelancer',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.star_border),
                label: Text(t.viewAllReviews),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.cardColor,
                  foregroundColor: Colors.amber,
                  side: const BorderSide(color: Colors.amber),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...reviews.take(3).map((review) => _buildReviewCard(review, theme)),
        if (reviews.length > 3)
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReviewsScreen(
                    userId: widget.freelancerId,
                    userName: _profileData['user']?['name'] ?? t.freelancer,
                    userRole: 'freelancer',
                  ),
                ),
              );
            },
            child: Text(
              '${t.seeMore} →',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
      ],
    );
  }
  // screens/client/freelancer_profile_preview_screen.dart
// أضف هذه الدوال في _FreelancerProfilePreviewScreenState

Future<void> _showContactOptions() async {
  final t = AppLocalizations.of(context)!;
  
  // === DEBUG: طباعة البيانات القادمة من API ===
  print('🔍 === CONTACT OPTIONS DEBUG ===');
  print('📦 Full _profileData keys: ${_profileData.keys}');
  
  final user = _profileData['user'] ?? {};
  final profile = _profileData['profile'] ?? {};
  
  print('👤 User data:');
  print('  - name: ${user['name']}');
  print('  - email: ${user['email']}');
  print('  - phone: ${user['phone']}');
  print('  - website: ${user['website']}');
  print('  - linkedin: ${user['linkedin']}');
  print('  - github: ${user['github']}');
  print('  - twitter: ${user['twitter']}');
  
  print('📋 Profile data:');
  print('  - website: ${profile['website']}');
  print('  - linkedin: ${profile['linkedin']}');
  print('  - github: ${profile['github']}');
  print('  - behance: ${profile['behance']}');
  print('  - dribbble: ${profile['dribbble']}');
  
  // جلب معلومات التواصل من البيانات
  final email = user['email']?.toString();
  final phone = user['phone']?.toString();
  
  // الأولوية: profile أولاً ثم user
  final website = (profile['website']?.toString() ?? user['website']?.toString());
  final linkedin = (profile['linkedin']?.toString() ?? user['linkedin']?.toString());
  final github = (profile['github']?.toString() ?? user['github']?.toString());
  final twitter = user['twitter']?.toString();
  final behance = profile['behance']?.toString();
  final dribbble = profile['dribbble']?.toString();
  
  print('✅ Final extracted values:');
  print('  - email: $email');
  print('  - phone: $phone');
  print('  - website: $website');
  print('  - linkedin: $linkedin');
  print('  - github: $github');
  print('  - twitter: $twitter');
  print('  - behance: $behance');
  print('  - dribbble: $dribbble');
  
  final contactOptions = <Map<String, dynamic>>[];
  
  // إضافة البريد الإلكتروني
  if (email != null && email.isNotEmpty) {
    print('✅ Adding email option: $email');
    contactOptions.add({
      'icon': Icons.email_outlined,
      'title': t.email,
      'subtitle': email,
      'action': () => _sendEmail(email),
      'color': AppColors.accent,
    });
  } else {
    print('⚠️ No email found');
  }
  
  // إضافة رقم الجوال
  if (phone != null && phone.isNotEmpty) {
    print('✅ Adding phone option: $phone');
    contactOptions.add({
      'icon': Icons.phone_outlined,
      'title': t.phone,
      'subtitle': phone,
      'action': () => _makePhoneCall(phone),
      'color': AppColors.success,
    });
  } else {
    print('⚠️ No phone found');
  }
  
  // إضافة الموقع الإلكتروني
  if (website != null && website.isNotEmpty) {
    print('✅ Adding website option: $website');
    contactOptions.add({
      'icon': Icons.language_outlined,
      'title': t.website,
      'subtitle': website,
      'action': () => _openUrl(website),
      'color': AppColors.info,
    });
  } else {
    print('⚠️ No website found');
  }
  
  // إضافة LinkedIn
  if (linkedin != null && linkedin.isNotEmpty) {
    print('✅ Adding LinkedIn option: $linkedin');
    contactOptions.add({
      'icon': Icons.business_center_outlined,
      'title': 'LinkedIn',
      'subtitle': linkedin,
      'action': () => _openUrl(linkedin),
      'color': const Color(0xFF0077B5),
    });
  } else {
    print('⚠️ No LinkedIn found');
  }
  
  // إضافة GitHub
  if (github != null && github.isNotEmpty) {
    print('✅ Adding GitHub option: $github');
    contactOptions.add({
      'icon': Icons.code_outlined,
      'title': 'GitHub',
      'subtitle': github,
      'action': () => _openUrl(github),
      'color': const Color(0xFF333333),
    });
  } else {
    print('⚠️ No GitHub found');
  }
  
  // إضافة Twitter
  if (twitter != null && twitter.isNotEmpty) {
    print('✅ Adding Twitter option: $twitter');
    contactOptions.add({
      'icon': Icons.chat_bubble_outline,
      'title': 'Twitter',
      'subtitle': twitter,
      'action': () => _openUrl(twitter),
      'color': const Color(0xFF1DA1F2),
    });
  } else {
    print('⚠️ No Twitter found');
  }
  
  // إضافة Behance
  if (behance != null && behance.isNotEmpty) {
    print('✅ Adding Behance option: $behance');
    contactOptions.add({
      'icon': Icons.brush_outlined,
      'title': 'Behance',
      'subtitle': behance,
      'action': () => _openUrl(behance),
      'color': const Color(0xFF1769FF),
    });
  } else {
    print('⚠️ No Behance found');
  }
  
  // إضافة Dribbble
  if (dribbble != null && dribbble.isNotEmpty) {
    print('✅ Adding Dribbble option: $dribbble');
    contactOptions.add({
      'icon': Icons.sports_basketball_outlined,
      'title': 'Dribbble',
      'subtitle': dribbble,
      'action': () => _openUrl(dribbble),
      'color': const Color(0xFFEA4C89),
    });
  } else {
    print('⚠️ No Dribbble found');
  }
  
  print('📊 Total contact options found: ${contactOptions.length}');
  
  // إذا ما في وسائل تواصل، نفتح محادثة عادية
  if (contactOptions.isEmpty) {
    print('⚠️ No contact options available, falling back to chat');
    _startChat();
    return;
  }
  
  print('🎯 Showing contact bottom sheet');
  
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t.contactOptions,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _profileData['user']?['name'] ?? t.freelancer,
            style: TextStyle(fontSize: 14, color: AppColors.gray),
          ),
          const Divider(height: 24),
          ...contactOptions.map(
            (option) => ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (option['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(option['icon'], color: option['color']),
              ),
              title: Text(
                option['title'],
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                option['subtitle'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: AppColors.gray),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                print('🖱️ User tapped on: ${option['title']}');
                Navigator.pop(context);
                option['action']();
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

// أضف هذه الدوال المساعدة مع debugging
Future<void> _sendEmail(String email) async {
  print('📧 Sending email to: $email');
  final Uri emailUri = Uri(
    scheme: 'mailto',
    path: email,
    query: 'subject=Inquiry%20about%20your%20freelance%20services&body=Hello,%0D%0A%0D%0AI%20saw%20your%20profile%20and%20I%27m%20interested%20in%20working%20with%20you.%0D%0A%0D%0ABest%20regards',
  );
  
  if (await canLaunchUrl(emailUri)) {
    print('✅ Email app launched');
    await launchUrl(emailUri);
  } else {
    print('❌ Could not open email app');
    Fluttertoast.showToast(msg: 'Could not open email app');
  }
}

Future<void> _makePhoneCall(String phone) async {
  print('📞 Making phone call to: $phone');
  final Uri phoneUri = Uri(scheme: 'tel', path: phone);
  if (await canLaunchUrl(phoneUri)) {
    print('✅ Phone dialer launched');
    await launchUrl(phoneUri);
  } else {
    print('❌ Could not make phone call');
    Fluttertoast.showToast(msg: 'Could not make phone call');
  }
}

Future<void> _openUrl(String url) async {
  print('🌐 Opening URL: $url');
  var uri = url.trim();
  if (!uri.startsWith('http')) {
    uri = 'https://$uri';
    print('🔄 Normalized URL: $uri');
  }
  final Uri parsedUri = Uri.parse(uri);
  if (await canLaunchUrl(parsedUri)) {
    print('✅ URL launched successfully');
    await launchUrl(parsedUri, mode: LaunchMode.externalApplication);
  } else {
    print('❌ Could not open URL');
    Fluttertoast.showToast(msg: 'Could not open link');
  }
}
  Future<void> _hireOrOpenProjectHire() async {
    final t = AppLocalizations.of(context)!;
    if (widget.projectId == null) {
      await _startChat();
      return;
    }

    setState(() => _isHiring = true);
    try {
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        '/client/hire-freelancer',
        arguments: {
          'freelancerId': widget.freelancerId,
          'projectId': widget.projectId,
          'freelancerName': _profileData['user']?['name'],
        },
      );
    } catch (e) {
      Fluttertoast.showToast(msg: '${t.error}: $e');
    } finally {
      if (mounted) setState(() => _isHiring = false);
    }
  }

  void _shareProfile() {
    final t = AppLocalizations.of(context)!;
    final user = _profileData['user'] ?? {};
    final profile = _profileData['profile'] ?? {};
    final name = user['name'] ?? t.freelancer;
    final title = profile['title'] ?? user['tagline'] ?? '';
    final text = title.toString().isNotEmpty ? '$name — $title' : name;
    Share.share('$text\n(${t.freelancerProfile})');
  }

  String _mediaUrl(String? path) => apiMediaUrl(path);

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (name.isNotEmpty) return name[0].toUpperCase();
    return '?';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Recently';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()} years ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} months ago';
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hours ago';
    return 'Recently';
  }

  double _getSafeDouble(dynamic value, {double defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  int _getSafeInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  String _availabilityLabel(String? code) {
    final t = AppLocalizations.of(context)!;
    switch (code) {
      case 'full_time':
        return t.fullTime;
      case 'part_time':
        return t.partTime;
      case 'as_needed':
        return t.asNeeded;
      case 'not_available':
        return t.notAvailable;
      default:
        return code?.replaceAll('_', ' ') ?? '';
    }
  }

  Future<void> _openExternal(String? url) async {
    if (url == null || url.isEmpty) return;
    var u = url.trim();
    if (!u.startsWith('http')) u = 'https://$u';
    final uri = Uri.tryParse(u);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildRatingStars(double rating, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: Colors.amber, size: 14);
        } else if (index < rating && rating - index > 0.5) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 14);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 14);
        }
      }),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isLoading,
    required bool outlined,
    required ThemeData theme,
  }) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.primary,
          side: BorderSide(color: theme.colorScheme.primary),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    final t = AppLocalizations.of(context)!;
    final user = _profileData['user'] ?? {};
    final profile = _profileData['profile'] ?? {};
    final stats = _profileData['stats'] ?? {};
    final trust = _profileData['trust'] ?? {};
    final name = user['name'] ?? t.freelancer;
    final title =
        profile['title'] ?? user['tagline'] ?? t.professionalFreelancer;
    final avatarUrl = _mediaUrl(user['avatar']?.toString());
    final coverUrl = _mediaUrl(user['cover_image']?.toString());
    final rating = _getSafeDouble(stats['rating']);
    final completedProjects = _getSafeInt(stats['completed_projects']);
    final jobSuccessScore = _getSafeInt(stats['job_success_score']);
    final totalReviews = _getSafeInt(stats['total_reviews']);
    final isAvailable = profile['is_available'] != false;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          children: [
            SizedBox(
              height: 200,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (coverUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: coverUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primary.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primary.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  Container(color: Colors.black.withOpacity(0.45)),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.share, color: Colors.white),
                            onPressed: _shareProfile,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -56),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Container(
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: avatarUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: avatarUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.3,
                                  ),
                                  child: Center(
                                    child: Text(
                                      _initials(name),
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.35,
                                ),
                                child: Center(
                                  child: Text(
                                    _initials(name),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.gray,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        if (trust['identity_verified'] == true)
                          _buildPill(
                            Icons.verified_user,
                            t.verified,
                            AppColors.success,
                            theme,
                          ),
                        if (trust['top_rated'] == true)
                          _buildPill(
                            Icons.military_tech,
                            t.topRated,
                            AppColors.warning,
                            theme,
                          ),
                        if (trust['rising_talent'] == true)
                          _buildPill(
                            Icons.trending_up,
                            t.risingTalent,
                            theme.colorScheme.primary,
                            theme,
                          ),
                        _buildPill(
                          isAvailable ? Icons.circle : Icons.circle_outlined,
                          isAvailable ? t.acceptingWork : t.limited,
                          isAvailable ? AppColors.success : AppColors.gray,
                          theme,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildRatingStars(rating, theme),
                        const SizedBox(width: 8),
                        Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          ' ($totalReviews ${t.reviews})',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.gray,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '·',
                          style: TextStyle(
                            color: AppColors.gray.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.work_outline,
                          size: 16,
                          color: AppColors.gray.withOpacity(0.9),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$completedProjects ${t.done}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.gray,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$jobSuccessScore% JSS',
                            style: const TextStyle(
                              color: Color(0xFF047857),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.chat_bubble_outline,
                            label: t.message,
                            onPressed: _startChat,
                            isLoading: _isHiring,
                            outlined: true,
                            theme: theme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.contact_phone_outlined,
                            label: t.contact, // "Contact"
                            onPressed: _showContactOptions, // يفتح الحوار
                            isLoading: false,
                            outlined: false,
                            theme: theme,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPill(IconData icon, String text, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required List<Widget> children,
    required ThemeData theme,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
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
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatsSection(ThemeData theme) {
    final t = AppLocalizations.of(context)!;
    final stats = _profileData['stats'] ?? {};
    final profile = _profileData['profile'] ?? {};

    final completedProjects = _getSafeInt(stats['completed_projects']);
    final totalReviews = _getSafeInt(stats['total_reviews']);
    final activeProjects = _getSafeInt(stats['active_projects']);
    final portfolioCount = _getSafeInt(stats['portfolio_count']);
    final responseTime = _getSafeInt(
      stats['response_time'] ?? profile['response_time'],
      defaultValue: 24,
    );
    final rating = _getSafeDouble(stats['rating']);
    final experienceYears = _getSafeInt(profile['experience_years']);
    final hourlyRate = _getSafeDouble(profile['hourly_rate']);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
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
          Text(
            t.atAGlance,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  value: '$completedProjects',
                  label: t.completed,
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  value: '$totalReviews',
                  label: t.reviews,
                  icon: Icons.reviews_outlined,
                  color: theme.colorScheme.primary,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  value: '$activeProjects',
                  label: t.active,
                  icon: Icons.trending_up,
                  color: AppColors.warning,
                  theme: theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  value: '$portfolioCount',
                  label: t.portfolio,
                  icon: Icons.collections_bookmark_outlined,
                  color: const Color(0xFF8B5CF6),
                  theme: theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: theme.dividerColor),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoRow(
                Icons.access_time,
                t.response,
                '$responseTime h',
                theme,
              ),
              const Spacer(),
              _buildInfoRow(
                Icons.star,
                t.rating,
                rating.toStringAsFixed(1),
                theme,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildInfoRow(
                Icons.work,
                t.experience,
                '$experienceYears ${t.years}',
                theme,
              ),
              const Spacer(),
              _buildInfoRow(
                Icons.attach_money,
                t.hourly,
                hourlyRate > 0
                    ? '\$${hourlyRate.toStringAsFixed(0)}/${t.hour}'
                    : '—',
                theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.gray),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.gray),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, color: AppColors.gray),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilitySection(ThemeData theme) {
    final t = AppLocalizations.of(context)!;
    final profile = _profileData['profile'] ?? {};
    final avail = profile['availability']?.toString();
    final weekly = _getSafeInt(profile['weekly_hours'], defaultValue: 40);
    if (avail == null || avail.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: _sectionCard(
        title: t.availability,
        children: [
          _buildInfoRow(
            Icons.schedule,
            t.commitment,
            _availabilityLabel(avail),
            theme,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.timelapse,
            t.weeklyHours,
            '$weekly ${t.hours}',
            theme,
          ),
        ],
        theme: theme,
      ),
    );
  }

  Widget _buildSkillsSection(ThemeData theme) {
    final t = AppLocalizations.of(context)!;
    final profile = _profileData['profile'] ?? {};
    final skills = _safeList(profile['skills']);
    final topSkills = _safeList(profile['top_skills']);

    if (skills.isEmpty && topSkills.isEmpty) {
      return const SizedBox.shrink();
    }

    final displaySkills = topSkills.isNotEmpty ? topSkills : skills;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: _sectionCard(
        title: t.skillsAndExpertise,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: displaySkills.map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  skill.toString(),
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        theme: theme,
      ),
    );
  }

  Widget _buildLanguagesSection(ThemeData theme) {
    final t = AppLocalizations.of(context)!;
    final profile = _profileData['profile'] ?? {};
    final langs = _safeList(profile['languages']);
    if (langs.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: _sectionCard(
        title: t.languages,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: langs
                .map(
                  (e) => Chip(
                    label: Text(e.toString()),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    side: BorderSide.none,
                    labelStyle: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
        theme: theme,
      ),
    );
  }

  Widget _buildCategoriesSection(ThemeData theme) {
    final t = AppLocalizations.of(context)!;
    final profile = _profileData['profile'] ?? {};
    final cats = _safeList(profile['categories']);
    if (cats.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: _sectionCard(
        title: t.categories,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: cats
                .map(
                  (c) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Text(
                      c.toString(),
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
        theme: theme,
      ),
    );
  }

  Widget _buildAboutSection(ThemeData theme) {
    final t = AppLocalizations.of(context)!;
    final profile = _profileData['profile'] ?? {};
    final user = _profileData['user'] ?? {};
    final bio = (profile['display_bio'] ?? profile['bio'] ?? user['bio'] ?? '')
        .toString()
        .trim();
    final location =
        (profile['display_location'] ??
                profile['location'] ??
                user['location'] ??
                '')
            .toString()
            .trim();
    final memberSince = user['member_since'] != null
        ? DateTime.tryParse(user['member_since'].toString())
        : null;
    final views = _getSafeInt(user['profile_views']);

    if (bio.isEmpty && location.isEmpty && memberSince == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: _sectionCard(
        title: t.about,
        children: [
          if (location.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 18,
                    color: AppColors.gray,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      location,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (memberSince != null || views > 0) ...[
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                if (memberSince != null)
                  _buildInfoRow(
                    Icons.calendar_today_outlined,
                    t.memberSince,
                    '${memberSince.year}',
                    theme,
                  ),
                if (views > 0)
                  _buildInfoRow(
                    Icons.visibility_outlined,
                    t.profileViews,
                    '$views',
                    theme,
                  ),
              ],
            ),
            if (bio.isNotEmpty) const SizedBox(height: 12),
          ],
          if (bio.isNotEmpty)
            Text(
              bio,
              style: TextStyle(
                fontSize: 14,
                height: 1.55,
                color: theme.colorScheme.onSurface,
              ),
            ),
        ],
        theme: theme,
      ),
    );
  }

  Widget _buildWorkExperienceSection(ThemeData theme) {
    final t = AppLocalizations.of(context)!;
    final profile = _profileData['profile'] ?? {};
    final raw = _safeList(profile['work_experience']);
    if (raw.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: _sectionCard(
        title: t.workExperience,
        children: raw.map((item) {
          final m = _safeMap(item);
          final role = m['title'] ?? m['role'] ?? m['position'] ?? '';
          final company = m['company'] ?? m['employer'] ?? '';
          final start = m['start'] ?? m['start_date'] ?? m['from'] ?? '';
          final end = m['end'] ?? m['end_date'] ?? m['to'] ?? '';
          final desc = m['description'] ?? m['summary'] ?? '';
          final period = [
            start,
            end,
          ].where((e) => e.toString().isNotEmpty).join(' — ');
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (role.toString().isNotEmpty)
                        Text(
                          role.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      if (company.toString().isNotEmpty)
                        Text(
                          company.toString(),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.gray,
                          ),
                        ),
                      if (period.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            period,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.gray.withOpacity(0.9),
                            ),
                          ),
                        ),
                      if (desc.toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            desc.toString(),
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.45,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        theme: theme,
      ),
    );
  }

  Widget _buildEducationSection(ThemeData theme) {
    final t = AppLocalizations.of(context)!;
    final profile = _profileData['profile'] ?? {};
    final edu = _safeList(profile['education']);
    if (edu.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: _sectionCard(
        title: t.education,
        children: edu.map((item) {
          final m = _safeMap(item);
          final degree = m['degree'] ?? m['field'] ?? '';
          final inst = m['institution'] ?? m['school'] ?? '';
          final year = m['year'] ?? m['end_year'] ?? '';
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (degree.toString().isNotEmpty)
                        Text(
                          degree.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      if (inst.toString().isNotEmpty)
                        Text(
                          inst.toString(),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.gray,
                          ),
                        ),
                      if (year.toString().isNotEmpty)
                        Text(
                          year.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.gray.withOpacity(0.85),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        theme: theme,
      ),
    );
  }

  Widget _buildCertificationsSection(ThemeData theme) {
    final t = AppLocalizations.of(context)!;
    final profile = _profileData['profile'] ?? {};
    final certs = _safeList(profile['certifications']);
    if (certs.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: _sectionCard(
        title: t.certifications,
        children: certs.map((item) {
          final m = _safeMap(item);
          final name = m['name'] ?? m['title'] ?? item.toString();
          final issuer = m['issuer'] ?? m['organization'] ?? '';
          final year = m['year'] ?? '';
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.verified_outlined,
                  size: 20,
                  color: AppColors.success,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (issuer.toString().isNotEmpty)
                        Text(
                          issuer.toString(),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.gray,
                          ),
                        ),
                      if (year.toString().isNotEmpty)
                        Text(
                          year.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.gray.withOpacity(0.85),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        theme: theme,
      ),
    );
  }

  Widget _buildContactLinksSection(ThemeData theme) {
    final t = AppLocalizations.of(context)!;
    final links = _safeMap(_profileData['contact_links']);
    if (links.isEmpty) return const SizedBox.shrink();

    final entries = <MapEntry<String, String>>[];
    void add(String key, String? v) {
      if (v != null && v.toString().trim().isNotEmpty) {
        entries.add(MapEntry(key, v.toString()));
      }
    }

    add(t.website, links['website']?.toString());
    add(t.gitHub, links['github']?.toString());
    add(t.linkedIn, links['linkedin']?.toString());
    add(t.behance, links['behance']?.toString());
    add(t.dribbble, links['dribbble']?.toString());
    add(t.twitter, links['twitter']?.toString());

    if (entries.isEmpty) return const SizedBox.shrink();

    IconData iconFor(String k) {
      switch (k) {
        case 'GitHub':
          return Icons.code;
        case 'LinkedIn':
          return Icons.business_center_outlined;
        case 'Twitter':
          return Icons.chat_bubble_outline;
        default:
          return Icons.link;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: _sectionCard(
        title: t.links,
        children: [
          ...entries.map(
            (e) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                iconFor(e.key),
                color: theme.colorScheme.primary,
                size: 22,
              ),
              title: Text(
                e.key,
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              subtitle: Text(
                e.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.gray),
              ),
              trailing: const Icon(
                Icons.open_in_new,
                size: 18,
                color: AppColors.gray,
              ),
              onTap: () => _openExternal(e.value),
            ),
          ),
        ],
        theme: theme,
      ),
    );
  }

  Widget _buildPortfolioSection(ThemeData theme) {
    final t = AppLocalizations.of(context)!;
    final portfolio = _safeList(_profileData['portfolio']);
    if (portfolio.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: _sectionCard(
        title: t.portfolio,
        children: [
          ...portfolio.map<Widget>((item) {
            final itemMap = _safeMap(item);
            final images = _safeList(itemMap['images']);
            final imageUrl = images.isNotEmpty
                ? _mediaUrl(images[0].toString())
                : '';
            final technologies = _safeList(
              itemMap['technologies'],
            ).map((e) => e.toString()).toList();
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Material(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    final url = itemMap['project_url'] ?? itemMap['github_url'];
                    _openExternal(url?.toString());
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imageUrl.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: imageUrl,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            height: 160,
                            color: theme.dividerColor,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            height: 120,
                            color: theme.dividerColor,
                            child: const Icon(Icons.image_not_supported),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    itemMap['title']?.toString() ?? t.project,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                if (itemMap['featured'] == true)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      t.featured,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFB45309),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if ((itemMap['description'] ?? '')
                                .toString()
                                .isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  itemMap['description'].toString(),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: AppColors.gray,
                                  ),
                                ),
                              ),
                            if (technologies.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: technologies
                                      .take(8)
                                      .map(
                                        (t) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.cardColor,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: theme.dividerColor,
                                            ),
                                          ),
                                          child: Text(
                                            t,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
        theme: theme,
      ),
    );
  }

  Widget _buildDeliveredProjectsSection(ThemeData theme) {
    final t = AppLocalizations.of(context)!;
    final projects = _safeList(_profileData['recent_completed_projects']);
    if (projects.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: _sectionCard(
        title: t.recentlyDelivered,
        children: [
          ...projects.take(6).map((item) {
            final data = _safeMap(item);
            final title = data['title']?.toString() ?? t.deliveredProject;
            final category = data['category']?.toString() ?? '';
            final budget = _getSafeDouble(data['budget']);
            final deliveredAt = data['delivered_at'] != null
                ? DateTime.tryParse(data['delivered_at'].toString())
                : null;
            final subtitleParts = <String>[];
            if (category.isNotEmpty) subtitleParts.add(category);
            if (budget > 0) subtitleParts.add('\$${budget.toStringAsFixed(0)}');
            final subtitle = subtitleParts.join(' · ');

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.task_alt, color: AppColors.success),
              title: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              subtitle: Text(
                subtitle.isNotEmpty
                    ? '$subtitle\n${t.delivered} ${_formatDate(deliveredAt)}'
                    : '${t.delivered} ${_formatDate(deliveredAt)}',
                style: const TextStyle(height: 1.4),
              ),
            );
          }),
        ],
        theme: theme,
      ),
    );
  }

  Widget _buildReviewsSectionWrap(ThemeData theme) {
    final t = AppLocalizations.of(context)!;
    final reviews = _safeList(_profileData['reviews']);
    if (reviews.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: _sectionCard(
        title: t.clientReviews,
        children: [
          ...reviews.take(6).map((review) {
            final reviewMap = _safeMap(review);
            final rating = _getSafeDouble(reviewMap['rating']);
            final createdAt = reviewMap['createdAt'] != null
                ? DateTime.tryParse(reviewMap['createdAt'].toString())
                : null;
            final from = _safeMap(reviewMap['from_user']);

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: from['avatar'] != null
                            ? CachedNetworkImageProvider(
                                _mediaUrl(from['avatar'].toString()),
                              )
                            : null,
                        child: from['avatar'] == null
                            ? Text(
                                _initials(from['name']?.toString() ?? 'C'),
                                style: const TextStyle(fontSize: 12),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              from['name']?.toString() ?? t.client,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            _buildRatingStars(rating, theme),
                          ],
                        ),
                      ),
                      Text(
                        _formatDate(createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.gray,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (reviewMap['comment'] ?? '').toString(),
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const Divider(height: 20),
                ],
              ),
            );
          }),
        ],
        theme: theme,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = AppLocalizations.of(context)!;

    if (_loading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_profileData.isEmpty || _profileData['user'] == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(t.profile),
          backgroundColor: theme.scaffoldBackgroundColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                t.couldNotLoadProfile,
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loadFreelancerProfile,
                child: Text(t.retry),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: RefreshIndicator(
        onRefresh: _loadFreelancerProfile,
        color: theme.colorScheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(theme, isDark),
              const SizedBox(height: 8),
              _buildStatsSection(theme),
              _buildAvailabilitySection(theme),
              _buildSkillsSection(theme),
              _buildLanguagesSection(theme),
              _buildCategoriesSection(theme),
              _buildAboutSection(theme),
              _buildWorkExperienceSection(theme),
              _buildEducationSection(theme),
              _buildCertificationsSection(theme),
              _buildContactLinksSection(theme),
              _buildDeliveredProjectsSection(theme),
              _buildPortfolioSection(theme),
              _buildReviewsSectionWrap(theme),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
