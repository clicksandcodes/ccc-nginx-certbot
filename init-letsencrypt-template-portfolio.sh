# NOTE
# Since the docker container for certbot is already live on the server, we do not need to run a lot of this original stuff.

# We can try this:

# Request the new certs
# -> Add "HOSTNAME_PORTFOLIO=pmeaney.com" to .env file on remote server in the nginx project folder (ccc-nginx-certbot)


# -> Run this.  It should request new certs for the domain new domain name & its subdomains.
curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "./data/certbot/conf/options-ssl-nginx--portfolio.conf"

curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "./data/certbot/conf/ssl-dhparams--portfolio.pem"

docker exec certbotContainerService sh -c "\
  certbot -vvv certonly --webroot -w /var/www/certbot \
    --email patrick.wm.meaney@gmail.com \
    -d pmeaney.com -d www.pmeaney.com -d api.pmeaney.com \
    --rsa-key-size 4096 \
    --agree-tos \
    --force-renewal"

# Since certbot shares its volume with nginx, nginx will now bring the new cert files into itself once its restarted.
# From there, we'll be ready to run our docker nginx service command to conver the nginx template conf file into the regular nginx conf file.
docker restart nginxContainerService

# Run the nginx service command...

# #!/bin/bash

# if ! [ -x "$(command -v docker-compose)" ]; then
#   echo 'Error: docker-compose is not installed.' >&2
#   exit 1
# fi

# domains=("${HOSTNAME_PORTFOLIO}" "www.${HOSTNAME_PORTFOLIO}")
# rsa_key_size=4096
# data_path="./data/certbot"
# email="${ADMIN_EMAIL}" # Adding a valid address is strongly recommended
# # staging=0 # Set to 1 if you're testing your setup to avoid hitting request limits

# if [ -d "$data_path" ]; then
#   read -p "Existing data found for $domains. Continue and replace existing certificate? (y/N) " decision
#   if [ "$decision" != "Y" ] && [ "$decision" != "y" ]; then
#     exit
#   fi
# fi

# # if [ ! -e "$data_path/conf/options-ssl-nginx.conf" ] || [ ! -e "$data_path/conf/ssl-dhparams.pem" ]; then
#   echo "### Downloading recommended TLS parameters ..."
#   mkdir -p "$data_path/conf"
#   curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "$data_path/conf/options-ssl-nginx--portfolio.conf"
#   curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "$data_path/conf/ssl-dhparams--portfolio.pem"
# # fi

# docker exec certbotContainerService sh -c "\
#   certbot -vvv certonly --webroot -w /var/www/certbot \
#     --email ${ADMIN_EMAIL} \
#     -d ${HOSTNAME_PORTFOLIO} -d www.${HOSTNAME_PORTFOLIO} -d api.${HOSTNAME_PORTFOLIO} \
#     --rsa-key-size 4096 \
#     --agree-tos \
#     --force-renewal"

# echo "### Reloading nginx ..."
# docker restart nginxContainerService
