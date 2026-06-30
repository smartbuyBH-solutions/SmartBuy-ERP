# Scripts operacionais

Os scripts deste diretório integram a governança técnica do SmartBuy-ERP.

## Princípios

- responsabilidade única;
- arquivos manuais limitados a 300 linhas;
- ausência de `exit` em sessões interativas;
- falhas comunicadas por `throw`;
- validação sintática antes da execução;
- operações mutáveis somente após preflight aprovado;
- nenhuma credencial pode ser registrada;
- caminhos locais são recebidos por parâmetro.

## Estrutura

- `validation`: verificações somente leitura;
- `bootstrap`: futuras operações pequenas de inicialização;
- `recovery`: futuras retomadas idempotentes.

## Regra operacional

O preflight deve ser executado antes de instalações, builds ou alterações estruturais.