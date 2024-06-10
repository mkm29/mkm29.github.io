#!/bin/bash

# Set color variables
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
PINK=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
NC='\e[0m'

# Function to print info message
info() {
  echo "${GREEN}[INFO]  ${WHITE}$1" 1>&2
}

# Function to print error message
error() {
  echo "${RED}[ERROR] ${WHITE}$1" 1>&2
}

# Function to print warning message
warn() {
  echo "${YELLOW}[WARN]  ${WHITE}$1" 1>&2
}

# Function to print debug message
debug() {
  echo "${BLUE}[DEBUG] ${WHITE}$1" 1>&2
}

has_argument() {
    [[ ("$1" == *=* && -n ${1#*=}) || ( ! -z "$2" && "$2" != -*)  ]];
}

extract_argument() {
  echo "${2:-${1#*=}}"
}

setup() {
  # set default values
  CHALLENGE="DNS"
  KEY_SIZE=4096
  STAGING=false
  PRODUCTION=true
  DOMAINS=()
  EMAIL=""
  # make sure that certbot is installed
  if ! [ -x "$(command -v certbot)" ]; then
    error "certbot is not installed"
    exit 1
  fi
}

parse_args() {
  # parse arguments
  while [ "$1" != "" ]; do
      case $1 in
      --domains )
        shift
        DOMAINS=($1)
        ;;
      --email )
        shift
        EMAIL=$1
        ;;
      --staging )
          STAGING=true
          ;;
      --production )
          PRODUCTION=true
          ;;
      --challenge )
        shift
        CHALLENGE=$1
        ;;
      --key-size )
          shift
          KEY_SIZE=$1
          ;;
      -h | --help )
        usage
        exit
        ;;
      * )
        exit 1
      esac
      shift
  done
}

usage() {
  info "Get a certificate from letsencrypt"
  info "Usage: $0 [OPTIONS]"
  echo
  info "Options:"
  echo
  info "-h, --help                   Display this help message"
  info "    --domains               List of domains to make a cert for"
  info "    --email                 Email to use for letsencrypt"
  info "    --staging               Use the staging server"
  info "    --production            Use the production server"
  info "    --challenge             Challenge type to use (DNS or HTTP)"
  info "    --key-size              Size of the key to generate (default: 4096)"
}

main() {
  echo "${GREEN}Welcome to letsencrypt.sh, setting up..." 1>&2
  setup
  parse_args "$@"
  local errs=false

  if [ ${#DOMAINS[@]} -eq 0 ]; then
    # echo "No domains specified"
    error "No domains specified"
    errs=true
  fi

  if [ -z "$EMAIL" ]; then
    # echo "No email specified"
    error "No email specified"
    errs=true
  fi
  if [ "$errs" = true ]; then
    echo "Errors found, exiting"
    exit 1
  fi

  if [ "$STAGING" = true ]; then
    SERVER="https://acme-staging-v02.api.letsencrypt.org/directory"
  fi

  if [ "$PRODUCTION" = true ]; then
    SERVER="https://acme-v02.api.letsencrypt.org/directory"
  fi

  if [ "$CHALLENGE" = "DNS" ]; then
    CHALLENGE="dns"
  fi

  if [ "$CHALLENGE" = "HTTP" ]; then
    CHALLENGE="http"
  fi

  # print_vars
  certbot certonly --manual --preferred-challenges $CHALLENGE --email $EMAIL --server $SERVER --rsa-key-size=$KEY_SIZE --agree-tos -d ${DOMAINS[@]}
}

# Main script execution
main "$@"