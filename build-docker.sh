#!/bin/bash

NAME=sys-golf-ui
VERSION=latest

minikube image rm $NAME:$VERSION
docker build --no-cache . -t $NAME
minikube image load $NAME:$VERSION
