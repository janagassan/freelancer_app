import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/offer_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<OfferModel> _offers = [];
  bool _loading = true;
  String _currentTab = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          switch (_tabController.index) {
            case 0:
              _currentTab = 'all';
              break;
            case 1:
              _currentTab = 'pending';
              break;
            case 2:
              _currentTab = 'accepted';
              break;
            case 3:
              _currentTab = 'declined';
              break;
          }
        });
      }
    });
    _loadOffers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOffers() async {
    setState(() => _loading = true);
    try {
      final result = await ApiService.getMyOffers();

      if (result['success'] == true) {
        final List data = result['offers'] ?? [];
        setState(() {
          _offers = data.map((j) => OfferModel.fromJson(j)).toList();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      print('❌ Error loading offers: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _respondToOffer(OfferModel offer, String status) async {
    try {
      final result = await ApiService.respondToOffer(offer.id, status);

      if (result['success'] == true) {
        if (status == 'accepted' && result['contractId'] != null) {
          final int newContractId = result['contractId'];
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Offer accepted! Redirecting to contract...'),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 2),
              ),
            );
          }

          if (mounted) {
            await Navigator.pushNamed(
              context,
              '/contract',
              arguments: {
                'contractId': newContractId,
                'userRole': 'freelancer',
              },
            );
            _loadOffers();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Offer declined'),
                backgroundColor: AppColors.gray,
              ),
            );
            _loadOffers();
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to respond to offer'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  String _getAvatarUrl(String? avatar) {
    if (avatar == null || avatar.isEmpty) return '';
    if (avatar.startsWith('http')) return avatar;
    if (avatar.startsWith('/uploads')) {
      return 'https://freelancer-app-h6os.onrender.com$avatar';
    }
    return avatar;
  }

  List<OfferModel> get _filteredOffers {
    switch (_currentTab) {
      case 'pending':
        return _offers.where((o) => o.isPending && !o.isExpired).toList();
      case 'accepted':
        return _offers.where((o) => o.isAccepted).toList();
      case 'declined':
        return _offers.where((o) => o.isDeclined).toList();
      default:
        return _offers;
    }
  }

  int get _pendingCount =>
      _offers.where((o) => o.isPending && !o.isExpired).length;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 7) return '${date.day}/${date.month}/${date.year}';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  bool _isDarkMode() {
    return Theme.of(context).brightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = _isDarkMode();
    final filtered = _filteredOffers;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        title: Row(
          children: [
            Text(t.offers),
            if (_pendingCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_pendingCount',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
          ],
        ),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        foregroundColor: isDark ? AppColors.darkTextPrimary : Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.accent,
          unselectedLabelColor: isDark
              ? AppColors.darkTextSecondary
              : AppColors.gray,
          indicatorColor: AppColors.accent,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Accepted'),
            Tab(text: 'Declined'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : filtered.isEmpty
          ? _buildEmptyState(t, isDark)
          : RefreshIndicator(
              onRefresh: _loadOffers,
              color: AppColors.accent,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, index) =>
                    _buildOfferCard(filtered[index], t, isDark),
              ),
            ),
    );
  }

  Widget _buildOfferCard(OfferModel offer, t, bool isDark) {
    final isPending = offer.isPending && !offer.isExpired;
    final isAccepted = offer.isAccepted;
    final isDeclined = offer.isDeclined;
    final isExpired = offer.isExpired;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? AppColors.darkCard : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.accent.withOpacity(0.1),
                  backgroundImage:
                      offer.clientAvatar != null &&
                          offer.clientAvatar!.isNotEmpty
                      ? NetworkImage(_getAvatarUrl(offer.clientAvatar!))
                      : null,
                  child: offer.clientAvatar == null
                      ? Text(
                          offer.clientName.isNotEmpty
                              ? offer.clientName[0].toUpperCase()
                              : 'C',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.clientName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        offer.projectTitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.gray,
                        ),
                      ),
                    ],
                  ),
                ),
                if (offer.amount != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '\$${offer.amount!.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkBackground
                    : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                offer.message,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.gray,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 12, color: AppColors.gray),
                const SizedBox(width: 4),
                Text(
                  _formatDate(offer.createdAt),
                  style: TextStyle(fontSize: 11, color: AppColors.gray),
                ),
                if (offer.expiresAt != null) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.timer,
                    size: 12,
                    color: isExpired ? AppColors.danger : AppColors.warning,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isExpired
                        ? 'Expired'
                        : 'Expires: ${_formatDate(offer.expiresAt!)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isExpired ? AppColors.danger : AppColors.warning,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            if (isPending) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _respondToOffer(offer, 'declined'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: BorderSide(color: AppColors.danger),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(t.decline),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _respondToOffer(offer, 'accepted'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(t.accept),
                    ),
                  ),
                ],
              ),
            ] else if (isAccepted) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Offer accepted! Contract has been created.',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/contract',
                        arguments: {
                          'contractId': offer.id,
                          'userRole': 'freelancer',
                        },
                      ),
                      child: Text(
                        'View Contract',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isDeclined) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cancel, color: AppColors.danger, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Offer declined',
                        style: TextStyle(color: AppColors.danger, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isExpired) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_off, color: AppColors.warning, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This offer has expired',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(t, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mail_outline,
            size: 80,
            color: isDark ? AppColors.darkTextHint : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            t.noOffersYet,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.whenYouReceiveOffers,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkTextSecondary : AppColors.gray,
            ),
          ),
        ],
      ),
    );
  }
}
