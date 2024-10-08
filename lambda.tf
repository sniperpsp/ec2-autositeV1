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

// Adiciona uma política personalizada para permitir lambda:GetPolicy
resource "aws_iam_policy" "custom_lambda_policy" {
  name        = "CustomLambdaPolicy"
  description = "Permissão para executar lambda:GetPolicy na função sites"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["lambda:GetPolicy"],
        Resource = "arn:aws:lambda:us-east-1:730335588602:function:${var.nome_do_projeto}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_custom_lambda_policy" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.custom_lambda_policy.arn
}

resource "aws_lambda_function" "test_lambda" {
  filename         = "seu-site.zip"
  function_name    = var.nome_do_projeto
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = var.handler
  runtime          = var.runtime
  timeout          = 30  // Configura o tempo de execução para 30 segundos
  environment {
    variables = {
      BUCKET_NAME      = "bucket-teste124"
      EC2_INSTANCE_ID  = "id-da-sua-ec2"
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