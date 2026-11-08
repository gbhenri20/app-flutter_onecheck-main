# Modelos

Os modelos ficam em `lib/features`. A conversão usa os nomes reais do JSON da API (`snake_case`). Campo ausente vira nulo ou valor padrão documentado abaixo. Não há campo inventado para “completar” a tela.

## User

Arquivo: `features/auth/domain/user.dart`.

| Campo Dart | JSON | Tipo |
| --- | --- | --- |
| id | id | String |
| nome | nome | String |
| email | email | String |
| role | role | admin, gestor, vistoriador, locatario |
| cpf | cpf | String? |
| mfaEnabled | mfa_enabled | bool? |
| mfaConfigurado | mfa_configurado | bool? |
| mfaAtivo | mfa_ativo | bool? |

O login devolve um usuário mais curto (`id`, `nome`, `email`, `role`). `GET /usuarios/me` devolve também CPF e flags de MFA.

## Endereco e Imovel

Arquivo: `features/checklist/domain/checklist_models.dart`.

Endereço: `rua` (ou `logradouro`), `numero`, `complemento`, `bloco`, `andar`, `bairro`, `cidade`, `estado`, `cep`, `latitude`, `longitude`.

Imóvel: `id`, `codigo`, `titulo`, `tipo`, `tamanho`, `garagem`, `garagem_vagas`, `status`, `observacoes`, `ativo`, `endereco`.

A geolocalização é a que a API gravou. O app não consulta mapa.

## Comodo

`id`, `imovel_id`, `tipo`, `descricao`, `nome`. O nome exibido prefere `nome`, depois `descricao`, depois `tipo`.

## Contrato e Agendamento

Contrato: `id`, `imovel_id`, `locatario_id`, `data_inicio`, `data_fim`, `valor_mensal`, `status` (`ativo`, `encerrado`, `cancelado`).

Agendamento: `id`, `contrato_id`, `tipo` (`inicial` ou `encerramento`), `data_agendada`, `observacao`. Não há campo de status. Cancelar é `DELETE`.

## Checklist

`id`, `contrato_id`, `vistoriador_id`, `tipo`, `status`, `data_vistoria`, `itens`, `comodos`, `aceite`.

Status usados pela API: `em_preenchimento`, `pendente_aceite`, `aceito`, `rejeitado`. Só `em_preenchimento` permite editar item e foto.

Item: `id`, `checklist_id`, `comodo_id`, `item_vistoria_id`, `estado` (`otimo`, `bom`, `regular`, `ruim`), `observacao`, `fotos`.

Foto: `id`, `url`.

Aceite: um único registro (`id`, `status`, `motivo_rejeicao`, `locatario_id`, `created_at`). A API atualiza esse registro. Não há lista histórica de aceites. O histórico operacional está em `GET /logs`.

## Problema

`id`, `contrato_id`, `comodo_id`, `titulo`, `descricao`, `foto_url`, `prioridade` (`normal`, `alta`, `urgente`), `status` (`aberto`, `em_andamento`, `em_analise`, `resolvido`, `fechado`), `atualizacoes`.

Atualização: `id`, `problema_id`, `autor_id`, `descricao`, `foto_url`, `created_at`.

## Dashboard e log

Dashboard: `imoveis_locados`, `checklists_pendentes`, `problemas_abertos`, `vistorias_agendadas`.

Log: `id`, `usuario_id`, `acao`, `entidade`, `entidade_id`, `detalhes`, `payload`, `ip`, `created_at`. O app mostra os campos de texto. `payload` não é renderizado para não expor dado residual.

## Exemplo de checklist

```json
{
  "id": "ck1",
  "contrato_id": "ct1",
  "vistoriador_id": "v1",
  "tipo": "inicial",
  "status": "em_preenchimento",
  "itens": [
    {
      "id": "i1",
      "checklist_id": "ck1",
      "comodo_id": "c1",
      "item_vistoria_id": "iv1",
      "estado": "bom",
      "observacao": "ok",
      "fotos": [{ "id": "f1", "url": "/api/v1/uploads/abc.jpg" }]
    }
  ]
}
```
