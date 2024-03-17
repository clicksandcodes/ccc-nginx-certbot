# Strapi example

```bash
docker exec -it nginxContainerService sh -c "envsubst '\$NGINX_HOST' < /etc/nginx/templates/https-strapi-template.conf.template > /etc/nginx/conf.d/c-https-strapi-subdomain.conf" && docker restart nginxContainerService
```
