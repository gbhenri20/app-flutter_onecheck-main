# Endpoints

Prefixo real: `/api/v1`. Autenticação é Bearer, salvo quando a linha diz o contrário. Perfis são os que a API exige. O app não cria rota que não existe neste arquivo.

Legenda: **implementado** no Flutter, **parcial** (só uma parte do contrato) ou **não usado** pelo app.

## Auth

### Login — implementado

- `POST /auth/login`
- Corpo: `{ "email": "", "senha": "" }`
- Sucesso: tokens e `usuario`, ou `mfa_required` / `mfa_setup_required` com `temp_token`
- Público. Erros: credencial inválida em `sucesso: false`

### Verificar MFA — implementado

- `POST /auth/mfa/verify`
- Corpo: `{ "temp_token": "", "codigo": "" }`
- Público. Código inválido vem em `erro`

### Setup no primeiro acesso — implementado

- `GET /auth/mfa/setup-login?temp_token=`
- Resposta: `secret`, `provisioning_uri`, `otpauth_uri`, `qr_url`
- `POST /auth/mfa/activate-login` com `{ "temp_token", "codigo" }`

### Refresh — implementado

- `POST /auth/refresh`
- Corpo: `{ "refresh_token": "" }`
- Devolve access e refresh novos. Público, sem Bearer

### Logout — implementado

- `POST /auth/logout`
- Bearer. Corpo opcional `{ "refresh_token": "" }`

### MFA autenticado em /auth — não usado

A API também tem `GET /auth/mfa/setup`, `POST /auth/mfa/activate`, `POST /auth/mfa/disable`, `POST /auth/mfa/habilitar` e `POST /auth/mfa/desabilitar`. O app usa os equivalentes em `/usuarios`, que cobrem o usuário logado e a administração.

## Usuários

| Método e URL | Uso no app | Quem | Observação |
| --- | --- | --- | --- |
| `GET /usuarios/me` | implementado | autenticado | Restaura sessão |
| `PATCH /usuarios/me` | implementado | autenticado | Corpo `{ "nome" }`. Senha por este patch existe na API e não é usada; o app chama a rota de senha |
| `PUT /usuarios/me/senha` | implementado | autenticado | `{ "senha_atual", "nova_senha" }` |
| `POST /usuarios/me/mfa/setup` | não usado | autenticado | Setup do próprio usuário depois do login não tem tela |
| `POST /usuarios/me/mfa/enable` | não usado | autenticado | Corpo `{ "secret", "codigo" }` |
| `DELETE /usuarios/me/mfa` | não usado | autenticado | Desliga o próprio MFA |
| `GET /usuarios` | implementado | autenticado | `pagina`, `por_pagina`, `role` |
| `POST /usuarios` | implementado | admin, gestor | `{ nome, email, senha, role, cpf? }` |
| `GET /usuarios/{id}` | implementado no repositório | admin, gestor | A lista já traz o necessário; a tela não abre um detalhe separado |
| `PUT /usuarios/{id}` | implementado | admin, gestor | nome, email, role, senha, mfa_enabled |
| `DELETE /usuarios/{id}` | implementado | admin, gestor | Exclusão lógica. Não desativa a própria conta |
| `POST /usuarios/{id}/mfa/setup` | implementado | admin, gestor | Devolve o segredo |
| `POST /usuarios/{id}/mfa/habilitar` | implementado | admin, gestor | Sem corpo, ou `{ secret, codigo }` |
| `POST /usuarios/{id}/mfa/desabilitar` | implementado | admin, gestor | Zera segredo e flag |

## Imóveis

| Método e URL | Uso | Quem |
| --- | --- | --- |
| `GET /imoveis` | implementado | autenticado, filtrado pela API conforme o perfil. Query `status`, `com_endereco`, paginação |
| `POST /imoveis` | implementado | admin, gestor. Corpo com `tipo` e `endereco` opcional |
| `GET /imoveis/{id}` | implementado | autenticado, com endereço |
| `PUT /imoveis/{id}` | implementado no repositório | admin, gestor. A tela atual edita o endereço, não todos os campos do imóvel |
| `DELETE /imoveis/{id}` | implementado | admin, gestor. Lógico |
| `GET /imoveis/{id}/endereco` | implementado no repositório | autenticado. A tela usa o endereço que já vem no detalhe |
| `PUT /imoveis/{id}/endereco` | implementado | admin, gestor. Também aceita POST e PATCH na API |
| `GET /imoveis/{id}/comodos` | implementado | autenticado |
| `POST /imoveis/{id}/comodos` | implementado | admin, gestor. `{ tipo, descricao? }` |
| `PUT /imoveis/{id}/comodos/{comodoId}` | implementado no repositório | admin, gestor. A tela cria e exclui; não edita o texto |
| `DELETE /imoveis/{id}/comodos/{comodoId}` | implementado | admin, gestor |

Exemplo de criação:

```json
{
  "tipo": "apartamento",
  "titulo": "Apto 12",
  "status": "disponivel",
  "endereco": { "rua": "Rua A", "cidade": "São Paulo", "estado": "SP" }
}
```

## Contratos e agenda

Não existe `GET /agendamentos`.

| Método e URL | Uso | Quem |
| --- | --- | --- |
| `GET /contratos` | implementado | autenticado. Locatário vê os seus. Vistoriador vê os que têm checklist dele. Query `status`, `imovel_id`, paginação |
| `POST /contratos` | implementado | admin, gestor. `{ imovel_id, locatario_id, data_inicio, data_fim, valor_mensal? }` |
| `GET /contratos/{id}` | implementado | autenticado, com checagem de titular |
| `PATCH /contratos/{id}/encerrar` | implementado | admin, gestor. Só contrato `ativo` |
| `PATCH /contratos/{id}/cancelar` | implementado | admin, gestor. Só contrato `ativo` |
| `GET /contratos/{id}/agendamentos` | implementado | autenticado, locatário recebe 403 |
| `POST /contratos/{id}/agendamentos` | implementado | admin, gestor. `{ tipo, data_agendada, observacao? }`. Data precisa ser futura. Tipo `inicial` ou `encerramento` |
| `PUT /agendamentos/{id}` | implementado | admin, gestor |
| `DELETE /agendamentos/{id}` | implementado | admin, gestor. Remove o registro |
| `GET /contratos/{id}/checklists` | implementado | autenticado |
| `POST /contratos/{id}/checklists` | implementado | autenticado. `{ tipo, vistoriador_id, data_vistoria? }` |
| `GET /contratos/{id}/problemas` | implementado | quem pode ver o contrato |
| `POST /contratos/{id}/problemas` | implementado | locatário do contrato, admin, gestor. JSON ou multipart com `titulo`, `descricao`, `prioridade`, `comodo_id`, `foto` |

## Checklists

| Método e URL | Uso | Quem |
| --- | --- | --- |
| `GET /itens-vistoria` | implementado | autenticado |
| `GET /checklists/{id}` | implementado | autenticado |
| `POST /checklists/{id}/itens` | implementado | vistoriador do checklist ou admin. `{ comodo_id, item_vistoria_id, estado, observacao? }` |
| `PUT /checklists/{id}/itens/{itemId}` | implementado | mesmo grupo. `{ estado, observacao? }` |
| `POST /checklists/{id}/itens/{itemId}/fotos` | implementado | campo `foto`. Só em `em_preenchimento` |
| `DELETE /checklists/{id}/itens/{itemId}/fotos/{fotoId}` | implementado | mesmo grupo |
| `PATCH /checklists/{id}/submeter` | implementado | vistoriador dono ou admin. Exige ao menos um item |
| `PATCH /checklists/{id}/enviar-para-aceite` | implementado | admin, gestor |
| `PATCH /checklists/{id}/aceitar` | implementado | locatário do contrato, admin, gestor |
| `PATCH /checklists/{id}/rejeitar` | implementado | mesmo grupo. `{ "motivo" }` |
| `GET /checklists/{id}/pdf` | implementado | não vistoriador. Aliases da API: `/download` e `/download-pdf`. O app chama `/pdf` |

## Problemas

| Método e URL | Uso | Quem |
| --- | --- | --- |
| `GET /problemas/{id}` | implementado | quem acessa o contrato |
| `PATCH /problemas/{id}/status` | implementado | admin, gestor. `{ "status" }` |
| `POST /problemas/{id}/atualizacoes` | implementado | admin, gestor. JSON `{ descricao }` ou multipart `descricao` + `foto` |
| `GET /problemas/{id}/atualizacoes` | parcial | A lista já vem dentro de `GET /problemas/{id}` |

## Dashboard, logs, saúde, admin

| Método e URL | Uso | Quem |
| --- | --- | --- |
| `GET /dashboard` | implementado | autenticado |
| `GET /logs` | implementado | admin, gestor. Query `pagina`, `por_pagina`, `acao`, `entidade`, `usuario_id`, `de`, `ate` |
| `GET /health` | implementado | público. Usado ao salvar a URL |
| `GET /uploads/{arquivo}` | implementado | público na API. O app só monta a URL da foto |
| `GET /` | não usado | raiz do serviço |
| `POST /admin/seed`, `POST|PUT|PATCH /admin/refresh-data`, `GET /admin/data/status` | não usado | manutenção. Sem botão no app |

## Códigos que o app trata

- 400 dados inválidos
- 401 sessão expirada, com uma tentativa de refresh
- 403 sem permissão
- 404 não encontrado
- 409 conflito
- 422 validação
- 429 muitas tentativas
- 5xx falha do servidor
- falha de rede ou timeout, sem marcar a operação como concluída
