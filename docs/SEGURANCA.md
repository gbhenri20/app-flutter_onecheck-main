# Segurança

## Autenticação

Senha só trafega no `POST /auth/login` e nas trocas de senha. Não é gravada no Hive nem no secure storage. O app não valida MFA localmente: o código vai para a API.

## Tokens

Access e refresh ficam no `flutter_secure_storage`.

- Android: SharedPreferences criptografadas.
- Web: WebCrypto, banco `OneCheckSecure`. Isso não é um cofre de sistema operacional. Quem tem acesso ao perfil do navegador pode extrair o dado. Por isso o refresh é rotativo e o logout revoga o token na API.
- O JSON do usuário autenticado também fica nesse cofre, para restaurar a sessão sem rede. Não inclui senha.

## Permissões

O roteador limita a navegação por perfil. A API continua sendo a barreira:

- Criar imóvel, contrato e agendamento: admin e gestor.
- Criar, editar, desativar conta e administrar o MFA de outra pessoa: somente admin.
- Listar contas com e-mail, CPF e MFA: somente admin. O gestor recebe só `id`, `nome` e `role` em `GET /usuarios/resumo`, e apenas de vistoriador ou locatário.
- Submeter checklist: vistoriador dono ou admin.
- Enviar para aceite: admin e gestor.
- Aceitar ou rejeitar: locatário do contrato, admin ou gestor.
- PDF: admin, gestor e o locatário do próprio contrato. O laudo mostra o nome, sem e-mail.
- Logs e histórico local: somente admin. A gravação dos logs continua para todos os papéis.
- Problema: locatário do contrato ativo, admin ou gestor. Atualizar status e linha do tempo: admin e gestor.
- Imóvel, contrato e vistoria de outra pessoa: a API recusa a troca de ID. O vistoriador só abre o que está atribuído a ele.

## Arquivos

Uploads da API em `/api/v1/uploads/{arquivo}` não exigem Bearer. Quem tiver a URL consegue abrir a foto. Isso é comportamento do backend. O app não publica a URL fora da sessão, mas não consegue tornar o arquivo privado.

O PDF é baixado com o token e não é guardado em cache permanente pelo app.

## Dados locais

Hive guarda rascunho do checklist, fila de foto (bytes em base64) e a URL da API. A fila existe para não perder a foto quando a rede cai. Não coloque senha nesse armazenamento.

## Recomendações

- Publique a API só em HTTPS.
- Troque o segredo JWT e os usuários de seed antes de qualquer ambiente real.
- Não commite token, `.env` da API nem senha.
- No FlutLab, não deixe a URL de produção apontando para uma API sem autenticação.
- O seed acadêmico compartilha um segredo TOTP. Isso vale só para desenvolvimento.
