# Projeto de Upload para S3 e Configuração de Lambda

Este projeto consiste em um servidor Node.js que permite aos usuários fazer upload de arquivos `.zip` para um bucket S3. Além disso, há uma função Lambda configurada para processar esses arquivos, descompactá-los em uma instância EC2, configurar um servidor web Apache e criar um registro DNS no Route 53.

## Funcionalidades

1. **Upload de Arquivos para S3**:
   - Um servidor Node.js com um formulário HTML permite que os usuários façam upload de arquivos `.zip` para um bucket S3.

2. **Processamento de Arquivos com Lambda**:
   - Uma função Lambda é acionada quando um novo arquivo é carregado no bucket S3.
   - A função Lambda descompacta o arquivo em uma instância EC2, configura um servidor web Apache e cria um registro DNS no Route 53.

## Estrutura do Projeto

- `server.js`: Servidor Node.js que lida com uploads de arquivos.
- `index.html`: Formulário HTML para upload de arquivos.
- `ssm-ec2.py`: Código da função Lambda que processa os arquivos carregados.
- `lambda.tf`: Arquivo Terraform para configurar a função Lambda e suas permissões.
- `.env`: Arquivo de configuração para credenciais AWS (não incluído no repositório por razões de segurança).

## Configuração

### Pré-requisitos

- Node.js e npm instalados.
- Conta AWS com permissões para S3, Lambda, EC2 e Route 53.
- Terraform instalado.

### Configuração do Bucket S3

Certifique-se de que o bucket S3 tem uma política que permite uploads de arquivos. Aqui está um exemplo de política:

{
"Version": "2012-10-17",
"Statement": [
{
"Effect": "Allow",
"Principal": "",
"Action": "s3:PutObject",
"Resource": "arn:aws:s3:::bucket-teste124/"
}
]
}


### Configuração do Servidor Node.js

1. **Inicialize o Projeto Node.js**:

   ```sh
   mkdir s3-upload
   cd s3-upload
   npm init -y
   ```

2. **Instale as Dependências**:

   ```sh
   npm install express aws-sdk multer dotenv
   ```

3. **Crie um Arquivo `.env`**:

   ```env
   AWS_ACCESS_KEY_ID=your_access_key_id
   AWS_SECRET_ACCESS_KEY=your_secret_access_key
   AWS_REGION=us-east-1
   S3_BUCKET_NAME=bucket-teste124
   ```

4. **Crie o Servidor Node.js**:

   ```javascript
   const express = require('express');
   const AWS = require('aws-sdk');
   const multer = require('multer');
   const multerS3 = require('multer-s3');
   const path = require('path');
   require('dotenv').config();

   const app = express();
   const port = 3000;

   // Configurar o AWS SDK
   AWS.config.update({
     accessKeyId: process.env.AWS_ACCESS_KEY_ID,
     secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
     region: process.env.AWS_REGION
   });

   const s3 = new AWS.S3();

   // Configurar o multer para usar o S3
   const upload = multer({
     storage: multerS3({
       s3: s3,
       bucket: process.env.S3_BUCKET_NAME,
       acl: 'public-read',
       key: function (req, file, cb) {
         cb(null, `uploads/${Date.now()}_${file.originalname}`);
       }
     })
   });

   // Rota para upload de arquivos
   app.post('/upload', upload.single('file'), (req, res) => {
     res.send(`Arquivo carregado com sucesso: ${req.file.location}`);
   });

   // Rota para servir o formulário de upload
   app.get('/', (req, res) => {
     res.sendFile(path.join(__dirname, 'index.html'));
   });

   app.listen(port, () => {
     console.log(`Servidor rodando em http://localhost:${port}`);
   });
   ```

5. **Crie o Formulário de Upload**:

   ```html
   <!DOCTYPE html>
   <html lang="en">
   <head>
       <meta charset="UTF-8">
       <meta name="viewport" content="width=device-width, initial-scale=1.0">
       <title>Upload de Arquivo para S3</title>
   </head>
   <body>
       <h1>Upload de Arquivo para S3</h1>
       <form ref='uploadForm' id='uploadForm' action='/upload' method='post' encType="multipart/form-data">
           <input type="file" name="file" />
           <input type='submit' value='Upload!' />
       </form>
   </body>
   </html>
   ```

6. **Inicie o Servidor**:

   ```sh
   node server.js
   ```

### Configuração da Função Lambda com Terraform

1. **Crie o Arquivo `lambda.tf`**:

   ```hcl
   data "aws_iam_policy_document" "assume_role" {
     statement {
       effect = "Allow"

       principals {
         type        = "Service"
         identifiers = ["lambda.amazonaws.com"]
       }

       actions = ["sts:AssumeRole"]
     }
   }

   resource "aws_iam_role" "iam_for_lambda" {
     name               = "iam_${var.nome_do_projeto}"
     assume_role_policy = data.aws_iam_policy_document.assume_role.json
   }

   resource "aws_iam_role_policy_attachment" "lambda_policy" {
     role       = aws_iam_role.iam_for_lambda.name
     policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
   }

   resource "aws_iam_role_policy_attachment" "lambda_s3_policy" {
     role       = aws_iam_role.iam_for_lambda.name
     policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
   }

   resource "aws_iam_role_policy_attachment" "lambda_ssm_policy" {
     role       = aws_iam_role.iam_for_lambda.name
     policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
   }

   resource "aws_iam_policy" "lambda_route53_policy" {
     name        = "lambda_route53_policy"
     description = "Permissões para modificar registros no Route 53"
     policy      = jsonencode({
       Version = "2012-10-17",
       Statement = [
         {
           Effect = "Allow",
           Action = [
             "route53:ChangeResourceRecordSets"
           ],
           Resource = "arn:aws:route53:::hostedzone/${var.hosted_zone_id}"
         }
       ]
     })
   }

   resource "aws_iam_role_policy_attachment" "lambda_route53_policy_attachment" {
     role       = aws_iam_role.iam_for_lambda.name
     policy_arn = aws_iam_policy.lambda_route53_policy.arn
   }

   resource "aws_lambda_function" "test_lambda" {
     filename         = "lambda_function.zip"
     function_name    = var.nome_do_projeto
     role             = aws_iam_role.iam_for_lambda.arn
     handler          = var.handler
     runtime          = var.runtime
     timeout          = 30  # Configura o tempo de execução para 30 segundos
     source_code_hash = filebase64sha256("lambda_function.zip")
     environment {
       variables = {
         BUCKET_NAME      = "bucket-teste124"
         EC2_INSTANCE_ID  = "i-012f93c88348a7b57"
         HOSTED_ZONE_ID   = var.hosted_zone_id
       }
     }
   }

   resource "aws_s3_bucket_notification" "bucket_notification" {
     bucket = "bucket-teste124"

     lambda_function {
       lambda_function_arn = aws_lambda_function.test_lambda.arn
       events              = ["s3:ObjectCreated:*"]
     }

     depends_on = [aws_lambda_permission.allow_s3]
   }

   resource "aws_lambda_permission" "allow_s3" {
     statement_id  = "AllowS3Invoke"
     action        = "lambda:InvokeFunction"
     function_name = aws_lambda_function.test_lambda.function_name
     principal     = "s3.amazonaws.com"
     source_arn    = "arn:aws:s3:::bucket-teste124"
   }
   ```

2. **Defina as Variáveis no `variables.tf`**:

   ```hcl
   variable "nome_do_projeto" {
     description = "Nome do projeto"
     type        = string
   }

   variable "handler" {
     description = "Handler da função Lambda"
     type        = string
     default     = "ssm-ec2.lambda_handler"
   }

   variable "runtime" {
     description = "Runtime da função Lambda"
     type        = string
     default     = "python3.8"
   }

   variable "hosted_zone_id" {
     description = "ID da Hosted Zone do Route 53"
     type        = string
   }
   ```

3. **Empacote o Código da Lambda**:

   ```sh
   zip lambda_function.zip ssm-ec2.py
   ```

4. **Inicialize e Aplique o Terraform**:

   ```sh
   terraform init
   terraform apply
   ```

## Teste

1. **Acesse o Formulário de Upload**:
   - Abra o navegador e vá para `http://localhost:3001`.
   - Selecione um arquivo `.zip` e clique no botão "Upload".

2. **Verifique o Bucket S3**:
   - Verifique se o arquivo foi carregado corretamente no bucket S3.

3. **Verifique a Função Lambda**:
   - Verifique os logs no CloudWatch para garantir que a função Lambda foi acionada e processou o arquivo corretamente.

4. **Verifique o Registro DNS**:
   - Verifique se o registro DNS foi criado no Route 53.

##rondaod o front

npm install winston

se precisar entre no direotiro do backend e frontend e execute npm install

Navegue até a pasta do projeto:

 cd s3front

## Script para Iniciar Backend e Frontend

de permissão ao shell iniciar_site.sh e ajuste caso necessário.

Torne o script executável:

chmod +x start_servers.sh

Execute o script:

./start_servers.sh

## Licença

Este projeto está licenciado sob a licença MIT.



