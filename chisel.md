Sí. Aquí tienes el **recopilatorio exhaustivo** de todo lo tratado, organizado para que luego podamos convertirlo en índice, borrador o “signature piece”. La conclusión estratégica ya quedó clara: no es terreno virgen, pero sí una integración rara y valiosa de extremo a extremo: **container → rootfs con Chisel → FS inmutable → boot con UKI/LinuxBoot → runtime mínimo sin shell → persistencia estilo volumen**. Eso es precisamente lo que lo hace bueno para artículo técnico fuerte, e incluso para paper si después añades benchmark, seguridad o reproducibilidad medible. 

---

# 0. Idea central que ha ido emergiendo

La conversación empezó con algo muy concreto:

> “Quiero saber si un Docker build fue ejecutado con `--output` desde dentro del Dockerfile”.

Y terminó evolucionando hacia una arquitectura bastante más ambiciosa:

> **Construir una imagen mínima, inmutable, sin shell, basada en Chisel, exportar licencias fuera de la imagen, y eventualmente convertir ese rootfs en un sistema Linux arrancable tipo appliance, con EROFS/SquashFS, UKI, init mínimo, volumen persistente y posible evolución hacia LinuxBoot/Coreboot.**

La idea narrativa final sería algo como:

> **What if your container WAS the operating system?**

O:

> **Turning a Docker Image into a Bootable Immutable Linux Appliance**

---

# 1. Punto inicial: detectar `--output` dentro de un Dockerfile

## 1.1 Pregunta inicial

Querías saber si dentro del `Dockerfile` se puede detectar si el build se ejecutó con:

```bash
docker build --output ...
```

Y abortar si no se había usado.

## 1.2 Conclusión

No se puede detectar directamente.

Dentro del `Dockerfile` no existe una variable tipo:

```text
DOCKER_BUILD_COMMAND
DOCKER_OUTPUT
BUILD_FLAGS
```

ni nada equivalente.

Docker no expone al proceso de build:

* el comando completo usado;
* si se pasó `--output`;
* si se pasó `--load`;
* si se pasó `--push`;
* flags como `--progress`, `--platform`, etc.

## 1.3 Alternativas consideradas

### Alternativa A: wrapper externo

Validar antes de invocar Docker:

```bash
#!/usr/bin/env bash
set -e

if [[ " $* " != *" --output "* ]]; then
    echo "ERROR: debes usar --output"
    exit 1
fi

docker build "$@"
```

Problema: no está dentro del Dockerfile.

### Alternativa B: `--build-arg`

Forzar una señal explícita:

```dockerfile
ARG OUTPUT_ENABLED
RUN test "$OUTPUT_ENABLED" = "1" || \
    (echo "ERROR: este build requiere --output"; exit 1)
```

Invocación:

```bash
docker build \
  --output type=local,dest=out \
  --build-arg OUTPUT_ENABLED=1 \
  .
```

Problema: comprueba el `ARG`, no el `--output` real.

### Alternativa C: comprobar artefacto externo

Tras el build, verificar si el directorio esperado existe.

Problema: post-build, no Dockerfile.

## 1.4 Conclusión conceptual

El `Dockerfile` describe el filesystem y la build graph, pero **no controla ni conoce el exporter del build**.

---

# 2. Multi-stage Dockerfile con dos “finales”: app e información legal

## 2.1 Tu caso real

Querías generar:

1. Una imagen final normal con el programa.
2. Una salida local con copyrights/licencias usando `--output`.

La idea era evitar meter licencias en la imagen final para hacerla más pequeña, pero conservarlas fuera.

## 2.2 Patrón técnico resultante

Usar dos stages finales:

```dockerfile
FROM ... AS app
# imagen final real

FROM ... AS copyrights
# solo material legal
```

Y construir cada uno con `--target`.

## 2.3 Qué pasa si no usas `--target`

En un Dockerfile multi-stage, si haces:

```bash
docker build .
```

Docker construye el **último stage** del Dockerfile.

Los stages anteriores solo se construyen si el último los necesita directa o indirectamente, por ejemplo con:

```dockerfile
COPY --from=copyrights ...
```

Por eso decidimos que:

* `licenses` / `copyrights` debe ir **antes**;
* `app` debe ir **al final**;
* así `docker build .` genera solo la imagen de la app.

## 2.4 Uso de `--target`

Para construir solo las licencias:

```bash
docker buildx build \
  --target licenses \
  --output type=local,dest=./legal \
  .
```

Para construir la app:

```bash
docker buildx build \
  --target app \
  -t miapp:latest \
  --load \
  .
```

## 2.5 Qué hace `--load`

Con `docker buildx build`, si no usas `--load`, `--push` u otro `--output`, la imagen puede quedarse solo en la caché de BuildKit y no aparecer en:

```bash
docker images
```

`--load` exporta la imagen al daemon local de Docker, equivalente al flujo clásico de `docker build`.

Ejemplo:

```bash
docker buildx build -t miapp:latest --load .
docker run miapp:latest
```

---

# 3. Licencias, copyrights y cumplimiento

## 3.1 Motivación

Querías minimizar la imagen final eliminando material legal/documentación, pero sin perderlo.

Duda central:

> ¿Va contra las licencias quitar los copyrights de la imagen y guardarlos fuera?

## 3.2 Conclusión matizada

No hay una única regla universal.

Muchas licencias permiten entregar avisos y textos legales como artefacto separado, **siempre que acompañen la distribución del binario/imagen**.

Pero si publicas una imagen en un registry y no distribuyes junto a ella el material legal, podrías incumplir ciertas licencias.

## 3.3 Formatos discutidos

### Carpeta de licencias

Ventaja:

* más transparente;
* conserva archivos originales;
* mejor para auditoría.

### `.tgz`

Ventaja:

* un solo artefacto;
* fácil de subir a CI;
* fácil de adjuntar en releases.

### Markdown

Ventaja:

* legible;
* útil para humanos;
* buen `THIRD_PARTY.md`.

Limitación:

* puede no contener todo el texto legal completo si solo lista rutas/resúmenes.

## 3.4 Decisión final

Generar ambos:

```text
THIRD_PARTY.md
licenses.tgz
files/<package>/copyright
```

---

# 4. Introducción de Canonical Chisel

## 4.1 Por qué Chisel

Querías usar **Canonical Chisel** para crear imágenes Ubuntu mínimas tipo distroless.

Chisel permite construir un rootfs mínimo a partir de *slices* de paquetes Ubuntu.

La conversación corrigió el enfoque anterior:

* no hace falta buscar licencias en `.deb`;
* los slices de Chisel ya incluyen explícitamente los archivos de licencia;
* el rootfs generado por Chisel puede usarse como base para una imagen `scratch`.

## 4.2 Patrón oficial de Chisel en Dockerfile

La documentación de Ubuntu muestra el patrón:

```dockerfile
FROM ubuntu:24.04 AS chiseler
RUN apt-get update && apt-get install -y chisel
RUN chisel cut --release ubuntu-24.04 --root /rootfs libc6

FROM scratch
COPY --from=chiseler /rootfs /
CMD [...]
```

## 4.3 Decisiones adoptadas

* Chisel se ejecuta en un stage Ubuntu.
* La imagen final es `scratch`.
* El rootfs final viene de `/rootfs`.
* Las licencias se extraen desde ese rootfs.
* No reconstruimos licencias desde `.deb`.

---

# 5. Reglas que fuiste imponiendo al Dockerfile

Fuiste refinando las restricciones:

## 5.1 No Alpine, no BusyBox, no Debian

Regla final:

> Usar solo imágenes base `scratch` o Ubuntu slim cuando sea posible.

Esto descartó soluciones basadas en:

```dockerfile
FROM alpine
FROM busybox
FROM debian:bookworm-slim
```

## 5.2 No instalar paquetes innecesarios

Las herramientas pueden existir en stages intermedios, pero no deben llegar a la imagen final.

## 5.3 Imagen final `scratch`

La final debe ser:

```dockerfile
FROM scratch AS app
```

y copiar únicamente:

* rootfs chiseado;
* `/etc/passwd`;
* `/etc/group`;
* home del usuario;
* binario de la app;
* quizá `rocheck` o init mínimo si aplica.

## 5.4 Usuario nonroot

Querías usuario similar a distroless:

```text
nonroot
```

No querías usar solo UID/GID en la declaración final.

Preferencia:

```dockerfile
USER nonroot:nonroot
```

## 5.5 Shell de usuarios

Inicialmente se propuso `/bin/false`.

Lo corregiste:

> usar `/sbin/nologin`.

Por tanto:

```text
root:x:0:0:root:/:/sbin/nologin
nonroot:x:65532:65532:nonroot:/home/nonroot:/sbin/nologin
```

## 5.6 Home de root

Querías:

* no copiar `/root`;
* root con home `/`, o a un directorio no existente;
* evitar `/root` como directorio usable.

Se adoptó:

```text
root:x:0:0:root:/:/sbin/nologin
```

## 5.7 Home de nonroot

```text
/home/nonroot
```

Debe ser el único lugar escribible por defecto.

## 5.8 Volumen

Declarar:

```dockerfile
VOLUME ["/home/nonroot"]
```

## 5.9 Permisos

Inicialmente querías eliminar permisos de escritura en todo salvo `/home/nonroot`.

Después matizamos:

* modificar permisos del rootfs puede romper supuestos;
* no equivale a `--read-only`;
* puede añadir fragilidad;
* Chisel/Canonical no hace chmod masivo;
* mejor enforcement runtime con `--read-only`.

Pero tú aclaraste:

> Quiero `chmod` solo como capa adicional, no como sustituto de `--read-only`.

Finalmente vimos que Docker no permite hacer que una imagen sea read-only por defecto a nivel OCI, así que apareció la solución fail-fast.

---

# 6. Dockerfile con Chisel + licencias + app + usuario nonroot

## 6.1 Estructura final propuesta

Conceptualmente:

```dockerfile
# syntax=docker/dockerfile:1.10

FROM ubuntu:24.04 AS chiseler
# install chisel
# chisel cut --root /rootfs ...

FROM ubuntu:24.04 AS licenses
COPY --from=chiseler /rootfs /rootfs
# generate THIRD_PARTY.md
# generate licenses.tgz

FROM ubuntu:24.04 AS build
# build app

FROM ubuntu:24.04 AS etcfiles
# create passwd/group/home

FROM scratch AS app
COPY --from=chiseler /rootfs/ /
COPY --from=etcfiles /etc/passwd /etc/passwd
COPY --from=etcfiles /etc/group /etc/group
COPY --from=etcfiles --chown=nonroot:nonroot /home/nonroot /home/nonroot
COPY --from=build --chown=nonroot:nonroot /out/myapp /usr/local/bin/myapp

ENV HOME=/home/nonroot
WORKDIR /home/nonroot
VOLUME ["/home/nonroot"]
USER nonroot:nonroot
ENTRYPOINT ["/usr/local/bin/myapp"]
```

## 6.2 Generación de licencias

Stage conceptual:

```dockerfile
FROM ubuntu:24.04 AS licenses
COPY --from=chiseler /rootfs /rootfs
WORKDIR /out

ARG CHISEL_RELEASE=ubuntu-24.04
ARG CHISEL_SLICES

RUN set -e; \
  echo "# THIRD_PARTY (Chisel ${CHISEL_RELEASE})" > THIRD_PARTY.md; \
  echo "" >> THIRD_PARTY.md; \
  echo "Slices utilizados:" >> THIRD_PARTY.md; \
  for s in ${CHISEL_SLICES}; do echo "- ${s}" >> THIRD_PARTY.md; done; \
  echo "" >> THIRD_PARTY.md; \
  echo "## Paquetes y licencias detectadas" >> THIRD_PARTY.md; \
  mkdir -p /out/files; \
  if [ -d /rootfs/usr/share/doc ]; then \
    find /rootfs/usr/share/doc -maxdepth 2 -type f -name copyright \
      | sort \
      | while read -r f; do \
          pkg="$(echo "$f" | sed -E 's#.*/usr/share/doc/([^/]+)/copyright#\1#')"; \
          echo "### ${pkg}" >> THIRD_PARTY.md; \
          echo "- Ruta: ${f#/rootfs}" >> THIRD_PARTY.md; \
          echo "" >> THIRD_PARTY.md; \
          mkdir -p "/out/files/${pkg}"; \
          cp "$f" "/out/files/${pkg}/"; \
        done; \
  fi; \
  tar -C /out -czf /out/licenses.tgz files THIRD_PARTY.md
```

## 6.3 Exportar licencias

```bash
docker buildx build \
  --target licenses \
  --build-arg CHISEL_SLICES="base core ca-certificates tzdata libc6 minimal" \
  --output type=local,dest=./legal \
  .
```

Resultado:

```text
./legal/THIRD_PARTY.md
./legal/licenses.tgz
./legal/files/<package>/copyright
```

---

# 7. docker-bake.hcl

## 7.1 Por qué apareció

Querías generar:

* imagen de app;
* salida de licencias;

potencialmente en un solo comando.

## 7.2 Qué es HCL

HCL = **HashiCorp Configuration Language**.

Es un lenguaje declarativo usado por Terraform, Packer y otros.

Docker Buildx Bake lo usa para definir:

* targets;
* args;
* tags;
* outputs;
* grupos de build.

## 7.3 Ejemplo final

```hcl
group "default" {
  targets = ["app_image", "licenses"]
}

target "app_image" {
  target = "app"
  tags   = ["miapp:latest"]
  output = ["type=docker"]
}

target "licenses" {
  target = "licenses"
  args = {
    CHISEL_SLICES = "base core ca-certificates tzdata libc6 minimal"
  }
  output = ["type=local,dest=./legal"]
}
```

## 7.4 Ejecutar

```bash
docker buildx bake
```

Genera:

* imagen local `miapp:latest`;
* directorio `./legal`.

---

# 8. Read-only root filesystem en contenedores Docker

## 8.1 Problema

Querías que la imagen pudiera declarar:

> “Este root filesystem debe ser read-only”.

Docker no ofrece un `Dockerfile` equivalente a:

```dockerfile
READONLY_ROOTFS true
```

## 8.2 Por qué

OCI separa:

* imagen: qué archivos existen;
* runtime: cómo se montan.

`--read-only` pertenece al runtime, no a la imagen.

## 8.3 Opciones disponibles

### Docker CLI

```bash
docker run --read-only miapp
```

### Docker Compose

```yaml
services:
  app:
    image: miapp
    read_only: true
    volumes:
      - app-data:/home/nonroot
```

### Kubernetes

```yaml
securityContext:
  readOnlyRootFilesystem: true
```

## 8.4 No hay enforcement desde imagen

No hay label estándar que Docker aplique automáticamente.

Se pueden usar labels solo como documentación/política:

```dockerfile
LABEL org.opencontainers.image.readonly-rootfs="true"
```

Pero no enforcea nada.

---

# 9. Fail-fast si el filesystem no es read-only

## 9.1 Solución conceptual

La imagen no puede imponer `--read-only`, pero sí puede negarse a arrancar si el rootfs es escribible.

## 9.2 Primer enfoque con shell

```sh
#!/bin/sh
set -e

if touch /.rw-test 2>/dev/null; then
  echo "ERROR: root filesystem is writable. Run with --read-only."
  rm -f /.rw-test
  exit 1
fi

exec /usr/local/bin/myapp
```

Pero no querías shell.

## 9.3 Fail-fast sin shell en C

Código propuesto:

```c
#define _GNU_SOURCE
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv) {
    int fd = open("/.rw-test", O_WRONLY | O_CREAT, 0600);
    if (fd >= 0) {
        close(fd);
        unlink("/.rw-test");
        write(2,
            "ERROR: root filesystem is writable.\n"
            "Run container with --read-only or "
            "readOnlyRootFilesystem: true\n",
            98);
        _exit(1);
    }

    if (errno != EROFS) {
        perror("ERROR: filesystem check failed");
        _exit(1);
    }

    if (argc < 2) {
        write(2, "ERROR: no command specified\n", 28);
        _exit(1);
    }

    execv(argv[1], &argv[1]);
    perror("execv failed");
    _exit(1);
}
```

## 9.4 Compilación

```bash
cc -static -Os -s rocheck.c -o rocheck
```

## 9.5 Integración en imagen

```dockerfile
COPY rocheck /rocheck
COPY myapp /usr/local/bin/myapp

USER nonroot:nonroot
ENTRYPOINT ["/rocheck", "/usr/local/bin/myapp"]
```

## 9.6 Comportamiento

```bash
docker run miapp
# falla

docker run --read-only miapp
# arranca
```

## 9.7 Ventaja

Comprueba el mount real del kernel, no permisos POSIX.

Detecta correctamente `EROFS` devuelto por `open()` al intentar escribir en un FS montado read-only.

---

# 10. Limitaciones del modelo Docker/OCI respecto a sistemas de archivos reales

## 10.1 Tu observación

Dijiste que te gustaría usar:

* ISO9660;
* ROMFS;
* SquashFS;
* EROFS;

como root real.

## 10.2 Conclusión

Una imagen Docker/OCI es básicamente:

```text
capas tar + metadata
```

El runtime decide cómo montarlas, normalmente con overlayfs.

No eliges desde la imagen el FS final como ISO9660/EROFS/SquashFS.

## 10.3 Consecuencia

Para tener un FS realmente inmutable:

* no basta con Docker;
* hay que convertir el rootfs en una imagen de disco;
* hay que arrancar Linux contra ese rootfs.

---

# 11. Evolución hacia sistema arrancable inmutable

## 11.1 Idea emergente

Convertir el rootfs generado desde Docker/Chisel en un sistema operativo real:

```text
Docker/Chisel rootfs
  ↓
EROFS/SquashFS image
  ↓
Kernel + initramfs / UKI
  ↓
Bootable immutable appliance
```

## 11.2 Motivación

Tener un sistema “tipo contenedor”, pero sobre bare metal:

* rootfs inmutable;
* sin shell;
* sin apt;
* persistencia separada;
* actualización controlada;
* superficie de ataque mínima.

## 11.3 Casos de uso considerados

* sistema anti-drones TRC;
* SAT Companion Terrestar;
* device guía turístico Tourstream/Viamo;
* edge media;
* gateways WebRTC;
* dispositivos offline;
* IoT industrial;
* defensa/militar;
* cámaras/video analytics;
* Django appliance.

---

# 12. ISO9660 vs EROFS vs SquashFS vs ROMFS

## 12.1 ISO9660

Características:

* diseñado para CD-ROM;
* universalmente soportado;
* muy compatible;
* no ideal para rootfs moderno;
* estructura antigua;
* tamaños/filenames limitados salvo extensiones Rock Ridge/Joliet;
* útil para ISOs bootables/legacy.

## 12.2 EROFS

Características discutidas:

* moderno;
* read-only;
* diseñado para Linux/Android/embedded;
* compresión eficiente;
* buen acceso aleatorio;
* buen candidato para rootfs inmutable moderno;
* más adecuado que ISO9660 para sistema Linux appliance.

## 12.3 SquashFS

Características:

* muy usado en LiveCDs, routers, embedded;
* read-only;
* comprimido;
* más clásico;
* muy soportado por bootloaders;
* GRUB lo soporta como `squash4`.

## 12.4 ROMFS

Mencionado como alternativa histórica read-only.

Más simple, pero menos atractivo que EROFS/SquashFS.

## 12.5 Decisión conceptual

* Para compatibilidad bootloader: SquashFS puede ser más fácil.
* Para rootfs moderno montado por Linux: EROFS parece mejor candidato.
* Para legacy/boot universal: ISO9660.
* Para artículo: comparar los tres.

---

# 13. GRUB y sistemas de archivos

## 13.1 Pregunta

Preguntaste qué FS soporta GRUB y si había alguno similar a EROFS aparte de ISO9660.

## 13.2 Lista discutida

GRUB soporta muchos FS mediante módulos:

* FAT12/16/32;
* ext2/ext3/ext4;
* XFS;
* JFS;
* Btrfs;
* ReiserFS;
* ISO9660;
* UDF;
* NTFS;
* HFS+;
* ZFS;
* SquashFS/squash4;
* ROMFS;
* soporte emergente/parcial para EROFS según versión.

## 13.3 Implicación

Si GRUB puede leer el FS donde están kernel/initramfs, puedes usar GRUB clásico.

Pero si usas UKI, puedes evitar GRUB.

---

# 14. Kernel, bootloader, UKI y `linux-image-generic`

## 14.1 Pregunta

Preguntaste si basta con instalar `linux-image-generic`.

## 14.2 Conclusión

No basta por sí solo.

`linux-image-generic` instala:

* `vmlinuz-*`;
* módulos;
* initrd generado normalmente por hooks;
* archivos en `/boot`.

Pero necesitas algo que lo arranque:

* GRUB;
* systemd-boot;
* UKI;
* U-Boot;
* firmware UEFI directo;
* LinuxBoot/kexec.

## 14.3 El kernel es pasivo

El kernel no se autoejecuta.

Hace falta:

* firmware;
* bootloader;
* o UKI ejecutable por UEFI.

## 14.4 Si EROFS está como módulo

Problema huevo-gallina:

* rootfs está en EROFS;
* driver EROFS está en `/lib/modules` dentro del rootfs;
* el kernel no puede leer EROFS hasta cargar el módulo;
* no puede cargar el módulo hasta leer EROFS.

Soluciones:

* EROFS built-in en kernel;
* módulo EROFS dentro del initramfs.

---

# 15. UKI — Unified Kernel Image

## 15.1 Qué es

UKI combina en un único binario EFI:

* kernel;
* initramfs;
* cmdline;
* os-release/metadatos;
* opcionalmente firmas/mediciones.

## 15.2 Ventajas

* evita GRUB;
* un solo archivo `.efi`;
* se puede firmar;
* más fácil de razonar;
* kernel, initramfs y cmdline están unidos;
* útil para Secure Boot;
* más “appliance-like”.

## 15.3 Ubicación

En partición EFI FAT32:

```text
/EFI/BOOT/BOOTX64.EFI
```

o ruta registrada con `efibootmgr`.

## 15.4 Partición EFI

No hace falta que sea 512 MB.

Opciones:

* tamaño mínimo ajustado al UKI;
* 64–128 MB si solo un UKI;
* 256 MB si quieres fallback;
* 512 MB como opción conservadora.

## 15.5 Seguridad

Mejor no montar la ESP en el sistema normal.

Solo montarla temporalmente durante actualización.

## 15.6 Comando `efibootmgr`

Ejemplo:

```bash
efibootmgr --create \
  --disk /dev/sda \
  --part 1 \
  --label "MiSistemaInmutable" \
  --loader /EFI/BOOT/BOOTX64.EFI
```

Para NVMe:

```bash
efibootmgr --create \
  --disk /dev/nvme0n1 \
  --part 1 \
  --label "MiSistemaInmutable" \
  --loader /EFI/BOOT/BOOTX64.EFI
```

---

# 16. Initramfs

## 16.1 Por qué aparece

Si el kernel no tiene todo built-in, necesita initramfs para:

* cargar drivers de disco;
* cargar FS de root;
* montar rootfs real;
* hacer `switch_root`.

## 16.2 Contenido mínimo

Para EROFS root:

* driver de bloque: NVMe, AHCI, USB storage, etc.;
* EROFS;
* compresión usada: LZ4/LZMA/Zstd según caso;
* script/binario de initramfs;
* herramienta o syscall para montar;
* `switch_root` o equivalente.

## 16.3 Dracut

Se mencionó como herramienta para generar initramfs mínimo.

Ejemplo conceptual:

```bash
dracut --force \
  --kvm \
  --modules "bash rootfs-block" \
  --add-drivers "erofs lz4 lz4_rom" \
  --filesystems "erofs" \
  --strip \
  initrd-minimal.img
```

Pero después se criticó porque incluía shell/bash, no deseado para tu objetivo.

## 16.4 Initramfs con shell vs sin shell

Querías evitar:

* `/bin/sh`;
* `mount` externo;
* scripts.

Preferías un binario estático que haga syscalls directamente.

---

# 17. ¿El initramfs permanece en RAM?

## 17.1 Pregunta

Te preocupaba que meter cosas en initramfs aumente consumo de RAM permanente.

## 17.2 Conclusión matizada

Initramfs se carga en RAM.

Tras `switch_root`, normalmente se puede liberar gran parte, pero no conviene meter cosas innecesarias.

## 17.3 Decisión

Mantener initramfs mínimo.

Poner el init real, tini y aplicación en EROFS, no en initramfs, salvo que sea estrictamente necesario.

---

# 18. Módulos del kernel

## 18.1 Preguntas tratadas

Preguntaste:

* ¿meter todos los módulos de `linux-image-generic`?
* ¿solo los usados?
* ¿initramfs o EROFS?
* ¿kernel built-in?
* ¿quién carga módulos sin udev?
* ¿diferencia si conocemos hardware exacto?
* ¿diferencia para máxima compatibilidad?

## 18.2 Conclusión general

No tiene sentido meter todos los módulos si buscas minimalismo y seguridad.

## 18.3 Clasificación

### Necesarios para montar rootfs

Deben ir:

* built-in en kernel; o
* en initramfs.

Ejemplos:

* EROFS;
* compresión EROFS;
* NVMe/AHCI/USB storage;
* particiones;
* ext4/xfs si `/data` se monta muy temprano.

### Necesarios tras montar rootfs

Pueden ir en EROFS:

```text
/lib/modules/...
```

Ejemplos:

* red;
* audio;
* video;
* cámaras;
* GPU;
* periféricos;
* firmware.

### No necesarios

No incluir.

## 18.4 Sin udev

Si no hay udev/systemd, los módulos no se cargan “mágicamente” como en una distro normal.

Opciones:

* built-in;
* cargar manualmente en init propio usando `finit_module`;
* usar modprobe/kmod, pero eso añade binarios/config;
* usar mdev/udev, pero aumenta complejidad.

## 18.5 Built-in vs módulos

### Built-in (`=y`)

Ventajas:

* no necesitas cargar nada;
* más simple;
* más seguro;
* no hay `.ko` que manipular;
* arranque más directo.

Desventajas:

* kernel custom;
* mantener parches/updates;
* menos flexible;
* puede crecer el kernel.

### Módulos en initramfs

Ventajas:

* puedes usar kernel genérico;
* soportas hardware variable;
* drivers críticos disponibles antes de rootfs.

Desventajas:

* UKI/initramfs crece;
* más RAM inicial;
* más complejidad;
* hay que cargar módulos.

### Módulos en EROFS

Ventajas:

* no aumentan UKI;
* no ocupan RAM hasta cargarse;
* puedes conservar flexibilidad.

Desventajas:

* necesitas rootfs montado;
* necesitas mecanismo de carga;
* no sirven para montar el propio rootfs.

## 18.6 Recomendación por escenario

### Hardware exacto

Kernel custom con drivers críticos built-in.

### Hardware flexible

Kernel genérico + initramfs host-only.

### Máxima compatibilidad

Kernel genérico + más módulos, aceptando más tamaño.

---

# 19. Init del sistema final

## 19.1 Tini

Tini se discutió como opción simple.

Características:

* reaper de zombies;
* forward de señales;
* muy pequeño;
* común en contenedores;
* no monta discos;
* no supervisa múltiples servicios;
* si PID 1 termina y no apaga/reinicia, puede provocar panic en bare metal.

## 19.2 s6

Se discutió como alternativa.

Características:

* supervisor completo;
* reinicio automático;
* múltiples servicios;
* etapas de init;
* más parecido a docker-compose/system supervisor;
* más complejo;
* más grande.

Tu conclusión:

> Prefiero simplicidad; s6 parece más docker-compose.

## 19.3 Init propio tipo minit

Recordaste NodeOS:

* usabas un script Node.js;
* luego lanzabas un init mínimo parecido a tini;
* no usabas `mount`;
* usabas paquete npm que hacía syscalls de kernel;
* el sistema cerraba o reiniciaba limpiamente si la app terminaba.

## 19.4 Solución preferida

Un binario mínimo en C o Rust:

* PID 1;
* monta `/proc`, `/sys`, `/dev`;
* monta `/data`;
* lanza app/tini;
* espera;
* hace `sync`;
* llama a `reboot()` o `poweroff()`.

## 19.5 Código C conceptual

```c
#include <sys/mount.h>
#include <sys/wait.h>
#include <sys/reboot.h>
#include <unistd.h>
#include <stdlib.h>

int main() {
    mount("proc", "/proc", "proc", 0, NULL);
    mount("sysfs", "/sys", "sysfs", 0, NULL);
    mount("devtmpfs", "/dev", "devtmpfs", 0, NULL);

    if (mount("/dev/sda3", "/data", "ext4", 0, NULL) != 0) {
        return 1;
    }

    pid_t pid = fork();

    if (pid == 0) {
        char *args[] = {"/usr/bin/tini", "--", "/app/my_binary", NULL};
        execv(args[0], args);
        _exit(1);
    }

    if (pid > 0) {
        int status;
        waitpid(pid, &status, 0);
        sync();
        reboot(RB_AUTOBOOT);
    }

    return 1;
}
```

## 19.6 Variante sin tini

El init puede lanzar directamente la app.

Pero tini sigue siendo útil si:

* tu app crea hijos;
* quieres reaping estándar;
* quieres señalización limpia.

---

# 20. Shell o no shell

## 20.1 Decisión fuerte

No quieres shell.

Razones:

* seguridad;
* reducir superficie de ataque;
* evitar que un atacante tenga `/bin/sh`;
* coherencia con sistema appliance;
* coherencia con distroless.

## 20.2 Consecuencia

Evitar:

* bash;
* dash;
* busybox shell;
* scripts de init;
* `system("mount ...")`.

Usar:

* C/Rust;
* syscalls directas;
* `mount(2)`;
* `finit_module(2)` si hace falta;
* `reboot(2)`.

---

# 21. Layout de particiones para sistema bootable

## 21.1 Layout base con UKI

```text
/dev/sda1  ESP FAT32   UKI: /EFI/BOOT/BOOTX64.EFI
/dev/sda2  EROFS       rootfs inmutable
/dev/sda3  EXT4/XFS    data persistente
```

## 21.2 ESP

* FAT32;
* no montada en runtime normal;
* montada solo para actualizaciones;
* contiene UKI.

## 21.3 Root

* EROFS o SquashFS;
* read-only real;
* contiene sistema generado desde Docker/Chisel;
* puede incluir app, libs, tini, init, módulos no críticos.

## 21.4 Data

* EXT4 o XFS;
* equivalente al volumen Docker;
* contiene base de datos, logs, uploads, etc.

## 21.5 OverlayFS opcional

Se discutió como alternativa:

```text
lowerdir = EROFS
upperdir = data
workdir  = data
```

Ventaja:

* el sistema “parece” escribible.

Desventaja:

* rompe la pureza del modelo;
* más difícil razonar;
* puede ocultar modificaciones;
* para appliance seguro quizá mejor montar rutas explícitas.

---

# 22. EXT4 vs XFS para partición de datos

## 22.1 EXT4

Ventajas:

* muy probado;
* simple;
* fácil de reparar;
* flexible;
* bueno para Raspberry/LuckFox/disco USB;
* permite shrink en ciertos escenarios;
* buena opción por defecto.

## 22.2 XFS

Ventajas:

* bueno con escrituras concurrentes;
* bueno con archivos grandes;
* bueno para logs/video/datos sostenidos;
* robusto.

Desventajas:

* no se puede reducir fácilmente;
* quizá excesivo para sistemas pequeños.

## 22.3 Recomendación matizada

Para Django + DB ligera:

* EXT4 probablemente suficiente y prudente.

Para vídeo/logs/escrituras concurrentes sostenidas:

* XFS puede tener sentido.

No vender XFS como “siempre superior”.

---

# 23. Actualizaciones

## 23.1 Root EROFS

Si root es EROFS, no se actualiza “dentro”.

Se reemplaza la imagen completa.

Opciones:

### Sin A/B

Sobrescribir partición root:

```bash
dd if=new-root.erofs of=/dev/sda2
```

Problema: si falla, sistema roto.

### Con A/B

```text
sda2 rootA
sda3 rootB
sda4 data
```

Actualizar slot inactivo y cambiar boot target.

Ventaja:

* rollback.

## 23.2 ESP/UKI

Actualizar UKI implica copiar nuevo `.efi`.

Proceso seguro:

```bash
mount /dev/sda1 /mnt/efi
cp new.efi /mnt/efi/EFI/BOOT/BOOTX64.EFI.tmp
sync
mv /mnt/efi/EFI/BOOT/BOOTX64.EFI.tmp /mnt/efi/EFI/BOOT/BOOTX64.EFI
sync
umount /mnt/efi
```

Mejor si hay fallback:

```text
BOOTX64.EFI
BOOTX64-previous.EFI
```

## 23.3 No actualizar kernel “en caliente”

Tu observación:

> Si root es inmutable y hay que reescribir particiones, no tiene sentido pensar en actualización caliente.

Correcto.

Modelo: actualización offline/atómica + reboot.

---

# 24. Secure Boot, firmas y verificación

## 24.1 UKI

UKI permite firmar un único binario:

```text
kernel + initramfs + cmdline
```

Ventaja:

* más fácil que firmar piezas separadas;
* reduce manipulación de cmdline;
* evita `init=/bin/sh` si cmdline está embebida y firmada.

## 24.2 EROFS/rootfs

Para sistema más serio:

* verificar hash de rootfs;
* dm-verity;
* firma de imagen;
* measured boot;
* attestation.

No lo desarrollamos con comandos, pero quedó como extensión clara.

## 24.3 Paper potencial

Aquí aparece la línea de paper:

```text
From Docker Image to Verifiable Immutable Appliance
```

con:

* SBOM;
* attestation;
* Secure Boot;
* dm-verity;
* mediciones;
* benchmark.

---

# 25. Coreboot, LinuxBoot y Linux-as-BIOS

## 25.1 Aclaración conceptual

Tú pensabas que Coreboot era “Linux sustituyendo BIOS/UEFI”.

Matiz:

* Coreboot sustituye firmware/BIOS del fabricante;
* LinuxBoot suele ser un payload Linux ejecutado por Coreboot.

## 25.2 Capas

```text
Firmware propietario tradicional
  ↓
UEFI
  ↓
GRUB/UKI
```

vs

```text
Coreboot
  ↓
payload: TianoCore / SeaBIOS / LinuxBoot / Heads
```

## 25.3 LinuxBoot

LinuxBoot es usar un kernel Linux como entorno de firmware/boot.

Normalmente:

```text
Coreboot inicializa hardware básico
LinuxBoot payload arranca
LinuxBoot localiza/verifica kernel real
kexec hacia kernel real
```

## 25.4 Por qué kexec

Preguntaste:

> ¿Por qué no usar directamente el kernel de LinuxBoot?

Respuesta:

Se puede, pero kexec permite:

* mantener kernel firmware mínimo;
* actualizar kernel real sin flashear BIOS;
* evitar brick si falla actualización;
* usar kernel real más grande;
* separar firmware de OS;
* tener recuperación.

## 25.5 Usar LinuxBoot directamente

Tiene sentido si:

* hardware fijo;
* appliance extremo;
* kernel muy pequeño;
* no quieres kernel separado;
* aceptas flashear firmware para actualizar kernel.

## 25.6 Coreboot + TianoCore

Alternativa intermedia:

```text
Coreboot
  ↓
TianoCore UEFI
  ↓
UKI
```

Mantienes compatibilidad UEFI pero con firmware abierto.

## 25.7 Conclusión

Para artículo:

* UKI = práctico/portable.
* Coreboot + LinuxBoot = extremo/hardware-specific.
* LinuxBoot directo = appliance muy cerrado.
* kexec = separación limpia firmware/OS.

---

# 26. Raspberry Pi, LuckFox, U-Boot y hardware real

## 26.1 Raspberry Pi

Observaciones:

* no usa UEFI PC estándar por defecto;
* Coreboot no es la vía típica;
* se puede usar UEFI firmware en algunas Pi;
* puede arrancar kernel/initramfs de forma propia;
* buena para PoC;
* limitación de I/O si disco y cámara van por USB.

## 26.2 LuckFox / Rockchip

Observaciones:

* suelen usar U-Boot;
* más orientados a embedded/cámaras;
* algunos tienen NPU;
* pueden ser interesantes para video analytics;
* U-Boot puede cargar kernel/initramfs/FIT images;
* equivalente conceptual a UKI sería otra cadena: U-Boot + signed FIT.

## 26.3 Hardware concreto no decidido

La conversación está aún en teoría, para artículo.

Caso mental:

* servidor Django;
* recibe info por red;
* guarda en base de datos;
* dashboard web;
* quizá decodifica/análisis de streams de vídeo;
* baja carga general;
* decenas/cientos registros por segundo.

---

# 27. Bootable containers

## 27.1 Mención

Has visto por ahí “bootable containers”.

Lo conectamos con esta idea.

## 27.2 Diferencia conceptual

Un contenedor bootable intenta reutilizar artefactos OCI como base de sistemas arrancables.

Tu variante conceptual:

```text
OCI/Docker build
  ↓
Chisel rootfs
  ↓
EROFS/SquashFS
  ↓
UKI / GRUB / U-Boot
  ↓
Appliance
```

## 27.3 Posicionamiento

No es completamente nuevo, pero sí poco explicado de extremo a extremo.

---

# 28. Comparativa de arquitecturas de arranque

## 28.1 Opción A — Docker normal hardened

```text
Docker image
docker run --read-only
volume /home/nonroot
rocheck fail-fast
```

Ventajas:

* fácil;
* portable;
* compatible con infra actual.

Desventajas:

* depende de runtime;
* no es bare metal;
* rootfs no es FS read-only real;
* `--read-only` es opt-in externo.

## 28.2 Opción B — GRUB + kernel/initramfs + EROFS/SquashFS

Ventajas:

* fácil de depurar;
* clásico;
* flexible;
* GRUB soporta muchos FS.

Desventajas:

* más piezas;
* config externa;
* más superficie;
* cmdline editable si no se protege.

## 28.3 Opción C — UKI + EROFS + data

Ventajas:

* limpio;
* un único `.efi`;
* firmable;
* sin GRUB;
* ideal appliance.

Desventajas:

* requiere ESP;
* UKI crece con initramfs;
* firmware UEFI requerido.

## 28.4 Opción D — U-Boot + FIT image

Más adecuada para embedded ARM.

No se desarrolló mucho, pero debe entrar como alternativa para Raspberry/LuckFox/Rockchip.

## 28.5 Opción E — Coreboot + LinuxBoot + kexec

Ventajas:

* firmware abierto;
* verificación antes del OS;
* recuperación avanzada;
* seguridad extrema.

Desventajas:

* hardware-specific;
* complejo;
* difícil de vender como primer paso;
* riesgo de brick.

## 28.6 Opción F — Coreboot + LinuxBoot directo

Ventajas:

* extremo minimalismo;
* boot muy rápido;
* kernel en firmware.

Desventajas:

* muy rígido;
* actualizaciones peligrosas;
* límite de flash;
* solo appliances muy cerrados.

---

# 29. Paper vs artículo vs PoC

## 29.1 Evaluación

Preguntaste si esto da para paper o es camino trillado.

Respuesta:

* como idea pura, no es paper fuerte;
* como integración técnica, sí da para artículo muy bueno;
* como paper, necesitaría medición o novedad concreta.

## 29.2 Para paper necesitarías

### Benchmark

Comparar:

```text
Raspbian
Docker normal
Docker --read-only
Chisel container
Chisel + EROFS + UKI
```

Métricas:

* tamaño;
* boot time;
* RAM;
* I/O;
* superficie de ataque;
* write paths;
* consumo de CPU;
* tiempo de recuperación;
* resistencia a corrupción.

### Seguridad

* persistencia tras compromiso;
* paths escribibles;
* ausencia de shell;
* ausencia de package manager;
* manipulación de boot;
* cmdline protegida;
* dm-verity/Secure Boot.

### Framework reproducible

Pipeline:

```text
Dockerfile → rootfs → SBOM → EROFS → UKI → signed appliance image
```

## 29.3 Recomendación estratégica

Primero artículo.

Después PoC.

Después, si hay datos, paper.

---

# 30. Signature piece

## 30.1 Definición

Un “signature piece” es un artículo que define tu identidad profesional.

No es solo “un post”.

Es algo que hace que alguien diga:

> “Esta persona sabe de verdad de esto”.

En tu caso:

> “Este tío no solo hace WebRTC; diseña sistemas completos desde hardware, networking, kernel y OS hasta aplicación, optimización e IA”.

## 30.2 Cómo se cita

No como paper académico con DOI, salvo que lo publiques también en Zenodo/arXiv/etc.

Pero en industria se puede citar como:

```text
Leganés Combarro, J. (2026).
Turning a Docker Image into a Bootable Immutable Linux Appliance.
https://piranna.github.io/...
```

## 30.3 Diferenciarlo en tu web

Propuestas:

* sección `Featured Articles`;
* sección `Signature Work`;
* tag `signature`;
* destacar 3–5 piezas en homepage.

## 30.4 Candidatos existentes

Según lo hablado:

* Types of WebRTC networks;
* AI code generation and the oversight problem;
* npm lifecycle article;
* futuro artículo Chisel/EROFS/UKI;
* potencial artículo de Mafalda SFU / scalable real-time media;
* quizá uno futuro sobre BLE/SAT Companion si se formaliza.

---

# 31. Dónde publicar

## 31.1 WebRTC.ventures

Pros:

* visibilidad;
* SEO;
* marca;
* clientes.

Contras:

* no es claramente WebRTC;
* perderías control;
* tono corporate;
* cola editorial;
* ya tienes otro artículo pendiente;
* podrían suavizarlo.

## 31.2 Blog personal

Pros:

* control total;
* voz propia;
* ideal como signature piece;
* puedes ser más radical;
* construye tu marca.

Contras:

* menos tráfico inicial.

## 31.3 Recomendación

Publicar primero en tu blog como versión canonical.

Después, si interesa, derivar una versión corporativa orientada a:

```text
immutable edge systems for real-time media
```

---

# 32. Dominio personal

## 32.1 Situación

Tu web actual:

```text
https://piranna.github.io
```

Está ya publicada en muchos sitios.

## 32.2 Recomendación

Comprar dominio, pero no romper URL.

Usar:

* dominio propio como principal;
* GitHub Pages como backend;
* redirecciones/canonical URLs.

---

# 33. Código y comandos aparecidos

## 33.1 Validar `--output` con wrapper

```bash
if [[ " $* " != *" --output "* ]]; then
    echo "ERROR: Debes usar --output"
    exit 1
fi

docker build "$@"
```

## 33.2 Docker build app

```bash
docker buildx build \
  --target app \
  -t miapp:latest \
  --load \
  .
```

## 33.3 Docker build licenses

```bash
docker buildx build \
  --target licenses \
  --output type=local,dest=./legal \
  .
```

## 33.4 Bake

```bash
docker buildx bake
```

## 33.5 Fail-fast C

```c
int fd = open("/.rw-test", O_WRONLY | O_CREAT, 0600);
if (fd >= 0) {
    close(fd);
    unlink("/.rw-test");
    write(2, "ERROR: root filesystem is writable.\n", 36);
    _exit(1);
}
if (errno != EROFS) {
    perror("ERROR: filesystem check failed");
    _exit(1);
}
execv(argv[1], &argv[1]);
```

## 33.6 Init mínimo C conceptual

```c
mount("proc", "/proc", "proc", 0, NULL);
mount("sysfs", "/sys", "sysfs", 0, NULL);
mount("devtmpfs", "/dev", "devtmpfs", 0, NULL);
mount("/dev/sda3", "/data", "ext4", 0, NULL);

pid_t pid = fork();

if (pid == 0) {
    char *args[] = {"/usr/bin/tini", "--", "/app/my_binary", NULL};
    execv(args[0], args);
    _exit(1);
}

waitpid(pid, &status, 0);
sync();
reboot(RB_AUTOBOOT);
```

## 33.7 efibootmgr

```bash
efibootmgr --create \
  --disk /dev/sda \
  --part 1 \
  --label "MiSistemaInmutable" \
  --loader /EFI/BOOT/BOOTX64.EFI
```

## 33.8 Montar ESP solo durante actualización

```bash
mount /dev/sda1 /mnt/efi-temp
cp nuevo_sistema.efi /mnt/efi-temp/EFI/BOOT/BOOTX64.EFI
sync
umount /mnt/efi-temp
```

---

# 34. Posible estructura futura del artículo

## 34.1 Título posible

```text
What if your container WAS the operating system?
```

o

```text
Turning a Docker Image into a Bootable Immutable Linux Appliance
```

## 34.2 Índice posible

1. Containers solved packaging, not booting.
2. The missing piece: immutable rootfs.
3. Building a minimal Ubuntu rootfs with Chisel.
4. Separating application image and legal artifacts.
5. Making Docker images read-only: limits of OCI.
6. Fail-fast read-only enforcement without shell.
7. From OCI rootfs to EROFS/SquashFS.
8. Boot options: GRUB, UKI, U-Boot, LinuxBoot.
9. Kernel modules: initramfs vs built-in vs EROFS.
10. Init without shell: C/Rust PID 1.
11. Persistence as a Docker-like volume.
12. Updating immutable systems.
13. Security model and threat model.
14. Use cases: edge, WebRTC, drones, SAT Companion, tourism device.
15. What is novel, what is not.
16. Future work: benchmarks, SBOM, Secure Boot, dm-verity.

---

# 35. Frase de tesis

Una buena tesis del artículo:

> Containers gave us reproducible application filesystems. But for edge appliances, drones, satellites, media gateways, and unattended devices, the next step is making that filesystem bootable, immutable, verifiable, and explicitly persistent only where intended.

O en versión más directa:

> A Docker image is almost a root filesystem. Chisel, EROFS, and UKI let us close the gap and turn it into a bootable appliance.

---

# 36. Conclusión final del resumen

Todo el proceso mental fue:

```text
Detectar --output dentro de Dockerfile
  ↓
No se puede: usar stages y targets
  ↓
Separar imagen app y licencias
  ↓
Usar Chisel para rootfs mínimo
  ↓
Imagen final scratch, nonroot, nologin, sin shell
  ↓
Licencias exportadas como Markdown + tgz
  ↓
Docker no puede imponer read-only desde imagen
  ↓
Fail-fast sin shell con binario C
  ↓
Si queremos read-only real: salir de Docker
  ↓
Convertir rootfs en EROFS/SquashFS
  ↓
Arrancar con GRUB/UKI/U-Boot/LinuxBoot
  ↓
Init mínimo en C/Rust
  ↓
/data como volumen persistente
  ↓
Modelo appliance robusto para edge/defensa/WebRTC/media
```

Ahí está el artículo. Y probablemente, con PoC y métricas, también el germen de un paper industrial.

