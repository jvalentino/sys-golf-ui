# System Golf (UI)

This application serves the UI as a part of the overall https://github.com/jvalentino/sys-golf project. For system details, please see that location

Prerequisites

- Node
- Visual Studio Code
- Git
- Docker
- Helm
- Minikube

All of these you can get in one command using this installation automation (if you are on a Mac): https://github.com/jvalentino/setup-automation

# Developer

This project was bootstrapped with [Create React App](https://github.com/facebook/create-react-app).

## Available Scripts

In the project directory, you can run:

### `npm start`

Runs the app in the development mode.\
Open [http://localhost:3000](http://localhost:3000) to view it in your browser.

The page will reload when you make changes.\
You may also see any lint errors in the console.

### `npm test`

Launches the test runner in the interactive watch mode.\
See the section about [running tests](https://facebook.github.io/create-react-app/docs/running-tests) for more information.

### `npm run build`

Builds the app for production to the `build` folder.\
It correctly bundles React in production mode and optimizes the build for the best performance.

The build is minified and the filenames include the hashes.\
Your app is ready to be deployed!

See the section about [deployment](https://facebook.github.io/create-react-app/docs/deployment) for more information.

## Docker

### build-docker.sh

You build the docker image by running this:

```bash
./build-docker.sh
```

This script consists of the following:

```bash
#!/bin/bash

NAME=sys-golf-ui
VERSION=latest
HELM_NAME=frontend

helm delete $HELM_NAME || true
minikube image rm $NAME:$VERSION
rm -rf ~/.minikube/cache/images/arm64/$NAME_$VERSION || true
docker build --no-cache . -t $NAME
minikube image load $NAME:$VERSION
```

There is quite a bit of magic in here not directly relating to docker. This scripting ensures we build a clean new image, make sure to remove it if it is running in Minikube, and then load it back into the cache.

### Dockerfile

The container for running this application consists of two parts:

- Nginx - The web server for hosting the static content of the application
- Fluentbit - A log forwarder to take the log files from nginx and forward them to Elasticsearch.

Nginx is easy, while getting fluent bit to actually work was hard as evident by the Dockerfile:

```Docker
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
```

### nginx-ui.conf

```groovy
events { worker_connections 1024;}
error_log ... debug;

http {

    access_log /var/log/nginx/access-custom.log;
    error_log /var/log/nginx/error-custom.log;

    server {
        listen 80;

        location / {
            root /usr/share/nginx/html/;
            include /etc/nginx/mime.types;
            try_files $uri $uri/ /index.html;
        }
    }
}
```

By default this variant of nginx redirects access and error logs to standard out and standard error, which we can't capture with our log forwarder. For that reason, I had to override the logging configuration to go to specific files that can be picked up by the log forwarder.

### fluentbit.conf

```properties
[INPUT]
    name              tail
    path              /var/log/nginx/*-custom.log
    multiline.parser docker, cri

[OUTPUT]
    Name  es
    Match *
    Host elasticsearch-master
    Port 9200
    Index frontend
    Suppress_Type_Name On
```

This configuration picks up the custom log files,, and forward them to elastic search using the index of `frontend`.

### start.sh

Since we are now launching two applications instead of just nginx, we have to override the application entrypoint to run this script:

```bash
#!/bin/bash
cd /opt/td-agent-bit/bin; ./td-agent-bit -c fluentbit.conf > fluentbit.log 2>&1 &
nginx -g "daemon off;"
```

