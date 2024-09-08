#!/bin/bash

# Criar usuário template com senha Te#mpl@te e dar permissões de root
useradd template #criando usuario
echo 'template:Te#mpl@te' | chpasswd #senhad o usuario
echo 'root:33557788' | chpasswd #senhad o usuario
usermod -aG wheel template #permissão de root para o usuario

# Habilitar login com usuário e senha
sed -i 's/^#PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config  #habilitando acesso com senha via ssh
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config #habilitando acesso com senha via ssh
sed -i 's/^#PermitEmptyPasswords no/PermitEmptyPasswords no/' /etc/ssh/sshd_config #habilitando acesso com senha via ssh
sed -i 's/^PermitEmptyPasswords yes/PermitEmptyPasswords no/' /etc/ssh/sshd_config #habilitando acesso com senha via ssh


# Reiniciar o serviço SSH para aplicar as mudanças
systemctl restart sshd

#Instalar Docker e Git
sudo yum update -y
sudo yum install git -y
sudo yum install docker -y
sudo usermod -a -G docker template
id ec2-user ssm-user
sudo newgrp docker

#Ativar docker
sudo systemctl enable docker.service
sudo systemctl start docker.service

#Instalar docker compose 2
sudo mkdir -p /usr/local/lib/docker/cli-plugins
sudo curl -SL https://github.com/docker/compose/releases/download/v2.23.3/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

#Instalar node e npm
curl -fsSL https://rpm.nodesource.com/setup_21.x | sudo bash -
sudo yum install -y nodejs