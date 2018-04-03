
    FROM ubuntu:16.04

    # set working directory
    RUN mkdir -p /home/howard/flask-demo
    WORKDIR /home/howard/flask-demo

    COPY . /home/howard/flask-demo

    RUN apt-get -y update &&         apt-get -y install python3-pip python3-dev nginx curl vim git htop

    RUN pip3 install --upgrade pip &&         pip3 install --trusted-host pypi.python.org -r requirement.txt &&         cp demo /etc/nginx/sites-available &&         ln -s /etc/nginx/sites-available/demo /etc/nginx/sites-enabled

    EXPOSE 5000

    CMD ["bash", "start.sh"]

