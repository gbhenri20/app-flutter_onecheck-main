import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../core/config/app_config.dart';
import '../core/network/dio_client.dart';
import '../core/security/token_storage.dart';
import '../core/storage/local_database.dart';
import '../core/utils/image_compressor.dart';
import '../core/sync/sync_service.dart';
import '../features/agenda/data/agenda_repository.dart';
import '../features/auditoria/data/auditoria_repository.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/domain/auth_session.dart';
import '../features/auth/domain/user.dart';
import '../features/checklist/data/checklist_repository.dart';
import '../features/contratos/data/contratos_repository.dart';
import '../features/imoveis/data/imoveis_repository.dart';
import '../features/ocorrencias/data/problemas_repository.dart';
import '../features/usuarios/data/usuarios_repository.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError('AppConfig deve ser sobrescrito no ProviderScope');
});

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final localDatabaseProvider = Provider<LocalDatabase>((ref) => localDatabase);

final sessionExpiredProvider = StateProvider<int>((ref) => 0);

/// Evita ciclo dio ↔ auth: o callback é ligado após a criação do AuthController.
final sessionExpiredCallbackProvider = Provider<void Function()>((ref) {
  return () {
    ref.read(sessionExpiredProvider.notifier).state++;
  };
});

final dioClientProvider = Provider<DioClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final storage = ref.watch(tokenStorageProvider);
  return DioClient(
    config: config,
    tokenStorage: storage,
    onSessionExpired: () {
      ref.read(sessionExpiredCallbackProvider)();
    },
  );
});

final onlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  yield _hasNetwork(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(_hasNetwork);
});

bool _hasNetwork(List<ConnectivityResult> results) {
  return results.any((result) => result != ConnectivityResult.none);
}

final syncRevisionProvider = StateProvider<int>((ref) => 0);

final pendingOpsCountProvider = Provider<int>((ref) {
  ref.watch(syncRevisionProvider);
  return ref.watch(localDatabaseProvider).pendingSync().length;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    client: ref.watch(dioClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
    localDb: ref.watch(localDatabaseProvider),
  );
});

final agendaRepositoryProvider = Provider<AgendaRepository>((ref) {
  return AgendaRepository(ref.watch(dioClientProvider));
});

final checklistRepositoryProvider = Provider<ChecklistRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return ChecklistRepository(
    client: ref.watch(dioClientProvider),
    localDb: ref.watch(localDatabaseProvider),
    compressor: ImageCompressor(
      maxWidth: config.imageMaxWidth,
      quality: config.imageQuality,
    ),
  );
});

final problemasRepositoryProvider = Provider<ProblemasRepository>((ref) {
  return ProblemasRepository(ref.watch(dioClientProvider));
});

final imoveisRepositoryProvider = Provider<ImoveisRepository>((ref) {
  return ImoveisRepository(ref.watch(dioClientProvider));
});

final contratosRepositoryProvider = Provider<ContratosRepository>((ref) {
  return ContratosRepository(ref.watch(dioClientProvider));
});

final usuariosRepositoryProvider = Provider<UsuariosRepository>((ref) {
  return UsuariosRepository(ref.watch(dioClientProvider));
});

final auditoriaRepositoryProvider = Provider<AuditoriaRepository>((ref) {
  return AuditoriaRepository(ref.watch(dioClientProvider));
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    localDb: ref.watch(localDatabaseProvider),
    checklistRepository: ref.watch(checklistRepositoryProvider),
  );
});

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.pendingMfaToken,
    this.pendingSetupToken,
    this.loginEmail,
  });

  final AuthStatus status;
  final User? user;
  final String? pendingMfaToken;
  final String? pendingSetupToken;
  /// E-mail da tentativa atual, para a volta ao login não apagar o que foi digitado.
  final String? loginEmail;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo)
      : super(const AuthState(status: AuthStatus.unknown));

  final AuthRepository _repo;

  Future<void> bootstrap() async {
    final user = await _repo.restoreSession();
    if (user == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    } else {
      state = AuthState(status: AuthStatus.authenticated, user: user);
    }
  }

  /// Retorna: null = autenticado; 'mfa'; 'setup'; ou mensagem de erro.
  Future<String?> login(String email, String senha) async {
    final normalized = email.trim();
    state = AuthState(
      status: state.status,
      user: state.user,
      pendingMfaToken: state.pendingMfaToken,
      pendingSetupToken: state.pendingSetupToken,
      loginEmail: normalized,
    );
    final outcome = await _repo.login(email: normalized, senha: senha);
    return _applyOutcome(outcome);
  }

  /// Abandona a etapa de MFA e libera a volta ao login, sem encerrar uma sessão já autenticada.
  void abandonMfaChallenge() {
    if (state.status == AuthStatus.authenticated) return;
    state = AuthState(
      status: AuthStatus.unauthenticated,
      loginEmail: state.loginEmail,
    );
  }

  Future<String?> verifyMfa(String codigo) async {
    final token = state.pendingMfaToken;
    if (token == null) return 'Sessão MFA inválida';
    final outcome =
        await _repo.verifyMfa(tempToken: token, codigo: codigo);
    return _applyOutcome(outcome);
  }

  Future<String?> activateSetup(String codigo) async {
    final token = state.pendingSetupToken;
    if (token == null) return 'Sessão de setup MFA inválida';
    final outcome =
        await _repo.activateMfaLogin(tempToken: token, codigo: codigo);
    return _applyOutcome(outcome);
  }

  Future<MfaSetupData> loadSetupData() {
    final token = state.pendingSetupToken;
    if (token == null) {
      throw StateError('Setup MFA não iniciado');
    }
    return _repo.setupMfaLogin(token);
  }

  Future<String?> _applyOutcome(AuthOutcome outcome) async {
    switch (outcome) {
      case AuthMfaRequired(:final tempToken):
        state = AuthState(
          status: AuthStatus.unauthenticated,
          pendingMfaToken: tempToken,
          loginEmail: state.loginEmail,
        );
        return 'mfa';
      case AuthMfaSetupRequired(:final tempToken):
        state = AuthState(
          status: AuthStatus.unauthenticated,
          pendingSetupToken: tempToken,
          loginEmail: state.loginEmail,
        );
        return 'setup';
      case AuthAuthenticated():
        await _repo.persistAuthenticated(outcome);
        state = AuthState(
          status: AuthStatus.authenticated,
          user: outcome.usuario,
        );
        return null;
    }
  }

  Future<void> atualizarNome(String nome) async {
    final user = await _repo.updateMe(nome: nome);
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  Future<void> alterarSenha({
    required String senhaAtual,
    required String novaSenha,
  }) {
    return _repo.alterarSenha(senhaAtual: senhaAtual, novaSenha: novaSenha);
  }

  Future<void> logout() async {
    final email = state.loginEmail ?? state.user?.email;
    try {
      await _repo.logout();
    } finally {
      state = AuthState(status: AuthStatus.unauthenticated, loginEmail: email);
    }
  }

  void forceLogoutLocal() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authStateProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final controller = AuthController(ref.watch(authRepositoryProvider));
  // Liga o callback de sessão expirada sem criar ciclo de providers.
  ref.listen<int>(sessionExpiredProvider, (prev, next) {
    if (prev != null && next > prev) {
      controller.forceLogoutLocal();
    }
  });
  return controller;
});
