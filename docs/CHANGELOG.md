# Changelog

## 2026-10-29

Preparação do app existente para o FlutLab Web e conclusão das integrações que a API realmente expõe. O aplicativo não foi reescrito do zero.

### Correções

- Removido `dart:io` e `flutter_image_compress`, que impediam o build web. A compressão passou para o pacote `image`.
- Fotos passam a ser lidas em memória, o que funciona no navegador.
- Download de PDF separado por plataforma, sem `dart:io` no código web.
- Prioridade de ocorrência alinhada à API: `normal`, `alta`, `urgente`. O valor `media` era rejeitado.
- URL local deixa de ser tratada como endereço de produção. O usuário configura a URL pública no login.
- Teste de autenticação deixa de depender do caminho `/tmp`, que falha no Windows.

### Integrações novas no app

- Imóveis, endereço, cômodos e exclusão lógica.
- Contratos, encerramento, cancelamento, agendamentos por contrato e criação de checklist.
- Usuários, edição, desativação e MFA administrativo.
- Dashboard pelos campos reais e auditoria em `GET /logs`.
- Ocorrência com foto, status e atualização.
- Envio para aceite, registro de aceite e PDF.
- Nome e senha do usuário autenticado.
- Fila de foto que só sai depois da confirmação da API.

### Interface

- Navegação por perfil, com trilho em tela larga e menu “Mais” no celular.
- Banner de conexão e de operações pendentes.
- Confirmação antes de excluir, encerrar, cancelar ou enviar vistoria.

### Fora do app de propósito

- `POST /admin/seed` e refresh de dados.
- `GET /agendamentos` global, porque a API não tem essa rota.
- Validação local de TOTP.
