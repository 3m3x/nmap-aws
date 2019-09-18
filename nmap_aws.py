import subprocess
import os



def lambda_handler(event, context):
    nmap_args = event['args'].split()
    cmd = ['./nmap'] + nmap_args
    out = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

    print(out.stdout.decode())
    return {
        'statusCode': 200,
        'body': out.stdout.decode()
    }
