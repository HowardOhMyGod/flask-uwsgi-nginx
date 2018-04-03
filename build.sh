#!/bin/bash

# This shell is use to build a Python flask project with uwsgi
# and nginx to run a server

PROJ_NAME="myproject"
PORT=3000

read -p "Enter your project name (myproject): " PROJ_NAME
PROJ_NAME=${PROJ_NAME:-myproject}

read -p "Enter your (WORKDIR) currently: " WORKDIR
read -p "Enter your (WORKDIR_DOCK) on docker container: " WORKDIR_DOCK
read -p "Enter your entryfile for uWSGI: " ENTRY_FILE
read -p "Enter your flask instance: " FLASK_APP

read -p "Enter port number (3000): " PORT
PORT=${PORT:-3000}

# check if WORKDIR exist
if [ ! -d ${WORKDIR} ]; then
    echo "The directory path do not exist."
    exit 1
else
    cd ${WORKDIR}
fi

# check entry file .py
if [ ! -f "${ENTRY_FILE}" ]; then
    echo "The entry file do not exist."
    exit 1
fi

# check flask app instance
grep -q "import ${FLASK_APP}" ${ENTRY_FILE}
if [ $? != 0 ]; then
    echo "Can't find ${FLASK_APP} in ${ENTRY_FILE}."
    exit 1
fi

# set uWSGI init file
echo "
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
" > "${PROJ_NAME}.ini"

# set nginx config
echo "
    server {
        listen ${PORT};
        server_name localhost;

        location / {
            include uwsgi_params;
            uwsgi_pass unix:${WORKDIR_DOCK}/${PROJ_NAME}.sock;
        }
    }
" > "${PROJ_NAME}"

# set Dokcerfile
echo "
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
" > Dockerfile

# set start.sh for docker CMD
echo "
    #!/bin/bash

    # this shell use to start flask-wsgi server
    service nginx restart || echo \"Server fail to start\"
    uwsgi --ini ${PROJ_NAME}.ini
" > start.sh

# start to build docker image
docker build -t howardohmygod/flask-uwsgi:python3.5 .

# cleanup files if build fail
if [ $? != 0 ]; then
    rm -f ${PROJ_NAME}.ini
    rm -f ${PROJ_NAME}
    rm -f ${PROJ_NAME}.sh
    rm -f Dockerfile
    echo "Docker build fail."
    exit 1
fi
