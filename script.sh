#!/bin/bash

DOCKER0_IP=$(ifconfig docker0 | grep "inet " | awk '{print $2}')

function deploy {
  if [ ! -d "./data" ]; then
    rm -rf data
    mkdir data
    openssl genpkey -algorithm ed25519 > data/private.key
    openssl pkey -in data/private.key -pubout -out data/public.pub
    echo "Generate User key pair (Ed25519) successfully"

    openssl genpkey -algorithm ed25519 > data/server.key
    openssl req -new -key data/server.key -out data/server.csr -subj "/C=CN/ST=Shanghai/L=Shanghai/O=Alibaba/OU=Aliyun/CN=KBS-server"
    openssl x509 -req -in data/server.csr -CA local_ca/root.crt -CAkey local_ca/root.key -CAcreateserial -out data/server.crt -extfile ssl.conf -extensions req_ext
    echo "Generate KBS certificate (x.509) successfully"
  fi

  tar xzf rvp/rvps-client-0.1.0-an8.tar.gz -C /usr/local/bin/ 
  tar xzf kbs-client.tar.gz -C /usr/local/bin/
  cp local_ca/root.crt /etc/kbs-ca.crt

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
    rm -rf /usr/local/bin/rvps-client
    rm -rf /usr/local/bin/kbs-client
    rm -rf /etc/kbs-ca.crt
    echo "Clean all. Done."
}

function set_rv {
    local rv=""
    while read line
    do
      if [[ ${line:0:1} != "#" ]]
      then
        rv+=$line
      fi
    done < rv.conf
    provenance=$(echo $rv | base64 --wrap=0)
    echo "Set reference data: $rv"
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
    mkdir -p ./data/repository/$(dirname $key_tag) 
    cp $key_file ./data/repository/$key_tag
    # kbs-client --url https://127.0.0.1:8080 --cert-file /etc/kbs-ca.crt config --auth-private-key ./data/private.key set-resource --resource-file $key_file --path $key_tag
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