# Telas e funcionalidades

A navegação estreita usa barra inferior. A partir de 960 px, admin e gestor usam trilho lateral. O menu “Mais” existe no celular para não espremer oito destinos.

## Acesso

| Tela | Rota | Quem entra | O que faz |
| --- | --- | --- | --- |
| Login | `/login` | público | E-mail e senha. Configura a URL da API |
| MFA | `/mfa` | temp token | Envia o código TOTP para a API |
| Setup MFA | `/mfa-setup` | temp token | Mostra QR/segredo e ativa |
| Painel | `/admin` | admin, gestor | Contagens reais de `GET /dashboard` |
| Imóveis | `/imoveis`, `/imoveis/:id` | admin, gestor | Lista, cria, endereço, cômodos, exclusão lógica |
| Contratos | `/contratos`, `/contratos/:id` | admin, gestor | Cria, encerra, cancela, agenda e abre vistoria |
| Agenda | `/agenda` | vistoriador, admin, gestor | Checklists por contrato. Saída pode ser ocultada |
| Checklist | `/vistoria/:id` | vistoriador e admin | Itens, estado, observação, foto |
| Revisão | `/vistoria/:id/revisao` | quem pode abrir a vistoria | Envia, mostra aceite e baixa PDF se a API permitir |
| Vistorias do locatário | `/locatario` | locatário | Lista e abre o laudo |
| Detalhe do locatário | `/locatario/vistoria/:id` | locatário | Aceita, rejeita com motivo, baixa PDF |
| Ocorrências | `/ocorrencias` | locatário, admin, gestor | Lista agregada pelos contratos visíveis |
| Detalhe da ocorrência | `/ocorrencias/:id` | mesmo grupo | Status e linha do tempo (mudança só admin/gestor) |
| Usuários | `/usuarios` | admin, gestor | CRUD lógico e MFA administrativo |
| Auditoria | `/auditoria` | admin, gestor | `GET /logs` com filtro e paginação |
| Histórico local | `/historico` | autenticado | Log do aparelho, não é a auditoria da API |
| Perfil | `/perfil` | autenticado | Nome, senha, URL, fila offline, sair |
| Menu | `/menu` | admin, gestor no celular | Atalhos |

## Regras de interface

- Botão de envio da vistoria fica desabilitado sem item preenchido.
- Depois de `pendente_aceite`, `aceito` ou `rejeitado`, a edição some e a API também recusa.
- Gestor envia por `PATCH .../enviar-para-aceite`. Vistoriador e admin usam `PATCH .../submeter`.
- PDF não aparece para vistoriador, porque a API responde 403.
- Câmera fica oculta no navegador. A galeria/arquivo funciona.
- Ações destrutivas pedem confirmação.
- Banner mostra falta de rede e a quantidade de fotos ainda não confirmadas.

## O que a tela não finge fazer

- Não há mapa. Latitude e longitude só aparecem se a API devolver.
- Agendamento não tem status. Cancelar apaga o registro.
- O aceite exibido é o registro atual, não uma linha do tempo de várias decisões.
- `POST /admin/seed` e `POST /admin/refresh-data` não têm botão. São manutenção do servidor.
