
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