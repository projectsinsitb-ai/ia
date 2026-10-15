# Examen DHCP: requisitos

**Cicle formatiu:** Sistemes Microinformàtics i Xarxes
**Grup:** SMX2A
**Mòdul:** 0227, Serveis de Xarxa i Internet
**RA 1:** Instal·la serveis de configuració dinàmica, descrivint-ne les característiques i aplicacions.

---

## 1. Escenari

Configurar l'assignació dels paràmetres de xarxa per a **dues xarxes diferents**, cadascuna amb la seva pròpia interfície física:

- Una xarxa per a dispositius de l'**empresa**.
- Una xarxa per a dispositius **externs**.

## 2. Estructura física

```
Internet --- Default Gateway --- (Ethernet Default) --- SERITBRCE
                                                          |-- (Ethernet Personal1) --- switch --- CLILINRCE (Linux)
                                                          |-- (Ethernet Personal2) --- switch --- CLIWINRCE (Windows)
```

## 3. Nomenclatura

| Element | Valor |
|---|---|
| Nom servidor | `seritbrce` |
| Nom domini | `domrce.internal` |
| Nom client Linux | `clilinrce` |
| IP client Linux | `192.105.22.100` |

---

## 4. Requeriments tècnics: opcions globals

- [ ] El servidor **no actualitza el DNS** (encara no hi ha servidor DNS configurat).
- [ ] Ubicació dels fitxers de log del DHCP i temporització de la seva compressió: **per defecte**.
- [ ] El servidor és **l'autoritzat** i revoca les adreces IP que no ha concedit.
- [ ] **Denega** l'actualització de les assignacions d'un client a requeriment d'aquest.
- [ ] El servidor informarà que és el **principal** si hi ha més d'una interfície.

## 5. Requeriments tècnics: xarxa de dispositius d'empresa

Representada pel **client Linux**.

- [ ] Disposen de **reserva d'IP**, per tant cap ordinador sense reserva pot obtenir una IP d'aquest rang.
- [ ] La reserva està emmagatzemada al fitxer `/etc/dhcp/linux.conf`.
- [ ] Els clients han de rebre automàticament:
  - [ ] Una IP de la xarxa `192.105.XX.0/24` entre la `192.105.XX.100` i la `192.105.XX.200`
  - [ ] Netmask
  - [ ] Broadcast
  - [ ] Gateway (que serà el mateix servidor)
  - [ ] Nom de domini
  - [ ] Servidors DNS (el propi servidor)
  - [ ] Concessió d'IP d'**un dia**, renovable **dos dies**

> Nota: el XX de la xarxa és 22 segons la nomenclatura (`192.105.22.100`).

## 6. Requeriments tècnics: xarxa de dispositius externs

Representada pel **client Windows**.

- [ ] Cap dels dispositius disposa de reserva d'IP.
- [ ] Els clients han de rebre automàticament:
  - [ ] Una IP de la xarxa `172.105.0.0/16` entre la `172.105.0.100` i la `172.105.0.200`
  - [ ] Netmask
  - [ ] Broadcast
  - [ ] **Sense** gateway i **sense** nom de domini
  - [ ] Servidor DNS només el de Google: `8.8.8.8`
  - [ ] Concessió d'IP d'**una hora** i **no renovable**

---

## 7. Ordre de treball suggerit

1. Preparar el servidor: nom de host i IP estàtica a les interfícies.
2. Instal·lar el servei DHCP i indicar les interfícies on escolta.
3. Opcions globals.
4. Subxarxa d'empresa.
5. Reserva del client Linux (`/etc/dhcp/linux.conf`).
6. Subxarxa d'externs.
7. Validar la sintaxi, arrencar el servei i provar amb els dos clients.
