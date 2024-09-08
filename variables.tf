#Aqui temos as variaveis que estou utilizando, você pode criar mais variaveis para facilitar no script.

variable "tag_name" {
  description = "Nome da instancia"
  type        = string
  default     = "sites"  
}
variable "tag_app" {
  description = "Nome da instancia"
  type        = string
  default     = "apache"  
}
variable "tag_servico" {
  description = "Nome da instancia"
  type        = string
  default     = "apache"  
}

variable "ami" {
  description = "Id da AMI que será usada no ec2"
  type = string
  default = "ami-03fc6344a8230fbb6"
  
}

variable "instance_type_ec2"{
  description = "Tipo da instancia usada"
  type = string
  default = "t3.micro"
}

variable "meu_ip" {
  description = "Meu endereço IP atual"
  default     = "45.228.245.0"  # Substitua pelo seu endereço IP atual para ser liberado a fazer ssh na maquina
}

variable "sg1" {
  default = "SG-Terraform"
  description = "Nome do SG que vai ser criado"
  
}


variable "nome_do_projeto" {
  description = "nome do projeto"
  type        = string
  default = "sites"
}

variable "handler" {
  description = "Handler da função Lambda"
  type        = string
  default     = "ssm-ec2.lambda_handler"
}

variable "runtime" {
  description = "Runtime da função Lambda"
  type        = string
  default     = "python3.9"
}

variable "hosted_zone_id" {
  description = "ID da Hosted Zone do Route 53"
  type        = string
  default = "Z09315943W3HUYZ1CG61C"
}