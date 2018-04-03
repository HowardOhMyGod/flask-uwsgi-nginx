# Building Web Server with Flask, uWSGI and Nginx in Docker

## Usage
Run `bash build.sh` in your *flask working directory* to build a docker image. After building this image, use `docker run -d -p [host_port]:[container_port] howardohmygod/flask-uwsgi:python3.5` it will automatically run your application on the host port on your machine (locahost:host_port).

The shell will automatically generate uwsgi ini file, nginx config file and start.sh.

## User Input
```
PROJ_NAME: Your project name, .ini filename, and nginx file name, default is "myproject"
WORKDIR: Your flask working directory. All files in this dir will be copy to WORKDIR_DOCK in container
WORKDIR_DOCK: set your working directory in docker container
ENTRY_FILE: Your Flask entry file. This file will be mounted by uWSGI
FLASK_APP: The flask instance in ENTRY_FILE
PORT: Set your container expose port
```

## .ini file
```
[uwsgi]

# mount entrypoint
mount = /=${ENTRY_FILE}
callable = ${FLASK_APP}

# tell uWSGI to rewrite PATH_INFO and SCRIPT_NAME according to mount-points
manage-script-name = true

# set main process and at most three child processes
master = true
processes = 3

# create socket read write by nginx
socket = ${PROJ_NAME}.sock
chmod-socket = 666

vacuum = true
die-on-term = true
```

## nginx config file
```
server {
    listen ${PORT};
    server_name localhost;

    location / {
        include uwsgi_params;
        uwsgi_pass unix:${WORKDIR_DOCK}/${PROJ_NAME}.sock;
    }
}
```

## Dockerfile
```bash
FROM ubuntu:16.04

# set working directory
RUN mkdir -p ${WORKDIR_DOCK}
WORKDIR ${WORKDIR_DOCK}

COPY ${WORKDIR} ${WORKDIR_DOCK}

RUN apt-get -y update && \
    apt-get -y install python3-pip python3-dev nginx curl vim git htop

RUN pip3 install --upgrade pip && \
    pip3 install --trusted-host pypi.python.org -r requirement.txt && \
    cp ${PROJ_NAME} /etc/nginx/sites-available && \
    ln -s /etc/nginx/sites-available/${PROJ_NAME} /etc/nginx/sites-enabled

EXPOSE ${PORT}

CMD [\"bash\", \"start.sh\"]
```

## start.sh
This script will be execute after running container.
```bash
#!/bin/bash

# this shell use to start flask-wsgi server
service nginx restart || echo \"Server fail to start\"
uwsgi --ini ${PROJ_NAME}.ini
```
