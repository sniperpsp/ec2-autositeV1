import json
import boto3
import os
import time

ssm_client = boto3.client('ssm')
s3_client = boto3.client('s3')
ec2_client = boto3.client('ec2')
route53_client = boto3.client('route53')

# Configurações
BUCKET_NAME = os.environ['BUCKET_NAME']
EC2_INSTANCE_ID = os.environ['EC2_INSTANCE_ID']
HOSTED_ZONE_ID = os.environ['HOSTED_ZONE_ID']

def lambda_handler(event, context):
    print("Iniciando a função Lambda")
    
    # Listar objetos no bucket S3 e obter o mais recente
    response = s3_client.list_objects_v2(Bucket=BUCKET_NAME)
    if 'Contents' not in response:
        print("Nenhum arquivo encontrado no bucket.")
        return {
            'statusCode': 400,
            'body': json.dumps('Nenhum arquivo encontrado no bucket.')
        }
    
    # Ordenar objetos por data de modificação e obter o mais recente
    latest_object = max(response['Contents'], key=lambda x: x['LastModified'])
    s3_object = latest_object['Key']
    print(f"Arquivo mais recente encontrado: {s3_object}")
    
    if not s3_object.endswith('.zip'):
        print("O arquivo mais recente não é um ZIP.")
        return {
            'statusCode': 400,
            'body': json.dumps('O arquivo mais recente não é um ZIP.')
        }
    
    # Extrair a variável do nome do arquivo
    variavel = os.path.splitext(os.path.basename(s3_object))[0]
    print(f"Variável extraída do nome do arquivo: {variavel}")
    
    # Obter o endereço IP público da instância EC2
    ec2_response = ec2_client.describe_instances(InstanceIds=[EC2_INSTANCE_ID])
    public_ip = ec2_response['Reservations'][0]['Instances'][0]['PublicIpAddress']
    print(f"Endereço IP público da instância EC2: {public_ip}")
    
    # Comandos a serem executados na instância EC2
    commands = [
        f'sudo mkdir -p /var/www/html/{variavel}/public_html',
        f'sudo unzip /mnt/s3bucket/{s3_object} -d /var/www/html/{variavel}/temp',
        f'sudo mv /var/www/html/{variavel}/temp/{variavel}/* /var/www/html/{variavel}/public_html/',
        f'sudo rm -rf /var/www/html/{variavel}/temp',
        f'sudo bash -c "cat > /etc/httpd/conf.d/{variavel}.com.conf <<EOL\n'
        f'<VirtualHost *:80>\n'
        f'    ServerAdmin webmaster@{variavel}.trustcompras.com.br\n'
        f'    ServerName {variavel}.trustcompras.com.br\n'
        f'    ServerAlias www.{variavel}.trustcompras.com.br\n'
        f'    DocumentRoot /var/www/html/{variavel}/public_html\n'
        f'    ErrorLog /var/log/httpd/{variavel}.com-error.log\n'
        f'    CustomLog /var/log/httpd/{variavel}.com-access.log combined\n'
        f'    <Directory /var/www/html/{variavel}/public_html>\n'
        f'        Options Indexes FollowSymLinks\n'
        f'        AllowOverride All\n'
        f'        Require all granted\n'
        f'    </Directory>\n'
        f'</VirtualHost>\n'
        f'EOL"',
        'sudo systemctl restart httpd'
    ]
    
    # Executar os comandos na instância EC2 via SSM
    response = ssm_client.send_command(
        InstanceIds=[EC2_INSTANCE_ID],
        DocumentName="AWS-RunShellScript",
        Parameters={'commands': commands}
    )
    
    command_id = response['Command']['CommandId']
    print(f"Comando SSM enviado. Command ID: {command_id}")
    
    # Adicionar um pequeno atraso antes de começar a verificar o status do comando
    time.sleep(5)
    
    # Esperar até que o comando seja concluído
    while True:
        try:
            output = ssm_client.get_command_invocation(
                CommandId=command_id,
                InstanceId=EC2_INSTANCE_ID,
            )
            if output['Status'] not in ['Pending', 'InProgress']:
                break
        except ssm_client.exceptions.InvocationDoesNotExist:
            # Se a invocação não existir, esperar um pouco e tentar novamente
            time.sleep(2)
            continue
        time.sleep(2)  # Esperar 2 segundos antes de verificar novamente
    
    print("Comando SSM concluído.")
    
    # Criar o registro DNS no Route 53
    try:
        route53_response = route53_client.change_resource_record_sets(
            HostedZoneId=HOSTED_ZONE_ID,
            ChangeBatch={
                'Changes': [
                    {
                        'Action': 'UPSERT',
                        'ResourceRecordSet': {
                            'Name': f'{variavel}.seu-dominio-aqui.com.br',
                            'Type': 'A',
                            'TTL': 300,
                            'ResourceRecords': [{'Value': public_ip}]
                        }
                    }
                ]
            }
        )
        print(f"Registro DNS criado: {route53_response}")
    except Exception as e:
        print(f"Erro ao criar o registro DNS: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps(f"Erro ao criar o registro DNS: {e}")
        }
    
    return {
        'statusCode': 200,
        'body': json.dumps('Processo concluído com sucesso.'),
        'output': output
    }