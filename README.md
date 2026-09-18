# Bootstrap público

Este diretório participa da fonte revisada dos arquivos publicados em
`sysadmin-stack/deskcomm-bootstrap`. A lista completa e fechada está em
`scripts/exportar-bootstrap.sh`; o workflow `publicar-bootstrap` sincroniza o repositório público
após merge na `main`. Ele não contém código do produto nem segredos.

O `instalar.sh` recebe uma credencial técnica somente de leitura, autentica Git e GHCR sem
colocar o token na URL ou na saída, clona o núcleo privado e entrega o fluxo ao instalador do
produto. A credencial fica em `~/.config/deskcomm/github-readonly` com permissão `0600`, e o
Docker mantém a autenticação no seu arquivo de configuração para atualizações futuras.

A credencial deve pertencer a uma conta técnica, ter acesso apenas a este repositório e aos três
pacotes, e ser rotacionada quando uma VPS for desativada.
