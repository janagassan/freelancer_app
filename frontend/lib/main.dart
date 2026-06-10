// main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:freelancer_platform/screens/ads/create_ad_campaign_screen.dart';
import 'package:freelancer_platform/screens/auth/reset_password_screen.dart';
import 'package:freelancer_platform/screens/contract/work_submissions_screen.dart';
import 'package:freelancer_platform/screens/settings/change_password_screen.dart';
import 'package:freelancer_platform/screens/settings/settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:freelancer_platform/providers/theme_provider.dart';
import 'package:freelancer_platform/models/contract_model.dart';
import 'package:freelancer_platform/models/interview_model.dart';
import 'package:freelancer_platform/models/project_model.dart';
import 'package:freelancer_platform/models/proposal_model.dart';
import 'package:freelancer_platform/models/dispute_model.dart' hide Project;
import 'package:freelancer_platform/screens/admin/admin_dashboard_screen.dart';
import 'package:freelancer_platform/screens/admin/users_management_screen.dart';
import 'package:freelancer_platform/screens/ai/ai_chat_screen.dart';
import 'package:freelancer_platform/screens/chat/chat_screen.dart';
import 'package:freelancer_platform/screens/client/compare_freelancers_screen.dart';
import 'package:freelancer_platform/screens/client/negotiation_screen.dart';
import 'package:freelancer_platform/screens/disputes/create_dispute_screen.dart';
import 'package:freelancer_platform/screens/disputes/my_disputes_screen.dart';
import 'package:freelancer_platform/screens/disputes/dispute_details_screen.dart';
import 'package:freelancer_platform/screens/features/features_shop_screen.dart';
import 'package:freelancer_platform/screens/freelancer/advanced_search_screen.dart';
import 'package:freelancer_platform/screens/freelancer/favorites_screen.dart';
import 'package:freelancer_platform/screens/freelancer/financial_dashboard_screen.dart';
import 'package:freelancer_platform/screens/freelancer/profile_screen.dart';
import 'package:freelancer_platform/screens/freelancer/work_submission_screen.dart';
import 'package:freelancer_platform/screens/interview/interview_calendar_screen.dart';
import 'package:freelancer_platform/screens/interview/interview_stats_screen.dart';
import 'package:freelancer_platform/screens/landing/landing_screen.dart';
import 'package:freelancer_platform/screens/landing/landing_screen_enhanced.dart';
import 'package:freelancer_platform/screens/payment/payment_screen.dart';
import 'package:freelancer_platform/screens/skill_tests/test_results_screen.dart';
import 'package:freelancer_platform/screens/subscription/my_subscription_screen.dart';
import 'package:freelancer_platform/screens/subscription/subscription_comparison_screen.dart';
import 'package:freelancer_platform/screens/subscription/subscription_invoices_screen.dart';
import 'package:freelancer_platform/screens/subscription/subscription_plans_screen.dart';
import 'package:freelancer_platform/screens/subscription/subscription_usage_screen.dart';
import 'package:freelancer_platform/screens/wallet/wallet_screen.dart';
import 'package:freelancer_platform/screens/workspace/add_reminder_screen.dart';
import 'package:freelancer_platform/screens/workspace/connect_github_screen.dart';
import 'package:freelancer_platform/screens/rating/add_rating_screen.dart';
import 'package:freelancer_platform/screens/workspace/calendar_screen.dart';
import 'package:freelancer_platform/screens/contract/my_contracts_screen.dart';
import 'package:freelancer_platform/services/websocket_service.dart'
    show WebSocketService, navigatorKey;
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/verify_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/freelancer/profile_screen.dart';
import 'screens/freelancer/project_details_screen.dart';
import 'screens/freelancer/submit_proposal_screen.dart';
import 'screens/freelancer/my_proposals_screen.dart';
import 'screens/freelancer/my_projects_screen.dart';
import 'screens/client/client_dashboard_screen.dart';
import 'screens/client/create_project_screen.dart';
import 'screens/client/project_details_screen.dart' as client;
import 'screens/client/project_proposals_screen.dart';
import 'screens/client/edit_project_screen.dart';
import 'theme/app_theme.dart';
import 'utils/token_storage.dart';
import 'services/api_service.dart';
import 'screens/contract/contract_screen.dart';
import 'package:freelancer_platform/screens/contract/contract_progress_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/chat/chats_list_screen.dart';
import 'services/socket_service.dart';
import 'package:freelancer_platform/screens/subscription/subscription_success_screen.dart';
import 'package:freelancer_platform/screens/subscription/subscription_cancel_screen.dart';
import 'screens/interview/interviews_screen.dart';
import 'screens/interview/interview_detail_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:freelancer_platform/services/language_service.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: "assets/.env");

  if (!kIsWeb) {
    try {
      Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
      await Stripe.instance.applySettings();
      print('✅ Stripe initialized');
    } catch (e) {
      print('❌ Stripe init error: $e');
    }
  }

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  final savedToken = await TokenStorage.getToken();
  final savedRole = await TokenStorage.getUserRole();
  final savedUserId = await TokenStorage.getUserId();
  ApiService.token = savedToken;

  print('🔌 Initializing SocketService...');
  await SocketService.instance.init();

  await Future.delayed(const Duration(seconds: 1));

  try {
    await WebSocketService.init();
    print('✅ WebSocket Service initialized');
  } catch (e) {
    print('❌ WebSocket Service init error: $e');
  }

  print('✅ App initialized with userId: $savedUserId');
  final locale = await LanguageService.getSavedLocale();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
      child: FreelancerApp(initialRole: savedRole, initialLocale: locale),
    ),
  );
}

class FreelancerApp extends StatefulWidget {
  final String? initialRole;
  final Locale initialLocale;

  const FreelancerApp({
    super.key,
    this.initialRole,
    required this.initialLocale,
  });

  @override
  State<FreelancerApp> createState() => _FreelancerAppState();
}

class _FreelancerAppState extends State<FreelancerApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
  }

  void _setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
    LanguageService.setLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'iPal ',
          locale: _locale,
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          initialRoute: _getInitialRoute(),
          routes: {
            '/': (_) => const LandingScreenEnhanced(),
            '/login': (_) => const LoginScreen(),
            '/signup': (_) => const SignupScreen(),
            '/verify': (_) => const VerifyScreen(),
            '/forgot': (_) => ForgotPasswordScreen(),
            '/change-password': (context) => const ChangePasswordScreen(),


            '/home': (_) => HomeScreen(),

            '/freelancer/home': (_) => FreelancerHomeScreen(),
            '/freelancer/my-proposals': (_) => const MyProposalsScreen(),
            '/freelancer/my-projects': (_) => const MyProjectsScreen(),

            '/projects': (_) => FreelancerHomeScreen(),
            '/settings': (_) => SettingsScreen(onLocaleChange: _setLocale),

            '/client/dashboard': (_) => const ClientDashboard(),
            '/client/create-project': (_) => const CreateProjectScreen(),
            '/subscription/plans': (_) => const SubscriptionPlansScreen(),
            '/subscription/my': (_) => const MySubscriptionScreen(),
            '/features/shop': (_) => const FeaturesShopScreen(),
            '/subscription_success': (_) => const SubscriptionSuccessScreen(),
            '/subscription_cancel': (_) => const SubscriptionCancelScreen(),
            '/subscription/invoices': (_) => const SubscriptionInvoicesScreen(),
            '/subscription/comparison': (_) =>
                const SubscriptionComparisonScreen(),
            '/subscription/usage': (_) => const SubscriptionUsageScreen(),
            '/chats': (_) => ChatsListScreen(),
            '/create-ad-campaign': (context) => const CreateAdCampaignScreen(),
            '/favorites': (_) => const FavoritesScreen(),
            '/financial-dashboard': (_) => const FinancialDashboardScreen(),
            '/advanced-search': (_) => const AdvancedSearchScreen(),
            '/contract/submissions': (context) {
  final args = ModalRoute.of(context)!.settings.arguments as Map;
  return WorkSubmissionsScreen(
    contractId: args['contractId'],
    userRole: args['userRole'],
  );
},

            '/my-contracts': (context) {
              final userRole =
                  ModalRoute.of(context)!.settings.arguments as String? ??
                  'client';
              return MyContractsScreen(userRole: userRole);
            },
            '/my-disputes': (_) => const MyDisputesScreen(),
          },
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/freelancer/project-details':
                final projectId = settings.arguments as int;
                return MaterialPageRoute(
                  builder: (_) => ProjectDetailsScreen(projectId: projectId),
                );

              case '/freelancer/submit-proposal':
                final project = settings.arguments as Project;
                return MaterialPageRoute(
                  builder: (_) => SubmitProposalScreen(project: project),
                );

              case '/work-submission':
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (_) => WorkSubmissionScreen(
                    contract: args['contract'],
                    milestoneIndex: args['milestoneIndex'],
                    milestone: args['milestone'],
                  ),
                );

              case '/create-ad-campaign':
                return MaterialPageRoute(
                  builder: (_) => const CreateAdCampaignScreen(),
                );

              case '/subscription_success':
                return MaterialPageRoute(
                  builder: (_) => const SubscriptionSuccessScreen(),
                );

              case '/subscription_cancel':
                return MaterialPageRoute(
                  builder: (_) => const SubscriptionCancelScreen(),
                );

              case '/create-dispute':
                final contractId = settings.arguments as int;
                return MaterialPageRoute(
                  builder: (_) => CreateDisputeScreen(contractId: contractId),
                );

              case '/dispute-details':
                final dispute = settings.arguments as Dispute;
                return MaterialPageRoute(
                  builder: (_) => DisputeDetailsScreen(dispute: dispute),
                );

              case '/subscription/plans':
                return MaterialPageRoute(
                  builder: (_) => const SubscriptionPlansScreen(),
                );

              case '/subscription/comparison':
                return MaterialPageRoute(
                  builder: (_) => const SubscriptionComparisonScreen(),
                );
              case '/compare-freelancers':
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (_) => CompareFreelancersScreen(
                    projectId: args['projectId'],
                    freelancerIds: args['freelancerIds'],
                  ),
                );
              case '/subscription/my':
                return MaterialPageRoute(
                  builder: (_) => const MySubscriptionScreen(),
                );

              case '/client/project-details':
                final projectId = settings.arguments as int;
                return MaterialPageRoute(
                  builder: (_) =>
                      client.ProjectDetailsScreen(projectId: projectId),
                );

              case '/features/shop':
                return MaterialPageRoute(
                  builder: (_) => const FeaturesShopScreen(),
                );

              case '/admin/dashboard':
                return MaterialPageRoute(
                  builder: (_) => const AdminDashboardScreen(),
                );

              case '/client/project-proposals':
                final projectId = settings.arguments as int;
                return MaterialPageRoute(
                  builder: (_) => ProjectProposalsScreen(projectId: projectId),
                );

              case '/client/edit-project':
                final project = settings.arguments as Project;
                return MaterialPageRoute(
                  builder: (_) => EditProjectScreen(project: project),
                );

              case '/interviews':
                return MaterialPageRoute(
                  builder: (_) => const InterviewsScreen(),
                );

              case '/interview-detail':
                final invitation = settings.arguments as InterviewInvitation;
                return MaterialPageRoute(
                  builder: (_) => InterviewDetailScreen(invitation: invitation),
                );

              case '/interview-stats':
                return MaterialPageRoute(
                  builder: (_) => const InterviewStatsScreen(),
                );
              case '/interview-calendar':
                return MaterialPageRoute(
                  builder: (_) => const InterviewCalendarScreen(),
                );

              case '/chat':
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    chatId: int.parse(args['chatId'].toString()),
                    otherUserId: int.parse(args['otherUserId'].toString()),
                    otherUserName: args['otherUserName'],
                    otherUserAvatar: args['otherUserAvatar'],
                  ),
                );

              case '/contract':
                final args = settings.arguments as Map<String, dynamic>;
                final contractId = args['contractId'] as int;
                final userRole = args['userRole'] as String;
                return MaterialPageRoute(
                  builder: (_) => ContractScreen(
                    contractId: contractId,
                    userRole: userRole,
                  ),
                );

              case '/contract/progress':
                final args = settings.arguments as Map<String, dynamic>;
                final contractId = args['contractId'] as int;
                final userRole = args['userRole'] as String;
                return MaterialPageRoute(
                  builder: (_) => ContractProgressScreen(
                    contractId: contractId,
                    userRole: userRole,
                  ),
                );

              case '/add-rating':
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (_) => AddRatingScreen(
                    contractId: args['contractId'],
                    projectTitle: args['projectTitle'],
                    otherPartyName: args['otherPartyName'],
                    role: args['role'],
                  ),
                );

              case '/calendar':
                return MaterialPageRoute(
                  builder: (_) => const CalendarScreen(),
                );

              case '/add-reminder':
                final contractId = settings.arguments as int;
                return MaterialPageRoute(
                  builder: (_) => AddReminderScreen(contractId: contractId),
                );

              case '/wallet':
                final userRole = settings.arguments as String? ?? 'client';
                return MaterialPageRoute(
                  builder: (_) => WalletScreen(userRole: userRole),
                );

              case '/negotiation':
                final proposal = settings.arguments as Proposal;
                return MaterialPageRoute(
                  builder: (_) => NegotiationScreen(proposal: proposal),
                );

              case '/payment':
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (_) => PaymentScreen(
                    contractId: args['contractId'],
                    paymentIntent: args['paymentIntent'],
                  ),
                );

              case '/connect-github':
                final contractId = settings.arguments as int;
                return MaterialPageRoute(
                  builder: (_) => ConnectGithubScreen(contractId: contractId),
                );

              case '/ai-chat':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (_) => AIChatScreen(projectId: args?['projectId']),
                );

              case '/test-results':
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (_) => TestResultsScreen(
                    userTestId: args['userTestId'],
                    test: args['test'],
                    result: args['result'],
                  ),
                );

              default:
                return MaterialPageRoute(
                  builder: (_) => const Scaffold(
                    body: Center(child: Text('Route not found')),
                  ),
                );
            }
          },
          onUnknownRoute: (settings) {
            return MaterialPageRoute(
              builder: (_) =>
                  const Scaffold(body: Center(child: Text('Page not found'))),
            );
          },
        );
      },
    );
  }

  String _getInitialRoute() {
    if (ApiService.token != null) {
      if (widget.initialRole == 'freelancer') {
        return '/freelancer/home';
      } else if (widget.initialRole == 'client') {
        return '/client/dashboard';
      }
    }
    return '/';
  }
}

final supabase = Supabase.instance.client;
