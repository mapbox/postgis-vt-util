#!/usr/bin/env bash

# install postgis and dep setup
apt-get install -y \
    libxml2-dev libbz2-dev libpq-dev libgeos-c1 libgeos++-dev libproj-dev \
    python-pip python-dev python-psycopg2  \
    postgresql-client-9.3 postgresql-9.3-postgis-2.1 postgresql-contrib-9.3 postgresql-plpython-9.3
