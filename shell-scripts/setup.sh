#!/bin/sh
# Script para instalar Setup na Vm UBUNTU 18.04

# Atualiza a lista de pacotes
sudo apt-get update -y

# Instala o Nginx
sudo apt-get install nginx -y

# Instala o .NET SDK 8.0
sudo apt-get update -y
sudo apt-get install -y dotnet-sdk-8.0
sudo apt-get install -y aspnetcore-runtime-8.0
sudo apt-get install -y dotnet-runtime-8.0

echo BlobServiceUri="https://upscalingstorageacc921.blob.core.windows.net" >> /etc/environment
echo ContainerName="container-image-1uploadfor-upscalingpj" >> /etc/environment
