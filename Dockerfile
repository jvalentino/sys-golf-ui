FROM nginx:1.13
WORKDIR .
COPY ./config/nginx-ui.conf /etc/nginx/nginx.conf
COPY ./build /usr/share/nginx/html/

# puts it in /opt/td-agent-bit/bin
RUN apt-get update && \
    apt-get install -y curl && \
    apt-get install -y gpg && \
    apt-get install -y apt-transport-https && \
    curl https://packages.fluentbit.io/fluentbit.key | gpg --dearmor > /usr/share/keyrings/fluentbit-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/fluentbit-keyring.gpg] https://packages.fluentbit.io/debian/stretch stretch main" >> /etc/apt/sources.list &&  \
    apt-get update && \
    apt-get install td-agent-bit -y
COPY config/fluentbit.conf /opt/td-agent-bit/bin/fluentbit.conf

EXPOSE 80

COPY config/start.sh /usr/local/start.sh
RUN ["chmod", "+x", "/usr/local/start.sh"]
ENTRYPOINT ["/usr/local/start.sh"]
