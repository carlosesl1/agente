import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Serviço de monitoramento de conectividade
///
/// Responsável por verificar se o dispositivo tem conexão com a internet
/// e executar callbacks quando a conexão for restabelecida
class ConnectivityService {
  /// Instância singleton
  static final ConnectivityService _instance = ConnectivityService._internal();

  factory ConnectivityService() => _instance;

  ConnectivityService._internal();

  /// Instância do Connectivity
  final Connectivity _connectivity = Connectivity();

  /// Stream controller para broadcasts de mudanças de conectividade
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  /// Stream de status de conectividade (true = online, false = offline)
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  /// Status atual de conectividade
  bool _isOnline = true;

  /// Getter do status atual
  bool get isOnline => _isOnline;

  /// Listener de mudanças de conectividade
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Callbacks para quando voltar online
  final List<Function()> _onlineCallbacks = [];

  /// Inicializa o monitoramento de conectividade
  Future<void> initialize() async {
    // Verifica status inicial
    await _checkConnectivity();

    // Monitora mudanças de conectividade
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        await _updateConnectionStatus(results);
      },
    );

    print('📡 ConnectivityService inicializado (Status: ${getStatusDescription()})');
  }

  /// Verifica conectividade atual
  Future<void> _checkConnectivity() async {
    try {
      final List<ConnectivityResult> results =
          await _connectivity.checkConnectivity();
      await _updateConnectionStatus(results);
    } catch (e) {
      print('❌ Erro ao verificar conectividade: $e');
      _isOnline = false;
      _connectionStatusController.add(false);
    }
  }

  /// Atualiza o status de conectividade
  Future<void> _updateConnectionStatus(List<ConnectivityResult> results) async {
    final wasOffline = !_isOnline;

    // Considera online se tiver qualquer tipo de conexão (exceto none)
    _isOnline = results.any((result) => result != ConnectivityResult.none);

    // Emite mudança de status
    _connectionStatusController.add(_isOnline);

    if (_isOnline) {
      print('✅ Conexão estabelecida: ${results.join(', ')}');

      // Se estava offline e agora está online, executa callbacks
      if (wasOffline) {
        print('🔄 Voltou online! Executando ${_onlineCallbacks.length} callback(s)...');
        _executeOnlineCallbacks();
      }
    } else {
      print('❌ Sem conexão com a internet');
    }
  }

  /// Registra callback para executar quando voltar online
  ///
  /// Útil para processar fila de mensagens pendentes
  ///
  /// Exemplo:
  /// ```dart
  /// ConnectivityService().addOnlineCallback(() {
  ///   print('Voltou online!');
  ///   // Processar fila offline
  /// });
  /// ```
  void addOnlineCallback(Function() callback) {
    _onlineCallbacks.add(callback);
    print('📝 Callback registrado (total: ${_onlineCallbacks.length})');
  }

  /// Remove callback
  void removeOnlineCallback(Function() callback) {
    _onlineCallbacks.remove(callback);
    print('🗑️  Callback removido (total: ${_onlineCallbacks.length})');
  }

  /// Executa todos os callbacks registrados
  void _executeOnlineCallbacks() {
    for (final callback in _onlineCallbacks) {
      try {
        callback();
      } catch (e) {
        print('❌ Erro ao executar callback online: $e');
      }
    }
  }

  /// Verifica se há conexão com a internet
  ///
  /// Versão estática para compatibilidade com código existente
  ///
  /// Exemplo:
  /// ```dart
  /// if (await ConnectivityService.isConnected()) {
  ///   // Enviar mensagem
  /// }
  /// ```
  static Future<bool> isConnected() async {
    final instance = ConnectivityService();
    await instance._checkConnectivity();
    return instance._isOnline;
  }

  /// Stream de mudanças na conectividade
  ///
  /// Versão estática para compatibilidade com código existente
  static Stream<bool> get onConnectivityChanged {
    return ConnectivityService().connectionStatus;
  }

  /// Retorna o tipo de conexão atual
  static Future<String> getConnectionType() async {
    try {
      final connectivity = Connectivity();
      final connectivityResult = await connectivity.checkConnectivity();

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

  /// Força verificação de conectividade
  ///
  /// Útil para verificar manualmente antes de operações importantes
  Future<bool> checkConnection() async {
    await _checkConnectivity();
    return _isOnline;
  }

  /// Aguarda até ter conexão
  ///
  /// Útil para operações que precisam esperar conectividade
  /// [timeout] - Tempo máximo de espera (null = infinito)
  Future<bool> waitForConnection({Duration? timeout}) async {
    if (_isOnline) {
      return true;
    }

    final completer = Completer<bool>();

    // Cria listener temporário
    StreamSubscription<bool>? subscription;
    subscription = connectionStatus.listen((isOnline) {
      if (isOnline) {
        subscription?.cancel();
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      }
    });

    // Adiciona timeout se especificado
    if (timeout != null) {
      Future.delayed(timeout, () {
        subscription?.cancel();
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      });
    }

    return completer.future;
  }

  /// Dispose de recursos
  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _connectionStatusController.close();
    _onlineCallbacks.clear();
    print('🛑 ConnectivityService finalizado');
  }

  /// Retorna descrição legível do status
  String getStatusDescription() {
    return _isOnline ? 'Online' : 'Offline';
  }
}
