
    #!/bin/bash

    # this shell use to start flask-wsgi server
    service nginx restart || echo "Server fail to start"
    uwsgi --ini demo.ini

