import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._init();
  final Connectivity _connectivity = Connectivity();

  ConnectivityService._init();

  Future<bool> isConnected() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.isNotEmpty && 
          !results.contains(ConnectivityResult.none) &&
          (results.contains(ConnectivityResult.mobile) || 
           results.contains(ConnectivityResult.wifi) ||
           results.contains(ConnectivityResult.ethernet));
    } catch (e) {
      // If we can't check connectivity, assume offline
      return false;
    }
  }

  Stream<List<ConnectivityResult>> get connectivityStream {
    return _connectivity.onConnectivityChanged;
  }
}

