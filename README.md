
https://gist.github.com/maxivak/4706c87698d14e9de0918b6ea2a41015

Src:
- https://github.com/wmnnd/nginx-certbot/tree/master
- https://pentacent.medium.com/nginx-and-lets-encrypt-with-docker-in-less-than-5-minutes-b4b8a60d3a71
Project description:

### Basic steps


This will insert the env var for your domain name from the docker container env vars into a conf file, for both an http conf file & https conf file.

The conf files will be placed into /etc/nginx/conf.d, at which is pointed the include statement within the default nginx conf.  So, the conf files will be picked up by nginx.

Run the first one, check that the domain works from your browser.

Then run the second one, then the init-letsencrypt.sh file, and check that https works.

### Clone repo and start up the http endpoint

- git clone the repo.
- enter the repo folder

See the codeblock below-- this is just a summary of the steps.
- start the containers: `docker-compose up`
- exec into the docker container of the nginx container: `docker exec -it nginx sh`
- Run this: `envsubst '\$NGINX_HOST' < /etc/nginx/templates/http-json-template.conf.template > /etc/nginx/conf.d/a-http-json-healthcheck.conf`
- (Note: the specific env var (i.e. $NGINX_HOST) is specified above because it tells Nginx envsubst to only overwrite that particular env var, whick keeps intact others such as $host and  $request_uri.  More info: https://github.com/docker-library/docs/issues/496#issuecomment-186149231)
- exit the container
- restart it: `docker restart nginx`

```shell
# Run this line by line.
docker exec -it nginx sh
envsubst < /etc/nginx/templates/http-json-template.conf.template > /etc/nginx/conf.d/a-http-json-healthcheck.conf

# OR combine the two above lines:
docker exec nginxContainerService sh -c "envsubst < /etc/nginx/templates/http-json-template.conf.template > /etc/nginx/conf.d/a-http-json-healthcheck.conf"

exit
docker restart nginx
```

- check the domain (w/o https) via your browser and you should see the json response from the nginx server block

```shell
# If you want to check how/why -- 
# - While still in the nginx docker container:

# Since we provided the env var of $NGINX_HOST via a .env file (via the docker-compose file's "env_file" and the .env file in the repo), the env var of $NGINX_HOST will not disappear on restart.
# Check the env vars: You'll see: NGINX_HOST=someDomain.com
# Run this:
env

# Check the conf file was made (It is created based off the .conf.template file via the envsubst command)  -- you should see the `a-http-json-healthcheck` file
# Run this:
ls /etc/nginx/conf.d

# Check that the conf file was populated with the domain name from the env var "NGINX_HOST"
# Run this:
cat /etc/nginx/conf.d/a-http-json-healthcheck
```

### Start up the https endpoint

We first needed an http endpoint in order for certbot to provide us certs.
Now that we have one, we can move on to the https endpoint.

We need to first create the https conf inside the docker container.
Run this line by line.

```shell
# Run this line by line.
docker exec -it nginx sh
envsubst '\$NGINX_HOST' < /etc/nginx/templates/https-json-template.conf.template > /etc/nginx/conf.d/b-https-json-healthcheck.conf
exit
docker restart nginx

# OR run them as one line:
docker exec -it nginxContainerService sh -c "envsubst '\$NGINX_HOST' < /etc/nginx/templates/https-json-template.conf.template > /etc/nginx/conf.d/b-https-json-healthcheck.conf" && docker restart nginxContainerService
```



Back outside of the container:
- From inside the project directory, Run these commands (permission to run file, file run)
  - ```shell
    # Set the env vars in the Linux server:
    export NGINX_HOST=livestauction.com && export ADMIN_EMAIL=patrick.wm.meaney@gmail.com
    # Here we populate the .sh file with the env vars.  When you run this command, you'll see the output of the file which has now been populated with the above two env vars.
    envsubst '\$NGINX_HOST \$ADMIN_EMAIL' < init-letsencrypt-template.sh > populated-init-letsencrypt.sh
    # Now give the current linux user permission to to execute the file
    chmod +x populated-init-letsencrypt.sh
    # Now run it.
    sudo ./populated-init-letsencrypt.sh
    ```

chmod +x init-letsencrypt.sh && sudo ./init-letsencrypt.sh
- Check domain (w/ https)



### Full instructions
Full Instructions for getting this running:
https://pentacent.medium.com/nginx-and-lets-encrypt-with-docker-in-less-than-5-minutes-b4b8a60d3a71

(Also in ./backup_files/article_backup/ARTICLE.md)

### Project steps




___________ Original doc _________
# Boilerplate for nginx with Let’s Encrypt on docker-compose

> This repository is accompanied by a [step-by-step guide on how to
set up nginx and Let’s Encrypt with Docker](https://medium.com/@pentacent/nginx-and-lets-encrypt-with-docker-in-less-than-5-minutes-b4b8a60d3a71).

`init-letsencrypt.sh` fetches and ensures the renewal of a Let’s
Encrypt certificate for one or multiple domains in a docker-compose
setup with nginx.
This is useful when you need to set up nginx as a reverse proxy for an
application.

## Installation
1. [Install docker-compose](https://docs.docker.com/compose/install/#install-compose).

2. Clone this repository: `git clone https://github.com/wmnnd/nginx-certbot.git .`

3. Modify configuration:
- Add domains and email addresses to init-letsencrypt.sh
- Replace all occurrences of example.org with primary domain (the first one you added to init-letsencrypt.sh) in data/nginx/app.conf

4. Run the init script:

        ./init-letsencrypt.sh

5. Run the server:

        docker-compose up

## Got questions?
Feel free to post questions in the comment section of the [accompanying guide](https://medium.com/@pentacent/nginx-and-lets-encrypt-with-docker-in-less-than-5-minutes-b4b8a60d3a71)

## License
All code in this repository is licensed under the terms of the `MIT License`. For further information please refer to the `LICENSE` file.




    # location / {
    #     return 301 https://$host$request_uri;
    # }