from mesh_client import MeshClient, Message
from secrets import SsmSecretManager
import os
import boto3

def build_mesh_client(secret_manager: SsmSecretManager, mesh_mailbox_name: str):
    mesh_url = os.environ["MESH_URL"]

    mesh_client_cert_path = "/tmp/client_cert.pem"
    mesh_client_key_path = "/tmp/client_key.pem"
    mesh_ca_cert_path = "/tmp/ca_cert.pem"

    secret_manager.download_secret(os.environ["MESH_CLIENT_CERT_SSM_PARAM_NAME"], mesh_client_cert_path)
    secret_manager.download_secret(os.environ["MESH_CLIENT_KEY_SSM_PARAM_NAME"], mesh_client_key_path)
    secret_manager.download_secret(os.environ["MESH_CA_CERT_SSM_PARAM_NAME"], mesh_ca_cert_path)

    mesh_password = secret_manager.get_secret(os.environ["MESH_PASSWORD_SSM_PARAM_NAME"])
    mesh_shared_key = secret_manager.get_secret(os.environ["MESH_SHARED_KEY_SSM_PARAM_NAME"])

    client = MeshClient(
        url=mesh_url,
        mailbox=mesh_mailbox_name,
        password=mesh_password,
        shared_key=bytes(mesh_shared_key, "utf-8"),
        verify= mesh_ca_cert_path,
        cert=(mesh_client_cert_path, mesh_client_key_path)
        )

    client.handshake()
    return client


def send_mesh_message(event, context):
    ssm = boto3.client("ssm")
    secret_manager = SsmSecretManager(ssm)
    mesh_mailbox_name = secret_manager.get_secret(os.environ["MESH_MAILBOX_SSM_PARAM_NAME"])
    
    client = build_mesh_client(secret_manager, mesh_mailbox_name)

    message = """HR,XXXXXX,000000000,"Testing3_9.7.14.0200 (45191)",122001000000000,2021-29-01,5.0,99,4.5,,"""
    client.send_message(mesh_mailbox_name, bytes(message, 'utf-8'), filename=event["file_name"])
    print("Message sent")