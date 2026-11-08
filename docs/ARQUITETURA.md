# Arquitetura

O OneCheck segue organização por funcionalidade. A tela não chama a API direto: ela lê um provider, que usa um repositório, que usa o `DioClient`.

## Camadas

| Pasta | Responsabilidade |
| --- | --- |
| `lib/app` | Tema Material 3, `GoRouter`, providers globais |
| `lib/core/config` | URL, timeouts e compressão lidos do asset |
| `lib/core/network` | Dio, envelope `{sucesso, dados, erro, paginacao}` |
| `lib/core/security` | Tokens no armazenamento seguro |
| `lib/core/storage` | Hive: rascunho, fila e URL da API |
| `lib/core/sync` | Reenvio de fotos pendentes |
| `lib/core/files` | Salvar PDF no dispositivo ou no navegador |
| `lib/features/*/data` | Repositórios |
| `lib/features/*/domain` | Modelos |
| `lib/features/*/presentation` | Telas e providers de tela |

## Fluxo de dados

1. A tela observa um `FutureProvider` ou o `AuthController`.
2. O repositório monta o caminho e o corpo já no formato da API.
3. `DioClient` acrescenta `Authorization: Bearer`, interpreta o envelope e traduz erros.
4. Se a resposta for `sucesso: false`, vira `AppException` com a mensagem `erro`.
5. A tela mostra carregamento, vazio ou a mensagem da API.

## Estado

Riverpod é a única biblioteca de estado.

- `authStateProvider` guarda sessão, token temporário de MFA e usuário.
- Repositórios são `Provider` e dependem do `DioClient`.
- Listas usam `FutureProvider.autoDispose`.
- A URL efetiva da API é `resolvedConfigProvider`. O cliente Dio não é recriado ao trocar a URL: só `baseUrl` muda, para a sessão não cair.

## Navegação

`GoRouter` redireciona quem não está autenticado para login, MFA ou setup. Depois do login, `routeAllowed` manda cada perfil para a área dele. Esconder o botão não substitui essa guarda, e a API ainda recusa o que o perfil não pode fazer.

## Padrões

- Envelope único da API, sem inventar campos.
- Paginação `pagina` e `por_pagina`, lendo `paginacao.itensPorPagina`.
- Agenda montada por contrato, porque não existe `GET /agendamentos`.
- Fotos comprimidas em memória e enviadas como `multipart` no campo `foto`.
- Operação só é tratada como concluída depois do `sucesso: true`.
