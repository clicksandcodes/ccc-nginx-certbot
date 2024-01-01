

Src:
- https://github.com/wmnnd/nginx-certbot/tree/master
- https://pentacent.medium.com/nginx-and-lets-encrypt-with-docker-in-less-than-5-minutes-b4b8a60d3a71
Project description:

### Basic steps


This will insert the env var for your domain name from the docker container env vars into a conf file, for both an http conf file & https conf file.

The conf files will be placed into /etc/nginx/conf.d, at which is pointed the include statement within the default nginx conf.  So, the conf files will be picked up by nginx.

Run the first one, check that the domain works from your browser.

Then run the second one, then the init-letsencrypt.sh file, and check that https works.

Here's how we do it:

- git clone the repo.
- exec into the docker container of the nginx container: `docker exec -it nginxContainerService sh`
- Run this: `envsubst < /etc/nginx/templates/http-json-template.conf.template > /etc/nginx/conf.d/a-http-json-healthcheck.conf`
- check domain (w/o https)

- While still in the nginx docker container:
- Run this: `envsubst < /etc/nginx/templates/https-json-template.conf.template > /etc/nginx/conf.d/b-https-json-healthcheck.conf`

Now, back outside of the container:
- Run these commands (permission to run file, file run)
  - ```shell
    chmod +x init-letsencrypt.sh
    sudo ./init-letsencrypt.sh
    ```
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
