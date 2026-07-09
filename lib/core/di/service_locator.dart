import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../database/database.dart';
import '../services/ai_engine.dart';
import '../services/settings_service.dart';
import '../../features/idea_stream/data/idea_repository.dart';

final getIt = GetIt.instance;

Future<void> setupLocator() async {
  getIt.registerSingleton<AppDatabase>(AppDatabase());
  getIt.registerSingleton<IdeaRepository>(IdeaRepository(getIt<AppDatabase>()));
  getIt.registerSingleton<AiEngine>(AiEngine());

  final settings = SettingsService();
  await settings.init();
  getIt.registerSingleton<SettingsService>(settings);

  debugPrint("Locus Core Hub Initialized.");
}
