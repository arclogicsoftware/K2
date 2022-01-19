
## Oracle Linux NGINX Reverse Proxy Setup

### Create compute instance.

* Tried to use Ubuntu and could not "see" the public IP port 443 Nginx server. Some sort of routing/firewall issue but firewall was not enabled. Instance was in a security group which allowed access.
* So went back to Oracle Linux and had no issues with hitting the public IP.
* Needed to add another repo to yum update in order to install NGINX.
    - https://stackoverflow.com/questions/27244511/no-package-nginx-available-error-centos-6-5

### Actual foo.io.conf file.

* This is what the file looks like after certbot runs. You will use a more basic version to begin with.
    - https://www.nginx.com/blog/using-free-ssltls-certificates-from-lets-encrypt-with-nginx/

```
# Add following to the file (change dgielis.com by your domain):
server {
    server_name    foo.io www.foo.io;
    root           /usr/share/nginx/html/foo.io;
    index          index.html;
    try_files $uri /index.html;

    listen [::]:443 ssl ipv6only=on; # managed by Certbot
    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/foo.io/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/foo.io/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot

    location /ords/ {
        proxy_pass https://ch77iiworj5dhyy-deepblue.adb.us-phoenix-1.oraclecloudapps.com/ords/;
        proxy_set_header Origin "" ;
        proxy_set_header X-Forwarded-Host $host:$server_port;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout       600;
        proxy_send_timeout          600;
        proxy_read_timeout          600;
        send_timeout                600;
    }

    location /i/ {
        proxy_pass https://ch77iiworj5dhyy-deepblue.adb.us-phoenix-1.oraclecloudapps.com/i/;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location / {
        # rewrite ^/$ /ords/f?p=111 permanent;
        # App ID was getting cached and breaking deployment. Typeing in domain
        # would route to old environment. Hopefully below fixes that.
        rewrite ^/$ /ords/r/app/slprd ;
    }

}


server {
    if ($host = www.foo.io) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


    if ($host = foo.io) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


    listen         80;
    listen         [::]:80;
    server_name    foo.io www.foo.io;
    return 404; # managed by Certbot

}
```