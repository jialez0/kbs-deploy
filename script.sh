#!/bin/bash

DOCKER0_IP=$(ifconfig docker0 | grep "inet " | awk '{print $2}')

function deploy {
  if [ ! -d "./data" ] || [! -e "root.crt"]; then
    rm -rf data
    mkdir data
    openssl genpkey -algorithm ed25519 > data/private.key
    openssl pkey -in data/private.key -pubout -out data/public.pub
    echo "Generate User key pair (Ed25519) successfully"

    openssl genpkey -algorithm ed25519 > root.key
    openssl req -new -key root.key -out root.csr -subj "/C=CN/ST=Shanghai/L=Shanghai/O=Alibaba/OU=Aliyun/CN=KBS-root"
    openssl x509 -req -in root.csr -signkey root.key -out root.crt -extfile /etc/ssl/openssl.cnf -extensions v3_req

    openssl genpkey -algorithm ed25519 > data/server.key
    openssl req -new -key data/server.key -out data/server.csr -subj "/C=CN/ST=Shanghai/L=Shanghai/O=Alibaba/OU=Aliyun/CN=KBS-server"
    openssl x509 -req -in data/server.csr -CA root.crt -CAkey root.key -CAcreateserial -out data/server.crt -extfile ssl.conf -extensions req_ext
    echo "Generate KBS certificate (x.509) successfully"

    rm -rf root.key
    rm -rf root.csr
  fi

  tar xzf rvp/rvps-client-0.1.0-an8.tar.gz -C /usr/local/bin/ 
  tar xzf aas-client.tar.gz -C /usr/local/bin/

  sed -i "s/DOCKER0_IP/$DOCKER0_IP/g" configs/sgx_default_qcnl.conf

  echo "Deploy KBS container group..."
  docker-compose up -d
}

function stop {
    docker-compose stop
}

function restart {
    docker-compose restart
}

function clean {
    docker-compose stop
    docker-compose rm -f
    rm -rf data
    rm -rf root.crt
    rm -rf /usr/local/bin/rvps-client
    rm -rf /usr/local/bin/aas-client
    echo "Clean all. Done."
}

function set_rv {
    provenance=$(cat rv.json | base64 --wrap=0)
    echo "Set reference data: $(cat rv.json)"
    sed -i "s/provenance/$provenance/g" rvp/req_payload
    rvps-client register --path ./rvp/req_payload --addr http://127.0.0.1:50004
}

function set_key {
    local key_tag=""
    local key_file=""
    while [ $# -gt 0 ]; do
    case "$1" in
      --key-tag)
        key_tag="$2"
        shift
        ;;
      --key-file)
        key_file="$2"
        shift
        ;;
      *)
        echo "Invalid option: $1"
        exit 1
        ;;
    esac
    shift
  done
    aas-client --url http://127.0.0.1:8080 config --auth-private-key ./data/private.key set-resource --resource-file $key_file --path $key_tag
}

function show_help {
  echo "Usage: ./script.sh <command>"
}

function main {
  case "$1" in
    deploy)
      deploy
      ;;
    clean)
      clean
      ;;
    stop)
      stop
      ;;
    restart)
      restart
      ;;
    set_rv)
      set_rv
      ;;
    set_key)
      shift
      set_key "$@"
      ;;
    *)
      show_help
      ;;
  esac
  exit 0
}

main "$@"