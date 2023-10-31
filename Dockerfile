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
    && apt-get install -y curl jq locales git build-essential libpq-dev wget \
    && apt-get install -y libevent-2.1 libevent-pthreads-2.1 brotli libbrotli1 \
    && echo 'Make sure we have a en_US.UTF-8 locale available' \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
    && wget https://www.python.org/ftp/python/3.7.12/Python-3.7.12.tgz \
    && tar xzf Python-3.7.12.tgz \
    && cd Python-3.7.12 \
    && ./configure --enable-optimizations \
    && make -j4 \
    && make altinstall \
    && cd .. \
    && rm -rf Python-3.7.12.tgz Python-3.7.12 \
    && pip3.7 install --no-cache-dir psycopg2-binary==2.8.6 six psutil \
    && pip3.7 install --no-cache-dir "patroni[kubernetes]==${PATRONI_VERSION}" \
    && PGHOME=/home/postgres \
    && mkdir -p $PGHOME \
    && sed -i "s|/var/lib/postgresql.*|$PGHOME:/bin/bash|" /etc/passwd \
    && echo 'Setting permissions for OpenShift' \
    && chmod 664 /etc/passwd \
    && mkdir -p $PGHOME/pgdata/pgroot \
    && chgrp -R 0 $PGHOME \
    && chown -R postgres $PGHOME \
    && chmod -R 775 $PGHOME

COPY contrib/root /

VOLUME /home/postgres/pgdata
USER postgres
WORKDIR /home/postgres

EXPOSE 5432 8008

CMD ["/bin/bash", "/usr/bin/entrypoint.sh"]
