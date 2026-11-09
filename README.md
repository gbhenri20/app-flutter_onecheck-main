# One Check — App Flutter

Aplicativo Flutter para vistorias imobiliárias, integrado à API REST OneCheck. A documentação completa está em [docs/README.md](docs/README.md). O passo a passo do emulador está em [docs/FLUTLAB.md](docs/FLUTLAB.md).

## Pré-requisitos

- Flutter com Dart **3.9+** (validado com Flutter 3.47 / Dart 3.13)
- API OneCheck acessível. No FlutLab Web use a URL pública, não `127.0.0.1`

## Configuração da URL da API

A API publicada é `https://isg022-one-check-api-python.onrender.com`. Esse endereço já está em `assets/env/app_config.json`, sem a barra no final e sem o prefixo `/api/v1`. O aplicativo acrescenta o prefixo sozinho.

## Instalação

```bash
flutter pub get
flutter analyze
flutter test
flutter build web
```

## Contas de demonstração

As contas abaixo existem apenas no seed de desenvolvimento da API. Não use essas senhas em produção.

| Perfil | E-mail | Senha | MFA |
| --- | --- | --- | --- |
| Admin | `admin@onecheck.local` | `admin123` | Sim |
| Gestor | `gestor@onecheck.local` | `gestor123` | Sim |
| Vistoriador | `vistoriador@onecheck.local` | `vistor123` | Sim |
| Locatário | `locatario@onecheck.local` | `locat123` | Não |

O segredo TOTP do seed de desenvolvimento é `JBSWY3DPEHPK3PXP`. A validação é sempre da API.

## Configuração da URL da API

Edite um único arquivo:

```json
// assets/env/app_config.json
{
  "environment": "development",
  "apiBaseUrl": "https://isg022-one-check-api-python.onrender.com",
  "apiPrefix": "/api/v1",
  ...
}
```

| Ambiente | Exemplo `apiBaseUrl` |
|----------|----------------------|
| API publicada | `https://isg022-one-check-api-python.onrender.com` |
| Desenvolvimento local | `http://127.0.0.1:8765` |
| Emulador Android → host | `http://10.0.2.2:8765` |
| Dispositivo físico | IP da máquina na LAN |

Modelo sem segredos: `assets/env/app_config.example.json`.

## Instalação e execução

```bash
flutter pub get
flutter analyze
flutter test

# Web (demonstração)
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 43125

# Android
flutter run -d android
```

### Subir a API local (referência)

```bash
cd caminho/da/api
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8765
```

Documentação Swagger da API publicada: `https://isg022-one-check-api-python.onrender.com/docs`

## Contas de demonstração (seed da API)

| Perfil | E-mail | Senha | MFA |
|--------|--------|-------|-----|
| Admin | `admin@onecheck.local` | `admin123` | Sim (TOTP) |
| Gestor | `gestor@onecheck.local` | `gestor123` | Sim |
| Vistoriador | `vistoriador@onecheck.local` | `vistor123` | Sim |
| Locatário | `locatario@onecheck.local` | `locat123` | Não |

Segredo TOTP do seed (apenas ambiente de desenvolvimento): `JBSWY3DPEHPK3PXP`  
(adicione no Google Authenticator / authenticator TOTP para gerar o código de 6 dígitos.)

## Arquitetura

```
lib/
  app/          # tema, router, providers
  core/         # config, Dio, secure storage, Hive, widgets
  features/
    auth/       # login, MFA, setup, sessão
    agenda/     # agenda do vistoriador
    checklist/  # preenchimento, fotos, revisão, envio
    vistoria/   # visão locatário
    ocorrencias/
    perfil/
    logs/       # histórico local de operações
```

**Estado:** Riverpod (DI + async, uma única abordagem).  
**HTTP:** Dio com interceptor de Bearer, refresh com lock e tratamento de erros.  
**Segredos:** `flutter_secure_storage` (nunca SharedPreferences).  
**Offline:** Hive (rascunhos, fila de sync, log local).

## Fluxos principais

1. Login → MFA ou setup MFA → tokens seguros
2. Vistoriador: agenda (pendentes/enviadas) → checklist por cômodo → fotos → revisão → `PATCH .../submeter`
3. Locatário: listar vistorias → aceitar / rejeitar com motivo → ocorrências
4. Admin/Gestor: dashboard agregado

## Documentação adicional

- [Documento do projeto](docs/PROJETO.md)
- [Diagnóstico da API e limitações](docs/DIAGNOSTICO_API.md)
- [README original da API](docs/api-reference/README.md)

## Testes e qualidade

```bash
flutter analyze   # esperado: No issues found
flutter test
```

Cobertura crítica: login/MFA, modelos de checklist, renovação de sessão (mock HTTP).

## Observações importantes

- O app **não** reimplementa TOTP localmente; a validação é sempre da API.
- Não há endpoint global de agenda: a lista é agregada via contratos/checklists.
- A agenda mostra entrada, saída e manutenção, com busca e filtros.
- Após submissão (`pendente_aceite` / `aceito` / `rejeitado`), a API bloqueia edição.
