# Testes

Comandos executados neste ajuste, com Flutter 3.47.7 e Dart 3.13.5:

```bash
flutter pub get
flutter analyze
flutter test
flutter build web
```

`flutter analyze` terminou sem issues. `flutter test` passou os 15 testes (modelos, compressão, login/MFA com HTTP mock e widget de login).

O build JavaScript (`flutter build web`) concluiu e gerou `build/web`. O aviso de wasm do `flutter_secure_storage_web` não impede esse build. O emulador do FlutLab usa o compilador JavaScript padrão, não wasm.

## Unitários

- `test/unit/auth_repository_test.dart` — credencial inválida, MFA obrigatório, setup, código inválido, sessão autenticada. Usa `http_mock_adapter`.
- `test/unit/auth_outcome_test.dart` — leitura do resultado de login.
- `test/unit/checklist_models_test.dart` — status e bloqueio de edição.
- `test/unit/api_models_test.dart` — JPEG em memória, latitude do imóvel, flags de MFA e paginação.

## Widget

`test/widget/login_page_test.dart` abre a tela, confere a marca e a validação de e-mail e senha.

## O que não está automatizado

Não há teste de integração contra a API real nem teste de interface de todas as telas. Para exercitar a API:

1. Suba a API (`uvicorn app.main:app`).
2. Aponte a URL no app.
3. Entre com um usuário do seed apenas em desenvolvimento.
4. Confira painel, um imóvel, um contrato, uma vistoria e uma ocorrência.
5. Desligue a rede e tente uma foto: a mensagem deve dizer que a foto ficou pendente, não que foi enviada.

## Falha da API

| Situação | Comportamento esperado |
| --- | --- |
| Sem rede | Mensagem de conexão e, na foto, item na fila |
| 401 | Refresh automático. Se o refresh falhar, volta ao login |
| `sucesso: false` | Snackbar com o texto `erro` |
| 403 | Mensagem de acesso não autorizado |
| 422 | Mensagem de validação da API |
