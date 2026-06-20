import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../database/database.dart';

final getIt = GetIt.instance;

Future<void> setupLocator() async {
  getIt.registerSingleton<AppDatabase>(AppDatabase());
  // Phase 3: getIt.registerSingleton<IAIEngine>(LocalOllama());

  debugPrint("Locus Core Hub Initialized.");
}
