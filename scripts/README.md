# Scripts operacionais

Os scripts deste diretório integram a governança técnica do SmartBuy-ERP.

## Princípios

- responsabilidade única;
- qualidade estrutural avaliada por complexidade, coesao e acoplamento;
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

## Qualidade estrutural

- complexidade ciclomatica superior a 15 por funcao exige refatoracao;
- cada script ou modulo deve possuir responsabilidade claramente definida;
- validacoes reutilizaveis devem permanecer em modulos de suporte;
- acoplamento com dados externos deve ser reduzido e explicito;
- WMC, ATFD e TCC devem ser avaliados quando existirem classes;
- contagem de linhas nao constitui criterio isolado de rejeicao.
