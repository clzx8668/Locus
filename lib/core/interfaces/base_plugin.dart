abstract class BasePlugin {
  String get pluginName;
  Future<void> init();
  void enable();
  void disable();
  bool get isEnabled;
}
