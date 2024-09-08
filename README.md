# Projeto de Upload para S3 e Configuração de Lambda

Este projeto  permite aos usuários fazer upload de arquivos `.zip` para um bucket S3. Além disso, há uma função Lambda configurada para processar esses arquivos, descompactá-los em uma instância EC2, configurar um servidor web Apache e criar um registro DNS no Route 53.

## Funcionalidades

1. **Upload de Arquivos para S3**:
   - Um servidor Node.js com um formulário HTML permite que os usuários façam upload de arquivos `.zip` para um bucket S3.

2. **Processamento de Arquivos com Lambda**:
   - Uma função Lambda é acionada quando um novo arquivo é carregado no bucket S3.
   - A função Lambda descompacta o arquivo em uma instância EC2, configura um servidor web Apache e cria um registro DNS no Route 53.

## Estrutura do Projeto

- `index.html`: Formulário HTML para upload de arquivos.
- `ssm-ec2.py`: Código da função Lambda que processa os arquivos carregados.
- `lambda.tf`: Arquivo Terraform para configurar a função Lambda e suas permissões.

## Configuração

### Pré-requisitos

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
     filename         = "nomeDoseu.zip"
     function_name    = var.nome_do_projeto
     role             = aws_iam_role.iam_for_lambda.arn
     handler          = var.handler
     runtime          = var.runtime
     timeout          = 30  # Configura o tempo de execução para 30 segundos
     environment {
       variables = {
         BUCKET_NAME      = "seu-bucket"
         EC2_INSTANCE_ID  = "id-do-ec2"
         HOSTED_ZONE_ID   = var.hosted_zone_id
       }
     }
   }

   resource "aws_s3_bucket_notification" "bucket_notification" {
     bucket = "seu-bucket"

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
     source_arn    = "arn:aws:s3:::seu-bucket"
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
     default     = "colocar seu id aqui"
   }
   ```

3. **Empacote o Código da Lambda**:

   ```sh
   zip seu-codigo.zip ssm-ec2.py
   ```
   ps: Crie o zip do seu codigo com o nome que quer para seu site.

4. **Inicialize e Aplique o Terraform**:

   ```sh
   terraform init
   terraform apply
   ```

## Teste

1. **Acesse o S3 para Upload**: 
   - Selecione um arquivo `.zip` que seja Aquivo.zip > aquivo > conteudos do site, clique no botão "Upload" e envie para seu s3.

2. **Verifique o Bucket S3**:
   - Verifique se o arquivo foi carregado corretamente no bucket S3.

3. **Verifique a Função Lambda**:
   - Verifique os logs no CloudWatch para garantir que a função Lambda foi acionada e processou o arquivo corretamente.

4. **Verifique o Registro DNS**:
   - Verifique se o registro DNS foi criado no Route 53.

Este projeto está licenciado sob a licença MIT.