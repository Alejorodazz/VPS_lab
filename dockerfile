FROM ubuntu:24.04

# Actualizar el sistema e instalar herramientas básicas y SSH
RUN apt-get update && apt-get install -y \
    openssh-server \
    sudo \
    curl \
    nano \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# Configurar el directorio de ejecución para SSH
RUN mkdir /var/run/sshd

# Permitir el acceso temporal por contraseña para la configuración inicial
RUN echo 'root:password' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Exponer el puerto estándar de SSH
EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
