import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/theme_data.dart';
import 'core/router/app_router.dart';
import 'core/constants/app_constants.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'features/resume/data/resume_repository.dart';
import 'features/resume/presentation/resume_provider.dart';
import 'features/interview/data/interview_repository.dart';
import 'features/interview/presentation/interview_provider.dart';
import 'features/quiz/data/quiz_repository.dart';
import 'features/quiz/presentation/quiz_provider.dart';
import 'features/report/data/report_repository.dart';
import 'features/report/presentation/report_provider.dart';
import 'shared/firebase/firebase_service.dart';

import 'core/services/local_storage_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/sync_service.dart';
import 'core/services/pdf_parser_service.dart';
import 'core/services/audio_recorder_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Local Cache Database (Hive)
  await Hive.initFlutter();
  await Hive.openBox(AppConstants.resumeBox);
  await Hive.openBox(AppConstants.draftBox);
  await Hive.openBox(AppConstants.userPrefsBox);

  // Initialize Firebase (Auth, Firestore, App Check)
  await FirebaseService.initialize();

  runApp(
    MultiProvider(
      providers: [
        Provider<FirebaseService>(create: (_) => FirebaseService()),
        Provider<LocalStorageService>(create: (_) => LocalStorageService()),
        Provider<ConnectivityService>(create: (_) => ConnectivityService()),
        
        // Auth
        ProxyProvider<FirebaseService, AuthRepository>(
          update: (_, firebase, previousRepository) => AuthRepository(firebase.auth),
        ),
        ChangeNotifierProxyProvider<AuthRepository, AuthProvider>(
          create: (context) => AuthProvider(context.read<AuthRepository>()),
          update: (_, repo, prev) => prev ?? AuthProvider(repo),
        ),

        // Core Services
        ProxyProvider2<ConnectivityService, LocalStorageService, SyncService>(
          update: (_, conn, storage, prev) => SyncService(conn, storage),
          dispose: (_, syncService) => syncService.dispose(),
        ),
        ProxyProvider<FirebaseService, PdfParserService>(
          update: (_, firebase, prev) => PdfParserService(firebase.functions),
          dispose: (_, parser) => parser.dispose(),
        ),
        Provider<AudioRecorderService>(
          create: (_) => AudioRecorderService(),
          dispose: (_, svc) => svc.dispose(),
        ),

        // Feature Repositories
        ProxyProvider<FirebaseService, ResumeRepository>(
          update: (_, firebase, prev) => ResumeRepository(firebase.firestore, firebase.functions),
        ),
        ProxyProvider<FirebaseService, InterviewRepository>(
          update: (_, firebase, prev) => InterviewRepository(firebase.firestore, firebase.functions),
        ),
        ProxyProvider<FirebaseService, QuizRepository>(
          update: (_, firebase, prev) => QuizRepository(firebase.firestore, firebase.functions),
        ),
        ProxyProvider<FirebaseService, ReportRepository>(
          update: (_, firebase, prev) => ReportRepository(firebase.firestore, firebase.functions),
        ),

        // Feature Providers (wired to their repositories)
        ChangeNotifierProxyProvider<ResumeRepository, ResumeProvider>(
          create: (context) => ResumeProvider(context.read<ResumeRepository>()),
          update: (_, repo, prev) => prev ?? ResumeProvider(repo),
        ),
        ChangeNotifierProxyProvider<InterviewRepository, InterviewProvider>(
          create: (context) => InterviewProvider(context.read<InterviewRepository>()),
          update: (_, repo, prev) => prev ?? InterviewProvider(repo),
        ),
        ChangeNotifierProxyProvider<QuizRepository, QuizProvider>(
          create: (context) => QuizProvider(context.read<QuizRepository>()),
          update: (_, repo, prev) => prev ?? QuizProvider(repo),
        ),
        ChangeNotifierProxyProvider<ReportRepository, ReportProvider>(
          create: (context) => ReportProvider(context.read<ReportRepository>()),
          update: (_, repo, prev) => prev ?? ReportProvider(repo),
        ),
      ],
      child: const ResuMatchApp(),
    ),
  );
}

class ResuMatchApp extends StatefulWidget {
  const ResuMatchApp({super.key});

  @override
  State<ResuMatchApp> createState() => _ResuMatchAppState();
}

class _ResuMatchAppState extends State<ResuMatchApp> {
  late GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _router = AppRouter.getRouter(authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box(AppConstants.userPrefsBox).listenable(),
      builder: (context, Box box, child) {
        final isDarkMode = box.get(AppConstants.keyThemeMode, defaultValue: false);

        return MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          routerConfig: _router,
        );
      },
    );
  }
}
