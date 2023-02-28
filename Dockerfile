FROM nginx:1.13
WORKDIR .
COPY ./config/nginx-ui.conf /etc/nginx/nginx.conf
COPY ./build /usr/share/nginx/html/
EXPOSE 80
