#!/usr/bin/env bash
# Build da versão Web no Render (Static Site).
#
# O ambiente do Render não tem Flutter: este script baixa a versão fixa do
# SDK (a mesma do container de desenvolvimento), guarda em cache entre builds
# quando possível e gera build/web.
#
# Configuração no painel do Render:
#   Build Command:      bash scripts/render-build.sh
#   Publish Directory:  build/web
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.44.0}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
FLUTTER_DIR="$CACHE_DIR/flutter-$FLUTTER_VERSION"

if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  echo ">> Baixando Flutter $FLUTTER_VERSION..."
  rm -rf "$FLUTTER_DIR"
  mkdir -p "$CACHE_DIR"
  git clone --depth 1 --branch "$FLUTTER_VERSION" \
    https://github.com/flutter/flutter.git "$FLUTTER_DIR"
else
  echo ">> Usando Flutter $FLUTTER_VERSION do cache."
fi

export PATH="$FLUTTER_DIR/bin:$PATH"
export FLUTTER_SUPPRESS_ANALYTICS=true

flutter config --no-analytics --no-cli-animations >/dev/null
flutter --version
flutter pub get

# Chave do TMDB: configurada como variável de ambiente no painel do Render,
# nunca no repositório. Sem ela, o app funciona só com cadastro manual.
if [ -z "${TMDB_API_KEY:-}" ]; then
  echo ">> AVISO: TMDB_API_KEY não definida; a busca de filmes ficará desativada."
fi
flutter build web --release --dart-define=TMDB_API_KEY="${TMDB_API_KEY:-}"

echo ">> Build pronto em build/web"
