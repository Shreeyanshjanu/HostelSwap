import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';

import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/chatbot_screen.dart';
import 'screens/create_request_screen.dart';
import 'screens/my_requests_screen.dart';
import 'screens/applicants_list_screen.dart';

import 'config/app_constants.dart';
import 'services/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize FCM
  // await FCMService().init();

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HostelSwap',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),

      initialRoute: '/login',

      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/chatbot': (context) => const ChatbotScreen(),
        '/create-request': (context) => const CreateRequestScreen(),
        '/my-requests': (context) => const MyRequestsScreen(),
        '/applicants': (context) => const ApplicantsListScreen(),
      },
    );
  }
}
