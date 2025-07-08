#!/bin/bash

# Exibe uma mensagem para o usuário
echo "Qual opção deseja escolher?"

# Define as opções disponíveis
echo "1. Plan"
echo "2. Apply"
echo "3. Destroy"

# Solicita ao usuário que insira sua escolha
read -p "Escolha uma opção (1 | 2 | 3): " option

# Estrutura de controle 'case' para lidar com as opções
case $option in
    1)
        echo "Executando 'terraform plan'..."
		rm -fr .terraform
		rm -fr .terraform.lock.hcl
		terraform init
        terraform plan
        ;;
    2)
        echo "Executando 'terraform apply'..."
		rm -fr .terraform
        rm -fr .terraform.lock.hcl
		terraform init
        terraform apply -auto-approve
		rm -fr .terraform
        rm -fr .terraform.lock.hcl        
        ;;
	3)
		echo "Executando 'terraform destroy'..."
		rm -fr .terraform
		rm -fr .terraform.lock.hcl
		terraform init
		terraform destroy -auto-approve
        rm -fr .terraform*
        rm -fr terraform*        
		;;
    *)
        echo "Opção inválida. Por favor, escolha 1 ou 2."
        ;;
esac
