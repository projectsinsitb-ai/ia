# CLAUDE.md: Examen SMX2 · 0227 Serveis de Xarxa i Internet · RA1 (servicios de configuración dinámica)

## Contexto
- Alumno: Hamza. Examen práctico sobre un **Ubuntu Server** con **3 tarjetas de red**:
  - 1 tarjeta **NAT**: da salida a Internet (no sirve a clientes).
  - 2 tarjetas **internas**: sirven a los clientes (DHCP y lo que haya configurado).
- El profesor ha introducido **20 errores o más** en ficheros de configuración. Hay que **encontrarlos, corregirlos y documentarlos**.
- Está permitido usar IA. Se valora el **tiempo** y el **control que el alumno tiene de la herramienta**. Por eso: trabaja rápido, pero explica cada hallazgo en el chat y espera mi visto bueno antes de aplicar cada arreglo.
- El servidor **no tiene entorno gráfico**: las "capturas" se generan como imágenes PNG a partir de la salida de terminal.

## Estructura de trabajo (todo bajo `~/sh/EX1`)
```
~/sh/EX1/
├── setup_examen.sh      (preparación inicial, ver abajo)
├── cap.sh               (genera evidencia + captura PNG)
├── diagnostico.sh       (diagnóstico de solo lectura)
├── backup/              (copia de cada fichero ANTES de tocarlo)
├── evidencias/          (salidas en texto: 00_estado_inicial.txt, 01_antes.txt, 01_despues.txt ...)
├── picture/             (capturas PNG: error_01_antes.png, error_01_despues.png ...)
└── md/
    └── informe.md       (informe final con la plantilla del profesor)
```

## Paso 0: preparación (hazlo primero, desde cero)
Comprueba si existe `~/sh/EX1/cap.sh`. Si **no** existe, crea `~/sh/EX1/setup_examen.sh` con el contenido de abajo, ejecútalo con `bash` y verifica que `cap.sh` funciona con una prueba:
`~/sh/EX1/cap.sh 00 prueba "ip -br a"` (debe crear `picture/error_00_prueba.png`). Después borra los ficheros de esa prueba.

Qué hace el script en una instalación limpia:
- Instala `imagemagick` y `fonts-dejavu-core` (necesitan Internet por la tarjeta NAT; si ya están instaladas, no descarga nada).
- Comenta en `/etc/ImageMagick-6/policy.xml` (o `-7`) la política que bloquea `@*`, para evitar el error `not authorized`. Además `cap.sh` pasa el texto directamente a ImageMagick (`label:"$TEXTO"`) en lugar de `label:@fichero`.
- Cada captura se ve como un terminal real: prompt con usuario, host y ruta actual (`isard@ubuntu-24:~/sh/1$ comando`), la salida y un prompt final. El prompt usa el usuario real, no `root` inventado. La ruta es la del directorio desde el que se lanza `cap.sh`, así que ejecútalo siempre desde donde quieras que aparezca.
- `cap.sh` ejecuta el comando con `bash -c`, por lo que no sirve para programas interactivos (`nano`, `visudo`, `vim`). Para esos, captura el contenido con `cat -n <fichero>` o `grep -n <patrón> <fichero>`.
- Crea `~/sh/EX1` con sus carpetas y los scripts `cap.sh` y `diagnostico.sh`.

Si no hay Internet, díselo al alumno: sin ImageMagick no hay PNG, y la alternativa es dejar solo los `.txt` de `evidencias/` y pegar su contenido en bloques de código del informe.

```bash
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
```

## Reglas de trabajo
1. **No inventes errores.** Solo documenta fallos reales que hayas visto en el fichero. Si al final hay menos de 20, dilo.
2. **Copia antes de tocar nada:** `cp -a --parents <fichero> ~/sh/EX1/backup/`
3. **Cambios mínimos:** corrige solo la línea errónea. No reescribas ficheros ni "mejores" cosas que funcionan.
4. **Ruta absoluta siempre** (`readlink -f <fichero>`), nunca relativa ni con `~`.
5. **Valida cada arreglo** antes de pasar al siguiente (ver "Validación").
6. Un error = una línea o directiva concreta. Si un fichero tiene 3 fallos, son 3 errores distintos.
7. No reinicies ni pares servicios sin avisarme, salvo para validar un arreglo del servicio afectado.
8. No toques la tarjeta NAT de forma que se pierda la conexión (podría cortar mi sesión SSH).

## Fase 1: diagnóstico (solo lectura)
Ejecuta `~/sh/EX1/diagnostico.sh` y lee `evidencias/00_estado_inicial.txt`. No modifiques nada en esta fase. Si falta algún servicio que el enunciado mencione, revisa también sus ficheros.

### Qué buscar (lista de fallos típicos)
**/etc/dhcp/dhcpd.conf**
- `;` que falta o sobra, llaves `{ }` sin cerrar, palabras clave mal escritas.
- `subnet` / `netmask` que no coinciden con la IP real de la tarjeta que sirve esa red.
- `range` fuera de la subred, invertido o que incluye la IP del servidor o del router.
- `option routers` / `option domain-name-servers` / `option subnet-mask` / `option broadcast-address` incorrectos.
- `default-lease-time` mayor que `max-lease-time`; valores absurdos.
- Falta `authoritative;` o está comentado.
- Reservas `host`: MAC con formato incorrecto, `fixed-address` fuera de subred o duplicada, `hardware ethernet` mal escrito.
- Rangos solapados entre las dos subredes; falta la declaración de alguna de las dos redes internas.

**/etc/default/isc-dhcp-server** (MUY IMPORTANTE: define en qué tarjetas escucha el servicio; un fallo aquí hace que dhcpd arranque pero no dé IPs, o que no arranque)
- `INTERFACESv4` con nombres de interfaz que no existen (compáralos con `ip -br a`) o que incluyen la NAT; falta alguna de las dos internas. Debe contener exactamente las dos internas, separadas por espacio y entre comillas.
- `INTERFACESv6` rellenado sin necesidad.
- Si aparecen `DHCPDv4_CONF`, `DHCPDv4_PID` u `OPTIONS` activos, comprueba que apuntan a rutas reales (`/etc/dhcp/dhcpd.conf`, `/run/dhcp-server/dhcpd.pid`).
- Líneas descomentadas por error o comentadas (`#`) que deberían estar activas.

**Otras rutas que suelen contener errores (revísalas todas, aunque diagnostico.sh no las muestre)**
- `/etc/dhcp/dhcpd6.conf`, `/etc/default/isc-dhcp-relay` (si hay relay), `/etc/dhcp/dhclient.conf`.
- `/etc/default/ufw` (`DEFAULT_FORWARD_POLICY`), `/etc/ufw/sysctl.conf` (`net/ipv4/ip_forward`) y `/etc/ufw/before.rules` (bloque `*nat` con `MASQUERADE`).
- `/etc/sysctl.conf` y `/etc/sysctl.d/*.conf` (`net.ipv4.ip_forward`).
- `/etc/hostname`, `/etc/hosts`, `/etc/resolv.conf`, `/etc/systemd/resolved.conf`.
- `/var/lib/dhcp/dhcpd.leases` (existencia y permisos) y `/etc/apparmor.d/usr.sbin.dhcpd`.
- `/lib/systemd/system/isc-dhcp-server.service` y overrides en `/etc/systemd/system/isc-dhcp-server.service.d/`.

**/etc/netplan/*.yaml**
- Indentación con tabuladores o desalineada, `addresses` con máscara errónea, `gateway4`/`routes` mal puestos en las internas, `dhcp4` activado donde debe ser estático (y al revés en la NAT), nombre de interfaz incorrecto.

**Sistema y red**
- `net.ipv4.ip_forward` en 0; falta la regla `MASQUERADE` hacia la interfaz NAT; UFW/iptables bloqueando UDP 67/68; permisos o propietario de `/var/lib/dhcp/dhcpd.leases` incorrectos; AppArmor; `/etc/hosts` o `/etc/resolv.conf` erróneos.

## Fase 2: corrección (de uno en uno, numerados 01, 02, 03...)
Por cada error NN, en este orden:
1. Explícame en el chat, en 2-3 frases: qué falla, por qué falla y cuál es el arreglo propuesto. **Espera mi OK.**
2. Copia de seguridad del fichero (regla 2).
3. Ruta absoluta con `readlink -f`.
4. **Captura ANTES:** `~/sh/EX1/cap.sh NN antes "grep -n <patrón> <ruta>"` o `"cat -n <ruta>"` (que se vea la línea errónea y su número).
5. Aplica el arreglo con el cambio mínimo.
6. Valida (ver abajo).
7. **Captura DESPUÉS:** `~/sh/EX1/cap.sh NN despues "<mismo comando>"`, y si procede otra con la validación (`dhcpd -t ...`).
8. Añade el bloque al informe (ver "Formato del informe") y pasa al siguiente.

## Validación
| Tipo de fichero | Comando |
|---|---|
| `dhcpd.conf` | `dhcpd -t -cf /etc/dhcp/dhcpd.conf` |
| netplan | `netplan generate` y luego `netplan try` (nunca `apply` directo sobre la NAT) |
| servicio DHCP | `systemctl restart isc-dhcp-server && systemctl status isc-dhcp-server --no-pager` |
| forwarding / NAT | `sysctl net.ipv4.ip_forward`, `iptables -t nat -S` |
| firewall | `ufw status verbose` |

Al final de todo: servicio DHCP `active (running)`, sin errores en `journalctl -u isc-dhcp-server`, y `ss -ulpn | grep :67` mostrando el puerto abierto.

## Formato del informe
Fichero: `~/sh/EX1/md/informe.md`. **Un bloque por error, numerados en orden**, con esta estructura (la tabla es la plantilla del profesor, no cambies los textos en catalán):

```
### Error N

| 7 | Path absolut del fitxer | /ruta/absoluta/del/fitxer |
| :---: | ----- | ----- |
|  |  |  |
|  | **Contingut de la línea de configuració on està l’error** | `línea errónea exacta` |
|  |  |  |
|  | **Configuració correcta** | `línea corregida exacta` |
|  |  |  |

**Captura antes:** ![error_NN_antes](../picture/error_NN_antes.png)
**Captura después:** ![error_NN_despues](../picture/error_NN_despues.png)
**Explicación:** qué es el error, de qué trata y cómo se ha solucionado (2-3 frases).
```

- Las líneas de configuración van entre comillas invertidas para que no se rompa la tabla.
- Tantos bloques como errores reales haya (hasta 20).
- Si el profesor no pide imágenes ni explicación, deja solo la tabla; pregúntame si hay duda.
- Al terminar, muéstrame el informe completo y una lista resumen: nº, fichero, qué se arregló.

## Al terminar
1. Informe en `~/sh/EX1/md/informe.md`, capturas en `~/sh/EX1/picture/`, textos en `~/sh/EX1/evidencias/`.
2. Resumen en el chat: errores encontrados, corregidos, y cualquier cosa que no pude arreglar o que dudo.
3. Recuérdame cómo sacar los ficheros: `scp -r usuario@ip:~/sh/EX1 .`
