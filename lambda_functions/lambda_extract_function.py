import json
import traceback # Importe traceback para detalhes do erro

def lambda_handler(event, context):
    """
    Função Lambda que processa eventos de criação de objeto no S3.
    Ela extrai o nome do bucket e a chave do objeto (nome do arquivo)
    do evento e os imprime, retornando um resumo do processamento.
    """
    print("Iniciando a execução da função Lambda para extrair nome do arquivo.")

    processed_files = [] # Para armazenar os detalhes dos arquivos processados

    try:
        if 'Records' not in event:
            print("Aviso: Nenhum 'Records' encontrado no evento. Não é um evento S3 esperado.")
            return {
                'statusCode': 400,
                'body': json.dumps({'message': 'Nenhum registro de S3 encontrado no evento ou formato inesperado.'})
            }

        for record in event['Records']:
            # Verifica se o registro é de um evento S3 e tem as chaves esperadas
            if 's3' in record and 'bucket' in record['s3'] and 'object' in record['s3']:
                bucket_name = record['s3']['bucket']['name']
                object_key = record['s3']['object']['key']

                print(f"Evento S3 recebido para o arquivo: s3://{bucket_name}/{object_key}")

                # Em um cenário real, aqui você faria o processamento do arquivo
                # Por exemplo, baixar o arquivo, analisá-lo, etc.
                # Para este exemplo, apenas registramos que ele foi "processado"
                processed_files.append({
                    'fileName': object_key,
                    'bucketName': bucket_name,
                    'status': 'Processed'
                })
            else:
                print(f"Aviso: Registro do evento não contém informações esperadas do S3: {json.dumps(record)}")
                processed_files.append({
                    'record': record,
                    'status': 'Skipped - Invalid S3 Event'
                })

        # Retorna um resumo após tentar processar todos os registros
        if processed_files:
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'Processamento de evento S3 concluído.',
                    'processedFiles': processed_files
                })
            }
        else:
            # Caso não haja registros S3 válidos após iterar por todos
            print("Nenhum registro S3 válido foi processado no evento.")
            return {
                'statusCode': 200, # Ou 204 No Content, dependendo da sua API
                'body': json.dumps({'message': 'Nenhum registro S3 válido encontrado para processamento.'})
            }

    except Exception as e:
        # Captura qualquer exceção não tratada e a imprime para depuração
        print(f"ERRO: Ocorreu uma exceção durante a execução da Lambda: {e}")
        print(traceback.format_exc()) # Imprime o stack trace completo para ajudar a depurar
        return {
            'statusCode': 500,
            'body': json.dumps({'message': f'Erro interno da Lambda: {e}'})
        }