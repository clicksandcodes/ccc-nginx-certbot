#!/bin/bash

if ! [ -x "$(command -v docker-compose)" ]; then
  echo 'Error: docker-compose is not installed.' >&2
  exit 1
fi

domains=("${NGINX_HOST}" "www.${NGINX_HOST}")
rsa_key_size=4096
data_path="./data/certbot"
email="${ADMIN_EMAIL}" # Adding a valid address is strongly recommended
# staging=0 # Set to 1 if you're testing your setup to avoid hitting request limits

if [ -d "$data_path" ]; then
  read -p "Existing data found for $domains. Continue and replace existing certificate? (y/N) " decision
  if [ "$decision" != "Y" ] && [ "$decision" != "y" ]; then
    exit
  fi
fi

if [ ! -e "$data_path/conf/options-ssl-nginx.conf" ] || [ ! -e "$data_path/conf/ssl-dhparams.pem" ]; then
  echo "### Downloading recommended TLS parameters ..."
  mkdir -p "$data_path/conf"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "$data_path/conf/options-ssl-nginx.conf"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "$data_path/conf/ssl-dhparams.pem"
  echo
fi

docker exec certbotContainerService sh -c "\
  certbot -vvv certonly --webroot -w /var/www/certbot \
    --email ${ADMIN_EMAIL} \
    -d ${NGINX_HOST} -d www.${NGINX_HOST} -d api.${NGINX_HOST} \
    --rsa-key-size 4096 \
    --agree-tos \
    --force-renewal"

 
docker exec certbotContainerService sh -c "\
  certbot -vvv certonly --expand -d livestauction.com -d pmeaney.com -d www.pmeaney.com -d api.pmeaney.com"

echo "### Reloading nginx ..."
docker restart nginxContainerService

# echo "### Creating dummy certificate for $domains ..."
# path="/etc/letsencrypt/live/$domains"
# mkdir -p "$data_path/conf/live/$domains"
# docker-compose run --rm --entrypoint "\
#   openssl req -x509 -nodes -newkey rsa:$rsa_key_size -days 1\
#     -keyout '$path/privkey.pem' \
#     -out '$path/fullchain.pem' \
#     -subj '/CN=localhost'" certbotContainerService
# echo


# echo "### Starting nginx ..."
# docker restart nginxContainerService
# Problem: this (--force-recreate) wipes the whole nginx container-- do dont use this.
# docker-compose up --force-recreate -d nginxContainerService
# echo

# echo "### Deleting dummy certificate for $domains ..."
# docker-compose run --rm --entrypoint "\
#   rm -Rf /etc/letsencrypt/live/$domains && \
#   rm -Rf /etc/letsencrypt/archive/$domains && \
#   rm -Rf /etc/letsencrypt/renewal/$domains.conf" certbotContainerService
# echo


# echo "### Requesting Let's Encrypt certificate for $domains ..."
# Join $domains to -d args
# domain_args=()
# for domain in "${domains[@]}"; do
#   domain_args+=("-d" "$domain")
# done

# Select appropriate email arg
# case "$email" in
#   "") email_arg="--register-unsafely-without-email" ;;
#   *) email_arg="--email $email" ;;
# esac

# Enable staging mode if needed
# staging_arg=""
# if [ "$staging" -ne 0 ]; then
#   staging_arg="--staging"
# fi

# docker-compose run --rm --entrypoint "\
#   certbot -vvv certonly --webroot -w /var/www/certbot \
#     $staging_arg \
#     $email_arg \
#     ${domain_args[@]} \
#     --rsa-key-size $rsa_key_size \
#     --agree-tos \
#     --force-renewal" certbotContainerService

# This worked WHEN RUN MANUALLY. Will check via this script.
# docker exec certbotContainerService sh -c "\
#   certbot -vvv certonly --webroot -w /var/www/certbot \
#     --email patrick.wm.meaney@gmail.com \
#     -d livestauction.com -d www.livestauction.com \
#     --rsa-key-size 4096 \
#     --agree-tos \
#     --force-renewal"

# I skipped checking the above simple command and went for this, but it results in an error (mentioned below).  Will skip for now.
# Now going to insert the shell env vars from above
# docker exec certbotContainerService sh -c "\
#   certbot -vvv certonly --webroot -w /var/www/certbot \
#     $email_arg \
#     ${domain_args[@]} \
#     --rsa-key-size $rsa_key_size \
#     --agree-tos \
#     --force-renewal"

# Still having problems with the above for some reason--
# this error:
# certbot: error: argument -d/--domains/--domain: expected one argument

# docker-compose exec nginx nginx -s reload

# So, I will keep it simple for now...
