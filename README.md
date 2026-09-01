Jhonny Home Studio

> Uma experiência digital de agendamento pensada para aproximar clientes, serviços e organização em um único lugar.

O **Jhonny Home Studio** é uma aplicação desenvolvida para modernizar o processo de agendamento de serviços do estúdio, 
tornando a experiência mais simples para o cliente e mais organizada para quem administra o negócio.

Mais do que criar apenas uma tela para escolher data e horário, a proposta deste projeto é transformar um processo que normalmente acontece através de mensagens, 
consultas de disponibilidade e confirmações manuais em uma experiência digital mais intuitiva, elegante e eficiente.

---

Sobre o projeto

O projeto nasceu de uma necessidade real.

Antes da aplicação, boa parte do processo de atendimento e agendamento dependia de conversas, consulta de agenda e confirmação manual de horários.

A proposta do Jhonny Home Studio é centralizar essa jornada.

O cliente poderá:

- conhecer os serviços disponíveis;
- visualizar informações e imagens de cada serviço;
- consultar horários disponíveis;
- escolher um período para atendimento;
- realizar seu agendamento;
- acompanhar as principais informações da reserva;
- ter uma experiência simples e agradável durante todo o processo.

Ao mesmo tempo, o sistema cria uma base para que o estabelecimento tenha cada vez mais controle sobre sua agenda, disponibilidade, serviços e atendimentos.

---

Objetivo

O principal objetivo do projeto é facilitar a conexão entre o cliente e o estúdio.

A aplicação foi pensada para reduzir situações como:

- troca excessiva de mensagens para encontrar horários;
- dificuldade na consulta da agenda;
- conflitos de disponibilidade;
- informações de serviços espalhadas;
- processos de confirmação manuais;
- dificuldade de organização dos atendimentos.

A ideia é que o cliente consiga realizar boa parte dessa jornada sozinho, enquanto o profissional mantém o controle sobre o funcionamento do negócio.

---

Experiência do usuário

Desde o início do desenvolvimento, uma das maiores preocupações do projeto foi evitar uma aplicação com aparência genérica.

A interface está sendo construída buscando uma experiência:

**limpa • moderna • elegante • intuitiva • responsiva**

A referência visual segue o nível de simplicidade encontrado em aplicativos modernos como Uber, Instagram e outras plataformas que utilizamos diariamente.

Isso significa trabalhar com:

- hierarquia visual clara;
- componentes discretos;
- espaçamentos bem definidos;
- cards modernos;
- tipografia limpa;
- navegação simples;
- imagens valorizadas;
- poucos elementos competindo pela atenção do usuário.

O objetivo não é apenas fazer o sistema funcionar.

O objetivo é fazer com que seja agradável utilizá-lo.

---

Jornada do cliente

A experiência principal foi organizada para seguir um fluxo natural.
-------------------------------------------------------------------------
Login / Cadastro
       ↓
      Home
       ↓
Lista de Serviços
       ↓
Detalhes do Serviço
       ↓
Escolha do Agendamento
       ↓
Data / Horário disponível
       ↓
Resumo do Agendamento
       ↓
Confirmação

----------------------------------------------------------------------------------------

A tela inicial funciona como o principal ponto de contato do cliente com o estúdio.

Ela foi projetada para apresentar conteúdos de forma visual e objetiva, utilizando elementos como:

destaques;
stories;
serviços;
imagens;
acesso rápido às principais funcionalidades;
navegação inferior;
menu lateral.

O objetivo da Home é permitir que o usuário encontre rapidamente aquilo que procura sem sobrecarregar a interface com informações desnecessárias.

Serviços

O sistema possui uma estrutura própria para apresentação dos serviços oferecidos pelo estúdio.

Cada serviço pode apresentar informações como:

nome;
descrição;
imagem;
informações adicionais;
disponibilidade para agendamento.

O cliente pode visualizar os serviços e acessar uma página com mais detalhes antes de prosseguir com a reserva.

Agendamentos

O módulo de agendamento é um dos principais componentes da aplicação.

O fluxo foi pensado para evitar confusão na escolha de horários e facilitar a organização da agenda.

Atualmente, os horários de atendimento seguem uma organização por turnos.

Segunda-feira a sábado

Turno Matutino

09:00 - 12:00

Turno Vespertino

13:00 - 17:00

Essa estrutura evita a apresentação de diversos horários fragmentados e deixa a escolha mais clara para o cliente.

Confirmação do agendamento

O fluxo também considera uma regra importante do negócio:

O horário somente é efetivamente confirmado após a validação do atendimento e, quando aplicável, do pagamento do sinal.

Essa abordagem ajuda a reduzir reservas não confirmadas e permite maior controle do estúdio sobre sua agenda.

A confirmação pode fazer parte de um processo integrado com atendimento via WhatsApp e validação administrativa.

Autenticação

A aplicação possui estrutura de autenticação para identificação dos usuários.

No Backend está sendo utilizada autenticação baseada em:

JWT - JSON Web Token

Esse mecanismo permite proteger os recursos da API e controlar quais informações podem ser acessadas por usuários autenticados.

Entre os fluxos existentes estão:

cadastro;
login;
autenticação;
autorização;
identificação do usuário.
Tecnologias utilizadas

O projeto foi separado entre aplicação cliente, API, infraestrutura e persistência de dados.

Aplicação




A aplicação do cliente está sendo desenvolvida utilizando Flutter, permitindo a criação de uma interface moderna e possibilitando execução em diferentes plataformas.

Backend




O Backend foi desenvolvido utilizando:

C#
.NET 8
ASP.NET Core Web API
Entity Framework Core

A API concentra as regras de negócio e serve como ponte entre a aplicação e o banco de dados.

Banco de dados

Para persistência dos dados foi utilizado:

PostgreSQL

O acesso ao banco é realizado através do Entity Framework Core, permitindo utilização de:

entidades;
relacionamentos;
migrations;
consultas;
atualização de registros;
controle da estrutura do banco através do código.
Arquitetura

Uma das preocupações durante o desenvolvimento foi evitar colocar toda a aplicação dentro de um único projeto.

Por isso, a solução foi organizada em diferentes responsabilidades.

Jhonny-Home-Studio
    src
    JhonnyHomeStudio.Api
    JhonnyHomeStudio.Infrastructure
    apps
      jhonny_home_studio_app



JhonnyHomeStudio.Api

Responsável pela API da aplicação.

Aqui ficam os endpoints responsáveis pela comunicação entre o Frontend e o Backend.

JhonnyHomeStudio.Infrastructure

Responsável principalmente pela infraestrutura e persistência de dados da aplicação.

Essa camada concentra recursos relacionados ao:

Entity Framework Core;
PostgreSQL;
contexto do banco;
configurações;
migrations;
persistência.
jhonny_home_studio_app

Aplicação desenvolvida em Flutter responsável pela experiência do usuário.

É aqui que ficam:

telas;
componentes;
navegação;
tema;
integração com a API;
experiência visual do aplicativo.

 Algumas telas desenvolvidas

O projeto já possui diferentes fluxos e componentes, incluindo:

Login;
Cadastro;
Home;
Stories;
Lista de serviços;
Detalhes do serviço;
Criação de agendamento;
Seleção de disponibilidade;
Resumo;
Menu lateral;
Bottom Navigation;
componentes reutilizáveis;
estrutura visual premium.

Design System

Ao longo do desenvolvimento foram criados componentes reutilizáveis para manter consistência visual na aplicação.

Alguns exemplos:

app_theme.dart
premium_card.dart
app_bottom_nav.dart
address_card.dart
available_slot_card.dart

Essa organização evita repetir estilos dentro de diversas telas e facilita futuras alterações na identidade visual da aplicação.

Alterando determinados componentes ou configurações de tema, várias telas podem acompanhar a mudança automaticamente.

Comunicação entre as camadas

De forma simplificada, a arquitetura funciona assim:


O Flutter não acessa diretamente o banco de dados.

Todas as operações passam pela API, que é responsável por aplicar as regras de negócio e realizar a comunicação com o PostgreSQL.

Segurança

Alguns cuidados adotados na arquitetura incluem:

autenticação utilizando JWT;
separação entre Frontend, API e banco de dados;
proteção das rotas da API;
validação das requisições;
controle de acesso;
credenciais de banco fora do código-fonte sempre que possível.

Desenvolvimento

Durante o desenvolvimento, o projeto também serviu como aplicação prática de diversos conceitos importantes de Engenharia e Desenvolvimento de Software.

Entre eles:

arquitetura em camadas;
APIs REST;
autenticação;
integração Frontend e Backend;
modelagem de banco de dados;
migrations;
tratamento de erros;
componentização;
gerenciamento de estado;
responsividade;
Git;
GitHub;
versionamento de código.

Nem tudo surgiu pronto.

Diversos problemas encontrados durante o desenvolvimento — conexão com banco, migrations, autenticação, configuração do ambiente Flutter, organização das telas e integração entre serviços — fizeram parte da evolução natural do projeto.

Cada problema resolvido também contribuiu para melhorar a arquitetura da aplicação.
