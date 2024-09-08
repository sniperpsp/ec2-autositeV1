FROM node:14

# Atualize os pacotes do sistema
RUN apt-get update && apt-get install -y

# Defina o diretório de trabalho no contêiner
WORKDIR /usr/src/app

# Copie os arquivos package.json e package-lock.json do backend
COPY backend/package*.json ./backend/
# Copie os arquivos package.json e package-lock.json do frontend
COPY frontend/package*.json ./frontend/

# Instale as dependências do backend
RUN cd backend && npm install
# Instale as dependências do frontend
RUN cd frontend && npm install

# Instale o concurrently globalmente
RUN npm install -g concurrently

# Copie o restante do código da aplicação
COPY backend ./backend
COPY frontend ./frontend

# Exponha as portas que as aplicações irão rodar
EXPOSE 3000 3001

# Comando para rodar a aplicação
CMD ["concurrently", "\"cd backend && npm start\"", "\"cd frontend && npm start\""]