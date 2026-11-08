# Integração com a API

A referência é o código em `ISG022-One-Check-API-Python-main`, prefixo `/api/v1`.

## URL base

`assets/env/app_config.json` traz `apiBaseUrl` e `apiPrefix`. A raiz usada pelo Dio é a concatenação dos dois, por exemplo `https://api.exemplo.com/api/v1`.

No login e no Perfil dá para gravar outra URL. Ela tem prioridade sobre o asset e fica na caixa Hive `oc_prefs`, chave `api_base_url`. Não é segredo.

`127.0.0.1`, `localhost` e `10.0.2.2` são endereços locais. O emulador web do FlutLab não alcança a máquina do desenvolvedor. Use a URL pública da API.

## Cabeçalhos

- `Accept: application/json`
- `Content-Type: application/json`, exceto upload (`multipart/form-data`)
- `Authorization: Bearer <access_token>` quando a rota exige sessão

Login, refresh e MFA de entrada usam `skipAuth`.

## Envelope

```json
{ "sucesso": true, "dados": {}, "paginacao": { "total": 1, "pagina": 1, "itensPorPagina": 20 } }
```

Falha de negócio, muitas vezes com HTTP 200:

```json
{ "sucesso": false, "erro": "Mensagem", "erros": {} }
```

O app lança `AppException` com `erro`. Códigos HTTP 401, 403, 404, 409, 422 e 5xx também viram mensagem.

## Tokens

- Access token no login ou no refresh.
- Refresh token rotativo: `POST /auth/refresh` devolve um par novo. O antigo deixa de valer.
- Os dois ficam no `flutter_secure_storage` (WebCrypto no navegador, armazenamento criptografado no Android).
- Várias respostas 401 compartilham um único refresh, para não rotacionar o token duas vezes.

## MFA

O app não calcula TOTP.

1. `POST /auth/login` com `email` e `senha`.
2. `mfa_required` abre a tela de código e envia `temp_token` + `codigo` em `POST /auth/mfa/verify`.
3. `mfa_setup_required` chama `GET /auth/mfa/setup-login?temp_token=` e depois `POST /auth/mfa/activate-login`.
4. Sem MFA, a resposta já traz `access_token`, `refresh_token` e `usuario`.

O administrador gera ou desliga MFA pelos caminhos de `/usuarios/{id}/mfa/...`. A API é quem valida o código.

## Logout e sessão

`POST /auth/logout` envia o refresh token para revogação e, em seguida, apaga a sessão local. Se a API estiver fora, a sessão local ainda é apagada.

Na abertura, o app chama `GET /usuarios/me`. Se estiver sem rede, reutiliza o último usuário salvo e mantém rascunhos. Token inválido limpa a sessão.

## Upload

Campo de arquivo: `foto`.

- Checklist: `POST /checklists/{id}/itens/{itemId}/fotos`
- Problema: `POST /contratos/{id}/problemas` com os demais campos no mesmo formulário
- Atualização: `POST /problemas/{id}/atualizacoes`

A imagem é reduzida em JPEG antes do envio. No navegador não existe caminho de arquivo: os bytes vêm do `image_picker`.

## Download

`GET /checklists/{id}/pdf` devolve `application/pdf`, não o envelope JSON. Vistoriador recebe 403. No navegador o arquivo é baixado por um link temporário. No Android, vai para a pasta de downloads ou para o diretório temporário.

Fotos da API chegam como `/api/v1/uploads/{arquivo}` e são prefixadas com a URL base.
