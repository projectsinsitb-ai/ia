#!/usr/bin/env bash
# recive.sh — recibir archivos con croc
# Usa Docker si está disponible; si no, croc nativo (y ofrece instalarlo).

# ---------- 1. Elegir cómo ejecutar croc ----------
MODO=""
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  MODO="docker"
elif command -v croc >/dev/null 2>&1; then
  MODO="croc"
else
  echo "⚠️  No se ha encontrado Docker (ni croc instalado)."
  read -p "¿Instalar croc ahora? (s/N): " R
  if [[ "$R" =~ ^[sSyY]$ ]]; then
    curl -fsSL https://getcroc.schollz.com | bash || { echo "❌ Falló la instalación de croc"; exit 1; }
    command -v croc >/dev/null 2>&1 || { echo "❌ croc no quedó disponible en el PATH"; exit 1; }
    MODO="croc"
  else
    echo "❌ Sin Docker ni croc no se puede continuar"
    exit 1
  fi
fi
echo "⚙️  Modo: $MODO"

# ---------- 2. Código ----------
read -p "🔑 Código de recepción: " CODIGO

if [ -z "$CODIGO" ]; then
  echo "❌ No has introducido ningún código"
  exit 1
fi

# ---------- 3. Recibir ----------
echo "📥 Recibiendo con código: $CODIGO"

if [ "$MODO" = "docker" ]; then
  mkdir -p "$HOME/.config/croc"
  docker run --rm -it \
    --user "$(id -u):$(id -g)" \
    -v "$(pwd):/transfer" \
    -v "$HOME/.config/croc:/.config/croc" \
    -w /transfer \
    schollz/croc --yes receive "$CODIGO"
else
  croc --yes receive "$CODIGO"
fi
