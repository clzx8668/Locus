import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../database/database.dart';
import '../services/ai_engine.dart';
import '../../features/idea_stream/data/idea_repository.dart';

final getIt = GetIt.instance;

Future<void> setupLocator() async {
  getIt.registerSingleton<AppDatabase>(AppDatabase());
  getIt.registerSingleton<IdeaRepository>(IdeaRepository(getIt<AppDatabase>()));
  getIt.registerSingleton<AiEngine>(AiEngine());

  debugPrint("Locus Core Hub Initialized.");
}
