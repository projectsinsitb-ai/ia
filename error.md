Tube que arreglar esto porque no tenia connexion para poder poner claude

Aquí tienes la lista completa y explicada de todos los errores presentes en el archivo original respecto a la sintaxis y reglas de **Netplan** (YAML):

---

## 1. Clave `ethernets` fuera del bloque `network` (Error sintáctico)

* **El problema:** En YAML, las claves hijas deben llevar indentación (espacios hacia la derecha) con respecto a su clave padre. En la imagen, la clave `ethernets:` estaba alineada en la misma columna vertical que `network:`.


* **Efecto:** Netplan interpretaba `ethernets:` como un comando raíz independiente en lugar de una propiedad de `network:`, lo que provocó el error: `unknown key 'ethernets'`.



---

## 2. Clave `version: 2` fuera del bloque `network`

* **El problema:** Al igual que `ethernets:`, la instrucción `version: 2` estaba colocada en el margen izquierdo sin espacios delante, al mismo nivel que `network:`.


* **Efecto:** Netplan requiere que `version: 2` esté dentro de la sección `network:` para saber qué versión del esquema de configuración está procesando.

---

## 3. Conflicto entre DHCP y dirección estática (`addresses`)

* **El problema:** En las interfaces `enp2s0` y `enp3s0`, tenías configurado simultáneamente `dhcp4: true` junto con el bloque `addresses:` asignando una IP fija.


* **Efecto:** Genera una ambigüedad en la configuración de la red. Si deseas usar una IP manual/estática, la asignación automática por DHCP debe desactivarse explicitly (`dhcp4: false`).



---

## 4. Uso de rangos de IP públicas para una red local

* **El problema:** Las direcciones IP especificadas (`192.105.22.1` y `172.105.22.1`) son **direcciones IP públicas** asignadas en Internet.


* **Efecto:** Aunque Netplan aceptará la sintaxis si la estructura es correcta, en la práctica provocará problemas de enrutamiento y acceso a Internet, ya que la máquina intentará buscar esa red localmente en lugar de salir a la web. Para entornos locales/de pruebas, siempre se deben usar rangos privados (ej. `192.168.x.x` o `172.16.x.x` - `172.31.x.x`).



---

### Resumen de la estructura correcta

```yaml
network:
  version: 2
  ethernets:
    enp1s0:
      dhcp4: true
      dhcp6: false
    enp2s0:
      dhcp4: false
      dhcp6: false
      addresses:
        - 192.168.22.1/24
    enp3s0:
      dhcp4: false
      dhcp6: false
      addresses:
        - 172.16.22.1/24

```

¿Necesitas ayuda para aplicar esta configuración o probar los comandos en tu terminal?
