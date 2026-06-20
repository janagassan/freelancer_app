// lib/screens/auth/signup_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/api_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nationalIdController = TextEditingController();
  final phoneController = TextEditingController();
  final hourlyRateController = TextEditingController();
  final companyNameController = TextEditingController();
  final commercialRegisterController = TextEditingController();
  final taxNumberController = TextEditingController();
  final referralSourceController = TextEditingController();

  String role = 'client';
  String clientType = 'individual';
  bool loading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool agreedToTerms = false;

  File? cvFile;
  File? verificationDocument;
  File? commercialRegisterImage;

  final List<String> selectedSkills = [];
  final TextEditingController skillController = TextEditingController();

  bool nationalIdVerified = false;
  bool checkingNationalId = false;

  String? nameError;
  String? emailError;
  String? passwordError;
  String? confirmPasswordError;
  String? phoneError;
  String? companyNameError;

  late TabController _tabController;
  int _currentStep = 0;

  final List<String> referralOptions = [
    'Search Engine (Google, Bing)',
    'Social Media (Facebook, LinkedIn, Instagram)',
    'Friend / Referral',
    'YouTube / Online Tutorials',
    'Freelancer Community (Forums, Groups)',
    'University / Course',
    'Other',
  ];

  final List<String> popularSkills = [
    'Flutter',
    'React',
    'Node.js',
    'Python',
    'UI/UX Design',
    'Graphic Design',
    'Content Writing',
    'SEO',
    'Digital Marketing',
    'WordPress',
    'PHP',
    'Java',
    'Swift',
    'Kotlin',
    'Django',
    'MongoDB',
    'PostgreSQL',
    'AWS',
    'Docker',
    'Git',
  ];

  static const Color primaryPurple = Color(0xFF5B5BD6);
  static const Color loginButtonColor = Color(0xFF122543);
  static const Color primaryBlue = Color(0xFF3A5A8C);
  static const Color errorRed = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentStep = _tabController.index;
          _clearErrors();
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nationalIdController.dispose();
    phoneController.dispose();
    hourlyRateController.dispose();
    companyNameController.dispose();
    commercialRegisterController.dispose();
    taxNumberController.dispose();
    referralSourceController.dispose();
    skillController.dispose();
    super.dispose();
  }

  void _clearErrors() {
    setState(() {
      nameError = null;
      emailError = null;
      passwordError = null;
      confirmPasswordError = null;
      phoneError = null;
      companyNameError = null;
    });
  }

  void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 3,
      backgroundColor: errorRed,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  void _showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _pickCV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null) {
        setState(() {
          cvFile = File(result.files.single.path!);
        });
        _showSuccessToast('CV uploaded successfully');
      }
    } catch (e) {
      _showErrorToast('Error picking file: $e');
    }
  }

  Future<void> _pickVerificationDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result != null) {
        setState(() {
          verificationDocument = File(result.files.single.path!);
        });
        _showSuccessToast('Document uploaded');
      }
    } catch (e) {
      _showErrorToast('Error: $e');
    }
  }

  Future<void> _pickCommercialRegister() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result != null) {
        setState(() {
          commercialRegisterImage = File(result.files.single.path!);
        });
        _showSuccessToast('Commercial register uploaded');
      }
    } catch (e) {
      _showErrorToast('Error: $e');
    }
  }

  Future<void> _checkNationalId() async {
    if (nationalIdController.text.isEmpty) {
      _showErrorToast('Please enter National ID first');
      return;
    }
    setState(() => checkingNationalId = true);
    final res = await ApiService.verifyNationalId(
      nationalId: nationalIdController.text,
      name: nameController.text,
    );
    setState(() => checkingNationalId = false);
    if (res['success'] == true) {
      setState(() => nationalIdVerified = true);
      _showSuccessToast('✓ National ID Verified Successfully');
    } else {
      _showErrorToast(res['message'] ?? '❌ Invalid National ID');
    }
  }

  void _addSkill() {
    if (skillController.text.isNotEmpty &&
        !selectedSkills.contains(skillController.text)) {
      setState(() {
        selectedSkills.add(skillController.text);
        skillController.clear();
      });
    } else if (skillController.text.isEmpty) {
      _showErrorToast('Please enter a skill name');
    } else if (selectedSkills.contains(skillController.text)) {
      _showErrorToast('Skill already added');
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      selectedSkills.remove(skill);
    });
  }

  bool _validateStep(int step) {
    setState(() {
      nameError = null;
      emailError = null;
      passwordError = null;
      confirmPasswordError = null;
      phoneError = null;
      companyNameError = null;
    });

    switch (step) {
      case 0:
        if (nameController.text.trim().isEmpty) {
          nameError = 'Please enter your full name';
          _showErrorSnackBar(nameError!);
          return false;
        }
        if (emailController.text.trim().isEmpty) {
          emailError = 'Please enter your email address';
          _showErrorSnackBar(emailError!);
          return false;
        }
        if (!emailController.text.contains('@') ||
            !emailController.text.contains('.')) {
          emailError = 'Please enter a valid email address';
          _showErrorSnackBar(emailError!);
          return false;
        }
        if (passwordController.text.length < 6) {
          passwordError = 'Password must be at least 6 characters';
          _showErrorSnackBar(passwordError!);
          return false;
        }
        if (passwordController.text != confirmPasswordController.text) {
          confirmPasswordError = 'Passwords do not match';
          _showErrorSnackBar(confirmPasswordError!);
          return false;
        }
        if (!agreedToTerms) {
          _showErrorSnackBar('Please accept Terms & Conditions to continue');
          return false;
        }
        return true;

      case 1:
        if (role == 'client') {
          if (clientType == 'business' && companyNameController.text.trim().isEmpty) {
            companyNameError = 'Company name is required for business accounts';
            _showErrorSnackBar(companyNameError!);
            return false;
          }
        }
        if (phoneController.text.trim().isEmpty) {
          phoneError = 'Phone number is required';
          _showErrorSnackBar(phoneError!);
          return false;
        }
        return true;

      default:
        return true;
    }
  }

  void _nextStep() {
    if (_validateStep(_currentStep) && _currentStep < 2) {
      _tabController.animateTo(_currentStep + 1);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _tabController.animateTo(_currentStep - 1);
    }
  }

  void signup() async {
    if (!_validateStep(_currentStep)) return;
    
    setState(() => loading = true);
    
    final res = await ApiService.signup(
      name: nameController.text,
      email: emailController.text,
      password: passwordController.text,
      role: role,
      nationalId: nationalIdController.text.isEmpty
          ? null
          : nationalIdController.text,
      phone: phoneController.text.isEmpty ? null : phoneController.text,
      clientType: clientType,
      companyName: companyNameController.text.isEmpty
          ? null
          : companyNameController.text,
      commercialRegisterNumber: commercialRegisterController.text.isEmpty
          ? null
          : commercialRegisterController.text,
      taxNumber: taxNumberController.text.isEmpty
          ? null
          : taxNumberController.text,
      hourlyRate: hourlyRateController.text.isEmpty
          ? null
          : double.tryParse(hourlyRateController.text),
      skills: selectedSkills.isEmpty ? null : selectedSkills,
      cvFile: cvFile,
      verificationDocument: verificationDocument,
      commercialRegisterImage: commercialRegisterImage,
      agreedToTerms: agreedToTerms,
      referralSource: referralSourceController.text.isEmpty
          ? null
          : referralSourceController.text,
    );

    print('SIGNUP RESPONSE: $res');

    
    setState(() => loading = false);
    
    if (res['error'] != null) {
  _showErrorToast(res['error']);
} else {
  print("BEFORE NAVIGATION");
print(res);
  _showSuccessToast(res['message'] ?? 'Account created successfully!');

  if (mounted) {
    if (res['cvAnalysis'] != null &&
        res['cvAnalysis']['has_analysis'] == true) {
      _showCVAnalysisDialog(res['cvAnalysis']);
    } else {
      Navigator.pushNamedAndRemoveUntil(
  context,
  '/login',
  (route) => false,
);
    }
  }
}
}

  void _showCVAnalysisDialog(Map<String, dynamic> analysis) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: primaryBlue),
            SizedBox(width: 8),
            Text('AI CV Analysis Complete'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📝 Suggested Title: ${analysis['title'] ?? 'Not detected'}'),
            const SizedBox(height: 8),
            Text('🔧 Skills Found: ${analysis['skills_count'] ?? 0}'),
            const SizedBox(height: 8),
            Text(
              '🎯 AI Confidence: ${((analysis['confidence'] ?? 0) * 100).toInt()}%',
            ),
            const SizedBox(height: 16),
            const Text(
              'Your profile has been enhanced with AI suggestions!',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
  context,
  '/login',
  (route) => false,
);
              }
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 700;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D1C33), Color(0xFF122543), Color(0xFF3A5A8C)],
          ),
        ),
        child: isWide ? _buildWideLayout() : _buildNarrowLayout(),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _buildLeftPanel()),
        Expanded(child: _buildRightCard()),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _buildRightCard(),
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLogo(),
          const Text(
            'Join iPal Today!',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Start your freelancing career',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Join thousands of freelancers and clients worldwide. Find work, hire talent, and get paid securely on iPal.',
            style: TextStyle(fontSize: 13, color: Colors.white60, height: 1.65),
          ),
          const SizedBox(height: 24),
          _buildProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step ${_currentStep + 1} of 3',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(3, (index) {
            return Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: index <= _currentStep ? primaryBlue : Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        Text(
          _getStepTitle(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Basic Information';
      case 1:
        return 'Verification & Professional Details';
      case 2:
        return 'Review & Submit';
      default:
        return '';
    }
  }

  Widget _buildRightCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 50, 50, 0),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 40,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              if (_currentStep > 0)
                TextButton(onPressed: _prevStep, child: const Text('Back')),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Fill in your details to get started',
            style: TextStyle(fontSize: 13, color: Colors.black45),
          ),
          const SizedBox(height: 28),

          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                SingleChildScrollView(child: _buildBasicInfoTab()),
                SingleChildScrollView(child: _buildVerificationTab()),
                SingleChildScrollView(child: _buildReviewTab()),
              ],
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: loading
                  ? null
                  : (_currentStep < 2 ? _nextStep : signup),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                disabledBackgroundColor: primaryBlue.withOpacity(0.7),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      _currentStep < 2 ? 'Continue' : 'Sign Up',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: nameController,
          hint: 'Full Name',
          icon: Icons.person_outline,
          errorText: nameError,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          controller: emailController,
          hint: 'Email Address',
          icon: Icons.email_outlined,
          errorText: emailError,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          controller: passwordController,
          hint: 'Password',
          icon: Icons.lock_outline,
          isPassword: true,
          isConfirmPassword: false,
          errorText: passwordError,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          controller: confirmPasswordController,
          hint: 'Confirm Password',
          icon: Icons.lock_outline,
          isPassword: true,
          isConfirmPassword: true,
          errorText: confirmPasswordError,
        ),
        const SizedBox(height: 14),
        _buildRoleDropdown(),
        const SizedBox(height: 14),
        Row(
          children: [
            Checkbox(
              value: agreedToTerms,
              onChanged: (val) => setState(() => agreedToTerms = val ?? false),
              activeColor: primaryBlue,
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => _showTermsDialog(),
                child: const Text(
                  'I agree to the Terms & Conditions and Privacy Policy',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVerificationTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (role == 'freelancer') ...[
          _buildFreelancerFields(),
        ] else ...[
          _buildClientFields(),
        ],
        const Divider(height: 24),
        _buildPhoneVerificationField(),
        const SizedBox(height: 14),
        _buildNationalIdField(),
        const SizedBox(height: 14),
        _buildReferralField(),
      ],
    );
  }

  Widget _buildFreelancerFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Professional Information',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          controller: hourlyRateController,
          hint: 'Hourly Rate (USD)',
          icon: Icons.attach_money,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 14),
        const Text(
          'Skills',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: selectedSkills
              .map(
                (skill) => Chip(
                  label: Text(skill),
                  onDeleted: () => _removeSkill(skill),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  backgroundColor: loginButtonColor.withOpacity(0.1),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: skillController,
                decoration: const InputDecoration(
                  hintText: 'Add a skill',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onSubmitted: (_) => _addSkill(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _addSkill,
              icon: const Icon(Icons.add_circle, color: primaryBlue),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickCV,
                icon: const Icon(Icons.upload_file, size: 18),
                label: Text(
                  cvFile == null ? 'Upload CV (Optional)' : 'CV Uploaded ✓',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (cvFile != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              cvFile!.path.split('/').last,
              style: const TextStyle(fontSize: 11, color: Colors.green),
            ),
          ),
      ],
    );
  }

  Widget _buildClientFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Company Information',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSelectionCard(
                title: 'Individual',
                icon: Icons.person_outline,
                isSelected: clientType == 'individual',
                onTap: () => setState(() => clientType = 'individual'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSelectionCard(
                title: 'Business',
                icon: Icons.business_outlined,
                isSelected: clientType == 'business',
                onTap: () => setState(() => clientType = 'business'),
              ),
            ),
          ],
        ),
        if (clientType == 'business') ...[
          const SizedBox(height: 16),
          _buildTextField(
            controller: companyNameController,
            hint: 'Company Name',
            icon: Icons.business_outlined,
            errorText: companyNameError,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: commercialRegisterController,
            hint: 'Commercial Register Number',
            icon: Icons.numbers_outlined,
          ),
          const SizedBox(height: 12),
          _buildUploadCard(
            title: 'Commercial Register',
            subtitle: 'Upload your commercial registration document',
            file: commercialRegisterImage,
            onTap: _pickCommercialRegister,
            icon: Icons.description_outlined,
          ),
        ],
        const SizedBox(height: 16),
        _buildTextField(
          controller: taxNumberController,
          hint: 'Tax Number (Optional)',
          icon: Icons.receipt_outlined,
        ),
        const SizedBox(height: 16),
        _buildUploadCard(
          title: 'Identity Verification',
          subtitle: clientType == 'business'
              ? 'Upload business license or company registration'
              : 'Upload government ID or passport',
          file: verificationDocument,
          onTap: _pickVerificationDocument,
          icon: Icons.verified_user_outlined,
        ),
      ],
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected ? primaryBlue : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? primaryBlue : Colors.grey, size: 18),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? primaryBlue : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard({
    required String title,
    required String subtitle,
    required File? file,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryBlue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onTap,
            icon: Icon(
              file != null ? Icons.check_circle : Icons.cloud_upload,
              size: 16,
              color: primaryBlue,
            ),
            label: Text(
              file != null ? 'File Uploaded' : 'Upload Document',
              style: const TextStyle(fontSize: 12),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              side: const BorderSide(color: Color(0xFFE0E0E0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneVerificationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone Number *',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          controller: phoneController,
          hint: '+1234567890',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          errorText: phoneError,
        ),
        const SizedBox(height: 4),
        const Text(
          'We will use this for account recovery and notifications',
          style: TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildNationalIdField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'National ID (Optional - Builds Trust)',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: nationalIdController,
                hint: 'National ID Number',
                icon: Icons.credit_card_outlined,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            if (nationalIdController.text.isNotEmpty && !nationalIdVerified)
              ElevatedButton(
                onPressed: checkingNationalId ? null : _checkNationalId,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  minimumSize: const Size(80, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: checkingNationalId
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Verify'),
              ),
            if (nationalIdVerified)
              const Icon(Icons.check_circle, color: Colors.green, size: 28),
          ],
        ),
        if (nationalIdVerified)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              '✓ Identity verified',
              style: TextStyle(color: Colors.green, fontSize: 11),
            ),
          ),
      ],
    );
  }

  Widget _buildReferralField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How did you hear about us?',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: referralSourceController.text.isEmpty
              ? null
              : referralSourceController.text,
          hint: const Text('Select an option'),
          items: referralOptions.map((option) {
            return DropdownMenuItem(value: option, child: Text(option));
          }).toList(),
          onChanged: (value) {
            setState(() {
              referralSourceController.text = value ?? '';
            });
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(50)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: primaryBlue, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReviewTile('Full Name', nameController.text),
        _buildReviewTile('Email', emailController.text),
        _buildReviewTile(
          'Account Type',
          role == 'freelancer' ? 'Freelancer' : 'Client',
        ),
        if (role == 'freelancer') ...[
          if (hourlyRateController.text.isNotEmpty)
            _buildReviewTile('Hourly Rate', '\$${hourlyRateController.text}'),
          if (selectedSkills.isNotEmpty)
            _buildReviewTile('Skills', selectedSkills.join(', ')),
          if (cvFile != null) _buildReviewTile('CV', 'Uploaded ✓'),
        ],
        if (role == 'client' && clientType == 'business') ...[
          if (companyNameController.text.isNotEmpty)
            _buildReviewTile('Company', companyNameController.text),
          if (commercialRegisterController.text.isNotEmpty)
            _buildReviewTile(
              'Commercial Register',
              commercialRegisterController.text,
            ),
        ],
        const Divider(),
        _buildReviewTile(
          'Phone',
          phoneController.text,
          verified: false,
        ),
        if (nationalIdController.text.isNotEmpty)
          _buildReviewTile(
            'National ID',
            '••••${nationalIdController.text.substring(nationalIdController.text.length - 4)}',
            verified: nationalIdVerified,
          ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.shield_outlined, color: primaryBlue),
              const SizedBox(width: 8),
              Expanded(
                child: const Text(
                  'Your information is secure and will be used only for verification purposes.',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewTile(String label, String value, {bool verified = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
          if (verified)
            const Icon(Icons.verified, color: Colors.green, size: 18),
        ],
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms & Conditions'),
        content: const SingleChildScrollView(
          child: Text(
            '1. You must be at least 18 years old to use this platform.\n\n'
            '2. You agree to provide accurate and complete information.\n\n'
            '3. You are responsible for maintaining the security of your account.\n\n'
            '4. The platform reserves the right to suspend accounts that violate terms.\n\n'
            '5. All transactions are subject to platform fees as described.\n\n'
            '6. Disputes will be resolved through our dispute resolution process.\n\n'
            '7. We collect and process data in accordance with our Privacy Policy.\n\n'
            '8. You agree not to use the platform for any illegal activities.\n\n'
            'By creating an account, you agree to these terms.',
            style: TextStyle(fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isConfirmPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: isPassword
              ? (isConfirmPassword ? obscureConfirmPassword : obscurePassword)
              : false,
          style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFFBBBBBB), size: 20),
            suffixIcon: isPassword
                ? GestureDetector(
                    onTap: () => setState(() {
                      if (isConfirmPassword) {
                        obscureConfirmPassword = !obscureConfirmPassword;
                      } else {
                        obscurePassword = !obscurePassword;
                      }
                    }),
                    child: Icon(
                      (isConfirmPassword ? obscureConfirmPassword : obscurePassword)
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFFBBBBBB),
                      size: 20,
                    ),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: const BorderSide(color: primaryBlue, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: const BorderSide(color: errorRed, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: const BorderSide(color: errorRed, width: 1.5),
            ),
            errorText: errorText,
            errorStyle: const TextStyle(fontSize: 11, color: errorRed),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: role,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFBBBBBB)),
          style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
          isExpanded: true,
          items: ['client', 'freelancer']
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Row(
                    children: [
                      Icon(
                        e == 'client'
                            ? Icons.business_outlined
                            : Icons.person_outline,
                        color: primaryBlue,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        e == 'client'
                            ? 'Client (Hire Freelancers)'
                            : 'Freelancer (Find Work)',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (val) {
            setState(() {
              role = val!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logoo.png',
          width: 100,
          height: 100,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(Icons.work, color: Colors.white, size: 40),
            );
          },
        ),
      ],
    );
  }
}