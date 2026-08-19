# Documentación Técnica - VPS Lab

## Descripción general

`VPS_lab` es un entorno de laboratorio basado en Docker que levanta un contenedor `Ubuntu LTS` con servicio `OpenSSH` habilitado. Su objetivo es ofrecer una instancia simple y accesible por SSH para pruebas operativas, ejercicios de administración básica y validaciones de conectividad.

La infraestructura actual esta definida únicamente por:

- [`docker/docker-compose.yml`]
- [`docker/dockerfile`]

## Arquitectura

El proyecto despliega un solo servicio:

| Componente | Función |
| --- | --- |
| `vps_lab` | Contenedor principal del laboratorio |
| `ubuntu:${BASE_IMAGE}` | Imagen base parametrizable del sistema operativo |
| `openssh-server` | Servicio de acceso remoto por SSH |
| Puerto `2222` del host | Puerto expuesto para conectarse al puerto `22` del contenedor |
| Volumen `/data` | Persistencia de archivos del laboratorio |
| Volumen `/scripts` | Acceso a scripts de aprovisionamiento desde el host |
| `working_dir: /scripts/.` | Directorio de trabajo por defecto dentro del contenedor |

Flujo operativo:

1. Docker Compose construye la imagen desde el contexto raíz del repositorio.
2. El `dockerfile` parametriza la versión de Ubuntu mediante `ARG BASE_IMAGE=24.04`, instala utilidades base y habilita `sshd`.
3. El contenedor publica el puerto `22` interno como `2222` en el host.
4. Docker monta `data/` en `/data` para persistencia y `scripts/` en `/scripts` para ejecutar aprovisionamiento desde el contenedor.
5. El directorio de trabajo por defecto queda apuntando a `/scripts/.`.

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
- Monta `../data:/data`.
- Monta `../scripts:/scripts/.`.
- Define `working_dir: /scripts/.` para facilitar la ejecución de scripts dentro del contenedor.

### 2. Imagen Docker

Archivo: [`docker/dockerfile`]

Durante la construcción se realizan estas acciones:

1. Se define `ARG BASE_IMAGE=24.04` para parametrizar la versión base de Ubuntu.
2. Se usa `ubuntu:${BASE_IMAGE}` como imagen base del stage `VPS_LAB`.
3. Se instalan paquetes:
   `openssh-server`, `sudo`, `curl`, `nano` y `net-tools`.
4. Se crea `/var/run/sshd`.
5. Se define la contraseña del usuario `root` como `password`.
6. Se habilita `PermitRootLogin yes` en `sshd_config`.
7. Se expone el puerto `22`.
8. Se mantiene `sshd` como proceso principal con `CMD ["/usr/sbin/sshd", "-D"]`.
9. Existen líneas comentadas para copiar `/scripts` a la imagen o usar `bootstrap_vps.sh` como comando alternativo, pero actualmente no forman parte del flujo activo.

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

Se agrego una carpeta de automatización para configuración inicial de una VPS Linux basada en Ubuntu LTS:

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
sudo bash /scripts/bootstrap_vps.sh devops 'ClaveTemporal123' 2222
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

El contenedor monta la carpeta `data/` de la raíz del proyecto hacia `/data`:

```yaml
volumes:
  - ../data:/data
```

Esto corrige la resolución de ruta respecto a la versión anterior y hace que la persistencia apunte explícitamente a la carpeta `data/` del repositorio.

Además, los scripts locales se montan en el contenedor con:

```yaml
volumes:
  - ../scripts:/scripts/.
```

Gracias a esto, los archivos dentro de `scripts/` pueden ejecutarse sin reconstruir la imagen.

## Ejecución de scripts en el contenedor

Como `docker-compose.yml` define `working_dir: /scripts/.`, el contenedor queda posicionado en esa ruta al iniciar una sesión interactiva.

Ejemplo:

```powershell
docker exec -it vps_lab bash
```

Dentro del contenedor se pueden ejecutar directamente scripts como:

```bash
bash bootstrap_vps.sh devops 'ClaveTemporal123' 2222
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

- La imagen sigue arrancando con `sshd`; los scripts de aprovisionamiento están disponibles por volumen y no se ejecutan automáticamente al iniciar el contenedor.
- El contenedor esta pensado como base de práctica, no como VPS endurecido para ambientes reales.

## Posibles mejoras

1. Crear un usuario administrativo no root.
2. Incorporar claves SSH por medio de volumen o build args.
3. Agregar `healthcheck` al servicio.