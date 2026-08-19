# Documentacion Tecnica - VPS Lab

## Descripcion general

`VPS_lab` es un entorno de laboratorio basado en Docker que levanta un contenedor `Ubuntu 24.04` con servicio `OpenSSH` habilitado. Su objetivo es ofrecer una instancia simple y accesible por SSH para pruebas operativas, ejercicios de administración básica y validaciones de conectividad.

La infraestructura actual esta definida únicamente por:

- [`docker/docker-compose.yml`]
- [`docker/dockerfile`]

## Arquitectura

El proyecto despliega un solo servicio:

| Componente | Función |
| --- | --- |
| `vps_lab` | Contenedor principal del laboratorio |
| `ubuntu:24.04` | Imagen base del sistema operativo |
| `openssh-server` | Servicio de acceso remoto por SSH |
| Puerto `2222` del host | Puerto expuesto para conectarse al puerto `22` del contenedor |
| Volumen `/data` | Persistencia de archivos del laboratorio |

Flujo operativo:

1. Docker Compose construye la imagen desde el contexto raíz del repositorio.
2. El `dockerfile` instala utilidades base y habilita `sshd`.
3. El contenedor publica el puerto `22` interno como `2222` en el host.
4. El volúmen montado permite conservar datos fuera del contenedor.

## Estructura del repositorio

```text
VPS_lab/
|-- README.MD
|-- data/
|-- scripts/
    |-- lib/
        |-- common.sh
    |-- 01_install_dependencies.sh
    |-- 02_install_dev_tools.sh
    |-- 03_create_sudo_user.sh
    |-- 04_configure_firewall.sh
    |-- bootstrap_vps.sh
`-- docker/
    |-- data/
    |-- docker-compose.yml
    `-- dockerfile
```

## Detalle de infraestructura

### 1. Docker Compose

Archivo: [`docker/docker-compose.yml`]

Configuración actual:

- Define el servicio `vps_lab`.
- Construye la imagen usando como contexto `..` y como archivo de build `docker/dockerfile`.
- Asigna el nombre fijo del contenedor: `vps_lab`.
- Expone `2222:22`.
- Monta `./data:/data`.

### 2. Imagen Docker

Archivo: [`docker/dockerfile`]

Durante la construcción se realizan estas acciones:

1. Se usa `ubuntu:24.04` como base.
2. Se instalan paquetes:
   `openssh-server`, `sudo`, `curl`, `nano` y `net-tools`.
3. Se crea `/var/run/sshd`.
4. Se define la contraseña del usuario `root` como `password`.
5. Se habilita `PermitRootLogin yes` en `sshd_config`.
6. Se expone el puerto `22`.
7. Se inicia `sshd` en primer plano con `CMD ["/usr/sbin/sshd", "-D"]`.

## Despliegue

### Requisitos

- Docker instalado
- Docker Compose disponible a traves de `docker compose`

### Levantar el entorno

```powershell
docker compose -f docker/docker-compose.yml up --build -d
```

### Verificar el contenedor

```powershell
docker ps
docker logs vps_lab
```

### Detener el entorno

```powershell
docker compose -f docker/docker-compose.yml down
```

## Scripts de aprovisionamiento

Se agrego una carpeta de automatizaciÓn para configuracion inicial de una VPS Linux basada en Ubuntu LTS:

- [`scripts/bootstrap_vps.sh`]
- [`scripts/01_install_dependencies.sh`]
- [`scripts/02_install_dev_tools.sh`]
- [`scripts/03_create_sudo_user.sh`]
- [`scripts/04_configure_firewall.sh`]

Objetivo de cada script:

1. `01_install_dependencies.sh`: instala dependencias base del sistema, incluyendo `curl`, `wget`, `build-essential`, `net-tools` y `ufw`.
2. `02_install_dev_tools.sh`: instala `git`, `neovim` y `neofetch`.
3. `03_create_sudo_user.sh`: crea un usuario y lo agrega al grupo `sudo`.
4. `04_configure_firewall.sh`: activa `ufw`, deniega trÁfico entrante por defecto y habilita el puerto SSH.
5. `bootstrap_vps.sh`: ejecuta toda la secuencia anterior en orden.

Los scripts validan el sistema operativo antes de ejecutar cambios y fallan si la VPS no corresponde a una version `Ubuntu LTS`.

Ejemplo de uso completo:

```bash
sudo bash scripts/bootstrap_vps.sh devops 'ClaveTemporal123' 2222
```

Ejemplos individuales:

```bash
sudo bash scripts/01_install_dependencies.sh
sudo bash scripts/02_install_dev_tools.sh
sudo bash scripts/03_create_sudo_user.sh devops
sudo bash scripts/04_configure_firewall.sh 22
```

## Acceso al laboratorio

Una vez levantado el contenedor, el acceso SSH se realiza contra el host local:

```powershell
ssh root@localhost -p 2222
```

Credenciales actuales:

- Usuario: `root`
- Contrasena: `password`

## Persistencia de datos

El contenedor monta el directorio `/data` contra la ruta declarada en `docker/docker-compose.yml`.

Nota tecnica importante:

- Como el archivo `docker-compose.yml` se encuentra dentro de la carpeta `docker/`, la ruta relativa `./data:/data` se resuelve actualmente como `docker/data` en el host.
- La carpeta `data/` ubicada en la raiz del repositorio no esta siendo usada por esta definicion de Compose.

Si se desea que la persistencia apunte a la carpeta raiz `data/`, la linea del volumen deberia ajustarse a:

```yaml
volumes:
  - ../data:/data
```

## Seguridad

La configuración actual es adecuada para laboratorio, pero no para producción.

Riesgos presentes:

- Inicio de sesión SSH como `root` habilitado.
- Contraseña fíja y conocida (`password`).
- Falta de autenticación por llave pública.
- Ausencia de endurecimiento adicional del servicio SSH.

Recomendaciones mínimas antes de usar fuera de un entorno controlado:

1. Deshabilitar el acceso por contraseña.
2. Usar autenticación por claves SSH.
3. Cambiar o bloquear el acceso directo de `root`.
4. Restringir el puerto expuesto por firewall o red local.

## Observaciones operativas

- La definicion de infraestructura fue validada con `docker compose config`.
- El contenedor esta pensado como base de practica, no como VPS endurecido para ambientes reales.

## Posibles mejoras

1. Crear un usuario administrativo no root.
2. Incorporar claves SSH por medio de volumen o build args.
3. Agregar `healthcheck` al servicio.
4. Separar claramente la carpeta de datos activa para evitar confusion entre `data/` y `docker/data/`.

