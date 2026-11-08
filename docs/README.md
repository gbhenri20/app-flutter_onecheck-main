# OneCheck

Aplicativo Flutter para vistorias imobiliárias. O app consome a API REST OneCheck (FastAPI) e foi preparado para o emulador web do FlutLab, sem abandonar a geração Android.

## Objetivo

Registrar vistorias de entrada e saída, com fotos, aceite do locatário, ocorrências e painel operacional. Cada perfil vê apenas o que a API autoriza. A autorização final continua no backend.

## Tecnologias

- Flutter e Dart (SDK `^3.9.0`, testado com Flutter 3.47 / Dart 3.13)
- Riverpod para estado e injeção
- GoRouter para rotas e guarda por perfil
- Dio para HTTP, com refresh do JWT
- `flutter_secure_storage` para tokens
- Hive para rascunhos, fila de fotos e preferência da URL da API
- Pacote `image` (Dart puro) para comprimir fotos no Web e no Android

## Requisitos

- Flutter com Dart 3.9 ou superior
- API OneCheck acessível por HTTP ou HTTPS
- No FlutLab Web, a API precisa de URL pública. `127.0.0.1` não sai do computador de quem desenvolve

## Instalação

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

## Configuração da API

O arquivo `assets/env/app_config.json` define o ambiente de desenvolvimento. No app, a tela de login e o Perfil permitem salvar outra URL. Esse valor fica no Hive, sem senha e sem token.

O health check usado pelo diálogo é `GET /api/v1/health`.

## Execução no FlutLab

Veja [FLUTLAB.md](FLUTLAB.md).

## Estrutura de pastas

```
lib/
  app/            tema, rotas, providers
  core/           config, Dio, tokens, Hive, compressão, download
  features/
    auth/         login, MFA, sessão
    agenda/       agenda agregada por contrato
    checklist/    preenchimento, fotos, revisão, PDF
    vistoria/     aceite do locatário
    ocorrencias/  problemas e linha do tempo
    imoveis/      imóveis, endereço e cômodos
    contratos/    contratos e agendamentos
    usuarios/     cadastro administrativo
    auditoria/    logs da API
    home/         painel e menu
    perfil/
    logs/         histórico local
docs/             esta documentação
assets/env/       URL e timeouts
web/              index.html do build web
```

## Documentação

- [ARQUITETURA.md](ARQUITETURA.md)
- [INTEGRACAO_API.md](INTEGRACAO_API.md)
- [ENDPOINTS.md](ENDPOINTS.md)
- [MODELOS.md](MODELOS.md)
- [TELAS_E_FUNCIONALIDADES.md](TELAS_E_FUNCIONALIDADES.md)
- [SEGURANCA.md](SEGURANCA.md)
- [FLUTLAB.md](FLUTLAB.md)
- [TESTES.md](TESTES.md)
- [CHANGELOG.md](CHANGELOG.md)
