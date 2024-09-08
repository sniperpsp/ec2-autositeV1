#!/bin/bash

# Navegue até o diretório do backend e inicie o servidor em segundo plano
cd /s3front/backend
npm start &

# Espere alguns segundos para garantir que o backend esteja iniciado
sleep 5

# Exportar a variável de ambiente necessária para o frontend
export NODE_OPTIONS=--openssl-legacy-provider

# Navegue até o diretório do frontend e inicie o servidor
cd /s3front/frontend
npm start