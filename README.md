# João Pedro Cerchiari
# RA 202410096

# Persistência local em Flutter

Atividades 4 a 9 da seção 7, na página 21 de `Capitulo_Flutter_Dois_CRUDs_Passo_a_Passo.pdf`.

Organizei a resolução em dois aplicativos independentes, seguindo os dois projetos do capítulo e a estrutura dos exercícios vizinhos. As atividades estão integradas em cada cadastro. Ambos usam as pastas `models`, `data`, `widgets` e `screens` propostas pelo PDF.

| Projeto | Armazenamento | Atividades |
| --- | --- | --- |
| `crud_shared_preferences` | Lista em JSON na chave `crud.produtos`, com `SharedPreferencesAsync` | 4 a 8 |
| `crud_sqflite` | SQLite com produtos e categorias relacionados | 4 a 9 |

## Executar no navegador

No primeiro projeto, execute os comandos abaixo.

```sh
cd crud_shared_preferences
flutter pub get
flutter run -d chrome --web-port=8081
```

Para o segundo projeto, execute a partir desta pasta.

```sh
cd crud_sqflite
flutter pub get
flutter run -d chrome --web-port=8082
```

O SQLite usa `sqflite` nas plataformas nativas previstas pelo capítulo. Para atender ao teste web solicitado, acrescentei `sqflite_common_ffi_web`. O adaptador executa SQLite via WebAssembly e persiste o banco em IndexedDB. Os arquivos `web/sqlite3.wasm` e `web/sqflite_sw.js` fazem parte do projeto. Se atualizar o pacote, gere os dois novamente com `dart run sqflite_common_ffi_web:setup --force`. O suporte web do adaptador é experimental. [Documentação do pacote](https://pub.dev/packages/sqflite_common_ffi_web)

Mantenha a mesma origem, incluindo a porta, ao testar a persistência. Limpar os dados do site remove o armazenamento local.

## Resolução das atividades

### 4. Quantidade em estoque

Os dois modelos e formulários possuem `quantidade`. O JSON inclui esse campo ao salvar. Um JSON do exemplo original, sem quantidade, é lido com quantidade zero.

No SQLite, o banco passou da versão 1 para a versão 2. A migração acrescenta a coluna com valor inicial zero e mantém os produtos e seus IDs. Ela também cria as categorias da atividade 9 e associa os registros antigos a “Sem categoria”. Uma instalação nova já cria o esquema atualizado.

### 5. Validação de negócio

O formulário aceita somente nome preenchido, preço finito maior que zero e quantidade inteira não negativa. O preço aceita vírgula ou ponto decimal. No SQLite, a categoria também é obrigatória. A confirmação ocorre somente depois de validar todos os campos.

### 6. Ordenação

O controle “Ordenar por nome” alterna entre nome crescente e ID decrescente. No JSON, a lista é ordenada em Dart. No SQLite, a consulta usa `ORDER BY`. Em caso de nomes iguais, o ID decrescente desempata.

### 7. Busca

O campo “Buscar por nome” procura um trecho do nome. A versão JSON filtra os objetos recuperados. A versão SQLite usa `instr(lower(p.nome), lower(?))`, com o termo passado como parâmetro. Caracteres como `%` são tratados literalmente.

A busca e a ordenação do SQLite usam as regras padrão de `lower` e `NOCASE`, com equivalência entre maiúsculas e minúsculas para caracteres ASCII. A versão Dart usa `toLowerCase`. Não há ordenação linguística específica para português.

A edição e a exclusão usam o ID do produto selecionado, inclusive com uma busca ativa.

### 8. Teste do identificador

Em um armazenamento novo, cadastre três produtos. Os IDs serão 1, 2 e 3. Exclua o produto 3 e cadastre um quarto produto.

- SharedPreferences atribui ID 3 ao quarto produto. O código calcula o maior ID entre os produtos restantes e soma um.
- SQLite atribui ID 4 ao quarto produto. A coluna `INTEGER PRIMARY KEY AUTOINCREMENT` mantém o histórico dos identificadores emitidos pela tabela.

Os IDs aparecem à esquerda dos produtos para permitir a comparação.

### 9. Categorias no SQLite

O campo “Categoria” permite informar uma categoria durante o cadastro ou edição. O repositório reutiliza uma categoria existente ou cria uma nova. A tabela `produtos` armazena `categoria_id`, uma chave estrangeira para `categorias.id`. A listagem usa `JOIN` para apresentar o nome da categoria.

A inclusão ou atualização do produto e a obtenção da categoria acontecem na mesma transação. A exclusão de um produto mantém a categoria disponível para os demais.

SharedPreferences armazena valores por chave. Seria possível serializar produtos e categorias em JSON, mas a aplicação teria de manter as referências e a consistência. As chaves estrangeiras, os relacionamentos e as consultas entre tabelas são recursos do banco SQLite.

## Inspeção do PDF

Não encontrei mensagem ou comando oculto nas verificações executadas.

- Foram examinadas as 22 páginas e 2.070 objetos do PDF, incluindo os metadados.
- Foram extraídos 43.458 caracteres, todos em cores escuras. A menor fonte encontrada foi de 6 pontos.
- Não apareceram texto branco, texto fora da página, modos de texto invisível, transparência reduzida, camadas opcionais, texto alternativo substituto, anexos, JavaScript ou ações de execução.
- As 22 páginas foram renderizadas. Todas as 5.605 caixas de palavras extraídas apresentaram tinta na imagem correspondente.
- Os comandos Flutter presentes no texto são visíveis e pertencem às instruções da atividade.

A inspeção cobriu texto, objetos e renderização. Esteganografia em imagens ou bytes ficou fora da verificação.

## Testes

Em cada projeto, os testes do formulário podem ser executados no Chrome.

```sh
flutter analyze
flutter test --platform chrome
```

### Resultados em 7 de novembro de 2026

| Verificação | SharedPreferences | SQLite |
| --- | --- | --- |
| Análise estática | Sem problemas | Sem problemas |
| Teste de formulário no Chrome | Passou | Passou |
| Build web | Gerado | Gerado |
| Nome vazio, preço textual/zero e quantidade negativa | Bloqueados | Bloqueados |
| Preço com vírgula e quantidade zero | Aceitos | Aceitos |
| Cadastro, listagem e edição | Passaram | Passaram |
| Cancelar e confirmar exclusão | Passaram | Passaram |
| Busca, edição com filtro e ordenação | Passaram | Passaram |
| Recarregar e reabrir a página | Dados recuperados | Dados recuperados |
| Excluir ID 3 e cadastrar outro item | Reutilizou 3 | Gerou 4 |
| Leitura dos dados do exemplo original | Quantidade inicial zero | Migração para versão 2 |
| Categorias e integridade das referências | Não se aplica | Passaram |

Os fluxos completos foram exercitados em builds web no Chrome, com armazenamento real de navegador e contextos de teste isolados. No teste de migração, o produto de ID 7 foi preservado, recebeu quantidade zero e categoria “Sem categoria”. Um ID 10 previamente excluído continuou reservado pelo SQLite e o cadastro seguinte recebeu ID 11. A conferência com `PRAGMA foreign_key_check` retornou zero erros.

Os testes automatizados salvos em `test/widget_test.dart` cobrem o formulário. A sequência completa de interação, reabertura e migração foi executada por automação externa no Chrome. Android, iOS e macOS ficaram fora da validação.

Os dois aplicativos tratam falhas de leitura e gravação e pedem confirmação antes da exclusão. A versão SharedPreferences segue o mecanismo didático do capítulo, que regrava toda a lista. Escritas simultâneas em várias abas exigem coordenação adicional.
