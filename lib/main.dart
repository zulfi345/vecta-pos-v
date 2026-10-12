import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/widgets/license_gate.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // <-- 1. Tambah import Supabase

import 'app/app.dart';
import 'app/di/app_providers.dart';
import 'core/services/database/database_service.dart';
import 'firebase_options.dart';

void main() async {
  // Initialize binding
  WidgetsFlutterBinding.ensureInitialized();

  // 3. Initialize Supabase untuk sistem lisensi
  await Supabase.initialize(
    url: 'https://zvpmcrpxydkdpmxttkcw.supabase.co',
    anonKey: 'sb_publishable_jJfj6-zPDPp4bfMDRe9vbg_FQxuHBRt',
  );

  // Initialize Firebase (use `flutterfire configure` to generate the options)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize app local db
  await DatabaseService.instance.init();

  // Initialize date formatting
  await initializeDateFormatting();

  // Initialize shared preferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Set/lock screen orientation
  await SystemChrome.setPreferredOrientations([]);

  // Set Default SystemUIOverlayStyle
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      statusBarColor: Colors.transparent,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(sharedPreferences)],
      child: const LicenseGate(child: App()),
    ),
  );
}

// Trigger auto-build update
