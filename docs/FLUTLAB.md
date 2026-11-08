# FlutLab

O critério de abertura é: importar o projeto, rodar Pub Get, fazer Build Web e abrir o Web Emulator.

## Importar

1. Compacte a pasta do app Flutter (a que contém `pubspec.yaml`), sem `build/` e sem `.dart_tool/` se o arquivo ficar grande.
2. No FlutLab, importe o zip ou o repositório.
3. Selecione um canal com **Dart 3.9 ou superior**. O `pubspec.yaml` declara `sdk: ^3.9.0`. Canal mais antigo falha no Pub Get.

## Pub Get

No painel do FlutLab, execute Pub Get. As dependências atuais compilam para web:

- Dio, Riverpod, GoRouter, Hive, connectivity_plus, image_picker, image, web
- `flutter_secure_storage` tem implementação web
- `flutter_image_compress` foi removido porque quebra o build web

## URL da API

Antes do login, use **Configurar URL da API**. Informe a URL pública, por exemplo `https://sua-api.onrender.com`, sem o sufixo `/api/v1` (o prefixo já está no asset).

`http://127.0.0.1:8765` é o padrão de desenvolvimento local. O emulador do FlutLab não enxerga esse endereço. O app avisa isso na tela de login.

O diálogo chama `GET /api/v1/health`. Se a API não responder, a URL ainda é salva e o erro aparece no login.

A API precisa liberar CORS para a origem do FlutLab. Isso é configuração do backend (`CORS_ORIGINS`), não do app.

## Build Web e emulador

1. Execute Build Web.
2. Abra o Web Emulator. O build JavaScript local (`flutter build web`) já gerou `build/web`. Se o FlutLab pedir wasm, ignore: `flutter_secure_storage_web` ainda cita `dart:html`, e o emulador usa o compilador JavaScript.
3. A primeira tela é o login do OneCheck, em tema escuro.
4. Sem API alcançável, o login mostra o erro de rede. A navegação de login, MFA e configuração da URL continua disponível.

## Erros comuns

| Sintoma | O que fazer |
| --- | --- |
| Pub Get reclama do SDK | Troque o canal do FlutLab para um Flutter com Dart >= 3.9 |
| Build cita `dart:io` | Não reintroduza `dart:io` em arquivo importado no web. Compressão e download já estão separados por plataforma |
| Tela branca | Confira se `web/index.html` referencia `flutter_bootstrap.js` (modelo atual do Flutter) |
| Login não conecta | A URL está local ou a API não tem CORS |
| Foto não anexa | No navegador use a galeria/arquivo. Câmera nativa não é oferecida no web |
| PDF não baixa | O perfil vistoriador não pode baixar. Confira também o bloqueio de pop-up |

## Limitações conhecidas

- Geolocalização do aparelho não é usada. Só aparecem latitude e longitude devolvidas pela API.
- O armazenamento seguro no navegador depende do WebCrypto do emulador. Se o emulador bloquear, o login conclui na API e a sessão pode não sobreviver a um refresh da página.
- Fontes Manrope e Sora vêm do Google Fonts em tempo de execução. Sem internet para `fonts.gstatic.com`, o Flutter usa a fonte padrão.
- Android continua possível com `flutter build apk`. Plugins nativos de câmera e armazenamento seguro permanecem nas dependências.
- Não há `GET /agendamentos` global. A agenda junta contratos, checklists e agendamentos de cada contrato.
