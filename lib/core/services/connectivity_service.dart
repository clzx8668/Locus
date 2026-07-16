import 'dart:async';
import 'dart:io';

/// 连通性事件类型
enum ConnectivityEvent { wentOnline, wentOffline }

/// 网络连通性监听服务
/// 周期性检测网络是否可用，供处理管线判断是否可调用云端 AI
class ConnectivityService {
  bool _isOnline = true;
  Timer? _timer;
  final _connectivityController = StreamController<bool>.broadcast();
  final _eventController = StreamController<ConnectivityEvent>.broadcast();

  ConnectivityService() {
    _startMonitoring();
  }

  /// 当前是否在线
  bool get isOnline => _isOnline;

  /// 网络状态变更流（bool）
  Stream<bool> get onConnectivityChange => _connectivityController.stream;

  /// 连通性事件流（wentOnline / wentOffline）
  Stream<ConnectivityEvent> get onConnectivityEvent => _eventController.stream;

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
      // 主检测站：google.com
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      final online = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      _updateStatus(online);
    } catch (_) {
      // 备用检测站：baidu.com（国内网络 google.com 可能不可达）
      try {
        final result = await InternetAddress.lookup('baidu.com')
            .timeout(const Duration(seconds: 5));
        final online = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
        _updateStatus(online);
      } catch (_) {
        _updateStatus(false);
      }
    }
  }

  void _updateStatus(bool online) {
    if (online != _isOnline) {
      _isOnline = online;
      _connectivityController.add(_isOnline);
      _eventController.add(
        online ? ConnectivityEvent.wentOnline : ConnectivityEvent.wentOffline,
      );
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
    _eventController.close();
  }
}
