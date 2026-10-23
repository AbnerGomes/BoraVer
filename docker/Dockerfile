# Imagem de desenvolvimento do BoraVer: Flutter + Android SDK (cirruslabs)
# com os artefatos da Web pré-baixados. Sem esta camada, cada
# `docker compose run --rm` baixaria o SDK Web de novo.
#
# Usa a mesma versão do Flutter do deploy (scripts/render-build.sh).
FROM ghcr.io/cirruslabs/flutter:3.44.0

RUN flutter config --no-analytics --no-cli-animations \
 && flutter precache --web --android --no-ios --no-linux --no-windows --no-macos --no-fuchsia \
 && rm -rf /root/.pub-cache/_temp /tmp/*
