// lib/screens/admin/users_management_screen.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart' as AppTheme;

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  List<User> users = [];
  bool loading = true;
  String selectedRole = 'all';
  String selectedStatus = 'all';
  String searchQuery = '';
  int currentPage = 1;
  int totalPages = 1;
  final int pageSize = 20;
  final GlobalKey<FormState> _createUserFormKey = GlobalKey<FormState>();
  final TextEditingController _newUserNameController = TextEditingController();
  final TextEditingController _newUserEmailController = TextEditingController();
  final TextEditingController _newUserPhoneController = TextEditingController();
  final TextEditingController _newUserNationalIdController =
      TextEditingController();
  final TextEditingController _newUserHourlyRateController =
      TextEditingController();
  final TextEditingController _newUserSkillsController =
      TextEditingController();
  final TextEditingController _newUserClientTypeController =
      TextEditingController();
  final TextEditingController _newUserCompanyNameController =
      TextEditingController();
  final TextEditingController _newUserCommercialRegisterController =
      TextEditingController();
  final TextEditingController _newUserTaxNumberController =
      TextEditingController();
  String _newUserRole = 'client';
  bool _creatingUser = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _newUserNameController.dispose();
    _newUserEmailController.dispose();
    _newUserPhoneController.dispose();
    _newUserNationalIdController.dispose();
    _newUserHourlyRateController.dispose();
    _newUserSkillsController.dispose();
    _newUserClientTypeController.dispose();
    _newUserCompanyNameController.dispose();
    _newUserCommercialRegisterController.dispose();
    _newUserTaxNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => loading = true);
    try {
      final response = await ApiService.getAdminUsers(
        role: selectedRole,
        status: selectedStatus,
        search: searchQuery,
        page: currentPage,
        limit: pageSize,
      );

      if (!mounted) return;

      setState(() {
        users = (response['users'] as List)
            .map((json) => User.fromJson(json))
            .toList();
        totalPages = response['totalPages'] ?? 1;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      final t = AppLocalizations.of(context);
      Fluttertoast.showToast(msg: '${t?.errorLoadingUsers}: $e');
    }
  }

  Future<void> _showCreateUserDialog() async {
    _newUserRole = 'client';
    _newUserNameController.clear();
    _newUserEmailController.clear();
    _newUserPhoneController.clear();
    _newUserNationalIdController.clear();
    _newUserHourlyRateController.clear();
    _newUserSkillsController.clear();
    _newUserClientTypeController.clear();
    _newUserCompanyNameController.clear();
    _newUserCommercialRegisterController.clear();
    _newUserTaxNumberController.clear();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)?.createNewUser ?? 'Create new user'),
              content: Form(
                key: _createUserFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTextField(
                        controller: _newUserNameController,
                        label: AppLocalizations.of(context)?.name ?? 'Name',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppLocalizations.of(context)?.nameRequired ?? 'Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _newUserEmailController,
                        label: AppLocalizations.of(context)?.email ?? 'Email',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppLocalizations.of(context)?.emailRequired ?? 'Email is required';
                          }
                          if (!RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$").hasMatch(value)) {
                            return AppLocalizations.of(context)?.enterValidEmail ?? 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _newUserPhoneController,
                        label: AppLocalizations.of(context)?.phoneOptional ?? 'Phone (optional)',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _newUserNationalIdController,
                        label: AppLocalizations.of(context)?.nationalIdOptional ?? 'National ID (optional)',
                      ),
                      const SizedBox(height: 14),
                      _buildRoleSelection(setState),
                      const SizedBox(height: 14),
                      if (_newUserRole == 'freelancer') ...[
                        _buildTextField(
                          controller: _newUserHourlyRateController,
                          label: AppLocalizations.of(context)?.hourlyRateOptional ?? 'Hourly Rate (optional)',
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _newUserSkillsController,
                          label: AppLocalizations.of(context)?.skillsOptional ?? 'Skills (optional, comma separated)',
                        ),
                      ],
                      if (_newUserRole == 'client') ...[
                        _buildTextField(
                          controller: _newUserClientTypeController,
                          label: AppLocalizations.of(context)?.clientTypeOptional ?? 'Client Type (optional)',
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _newUserCompanyNameController,
                          label: AppLocalizations.of(context)?.companyNameOptional ?? 'Company Name (optional)',
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _newUserCommercialRegisterController,
                          label: AppLocalizations.of(context)?.commercialRegisterOptional ?? 'Commercial Register Number (optional)',
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _newUserTaxNumberController,
                          label: AppLocalizations.of(context)?.taxNumberOptional ?? 'Tax Number (optional)',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
                ),
                ElevatedButton(
                  onPressed: _creatingUser ? null : _createUser,
                  child: _creatingUser
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(AppLocalizations.of(context)?.create ?? 'Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? AppTheme.AppColors.grayDark : AppTheme.AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.AppColors.accent, width: 1.5),
        ),
      ),
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        color: isDark ? Colors.white : AppTheme.AppColors.lightTextPrimary,
      ),
    );
  }

  Widget _buildRoleSelection(StateSetter setState) {
    final t = AppLocalizations.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _roleChip('client', t?.client ?? 'Client', _newUserRole == 'client', setState),
        _roleChip('freelancer', t?.freelancer ?? 'Freelancer', _newUserRole == 'freelancer', setState),
        _roleChip('admin', 'Admin', _newUserRole == 'admin', setState),
      ],
    );
  }

  Widget _roleChip(String value, String label, bool selected, StateSetter setState) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => setState(() => _newUserRole = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : (Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.AppColors.darkCard
                  : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : (Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.AppColors.grayDark
                    : Colors.grey.shade300),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : (Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade300
                    : Colors.black87),
          ),
        ),
      ),
    );
  }

  Future<void> _createUser() async {
    if (!_createUserFormKey.currentState!.validate()) return;

    final name = _newUserNameController.text.trim();
    final email = _newUserEmailController.text.trim();
    final phone = _newUserPhoneController.text.trim();
    final nationalId = _newUserNationalIdController.text.trim();
    final hourlyRate = _newUserHourlyRateController.text.trim();
    final skills = _newUserSkillsController.text.trim();
    final clientType = _newUserClientTypeController.text.trim();
    final companyName = _newUserCompanyNameController.text.trim();
    final commercialRegister = _newUserCommercialRegisterController.text.trim();
    final taxNumber = _newUserTaxNumberController.text.trim();

    setState(() => _creatingUser = true);
    try {
      final response = await ApiService.createAdminUser(
        name: name,
        email: email,
        role: _newUserRole,
        phone: phone.isNotEmpty ? phone : null,
        nationalId: nationalId.isNotEmpty ? nationalId : null,
        hourlyRate: hourlyRate.isNotEmpty ? double.tryParse(hourlyRate) : null,
        skills: skills.isNotEmpty
            ? skills.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
            : null,
        clientType: clientType.isNotEmpty ? clientType : null,
        companyName: companyName.isNotEmpty ? companyName : null,
        commercialRegisterNumber: commercialRegister.isNotEmpty ? commercialRegister : null,
        taxNumber: taxNumber.isNotEmpty ? taxNumber : null,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        final t = AppLocalizations.of(context);
        Fluttertoast.showToast(msg: t?.userCreated ?? 'User created. Password sent by email.');
        Navigator.of(context).pop();
        _loadUsers();
      } else {
        Fluttertoast.showToast(
          msg: response['message'] ?? AppLocalizations.of(context)?.failedToCreateUser ?? 'Failed to create user',
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '${AppLocalizations.of(context)?.error}: $e');
    } finally {
      if (mounted) setState(() => _creatingUser = false);
    }
  }

  Future<void> _updateUserStatus(int userId, String status) async {
    try {
      await ApiService.updateUserStatus(userId, status);
      final t = AppLocalizations.of(context);
      Fluttertoast.showToast(
        msg: status == 'active'
            ? (t?.userActivated ?? 'User activated successfully')
            : (t?.userSuspended ?? 'User suspended successfully'),
      );
      _loadUsers();
    } catch (e) {
      Fluttertoast.showToast(msg: '${AppLocalizations.of(context)?.error}: $e');
    }
  }

  Future<void> _verifyUser(int userId, bool verify) async {
    try {
      await ApiService.verifyUser(userId, verify);
      final t = AppLocalizations.of(context);
      Fluttertoast.showToast(
        msg: verify
            ? (t?.userVerified ?? 'User verified successfully')
            : (t?.verificationRemoved ?? 'Verification removed'),
      );
      _loadUsers();
    } catch (e) {
      Fluttertoast.showToast(msg: '${AppLocalizations.of(context)?.error}: $e');
    }
  }

  Future<void> _resendAccountEmail(int userId) async {
    try {
      final response = await ApiService.resendAccountEmail(userId);
      final t = AppLocalizations.of(context);
      if (response['success'] == true) {
        Fluttertoast.showToast(msg: t?.accountEmailResent ?? 'Account email resent successfully');
      } else {
        Fluttertoast.showToast(msg: response['message'] ?? t?.failedToResendEmail ?? 'Failed to resend email');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '${AppLocalizations.of(context)?.error}: $e');
    }
  }

  void _setRole(String r) {
    setState(() {
      selectedRole = r;
      currentPage = 1;
    });
    _loadUsers();
  }

  void _setStatus(String s) {
    setState(() {
      selectedStatus = s;
      currentPage = 1;
    });
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHeader(t, isDark),
          _buildFilterBar(t, isDark),
          _buildStatsBar(t, isDark),
          Expanded(
            child: loading && users.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : users.isEmpty
                    ? _buildEmptyState(t, isDark)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: users.length,
                        itemBuilder: (_, i) => _buildUserCard(users[i], t, isDark),
                      ),
          ),
          if (totalPages > 1) _buildPagination(t, isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations t, bool isDark) {
    return Container(
      color: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            t.users,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1B3E),
            ),
          ),
          SizedBox(
            width: 130,
            child: ElevatedButton.icon(
              onPressed: _showCreateUserDialog,
              icon: const Icon(Icons.person_add, size: 18),
              label: Text(t.addUser),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(AppLocalizations t, bool isDark) {
    return Container(
      color: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        children: [
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.AppColors.darkCard : const Color(0xFFF0F2F8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade200,
              ),
            ),
            child: TextField(
              style: TextStyle(
                color: isDark ? Colors.white : AppTheme.AppColors.lightTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: t.searchByNameOrEmail,
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade500 : const Color(0xFFAAAAAA),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 18,
                  color: isDark ? Colors.grey.shade500 : const Color(0xFFAAAAAA),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (v) {
                searchQuery = v;
                currentPage = 1;
                _loadUsers();
              },
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterLabel(t.role, isDark),
                _buildFilterChip(t.allUsers, selectedRole == 'all', () => _setRole('all'), isDark),
                _buildFilterChip(t.freelancer, selectedRole == 'freelancer', () => _setRole('freelancer'), isDark),
                _buildFilterChip(t.client, selectedRole == 'client', () => _setRole('client'), isDark),
                const SizedBox(width: 12),
                Container(
                  width: 1,
                  height: 20,
                  color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade300,
                ),
                const SizedBox(width: 12),
                _buildFilterLabel(t.status, isDark),
                _buildFilterChip(t.allUsers, selectedStatus == 'all', () => _setStatus('all'), isDark),
                _buildFilterChip(t.active, selectedStatus == 'active', () => _setStatus('active'), isDark),
                _buildFilterChip(t.suspended, selectedStatus == 'suspended', () => _setStatus('suspended'), isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Text(
        '$label:',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.grey.shade500 : const Color(0xFF888888),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: [Color(0xFF8B88FF), Color(0xFF5B58E2)])
              : null,
          color: selected
              ? null
              : (isDark ? AppTheme.AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : (isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade200),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar(AppLocalizations t, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: isDark ? AppTheme.AppColors.darkCard : const Color(0xFFF0F2F8),
      child: Row(
        children: [
          Text(
            '${users.length} ${users.length == 1 ? t.usersCount : t.usersCount_plural}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1A1B3E),
            ),
          ),
          if (loading) ...[
            const SizedBox(width: 12),
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations t, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.AppColors.darkCard : const Color(0xFFF0F2F8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline,
              size: 40,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t.noUsersFound,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t.tryAdjustingFilters,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(User user, AppLocalizations t, bool isDark) {
    final isSuspended = user.accountStatus == 'suspended';
    final initials = (user.name?.isNotEmpty == true) ? user.name![0].toUpperCase() : '?';
    final isVerified = user.isVerifiedUser;
    final roleColor = user.roleColor;
    final avatarUrl = user.avatar;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.AppColors.primary,
              backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? NetworkImage(avatarUrl)
                  : null,
              child: (avatarUrl == null || avatarUrl.isEmpty)
                  ? Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            if (isVerified)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Color(0xFF14A800),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 10, color: Colors.white),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.name ?? 'Unknown',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isSuspended
                      ? Colors.grey.shade500
                      : (isDark ? Colors.white : const Color(0xFF1A1B3E)),
                  decoration: isSuspended ? TextDecoration.lineThrough : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                user.displayRole,
                style: TextStyle(
                  fontSize: 10,
                  color: roleColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.email ?? 'No email',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSuspended
                        ? Colors.red.withOpacity(0.1)
                        : const Color(0xFF14A800).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isSuspended ? t.suspended : t.active,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSuspended ? Colors.red.shade700 : const Color(0xFF14A800),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (user.createdAt != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.access_time,
                    size: 11,
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    _formatDate(user.createdAt!),
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _updateUserStatus(user.id!, isSuspended ? 'active' : 'suspended'),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isSuspended
                      ? const Color(0xFF14A800).withOpacity(0.1)
                      : Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSuspended
                        ? const Color(0xFF14A800).withOpacity(0.2)
                        : Colors.red.withOpacity(0.15),
                  ),
                ),
                child: Icon(
                  isSuspended ? Icons.check_circle_outline : Icons.block,
                  size: 16,
                  color: isSuspended ? const Color(0xFF14A800) : Colors.red.shade400,
                ),
              ),
            ),
            const SizedBox(width: 6),
            PopupMenuButton<String>(
              icon: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.AppColors.darkSurface : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade200,
                  ),
                ),
                child: Icon(
                  Icons.more_vert,
                  size: 16,
                  color: isDark ? Colors.grey.shade400 : const Color(0xFF888888),
                ),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
              onSelected: (value) {
                if (value == 'verify') {
                  _verifyUser(user.id!, !isVerified);
                } else if (value == 'suspend' && !isSuspended) {
                  _updateUserStatus(user.id!, 'suspended');
                } else if (value == 'activate' && isSuspended) {
                  _updateUserStatus(user.id!, 'active');
                } else if (value == 'view') {
                  Navigator.pushNamed(
                    context,
                    '/admin/user-details',
                    arguments: {'userId': user.id},
                  );
                } else if (value == 'resend') {
                  _resendAccountEmail(user.id!);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'view',
                  child: _buildMenuItem(Icons.visibility_outlined, t.viewProfile, isDark),
                ),
                PopupMenuItem(
                  value: 'resend',
                  child: _buildMenuItem(Icons.email_outlined, t.resendAccountEmail, isDark, color: Colors.blue),
                ),
                PopupMenuItem(
                  value: 'verify',
                  child: _buildMenuItem(
                    isVerified ? Icons.verified : Icons.verified_user_outlined,
                    isVerified ? t.removeVerification : t.verifyUser,
                    isDark,
                    color: isVerified ? Colors.orange : const Color(0xFF14A800),
                  ),
                ),
                if (!isSuspended)
                  PopupMenuItem(
                    value: 'suspend',
                    child: _buildMenuItem(Icons.block_outlined, t.suspendUser, isDark, color: Colors.red),
                  ),
                if (isSuspended)
                  PopupMenuItem(
                    value: 'activate',
                    child: _buildMenuItem(Icons.check_circle_outline, t.activateUser, isDark, color: const Color(0xFF14A800)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, bool isDark, {Color? color}) {
    final defaultColor = isDark ? Colors.grey.shade300 : Colors.grey.shade700;
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? defaultColor),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: color ?? defaultColor),
        ),
      ],
    );
  }

  Widget _buildPagination(AppLocalizations t, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _paginationButton(
            Icons.chevron_left,
            currentPage > 1 ? () {
              setState(() => currentPage--);
              _loadUsers();
            } : null,
            isDark,
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.AppColors.darkCard : const Color(0xFFF0F2F8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${t.page} $currentPage ${t.ofWord} $totalPages',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1A1B3E),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _paginationButton(
            Icons.chevron_right,
            currentPage < totalPages ? () {
              setState(() => currentPage++);
              _loadUsers();
            } : null,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _paginationButton(IconData icon, VoidCallback? onTap, bool isDark) {
    final isEnabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isEnabled
              ? AppTheme.AppColors.primary.withOpacity(0.1)
              : (isDark ? AppTheme.AppColors.darkCard : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isEnabled
                ? AppTheme.AppColors.primary.withOpacity(0.2)
                : (isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade200),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isEnabled
              ? AppTheme.AppColors.primary
              : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 30) return '${date.day}/${date.month}/${date.year}';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'Today';
  }
}