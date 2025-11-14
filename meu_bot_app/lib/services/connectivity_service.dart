import 'package:connectivity_plus/connectivity_plus.dart';

/// Serviço para verificar conectividade com a internet
class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();

  /// Verifica se há conexão com a internet
  ///
  /// Retorna true se conectado, false caso contrário
  ///
  /// Exemplo:
  /// ```dart
  /// if (await ConnectivityService.isConnected()) {
  ///   // Enviar mensagem
  /// } else {
  ///   // Mostrar erro
  /// }
  /// ```
  static Future<bool> isConnected() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();

      // Verifica se não está sem conexão
      return !connectivityResult.contains(ConnectivityResult.none);
    } catch (e) {
      // Em caso de erro, assume que está conectado para não bloquear
      print('Erro ao verificar conectividade: $e');
      return true;
    }
  }

  /// Stream de mudanças na conectividade
  ///
  /// Use para reagir a mudanças em tempo real
  ///
  /// Exemplo:
  /// ```dart
  /// ConnectivityService.onConnectivityChanged.listen((isConnected) {
  ///   if (isConnected) {
  ///     print('Conectado!');
  ///   } else {
  ///     print('Sem conexão');
  ///   }
  /// });
  /// ```
  static Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((results) {
      return !results.contains(ConnectivityResult.none);
    });
  }

  /// Retorna o tipo de conexão atual
  ///
  /// Possíveis valores: wifi, mobile, ethernet, none
  static Future<String> getConnectionType() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();

      if (connectivityResult.contains(ConnectivityResult.wifi)) {
        return 'WiFi';
      } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
        return 'Dados móveis';
      } else if (connectivityResult.contains(ConnectivityResult.ethernet)) {
        return 'Ethernet';
      } else {
        return 'Sem conexão';
      }
    } catch (e) {
      return 'Desconhecido';
    }
  }
}
