# 🎬 BoraVer

**Bora ver o quê?** Um app para organizar os filmes que você quer assistir,
registrar os que já viu e, principalmente, deixar o sorteio escolher o
próximo filme.

Feito em **Flutter/Dart**, com o mesmo código para **Android (APK)** e
**Web**. Todo o desenvolvimento roda em **container Docker**: não é
preciso instalar Flutter, Android SDK nem Java na máquina.

---

## Funcionalidades

- **Sorteio** (destaque da tela inicial): sorteia entre os filmes não
  assistidos ou, se você quiser, entre toda a biblioteca. Aceita filtros
  combinados de gênero, país e ano, tem uma animação curta (respeita a opção
  "reduzir movimento") e oferece *Sortear outro*, *Marcar como assistido*,
  *Ver detalhes* e *Voltar para a biblioteca*. Sem candidatos, explica o
  motivo e oferece ajustar ou limpar os filtros.
- **Biblioteca única**, com as abas *Quero assistir*, *Já assisti* e *Todos*,
  além de contadores, busca por título (ignora acentos e também procura no
  título original), filtros, ordenação e um atalho "Sortear daqui".
- **Adicionar filme = pesquisar pelo nome.** Os resultados aparecem enquanto
  você digita (com *Em alta nesta semana* antes da busca). Um toque no **+**
  adiciona o filme; tocar no resultado abre uma prévia com a opção
  "Já assisti". Pôster, sinopse, gêneros, países, ano e título original vêm
  automaticamente do TMDB, e os filmes que já estão na biblioteca aparecem
  marcados.
- **Cadastro manual** apenas como alternativa ("Não achou? Cadastrar
  manualmente") e para editar dados, com validação, aviso de duplicata e
  confirmação antes de descartar alterações.
- **Avaliação** de 1 a 5 estrelas (alterável e removível; um filme sem
  avaliação é diferente de um avaliado) e **resenha** de texto livre.
- **Histórico de sessões** com datas. O contador vem desse histórico, e
  existem as ações "Assisti novamente", "Adicionar data" (sessões passadas)
  e remoção de sessões registradas por engano.
- **Excluir** com confirmação e **Desfazer** nas mudanças de estado.
- **Backup** em JSON (exportar e importar com mesclagem), que também serve
  para levar a biblioteca da Web para o celular e vice-versa.
- Interface **responsiva**: navegação inferior no celular, barra lateral em
  tablet e desktop, e lista em duas colunas em telas largas.

## Estrutura do projeto

```
lib/
├── main.dart                 # Inicializa o armazenamento e abre o app
├── app.dart                  # MaterialApp, tema, providers, idioma pt-BR
├── core/
│   ├── theme/                # Paleta, espaçamentos e tema (sistema visual)
│   └── utils/                # Normalização de texto, datas
├── domain/                   # Regras de negócio (Dart puro, sem Flutter)
│   ├── models/               # Movie, Genre, Country, MovieFilter
│   └── services/             # Sorteio, busca/ordenação, duplicatas
├── data/                     # Acesso a dados
│   ├── movie_repository.dart # Interfaces (trocáveis por nuvem no futuro)
│   ├── hive_storage.dart     # Implementação local (Hive)
│   ├── backup_codec.dart     # Formato do backup JSON
│   └── tmdb/                 # Cliente opcional da API do TMDB
├── state/                    # Controladores (ChangeNotifier)
└── ui/
    ├── shell/                # Navegação responsiva
    ├── screens/              # Início, Biblioteca, Sorteio, Detalhes, Formulário, Ajustes
    ├── widgets/              # Componentes reutilizáveis (pôster, estrelas, filtros, ingresso…)
    └── movie_actions.dart    # Ações comuns com mensagens e "Desfazer"
test/                         # Testes de domínio, dados, estado e fluxos de interface
tool/                         # Geração de ícones e capturas de tela
scripts/render-build.sh       # Build da Web no Render
docker/Dockerfile             # Imagem de desenvolvimento (Flutter + Android SDK)
```

## Como rodar (tudo via Docker)

### Pré-requisitos

- **Docker Desktop** (Windows/macOS) ou Docker Engine (Linux).
- Cerca de **9 GB livres** em disco para a imagem do Flutter com Android SDK,
  além dos caches.

> **Máquina com pouca RAM?** No Windows, o arquivo `%USERPROFILE%\.wslconfig`
> limita a memória do WSL2/Docker. Configuração usada neste projeto:
>
> ```ini
> [wsl2]
> memory=4GB
> swap=4GB
> processors=3
>
> [experimental]
> autoMemoryReclaim=gradual
> sparseVhd=true
> ```
>
> Depois de alterar, rode `wsl --shutdown` e abra o Docker Desktop de novo.

### Primeira vez

```bash
docker compose build          # cria a imagem local (Flutter 3.44.0 + SDK Web)
docker compose run --rm flutter flutter pub get
```

Depois, coloque a chave do TMDB no arquivo `.env` (veja [TMDB](#tmdb-a-chave-do-app)).

### Comandos do dia a dia

| O que | Comando |
|---|---|
| Rodar os testes | `docker compose run --rm flutter flutter test` |
| Análise estática | `docker compose run --rm flutter flutter analyze` |
| Web em modo desenvolvimento | `docker compose up web` e abra <http://localhost:8080> (para hot restart, use `docker attach boraver-web-1` e tecle `R`) |
| Build Web de produção | `docker compose run --rm flutter flutter build web --release --dart-define-from-file=.env` |
| Ver o build Web (servidor leve) | `docker compose up preview` e abra <http://localhost:8081> |
| Gerar o APK | `docker compose run --rm flutter flutter build apk --release --dart-define-from-file=.env` |
| Gerar APKs menores (por arquitetura) | `docker compose run --rm flutter flutter build apk --release --split-per-abi --dart-define-from-file=.env` |

> O `--dart-define-from-file=.env` coloca a chave do TMDB no app. Sem ele (ou
> com o `.env` vazio), o app funciona, mas "Adicionar filme" cai no cadastro
> manual.
| Parar servidores | `docker compose down` |

Os containers são descartados ao terminar (`--rm`). Os caches do `pub` e do
Gradle ficam em volumes nomeados, então não são baixados de novo.

### Instalar o APK no celular

1. Depois do build, o arquivo fica em
   `build/app/outputs/flutter-apk/app-release.apk` (com `--split-per-abi`,
   use `app-arm64-v8a-release.apk`, que serve para a maioria dos celulares
   atuais).
2. Copie o arquivo para o celular (cabo USB, Google Drive, e-mail…).
3. Abra o arquivo no celular e permita **instalar apps de fontes
   desconhecidas** quando o Android pedir.

> O APK é assinado com a chave de *debug* do container, o que serve para
> instalar e usar. Para publicar na Play Store, é preciso criar uma chave
> própria (`keytool`) e configurar `signingConfigs` em
> `android/app/build.gradle.kts`. **Nunca** coloque a chave no Git: o
> `.gitignore` já ignora `*.jks`, `*.keystore` e `key.properties`.

> **Rodar direto num celular via USB** não é prático a partir de um container
> no Windows. Instale o APK ou use a versão Web no navegador do celular.

### Ferramentas auxiliares

```bash
# Regenera os ícones (Android + Web) a partir da claquete do logotipo
docker compose run --rm flutter flutter test tool/generate_icons_test.dart

# Capturas das telas principais em build/screenshots/ (revisão visual)
docker compose run --rm flutter flutter test tool/screenshots_test.dart --update-goldens
```

### Teste de ponta a ponta no navegador (opcional)

`tool/e2e/web_persistence.js` abre o build Web (gerado **sem** chave do TMDB,
para usar o cadastro manual) num Chrome headless, cadastra
um filme, fecha e reabre o navegador e confirma que o filme persistiu. Ele usa
a imagem `zenika/alpine-chrome:with-puppeteer` (cerca de 1,5 GB):

```bash
docker compose run --rm flutter flutter build web --release
docker compose up -d preview
docker run --rm --memory 1g --add-host host.docker.internal:host-gateway \
  -v "$PWD/tool/e2e:/usr/src/app/e2e:ro" -v "$PWD/build:/out" \
  --entrypoint node zenika/alpine-chrome:with-puppeteer /usr/src/app/e2e/web_persistence.js
docker compose stop preview
```

### Liberar espaço em disco

```bash
docker compose down
docker volume rm boraver_pub-cache boraver_gradle-cache boraver_android-ndk  # caches (baixados de novo quando precisar)
docker image rm boraver-flutter:3.44.0 ghcr.io/cirruslabs/flutter:3.44.0       # remove as imagens (~7 GB)
docker builder prune                                                           # cache de build do Docker
```

Apagar a pasta `build/` também é seguro: ela é recriada pelos builds.

## Persistência: como e onde os dados ficam

- O armazenamento é **local**, com [Hive CE](https://pub.dev/packages/hive_ce):
  - **Android**: arquivos no diretório privado do app;
  - **Web**: **IndexedDB** do navegador, por site (origem).
- Cada filme é gravado como um JSON sob o seu id. Uma gravação só aparece na
  tela depois de confirmada no armazenamento, e se falhar o app avisa e
  mantém o estado anterior. Um registro corrompido é ignorado (sem apagar
  nada) e não impede o app de abrir.
- A camada `data/` tem interfaces (`MovieRepository`, `SettingsRepository`),
  então migrar para nuvem (ex.: Supabase/Firebase com login) significa
  escrever outra implementação, sem mexer nas telas nem nas regras.

### Limitações

- **Não há sincronização** entre dispositivos: a biblioteca do celular e a
  do navegador são independentes. Use **Ajustes → Backup** para transferir.
- Na Web, **limpar os dados de navegação** do site, usar **modo anônimo**
  (os dados somem ao fechar a janela) ou trocar de navegador ou de endereço
  (ex.: `localhost` → `onrender.com`) resulta em outra biblioteca.
  Desinstalar o app no Android também apaga os dados.
- Pôsteres são links da internet, não arquivos baixados: sem conexão, aparece
  o cartaz neutro.
- Bandeiras são emojis. No Android, dependem da fonte de emoji do sistema; na
  Web, o Flutter baixa a fonte de emoji na primeira vez. O nome do país sempre
  aparece junto.
- Sem tema escuro nesta versão.

## TMDB: a chave do app

A busca de filmes usa **uma única chave**, a do dono do app. Quem usa o app
não configura nada: só pesquisa e adiciona.

### 1. Obter a chave (grátis)

1. Crie uma conta em <https://www.themoviedb.org/signup> e confirme o e-mail.
2. Acesse <https://www.themoviedb.org/settings/api> e clique em **Create**
   (ou "Request an API Key"). Escolha **Developer**, aceite os termos e
   preencha o formulário. Como tipo de uso, informe app pessoal/não comercial
   e, como URL, a do Render (ou `http://localhost`).
3. Na mesma página aparecem a **API Key** e o **API Read Access Token**
   (um texto longo que começa com `eyJ`). Use o **Read Access Token**, mas a
   API Key também funciona.

### 2. Usar no desenvolvimento (container)

Edite o arquivo **`.env`** na raiz do projeto (ele está no `.gitignore` e
não vai para o Git):

```
TMDB_API_KEY=eyJhbGciOi...seu token inteiro...
```

Depois, gere os builds com `--dart-define-from-file=.env` (veja a tabela
acima). O `docker compose up web` já usa o `.env`.

### 3. Usar no Render

Cadastre a variável de ambiente `TMDB_API_KEY` no painel do Render. O
script de build a passa para o app.

### Segurança da chave

A chave **não está no código-fonte nem no Git**: ela entra só no momento do
build. Mas fica **dentro do app compilado** (no JavaScript da versão Web e no
APK), e alguém com conhecimento técnico consegue extraí-la. Para o TMDB, isso
é aceitável: o *Read Access Token* só permite leitura de dados públicos de
filmes, a API é gratuita e não há cobrança. No pior caso, alguém usa a sua
cota e você gera um token novo no site do TMDB (e atualiza o `.env` e o
Render). Para esconder a chave por completo, seria preciso um pequeno
servidor intermediário (proxy), o que fica como evolução futura.

*Este produto usa a API do TMDB, mas não é endossado nem certificado pelo
TMDB.*

## Deploy da Web no Render

Static Site com **Build Command** `bash scripts/render-build.sh` e
**Publish Directory** `build/web`.

## Testes

```bash
docker compose run --rm flutter flutter test
```

| Arquivo | Cobre |
|---|---|
| `test/domain/movie_filter_test.dart` | Filtros combinados (E entre categorias, OU/E entre gêneros), intervalos de ano, busca e ordenação |
| `test/domain/movie_draw_test.dart` | Só não assistidos por padrão, inclusão de assistidos, resultado sempre dentro dos filtros, sem candidatos, distribuição uniforme (40 mil sorteios) |
| `test/domain/movie_model_test.dart` | JSON ida e volta, dados inválidos, bandeiras e nomes de países, detecção de duplicatas |
| `test/state/library_controller_test.dart` | Adicionar, marcar como assistido, assistir de novo, desmarcar sem perder dados, nota, resenha, edição, exclusão, falha de gravação, desfazer, importação |
| `test/data/persistence_test.dart` | **Hive real**: fecha e reabre o banco (como reiniciar o app) e confirma filmes, notas, resenhas e sessões; registro corrompido; backup |
| `test/data/tmdb_client_test.dart` | Chave v3 e token v4, busca, "em alta", mapeamento de gêneros e países, sinopse em inglês quando falta em português, ausência de dados, mensagens de erro |
| `test/ui/app_flow_test.dart` | Fluxos completos na interface: adicionar pesquisando pelo nome (TMDB simulado), prévia com "Já assisti", busca sem resultado, cadastro manual, duplicata, sortear e marcar, sem candidatos, filtros, detalhes, excluir, layout largo |

**Resultado atual:** 56 testes, todos passando; `flutter analyze` sem
problemas.

Além da suíte, o build Web de produção foi testado num **Chrome real
(headless)**: o teste cadastrou um filme, fechou o navegador, reabriu com o
mesmo perfil e confirmou que o filme continuava salvo. Esse teste revelou um
bug que só acontece na Web (a geração de id usava `1 << 32`, que vale `0` em
JavaScript), já corrigido.

### Critérios de aceitação

| # | Cenário | Como foi verificado |
|---|---|---|
| 1 | Adicionar e encontrar em "Quero assistir" | Teste de interface + Chrome real |
| 2 | Fechar, reabrir e o filme continua salvo | Hive real (fecha e reabre o banco) + Chrome real (fecha e reabre o navegador) |
| 3 | Sorteado pertence à lista elegível | Testes de domínio (centenas de sorteios) + interface |
| 4 | Filtros combinados respeitados | Testes de domínio (gênero × país × ano) |
| 5 | Sem candidatos mostra mensagem | Teste de interface (duas situações) |
| 6 | Marcar como assistido muda de lista | Testes de estado + interface |
| 7 | Avaliação e resenha persistem | Teste com Hive real |
| 8 | Segunda visualização incrementa o contador | Testes de estado + interface |
| 9 | Sorteio incluindo assistidos | Testes de domínio + interface |
| 10 | Editar e excluir | Testes de estado + interface (com confirmação) |
| 11 | Executar no Android e no navegador | Web: build de produção rodando no Chrome. Android: APK gerado e inspecionado (`aapt2`), **mas não executado em aparelho/emulador** (veja as pendências) |
| 12 | APK instalável | `build/app/outputs/flutter-apk/app-release.apk` (assinado, SDK alvo 36, arm64/armv7/x86_64) |

## Pendências e próximos passos

- **Abrir o APK num celular real**: o container no Windows não roda o
  emulador Android (sem aceleração KVM), então a inicialização no Android
  ainda precisa ser conferida instalando o APK.
- O APK está assinado com a chave de *debug*. Para a Play Store, crie uma
  chave própria.
- A busca foi testada com o TMDB simulado e, no Chrome real, contra a API
  verdadeira (com uma chave falsa, confirmando conexão e mensagem de erro).
  Falta só testar com a sua chave.
- Exportar e importar backup usa o seletor de arquivos nativo (Android) e o
  download do navegador (Web). A lógica tem testes, mas os diálogos do
  sistema não são automatizáveis aqui.
- Ideias para evoluir: tema escuro, sincronização na nuvem com login (a
  camada `data/` já está preparada), listas personalizadas e estatísticas.
