# controlgastos

AO CLONAR O PROJETO, LEMBRE DE REALIZAR O COMANDO flutter pub get, LOGO DEPOIS O flutter run.
A API correspondente ao projeto foi feito em .NET: https://github.com/arturw9/ControleGastosPessoais_.NET_back

Logo abaixo os requisitos a serem cumpridos.


Descrição da Atividade: Aplicativo de Controle de Gastos Pessoais
________________________________________
Objetivo
Desenvolver um aplicativo de controle de gastos com as seguintes funcionalidades:
________________________________________
Funcionalidades
1. Tela de Login
•	Implementar autenticação básica utilizando banco de dados (MySQL ou MariaDB).
•	Permitir a criação de nova conta e realizar login.
2. Tela Principal
•	Exibir lista de transações financeiras do usuário, organizadas por data.
•	Cada transação deve mostrar: 
o	Descrição
o	Categoria
o	Valor
•	Apresentar um resumo financeiro contendo: 
o	Saldo total.
o	Totais de receitas e despesas.
3. Adicionar Transação
•	Criar tela para adicionar uma nova transação, com os seguintes campos: 
o	Data
o	Valor
o	Descrição
o	Categoria (selecionável).
•	Implementar validações, como: 
o	Proibição de valores negativos para receitas.
o	Validação obrigatória do campo "Valor".
4. Filtros e Organização
•	Permitir filtros para: 
o	Período (data inicial e final).
o	Categoria.
•	Adicionar funcionalidade para ordenar transações por: 
o	Data.
o	Valor.
5. Gráficos
•	Exibir gráficos de barras ou pizza para: 
o	Despesas por categoria.
o	Evolução dos gastos ao longo do tempo.
6. Tema Escuro/Claro
•	Implementar sistema de temas (claro e escuro) configurável pelo usuário.
7. Responsividade
•	Garantir que o layout funcione corretamente em: 
o	Smartphones.
o	Tablets.
________________________________________
Requisitos Técnicos e Avaliação
1. Organização e Limpeza do Código
•	Manter uma estrutura modular e organizada no projeto.
•	Seguir boas práticas de organização de pastas e arquivos.
2. State Management
•	Utilizar Provider para gerenciar o estado global e local do aplicativo.
3. Integração de APIs
•	Implementar o consumo de uma API externa.
•	Usar async/await com tratamento de erros.
4. Boas Práticas de UI e UX
•	Criar componentes customizados e reutilizáveis.
•	Seguir princípios do Material Design ou Cupertino Widgets, dependendo da plataforma.
5. Responsividade
•	Ajustar o layout para diferentes tamanhos de tela e densidades de pixel.
6. Tema
•	Implementar suporte ao tema claro/escuro, utilizando configurações nativas do Flutter.
