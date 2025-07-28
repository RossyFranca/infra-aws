# variables.tf

variable "bucket_name" {
  description = "O nome do bucket S3 a ser criado."
  type        = string
  default     = "bucket-csv1" # Valor padrão para o nome do bucket
  # Você pode remover o 'default' se quiser que o nome seja sempre fornecido manualmente
  # ou via arquivo .tfvars
}

variable "aws_region" {
  description = "A região AWS (ou LocalStack) a ser usada."
  type        = string
  default     = "us-east-1" # Região padrão para o LocalStack
}

variable "lambda_function_name" {
  description = "O nome da função Lambda a ser criada no LocalStack."
  type        = string
  default     = "lambda_handler" # Um nome mais descritivo para a função
}

