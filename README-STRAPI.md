# Strapi example

Make sure the Strapi container is up and running before you run this.

Based on the Strapi container's config, it should be placed onto the same docker network as nginx, so Nginx can reach it.

Once that's assured, run this...

```bash
#
# note: still experimenting.
# going to test c-experiment-nginx-conf-strapi.conf.template in place of https-strapi-template.conf.template
docker exec -it nginxContainerService sh -c "envsubst '\$NGINX_HOST' < /etc/nginx/templates/https-strapi-template.conf.template > /etc/nginx/conf.d/c-https-strapi-subdomain.conf" && docker restart nginxContainerService
```
