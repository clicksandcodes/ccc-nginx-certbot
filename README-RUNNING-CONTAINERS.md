# Running containers

Apr 28, 2024 – 02:07 pm
Portfolio Project

Going with the basic non-template ... by simply copying the template file into the conf file (no env var stuff)
`docker exec -it nginxContainerService sh -c "cp /etc/nginx/templates/e-portfolio-http-get-certs.conf.template /etc/nginx/conf.d/e-portfolio-http-get-certs.conf" && docker restart nginxContainerService`

Have not tried this yet: (not dealing with env vars yet until I get it running)
`docker exec -it nginxContainerService sh -c "envsubst '\$HOSTNAME_PORTFOLIO' < /etc/nginx/templates/c-strapi.conf.template > /etc/nginx/conf.d/c-https-strapi-subdomain.conf" && docker restart nginxContainerService`

---

The below examples are for:

- StrapiJS CMS (Content Management System)
  - To serve as a content database
- NextJS
  - To serve as the user interface of webpages
-

### Strapi example

Make sure the Strapi container is up and running before you run this.

Based on the Strapi container's config, it should be placed onto the same docker network as nginx, so Nginx can reach it.

Once that's assured, run this...

```bash
docker exec -it nginxContainerService sh -c "envsubst '\$NGINX_HOST' < /etc/nginx/templates/c-strapi.conf.template > /etc/nginx/conf.d/c-https-strapi-subdomain.conf" && docker restart nginxContainerService
```

### Nextjs container

Since our NextJS container will operate on the index URL route of "/", we will need to replace the file which was output by our docker command which turned the nginx template file: , `b-https-json-template.conf.template` into: `b-https-json-healthcheck.conf`, for simplicity, we will overwrite `b-https-json-healthcheck.conf` with this new template: `d-replaces-b--nextjs.conf.template`.

That's what happens when we run this command:

```bash
docker exec -it nginxContainerService sh -c "envsubst '\$NGINX_HOST' < /etc/nginx/templates/d-replaces-b--nextjs.conf.template > /etc/nginx/conf.d/b-https-json-healthcheck.conf" && docker restart nginxContainerService

```
