#!/bin/bash

PRETTY_PASS="\e[32m✔ \e[0m"
function print_pass() {
  printf "${PRETTY_PASS}%s\n" "${1}"
}
PRETTY_ERROR="\e[31m✘ \e[0m"
function print_error() {
  printf "${PRETTY_ERROR}%s\n" "${1}"
}
PRETTY_CODE="\e[1;100;37m"
function print_code() {
	printf "${PRETTY_CODE}%s\e[0m\n" "${1}"
}
function print_process_start() {
	printf "⌛ %s\n" "${1}"
}
function print_code_pass() {
  local MESSAGE=""
	local CODE=""
  OPTIND=1
  while getopts ":c:m:" opt; do
    case ${opt} in
			c ) CODE=${OPTARG};;
      m ) MESSAGE=${OPTARG};;
		esac
	done
  shift $((OPTIND-1))
	printf "${PRETTY_PASS}${PRETTY_CODE}%s\e[0m\n" "${CODE}"
	[[ -z "$MESSAGE" ]] || printf "\t$MESSAGE\n"			
}
function print_code_error() {
  local MESSAGE=""
	local CODE=""
  OPTIND=1
  while getopts ":c:m:" opt; do
    case ${opt} in
			c ) CODE=${OPTARG};;
      m ) MESSAGE=${OPTARG};;
		esac
	done
  shift $((OPTIND-1))
	printf "${PRETTY_ERROR}${PRETTY_CODE}%s\e[0m\n" "${CODE}"
	[[ -z "$MESSAGE" ]] || printf "\t$MESSAGE\n"			
}

function exit_with_error()
{
  local USAGE="\nUsage: exit_with_error -c code -n name -m message -l line_number\n"
  local NAME=""
  local MESSAGE=""
  local CODE=$UNSPECIFIED_ERROR
  local LINE=
  OPTIND=1
  while getopts ":n:m:c:l:" opt; do
    case ${opt} in
      n ) NAME=${OPTARG};;
      m ) MESSAGE=${OPTARG};;
      c ) CODE=${OPTARG};;
      l ) LINE=${OPTARG};;
      ? ) printf $USAGE;return 1;;
    esac
  done
  shift $((OPTIND-1))
  print_error "error ${CODE} occurred in ${NAME} at line $LINE"
	printf "\t${MESSAGE}\n"
  exit $CODE
}


printf "\nUpdating and installing required packages\n"
CMD="sudo apt-get update && sudo apt-get install -q -y jq apache2 python3-pip libapache2-mod-wsgi-py3 python3-confluent-kafka python3-avro python3-flask python3-flask-cors python3-werkzeug python3-rjsmin python3-rcssmin python3-requests certbot python3-certbot-apache docker-compose"
eval $CMD \
  && print_code_pass -c "$CMD" \
    || exit_with_error -c $? -n "$NAME" -m "$CMD" -l $(($LINENO -3))


printf "\nInstalling filebeat\n"
CMD="curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.2.2-amd64.deb && sudo dpkg -i filebeat-8.2.2-amd64.deb && rm filebeat-8.2.2-amd64.deb"
eval $CMD \
  && print_code_pass -c "$CMD" \
    || exit_with_error -c $? -n "$NAME" -m "$CMD" -l $(($LINENO -3))

printf "\nStaring local Splunk instance using docker-compose\n"
CMD="sudo docker-compose up -d"
eval $CMD \
  && print_code_pass -c "$CMD" \
    || exit_with_error -c $? -n "$NAME" -m "$CMD" -l $(($LINENO -3))

printf "\nSetting up website configuration\n"
SEDCMD="s/===WEBHOSTNAME===/$WEBHOSTNAME/g"
CMD="sed -e $SEDCMD cwd/apache2/sites-available/wordle.conf > wordle.conf && sudo cp wordle.conf /etc/apache2/sites-available/ && sudo cp -r cwd/wsgi /var/www/wsgi && sudo chown -R www-data:www-data /var/www/wsgi && sudo a2ensite wordle && sudo a2enmod rewrite proxy proxy_http && sudo systemctl reload apache2 && sudo certbot --non-interactive --apache --agree-tos -m $YOUREMAIL -d $WEBHOSTNAME"
eval $CMD \
  && print_code_pass -c "$CMD" \
    || exit_with_error -c $? -n "$NAME" -m "$CMD" -l $(($LINENO -3))

printf "\nAdding ccloud python config to Wordle app\n"
sudo sh -c 'awk "/^producer = Producer/,/})/" delta_configs/python.delta | awk "!/(plugin|location|configuration)/" > /var/www/wsgi/cwd/kafka.config'
sudo sed -i "/###PRODUCER START###/r /var/www/wsgi/cwd/kafka.config" /var/www/wsgi/cwd/app.py
sudo sh -c 'cd /var/www/wsgi/cwd && python3 init.py && chown -R www-data:www-data .'
sudo systemctl restart apache2
:
printf "\nConfiguring filebeat to send to CC\n"
sudo cp filebeat.yml /etc/filebeat/filebeat.yml
sudo cp filebeat.apache.yml /etc/filebeat/modules.d/apache.yml
sudo sed -i "s ###BOOTSTRAP### $BOOTSTRAP_SERVERS " /etc/filebeat/filebeat.yml
sudo sed -i "s ###USERNAME### $CLOUD_KEY " /etc/filebeat/filebeat.yml
sudo sed -i "s ###PASSWORD### $CLOUD_SECRET " /etc/filebeat/filebeat.yml
sudo systemctl restart filebeat