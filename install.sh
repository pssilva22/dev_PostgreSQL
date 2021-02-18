#!/bin/bash

# Carrega as variaveis settings.sh
source /vagrant/settings.sh

CLUSTER_DB = "main"

configura_bd_dir(){
    # Configurando repositorios
    touch /etc/apt/sources.list.d/pgdg.list
    echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

    # Atualizando repositorios 
    apt update --yes
    apt upgrade --yes
}

carrega_pacotes(){
    # Instalando pacotes 
    apt install --yes postgresql postgresql-commom pgadmin4
    apt install --yes ${PACKAGES}
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
        sudo su 
        add user ${POTSGRES_USER}
        usermod -aG sudo ${POTSGRES_USER}
        
        su - ${POTSGRES_USER}
        
        configura_bd_dir
        carrega_pacotes
        verifica_versao_db
        
        #Criando um cluster PostgreSQL
        pg_createcluster -d /home/postgres/BD ${PG_VERSAO:0:2} CLUSTER_DB --start

        # Configurando enderecos IP para a conexao ao Banco de Dados
        echo "listen_addresses = '*'" >> /etc/postgresql/${PG_VERSAO}/${CLUSTER_DB} 

        # Incluindo pgadmin na inicialização do server
        update-rc.d postgresql defaults
        update-rc.d pgadmin4 defaults
        postgresql &
        pgadmin4 &
    fi
}

_main