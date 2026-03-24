import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kheteebaadi/core/network/network_info.dart';

class ConnectivityService {
  final NetworkInfo _networkInfo;

  ConnectivityService({required NetworkInfo networkInfo})
      : _networkInfo = networkInfo;

  Stream<bool> get connectionStream => _networkInfo.connectionStream();

  Future<bool> get isConnected => _networkInfo.isConnected();

  Future<bool> get hasInternet => _networkInfo.hasInternetConnection();

  Future<ConnectionStatus> checkConnectionStatus() async {
    final hasConnection = await isConnected;
    if (!hasConnection) {
      return ConnectionStatus.offline;
    }

    final hasInternet = await hasInternet;
    return hasInternet
        ? ConnectionStatus.online
        : ConnectionStatus.wifiNoInternet;
  }
}

enum ConnectionStatus {
  online,
  offline,
  wifiNoInternet,
}

extension ConnectionStatusX on ConnectionStatus {
  bool get isOnline => this == ConnectionStatus.online;
  bool get isOffline => this == ConnectionStatus.offline;
  bool get hasNoInternet => this == ConnectionStatus.wifiNoInternet;
}
