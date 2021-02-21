#!/bin/bash

# Carrega as variaveis settings.sh
source /vagrant/settings.sh

CLUSTER_DB="BD"
POTSGRES_USER="postgres"

configura_bd_dir(){
    # Create the file repository configuration:
    sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
    curl https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo apt-key add

    # Import the repository signing key:
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
    sudo sh -c 'echo "deb https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list && apt update'

    # Atualizando repositorios 
    apt-get update 
    apt-get upgrade 
}

carrega_pacotes(){
    # Instalando pacotes 
    apt-get -y install postgresql
    apt-get -y install ${PACKAGES}
}

# Verifica a versão do postgresql
verifica_versao_db() {
    export PG_VERSAO 
    PG_VERSAO=$(pg_config --version | cut -d' ' -f2)
}

# Verifica se o diretório padrão do postgresql já existe
verifica_db() {
    declare -g DATABASE_EXISTE
    export PGDIR="/etc/postgresql"
    
    if [ -s "${PG_DIR}/${PG_VERSAO:0:2}"];then
        DATABASE_EXISTE="true"
    fi
}

# Altera variaveis padrão do POSTGRESQL
altera_arquivo_config_pg() {
    echo "Alterando arquivos de configuracao"
    
    sed -i 's/ssl = on/ssl = off/g' /etc/postgresql/${PG_VERSAO:0:2}/${CLUSTER_DB}/postgresql.conf 
    sed -i 's/#listen_addresses = 'localhost'/listen_addresses = '*'/g' /etc/postgresql/${PG_VERSAO:0:2}/${CLUSTER_DB}/postgresql.conf 
    echo "host  all  all  0.0.0.0/0  md5" >> /etc/postgresql/${PG_VERSAO:0:2}/${CLUSTER_DB}/pg_hba.conf
}

_main(){
    verifica_versao_db
    verifica_db
    # Se o diretorio do BD nao existir
    if [ -z "${DATABASE_EXISTE}" ]; then 
        mkdir /home/${POTSGRES_USER}

        sudo useradd -m ${POTSGRES_USER}
        sudo usermod -a -G sudo ${POTSGRES_USER}
        # Definindo diretorio padrao para o usuario postgres
        sudo usermod -d /home/${POTSGRES_USER} ${POTSGRES_USER}
        sudo chown -R ${POTSGRES_USER} /home/${POTSGRES_USER}

        sudo su ${POTSGRES_USER}
        
        mkdir /home/${POTSGRES_USER}/BD

        configura_bd_dir
        carrega_pacotes
        verifica_versao_db
        
        #Criando um cluster PostgreSQL
        pg_createcluster -d /home/${POTSGRES_USER}/BD ${PG_VERSAO:0:2} ${CLUSTER_DB} --start

        # Configurando enderecos IP para a conexao ao Banco de Dados
        altera_arquivo_config_pg

        # Reiniciando o serviço
        service postgresql restart
    fi
}

_main