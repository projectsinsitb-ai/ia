#!/bin/bash
# setup_examen.sh: prepara todo desde una instalación limpia de Ubuntu Server.
# Instala ImageMagick + fuentes y crea ~/sh/EX1 con los scripts cap.sh y diagnostico.sh.
# Requiere salida a Internet por la tarjeta NAT (solo la primera vez).
# Ajusta policy.xml (comenta la política que bloquea @) y cap.sh pasa el texto directo a ImageMagick.

BASE="$HOME/sh/EX1"

echo "[*] Comprobando dependencias (ImageMagick y fuentes)..."
if ! command -v convert >/dev/null 2>&1 || ! dpkg -s fonts-dejavu-core >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y imagemagick fonts-dejavu-core
else
    echo "    Ya instaladas, no hace falta descargar nada."
fi

echo "[*] Ajustando política de ImageMagick (permitir lectura de @ y evitar 'not authorized')..."
for P in /etc/ImageMagick-6/policy.xml /etc/ImageMagick-7/policy.xml; do
    if [ -f "$P" ]; then
        sudo sed -i -E 's#^(\s*)(<policy domain="path" rights="none" pattern="@\*"\s*/>)#\1<!-- \2 -->#' "$P"
        echo "    Revisado: $P"
    fi
done

echo "[*] Creando estructura en $BASE ..."
mkdir -p "$BASE"/{evidencias,picture,md,backup}

# ---------------------------------------------------------------- cap.sh
cat > "$BASE/cap.sh" << 'CAPEOF'
#!/bin/bash
# uso: cap.sh NN antes|despues "comando"
# Guarda la salida en evidencias/NN_fase.txt y genera picture/error_NN_fase.png
# El prompt muestra usuario real, host y ruta actual (ej: isard@ubuntu-24:~/sh/1$) y se ve el comando y el prompt final.
BASE="$HOME/sh/EX1"
N="$1"; FASE="$2"; CMD="$3"
if [ -z "$N" ] || [ -z "$FASE" ] || [ -z "$CMD" ]; then
    echo 'uso: cap.sh NN antes|despues "comando"'; exit 1
fi
TXT="$BASE/evidencias/${N}_${FASE}.txt"
IMG="$BASE/picture/error_${N}_${FASE}.png"

# Prompt realista: usuario@host:ruta-actual$  (con ~ si estamos bajo el home; # si fuese root)
DIR="$PWD"; case "$DIR" in "$HOME"*) DIR="~${DIR#"$HOME"}";; esac
SIG='$'; [ "$(id -u)" -eq 0 ] && SIG='#'
PROMPT="$(whoami)@$(hostname):${DIR}${SIG}"
# Captura: prompt + comando, salida del comando y prompt final vacio
{ echo "$PROMPT $CMD"; bash -c "$CMD" 2>&1; echo "$PROMPT "; } > "$TXT"

# Texto directo (sin label:@fichero) para evitar el bloqueo "not authorized" de ImageMagick.
TEXTO="$(expand -t 4 "$TXT" | head -c 100000)"
TEXTO="${TEXTO//\%/%%}"   # ImageMagick interpreta %x dentro de label:
CONV="$(command -v convert || command -v magick)"
if "$CONV" -background '#1e1e1e' -fill '#e6e6e6' -font DejaVu-Sans-Mono \
        -pointsize 14 -border 15 -bordercolor '#1e1e1e' label:"$TEXTO" "$IMG"; then
    echo "OK imagen: $IMG"
else
    echo "[!] convert falló. Queda solo el texto: $TXT"
fi
CAPEOF

# ---------------------------------------------------------- diagnostico.sh
cat > "$BASE/diagnostico.sh" << 'DIAGEOF'
#!/bin/bash
# Diagnóstico de solo lectura. Guarda todo en evidencias/00_estado_inicial.txt
BASE="$HOME/sh/EX1"
OUT="$BASE/evidencias/00_estado_inicial.txt"
run() { echo; echo "##### $*"; bash -c "$*" 2>&1; }
{
  run "ip -br a; ip r"
  run "ls -l /etc/netplan/; cat /etc/netplan/*.yaml; sudo netplan generate"
  run "systemctl --failed --no-pager"
  run "journalctl -p err -b --no-pager | tail -60"
  run "systemctl status isc-dhcp-server --no-pager"
  run "journalctl -u isc-dhcp-server -b --no-pager | tail -40"
  run "cat /etc/default/isc-dhcp-server"
  run "sudo dhcpd -t -cf /etc/dhcp/dhcpd.conf"
  run "cat -n /etc/dhcp/dhcpd.conf"
  run "ls -l /etc/dhcp/ /var/lib/dhcp/"
  run "sysctl net.ipv4.ip_forward; grep -n ip_forward /etc/sysctl.conf /etc/sysctl.d/*"
  run "sudo iptables -t nat -S; sudo nft list ruleset | head -50"
  run "sudo ufw status verbose"
  run "ss -ulpn | grep -E ':67|:68'"
  run "cat /etc/hosts /etc/resolv.conf"
} > "$OUT"
echo "Diagnóstico guardado en $OUT"
DIAGEOF

chmod +x "$BASE/cap.sh" "$BASE/diagnostico.sh"

# Informe inicial vacío (solo si no existe)
[ -f "$BASE/md/informe.md" ] || echo "# Informe SMX2 · 0227 · RA1" > "$BASE/md/informe.md"

echo "[*] Listo. Estructura creada:"
ls -R "$BASE" | head -30
