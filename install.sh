#!/bin/bash

# Carrega as variaveis settings.sh
source settings.sh

CLUSTER_DB = "main"

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
    apt-get -y install postgresql pgadmin4
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
    
    if [ -s "${PG_DIR}/${PG_VERSAO}"];then
        DATABASE_EXISTE="true"
    fi
}

_main(){
    verifica_versao_db
    verifica_db
    # Se o diretorio do BD nao existir
    if [ -z "${DATABASE_EXISTE}" ]; then 
        sudo useradd -m ${POTSGRES_USER}
        sudo passwd ${POTSGRES_USER}
        sudo usermod -a -G sudo ${POTSGRES_USER}
        
        mkdir /home/postgres
        mkdir /home/postgres/BD

        su - ${POTSGRES_USER}
        
        configura_bd_dir
        carrega_pacotes
        verifica_versao_db
        
        #Criando um cluster PostgreSQL
        pg_createcluster -d /home/postgres/BD ${PG_VERSAO:0:2} ${CLUSTER_DB} --start

        # Configurando enderecos IP para a conexao ao Banco de Dados
        echo "listen_addresses = '*'" >> ${PG_DIR}/${PG_VERSAO:0:2}/${CLUSTER_DB}/"postgresql.conf"
        
        service postgresql restart

        # Incluindo pgadmin na inicialização do server
        update-rc.d postgresql defaults
        update-rc.d pgadmin4 defaults
        postgresql &
        pgadmin4 &
    fi
}

_main