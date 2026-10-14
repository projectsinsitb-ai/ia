#!/usr/bin/env bash
# send.sh — enviar archivos o carpetas con croc
# Usa Docker si está disponible; si no, croc nativo (y ofrece instalarlo).
# Uso: ./send.sh [archivo_o_carpeta ...]   (sin argumentos te lo pregunta)

TEMPS=()
cleanup() {
  for t in "${TEMPS[@]}"; do
    [ -n "$t" ] && rm -f "$t"
  done
}
trap cleanup EXIT

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

# ---------- 2. Qué enviar ----------
if [ $# -gt 0 ]; then
  ITEMS=("$@")
else
  ls -la
  echo "📍 $(pwd)"
  read -p "📦 Archivo(s) o carpeta(s) a enviar (separados por espacio): " -a ITEMS
fi

if [ ${#ITEMS[@]} -eq 0 ]; then
  echo "❌ No has introducido nada"
  exit 1
fi

# ---------- 3. Validar y preparar (zip para carpetas) ----------
ENVIAR=()
ERROR=0
for ITEM in "${ITEMS[@]}"; do
  if [ -f "$ITEM" ]; then
    ENVIAR+=("$ITEM")

  elif [ -d "$ITEM" ]; then
    read -p "📁 '$ITEM' es una carpeta. ¿Comprimir en .zip antes de enviar? (S/n): " R
    if [[ "$R" =~ ^[nN]$ ]]; then
      ENVIAR+=("$ITEM")
    else
      BASE="$(basename "$(cd "$ITEM" && pwd)")"
      STAMP="$(date +%Y%m%d_%H%M%S)"

      if command -v zip >/dev/null 2>&1; then
        ARCH="$BASE.zip"
        [ -e "$ARCH" ] && ARCH="${BASE}_${STAMP}.zip"
        echo "🗜️  Creando $ARCH ..."
        zip -rq "$ARCH" "$ITEM" || { echo "❌ Error al crear el zip"; ERROR=1; continue; }
      elif command -v tar >/dev/null 2>&1; then
        ARCH="$BASE.tar.gz"
        [ -e "$ARCH" ] && ARCH="${BASE}_${STAMP}.tar.gz"
        echo "⚠️  'zip' no está instalado; uso tar.gz en su lugar."
        echo "🗜️  Creando $ARCH ..."
        tar czf "$ARCH" "$ITEM" || { echo "❌ Error al crear el tar.gz"; ERROR=1; continue; }
      else
        echo "❌ No hay 'zip' ni 'tar' para comprimir '$ITEM'"
        ERROR=1
        continue
      fi

      TEMPS+=("$ARCH")   # se borra al terminar
      ENVIAR+=("$ARCH")
    fi

  else
    echo "❌ '$ITEM' no existe en $(pwd)"
    ERROR=1
  fi
done

if [ $ERROR -eq 1 ] || [ ${#ENVIAR[@]} -eq 0 ]; then
  exit 1
fi

# ---------- 4. Enviar ----------
echo "📤 Enviando: ${ENVIAR[*]}"

if [ "$MODO" = "docker" ]; then
  mkdir -p "$HOME/.config/croc"
  docker run --rm -it \
    --user "$(id -u):$(id -g)" \
    -v "$(pwd):/transfer" \
    -v "$HOME/.config/croc:/.config/croc" \
    -w /transfer \
    schollz/croc send "${ENVIAR[@]}"
else
  croc send "${ENVIAR[@]}"
fi
