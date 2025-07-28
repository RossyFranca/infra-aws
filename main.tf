# Define as configurações globais do Terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Use uma versão compatível com a sua necessidade
    }
  }
}

# Configura o provedor AWS
provider "aws" {
  region  = var.aws_region
  profile = "default"

  endpoints {
    s3     = "http://localhost:4566" # O endpoint padrão para o S3 no LocalStack
    sts    = "http://localhost:4566"
    lambda = "http://localhost:4566"
    iam    = "http://localhost:4566"
  }
  s3_use_path_style = true
}

resource "aws_s3_bucket" "meu_bucket_localstack" {
  bucket = var.bucket_name # Nome do bucket. Deve ser globalmente único (mesmo no LocalStack).

  tags = {
    Ambiente = "Desenvolvimento"
    Projeto  = "TerraformLocalStack"
  }
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.lambda_function_name}-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_exec_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "minha_lambda_localstack" {
  function_name = var.lambda_function_name
  filename      = "lambda_extract_function.zip"       
  handler       = "lambda_extract_function.lambda_handler" 
  runtime       = "python3.9"           # O runtime do seu código Python
  memory_size   = 128
  timeout       = 30
  role          = aws_iam_role.lambda_exec_role.arn # Referencia o ARN da Role criada acima

  # Garante que a Lambda é criada após a Role
  depends_on = [aws_iam_role.lambda_exec_role]

  provider = aws # Garante que está usando a configuração do provider LocalStack
}

# 5. Recurso: Permissão para o S3 invocar a Lambda
resource "aws_lambda_permission" "allow_s3_to_invoke_lambda" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.minha_lambda_localstack.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.meu_bucket_localstack.arn # ARN do seu bucket S3

  # Garante que a permissão é criada após a Lambda
  depends_on = [aws_lambda_function.minha_lambda_localstack]
}

# 6. Recurso: Configuração de Notificação do S3 para a Lambda
resource "aws_s3_bucket_notification" "s3_to_lambda_notification" {
  bucket = aws_s3_bucket.meu_bucket_localstack.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.minha_lambda_localstack.arn
    events              = ["s3:ObjectCreated:*"] # Aciona a Lambda quando um objeto é criado
    filter_suffix       = ".csv"
  }

  # Garante que a notificação é configurada após a permissão
  depends_on = [aws_lambda_permission.allow_s3_to_invoke_lambda]
}
