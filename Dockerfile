FROM postgres:12.4

LABEL Alexander Kukushkin <alexander.kukushkin@zalando.de>

ENV PATRONI_VERSION=2.1.1
ENV LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENV PATRONI_HOME=/opt/patroni

ARG PGHOME=/home/postgres

RUN export DEBIAN_FRONTEND=noninteractive \
    && set -x \
    && echo 'APT::Install-Recommends "0";\nAPT::Install-Suggests "0";' > /etc/apt/apt.conf.d/01norecommend \
    && apt-get update -y \
    && apt-get install -y curl jq locales git build-essential libpq-dev python3 python3-dev python3-pip python3-wheel python3-setuptools python3-psycopg2 python3-virtualenv \
    && echo 'Make sure we have a en_US.UTF-8 locale available' \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
    && pip3 --isolated --no-cache-dir install psycopg2-binary==2.8.6 six psutil pyyaml \
    && pip3 --isolated --no-cache-dir install "patroni[kubernetes]==${PATRONI_VERSION}" \
    && PGHOME=/home/postgres \
    && mkdir -p $PGHOME \
    && sed -i "s|/var/lib/postgresql.*|$PGHOME:/bin/bash|" /etc/passwd \
    && echo 'Setting permissions for OpenShift' \
    && chmod 664 /etc/passwd \
    && mkdir -p $PGHOME/pgdata/pgroot \
    && chgrp -R 0 $PGHOME \
    && chown -R postgres $PGHOME \
    && chmod -R 775 $PGHOME 
    # && echo 'Cleaning up' \
    # && apt-get remove -y git build-essential python3-dev python3-pip python3-wheel python3-setuptools \
    # && apt-get autoremove -y \
    # && apt-get clean -y \
    # && rm -rf /var/lib/apt/lists/* /root/.cache
#RUN virtualenv --python=python3 venv && source venv/bin/activate && pip install pyyaml && python env/common_config/add_imagepullsecret.py
RUN pip3 install psycopg2-binary==2.8.6 
RUN pip3 install six 
RUN pip3 install psutil==2.0.0
RUN pip3 install pyyaml==6.0.1

COPY contrib/root /

VOLUME /home/postgres/pgdata
USER postgres
WORKDIR /home/postgres

EXPOSE 5432 8008

CMD ["/bin/bash", "/usr/bin/entrypoint.sh"]
