import 'dart:async';
import 'dart:io';

/// 网络连通性监听服务
/// 周期性检测网络是否可用，供处理管线判断是否可调用云端 AI
class ConnectivityService {
  bool _isOnline = true;
  Timer? _timer;
  final _connectivityController = StreamController<bool>.broadcast();

  ConnectivityService() {
    _startMonitoring();
  }

  /// 当前是否在线
  bool get isOnline => _isOnline;

  /// 网络状态变更流
  Stream<bool> get onConnectivityChange => _connectivityController.stream;

  void _startMonitoring() {
    // 立即做一次检测
    _checkConnectivity();
    // 每 30 秒检测一次
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkConnectivity();
    });
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      final online = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      if (online != _isOnline) {
        _isOnline = online;
        _connectivityController.add(_isOnline);
      }
    } catch (_) {
      if (_isOnline) {
        _isOnline = false;
        _connectivityController.add(false);
      }
    }
  }

  /// 手动触发一次检测并返回结果
  Future<bool> checkNow() async {
    await _checkConnectivity();
    return _isOnline;
  }

  void dispose() {
    _timer?.cancel();
    _connectivityController.close();
  }
}
