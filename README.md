### Welcome.

This is a project to get a basic http & https healthcheck endpoint (and basic html page) running in four commands.

It runs via a CICD file located at: `./github/workflows/clone-setup-http-https.yaml` when you git commit to the main branch (or other branch specified at the beginning of that file).

The CICD creates a temporary server which runs an ssh login into a remote server passed in via environment variables set within the github repo secrets. Those env vars are fed from github secerts into the github CICD process, and other env vars from the cicd process, plus the local repo's .env file... into docker containers. The two docker containers are: **nginx**, _for an http & https healthcheck endpoint_ and **certbot**, _for a certbot-to-lets-encrypt request for tls certificates._

NOTE: I use this also for launching a subdomain for use with Strapi app-- more info in README-STRAPI.md

For pushing changes to the server, I use rsync.
It's useful because on the server, I run a command which downloads TLS certificates to the server. If I were to try to git pull new changes, git would require I stash those. Whereas this will simply upload any files which have been added or changes-- leaving alone any other files.
`rsync -avvz . userName@IpAddress:~/ccc-nginx-certbot`

## How to get it going, in short:

```bash
# clone this repo.

#### *************
# Edit this line in the file `init-letsencrypt-template.sh`:
# -d ${NGINX_HOST} -d www.${NGINX_HOST} -d api.${NGINX_HOST} \
# to remove  `-d api.${NGINX_HOST}` -- you won't need that unless you're using a subdomain in your project.
#### *************

# edit .env to add your domain name (or remote server IP). You'll also need to edit the 3rd command below, to add your domain name (or remote server IP) and email address.

# Don't forget to move into the ccc-nginx-certbot directory, which is where you'll run these commands from.

# This gets the containers running...
# But without using the `-d` flag it will take up the shell-- with the benefit of showing live logs.  So, I recommend after running this, to create a 2nd terminal window and ssh into the server with it, move into the directory, and then run commands that follow (docker exec, etc.)
# COMMAND 1 OF 4
docker-compose up

# run these next 3 commands in a 2nd new ssh shell, in the ccc-nginx-certbot directory
# COMMAND 2 OF 4
docker exec nginxContainerService sh -c "envsubst '\$NGINX_HOST' < /etc/nginx/templates/a-http-json-template.conf.template > /etc/nginx/conf.d/a-http-json-healthcheck.conf" && docker restart nginxContainerService

# Now, access http://domain.com/healthcheck to see a JSON response
curl ttps://livestauction.com/healthcheck

# Here, be sure to update NGINX_HOST & ADMIN_EMAIL to your variables-- your domain or remote server IP, and your email.
# COMMAND 3 OF 4
export NGINX_HOST=yourDomainName.com && export ADMIN_EMAIL=yourEmailAddress@someEmail.com && envsubst '\$NGINX_HOST \$ADMIN_EMAIL' < init-letsencrypt-template.sh > populated-init-letsencrypt.sh && chmod +x populated-init-letsencrypt.sh && sudo ./populated-init-letsencrypt.sh

# COMMAND 4 OF 4 takes env var $NGINX_HOST and combines it with nginx conf template file (shared with the nginx server via volume property in docker-compose.yml) to and putputs the particular conf file the nginx server actually reads (into the conf.d directory)
docker exec -it nginxContainerService sh -c "envsubst '\$NGINX_HOST' < /etc/nginx/templates/b-https-json-template.conf.template > /etc/nginx/conf.d/b-https-json-healthcheck.conf" && docker restart nginxContainerService

# Now, access https://domain.com/healthcheck to see a JSON response
curl https://livestauction.com/healthcheck
# And as an example, a basic response of html at the index url:
curl https://livestauction.com/
```

---

## Here's how to get it going, in detail.

### Below these instructions is a TLDR.

### Step 1: Setup a healthcheck endpoint for http traffic, as a prerequisite to requesting TLS certificates.

> <span style="color:darkGreen; font-size: 1.1rem">In this step, we will pass environment variables to an nginx configuration template file (see it at ./data/nginx-templates/b-https-json-template.conf.template), in order to populate an nginx configuration... which is output into the Nginx docker container. From there, Nginx serves a JSON object at http://domain.com/healthcheck letting us know that the Nginx-routed server traffic is accessible.</span>

- Clone this repo.

  - <span style="color:blue; font-weight:bold; font-size: 1.5rem">**Command to run:**</span>
  - `git clone git@github.com:clicksandcodes/ccc-nginx-certbot.git`

- Edit this line in the file `init-letsencrypt-template.sh`:

  - `d ${NGINX_HOST} -d www.${NGINX_HOST} -d api.${NGINX_HOST} \`
  - to remove `-d api.${NGINX_HOST}` -- you won't need that unless you're using a subdomain in your project.

- <span style="color:blue; font-weight:bold; font-size: 1.5rem">**Edit**</span> the .env file: replace the value for `NGINX_HOST` with your domain name or the IP address of your server. If you're just testing things out, I recommend using the IP address of your server. **For the remainder of these instructions I will refer to this as domain.com (but consider it as your server IP if that's what you use as NGINX_HOST)**

- <span style="color:blue; font-weight:bold; font-size: 1.5rem">**Open**</span> **two** terminal windows. **In both windows**, ssh into your server. So, <span style="color:blue; font-weight:bold; font-size: 1.5rem">Run:</span> `ssh yourServerUser@yourServerIP` in two separate terminal windows

  > - _(Or you can use just one terminal window-- in which case, you'd just add the `-d` flag to the end of the `docker-compose up` command to run the project in the background. I prefer to keep it in the "foreground" so I can see the logs from the two containers (certbot & nginx) in real time)_

- Now in Terminal Window #1, start the docker-compose project:

  - <span style="color:blue; font-weight:bold; font-size: 1.5rem">**Command to run:**</span>
  - `docker-compose up`
  - You'll see Certbot & Nginx boot up.
  - **That's all you'll do in Terminal Window #1**

### From here, all following commands will be run in Terminal Window #2:

- Next you'll run the following command. But first, let's explain it does is:
  - With the previous command, docker-compose fed an environment variable "NGINX_HOST" into the nginx docker container.
  - The command itself takes an nginx configuration template file and feed it that "NGINX_HOST" environment variable, and then outputs an nginx configuration file.
  - Now nginx has access to a configuration file. The configuration file configures Nginx to serve a /healthcheck endpoint at domain or IP you specified as the "NGINX_HOST" in the .env file.
  - So, you'll be able to visit http://theDomainOrIP/healthcheck and see a JSON data object like this: `{ "api_version": "0.0.1", "status_msg": "http_is_alive", "status_code": "200" }` -- The purpose of which is simply to inform you that the nginx server can now support unsecured traffic to & from the public internet.
    - <span style="color:blue; font-weight:bold; font-size: 1.5rem">**Command to run:**</span>
    - `docker exec nginxContainerService sh -c "envsubst '\$NGINX_HOST' < /etc/nginx/templates/a-http-json-template.conf.template > /etc/nginx/conf.d/a-http-json-healthcheck.conf" && docker restart nginxContainerService`
    - (Remember-- run that command in Terminal Window #2. Because we leave Terminal Window #1 as simply the window to show the docker container logs in real time)
    - <span style="color:blue; font-weight:bold; font-size: 1.5rem">**Open**</span> your browser or create an HTTP GET request to: http://theDomainOrIP/healthcheck
    - > Be sure it navigates to http:// and not http**s**://

#### Sweet. Now we can serve unsecure traffic. Not exactly ideal-- However, it is a requirement for receiving TLS certificates from Let's Encrypt via Cerbot. So, that's why it's step 1.

## Step 2: Request TLS Certificates via the Certbot container involved in this project.

> <span style="color:darkGreen; font-size: 1.1rem">In this step, we request TLS Certificates using the Certbot docker container, which sends a request for certificates to a free certificate generation service called [Let's Encrypt](https://letsencrypt.org/how-it-works/). TLS Certificates are used to ensure encrypted traffic with internet users browsers-- providing the "s" in https, which stands for secure.</span>

- In this next command, you'll replace two values in the command with 1. your own domain or server's IP address 2. your email address (as the server administrator)
- The `export` linux command places those two items into your server's set environment variables. From there, the command combines the environment variables with a template shell file to output a "populated" shell file-- i.e. a shell file populated with the two environment variables. It then runs the populated shell file.
  - <span style="color:blue; font-weight:bold; font-size: 1.5rem">**Command to run**</span>
  - `export NGINX_HOST=YOUR_DOMAIN_OR_SERVER_IP && export ADMIN_EMAIL=YOUR_EMAIL_ADDRESS && envsubst '\$NGINX_HOST \$ADMIN_EMAIL' < init-letsencrypt-template.sh > populated-init-letsencrypt.sh && chmod +x populated-init-letsencrypt.sh && sudo ./populated-init-letsencrypt.sh`
- In Terminal Window #1, you'll see the certbot container request certificates from the Let's Encrypt service. The certbot container will also create a new directory in the project directory: ./data/certbot which will contain the certificates and other related files.

#### Sweet. Now that we have 1. an publicly accessible http server and 2.our TLS certificates -- both of which are prerequisites for the next step, we are ready to move on to...

## Step 3: Setup an nginx https endpoint

> <span style="color:darkGreen; font-size: 1.1rem">In this step, in a manner very similar to step #1, we run a docker command which will output a new nginx configuration file. How it works is... once again, it takes an environment variable ("NGINX_HOST") and combines it with a configuration template file (see it at ./data/nginx-templates/b-https-json-template.conf.template) in order to output an Nginx configuration file into the Nginx docker container. That configuration file will use the TLS certificates to host an https page of a basic html file at https://domain.com/ as well as a healthcheck endpoint at https://domain.com/healthcheck</span>

- The next step will do the aforementioned procedures, and then reload the nginx docker container.
- <span style="color:blue; font-weight:bold; font-size: 1.5rem">**Command to run:**</span>
- `docker exec -it nginxContainerService sh -c "envsubst '\$NGINX_HOST' < /etc/nginx/templates/b-https-json-template.conf.template > /etc/nginx/conf.d/b-https-json-healthcheck.conf" && docker restart nginxContainerService`
- <span style="color:blue; font-weight:bold; font-size: 1.5rem">**Open**</span> on a browser, or access via an HTTP GET Request the following domains:
  - https://domain.com/ - You'll see a very simply html page which says "Hello World, I am an https endpoint serving basic html"
  - https://domain.com/healthcheck - you'll see this JSON object: `{"api_version":"0.0.1", "status_msg":"https_is_alive", "status_code":"200"}`

## And that's it!

## What's next? I may continue working on the CICD portion of this project

Check out ./github/workflows/clone-setup-http-https.yaml

The github actions CICD task runner is a slight pain to deal with-- it seems like it's a regular shell, but it isn't. It's sort of a pseudo-shell. So, that makes it a bit tricky to run commands with.

What I am using it for is to basically automate the above four steps. In order to do that, the Github Actions CICD Task Runner acts as a linux server, which then logs into my remote linux server to run commands-- the four commands above.

At the moment, I don't really need this-- the intention is to get it working so that I can very quickly spin up new servers if needed for a new consulting client.

However in the mean time, I can simply spin up the servers by:

1. Running my terraform script workflow:
   - https://github.com/clicksandcodes/ccc-server-starter-kit
   - Documentation for that: https://github.com/clicksandcodes/ccc-server-starter-docs
2. Then, from clone this project (ccc-nginx-certbot), move into its directory, and runne the four commands in this project.

Hence... I don't _really_ have a pressing need to fix the last piece of that workflow. Though I expect to return to it in the near future.

### My TLDR

This is what I run-- the same as above, only using the environment variables I use for my workflow-- a domain name I am testing out, and my email address. I just leave them here since it makes it easier for me to copy & paste them.

In production, you may not want to expose these sorts of things-- environment variables, in general, and especially if they're meant to be private, keys, or important project passwords aka "secrets"

In this case though...

I simply made this project public to demonstrate an example project I've been working on. Otherwise this would be a private repo. Even then, since this is a project which is eventually intended to be a public website or app, and my email address is also relatively public information).

```bash
# edit .env as needed, as well as the 3rd command below.

# Don't forget to move into the ccc-nginx-certbot directory, which is where you'll run these commands from.

# This gets the containers running...
# But without using the `-d` flag it will take up the shell-- with the benefit of showing live logs.  So, I recommend after running this, to create a 2nd terminal window and ssh into the server with it, move into the directory, and then run commands that follow (docker exec, etc.)
docker-compose up

# run these in a 2nd new ssh shell, in the ccc-nginx-certbot directory
docker exec nginxContainerService sh -c "envsubst '\$NGINX_HOST' < /etc/nginx/templates/a-http-json-template.conf.template > /etc/nginx/conf.d/a-http-json-healthcheck.conf" && docker restart nginxContainerService

export NGINX_HOST=yourDomainName.com && export ADMIN_EMAIL=yourEmailAddress@someEmail.com && envsubst '\$NGINX_HOST \$ADMIN_EMAIL' < init-letsencrypt-template.sh > populated-init-letsencrypt.sh && chmod +x populated-init-letsencrypt.sh && sudo ./populated-init-letsencrypt.sh

docker exec -it nginxContainerService sh -c "envsubst '\$NGINX_HOST' < /etc/nginx/templates/b-https-json-template.conf.template > /etc/nginx/conf.d/b-https-json-healthcheck.conf" && docker restart nginxContainerService
```

https://gist.github.com/maxivak/4706c87698d14e9de0918b6ea2a41015

Src:

- https://github.com/wmnnd/nginx-certbot/tree/master
- https://pentacent.medium.com/nginx-and-lets-encrypt-with-docker-in-less-than-5-minutes-b4b8a60d3a71
  Project description:

## Below are notes from when this was my private repo. Maybe I will clean them up later.

---

---

---

### Basic steps

This will insert the env var for your domain name from the docker container env vars into a conf file, for both an http conf file & https conf file.

The conf files will be placed into /etc/nginx/conf.d, at which is pointed the include statement within the default nginx conf. So, the conf files will be picked up by nginx.

Run the first one, check that the domain works from your browser.

Then run the second one, then the init-letsencrypt.sh file, and check that https works.

### Clone repo and start up the http endpoint

- git clone the repo.
- enter the repo folder

See the codeblock below-- this is just a summary of the steps.

- start the containers: `docker-compose up`
- exec into the docker container of the nginx container: `docker exec -it nginx sh`
- Run this: `envsubst '\$NGINX_HOST' < /etc/nginx/templates/a-http-json-template.conf.template > /etc/nginx/conf.d/a-http-json-healthcheck.conf`
- (Note: the specific env var (i.e. $NGINX_HOST) is specified above because it tells Nginx envsubst to only overwrite that particular env var, whick keeps intact others such as $host and $request_uri. More info: https://github.com/docker-library/docs/issues/496#issuecomment-186149231)
- exit the container
- restart it: `docker restart nginx`

```shell
# Run this line by line.
docker exec -it nginx sh
envsubst < /etc/nginx/templates/a-http-json-template.conf.template > /etc/nginx/conf.d/a-http-json-healthcheck.conf

# OR combine the two above lines:
docker exec nginxContainerService sh -c "envsubst < /etc/nginx/templates/a-http-json-template.conf.template > /etc/nginx/conf.d/a-http-json-healthcheck.conf" && docker restart nginxContainerService
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
envsubst '\$NGINX_HOST' < /etc/nginx/templates/b-https-json-template.conf.template > /etc/nginx/conf.d/b-https-json-healthcheck.conf
exit
docker restart nginx

# OR run them as one line:
docker exec -it nginxContainerService sh -c "envsubst '\$NGINX_HOST' < /etc/nginx/templates/b-https-json-template.conf.template > /etc/nginx/conf.d/b-https-json-healthcheck.conf" && docker restart nginxContainerService
```

Back outside of the container:

- From inside the project directory, Run these commands (permission to run file, file run)
  - ```shell
    # Set the env vars in the Linux server:
    export NGINX_HOST=yourDomainName.com && export ADMIN_EMAIL=yourEmailAddress@someEmail.com
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

\***\*\_\_\_\*\*** Original doc \***\*\_\*\***

# Boilerplate for nginx with Let’s Encrypt on docker-compose

> This repository is accompanied by a [step-by-step guide on how to
> set up nginx and Let’s Encrypt with Docker](https://medium.com/@pentacent/nginx-and-lets-encrypt-with-docker-in-less-than-5-minutes-b4b8a60d3a71).

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

4.  Run the init script:

        ./init-letsencrypt.sh

5.  Run the server:

        docker-compose up

## Got questions?

Feel free to post questions in the comment section of the [accompanying guide](https://medium.com/@pentacent/nginx-and-lets-encrypt-with-docker-in-less-than-5-minutes-b4b8a60d3a71)

## License

All code in this repository is licensed under the terms of the `MIT License`. For further information please refer to the `LICENSE` file.

    # location / {
    #     return 301 https://$host$request_uri;
    # }

docker-compose run --rm "\
 certbot -vvv certonly --webroot -w /var/www/certbot \
 0 \
 yourEmailAddress@someEmail.com \
 yourDomainName.com www.yourDomainName.com \
 --rsa-key-size $rsa_key_size \
 --agree-tos" certbotContainerService

\***\*\_\_\_\_\*\*** Steps**\*\*\*\***\_**\*\*\*\***

If you recreate the nginxContainerService but not the certbot one, the certs will still exist in the server's project directory. From there, they're automatically available to the nginx container via the docker volume (which is essentially a shared directory, synchronized between the linux server and the docker container) So, no need to re-reques them. Instead, just reload the templates into conf files with:
docker exec nginxContainerService sh -c "envsubst '\$NGINX_HOST' < /etc/nginx/templates/a-http-json-template.conf.template > /etc/nginx/conf.d/a-http-json-healthcheck.conf" && docker exec -it nginxContainerService sh -c "envsubst '\$NGINX_HOST' < /etc/nginx/templates/b-https-json-template.conf.template > /etc/nginx/conf.d/b-https-json-healthcheck.conf" && docker restart nginxContainerService

\_**\_ For manual cert creation\_\_\_\_**
docker exec certbotContainerService sh -c "\
 certbot -vvv certonly --webroot -w /var/www/certbot \
 --email yourEmailAddress@someEmail.com \
 -d yourDomainName.com -d www.yourDomainName.com \
 --rsa-key-size 4096 \
 --agree-tos \
 --force-renewal"
