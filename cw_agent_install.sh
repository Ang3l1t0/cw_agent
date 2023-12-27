 #!/bin/bash

# Paso 1: Descargar el paquete del agente CloudWatch según la arquitectura
if [[ $(arch) == "x86_64" ]]; then
    wget https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
elif [[ $(arch) == "aarch64" ]]; then
    wget https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/arm64/latest/amazon-cloudwatch-agent.deb
else
    echo "Arquitectura no compatible."
    exit 1
fi

# Paso 2: Instalar el paquete del agente CloudWatch
sudo dpkg -i -E ./amazon-cloudwatch-agent.deb

# Paso 3: Crear el archivo de configuración /opt/aws/amazon-cloudwatch-agent/bin/config.json
cat <<EOF | sudo tee /opt/aws/amazon-cloudwatch-agent/bin/config.json > /dev/null
{
    "agent": {
        "metrics_collection_interval": 300,
        "run_as_user": "root",
        "region": "us-east-2"
    },
    "metrics": {
        "namespace": "CWAgent",
        "append_dimensions": {
            "InstanceId": "\${aws:InstanceId}"
        },
        "aggregation_dimensions": [["InstanceId"]],
        "metrics_collected": {
            "mem": {
                "measurement": [
                    {"name": "mem_used_percent", "unit": "Percent"}
                ],
                "resources": ["*"]
            },
            "cpu": {
                "measurement": [
                    {"name": "cpu_usage_user", "unit": "Percent"}
                ],
                "resources": ["*"],
                "totalcpu": true
            },
            "disk": {
                "measurement": [
                    {"name": "disk_used_percent", "unit": "Percent"}
                ],
                "resources": ["/"]
            }
        }
    }
}
EOF

# Paso 4: Ejecutar el comando para fetch-config del agente CloudWatch
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s
