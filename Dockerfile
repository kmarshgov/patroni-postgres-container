FROM postgres:12.4

LABEL Alexander Kukushkin <alexander.kukushkin@zalando.de>

ARG patroniv=2.0.1
#ARG postgresv=12.4
ENV PATRONI_VERSION=$patroniv
#ENV PGVERSION=$postgresv
ENV LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENV PATRONI_HOME=/opt/patroni
#ENV PATH=$PATH:/usr/lib/postgresql/$PGVERSION/bin

ARG PGHOME=/home/postgres

RUN export DEBIAN_FRONTEND=noninteractive \
    && set -x \
    && echo 'APT::Install-Recommends "0";\nAPT::Install-Suggests "0";' > /etc/apt/apt.conf.d/01norecommend \
    && apt-get update -y \
    && apt-get install -y curl jq locales git build-essential libpq-dev python3.7 python3.7-dev python3.7-pip python3.7-wheel python3.7-setuptools python3.7-virtualenv python3.7-pystache python3.7-requests patchutils binutils \
    && apt-get install -y postgresql-common libevent-2.1 libevent-pthreads-2.1 brotli libbrotli1 python3.7 python3.7-psycopg2 \
    && echo 'Make sure we have a en_US.UTF-8 locale available' \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
    && pip3.7 --isolated --no-cache-dir install psycopg2-binary==2.8.6 six psutil pyyaml \
    && pip3.7 --isolated --no-cache-dir install "patroni[kubernetes]==${PATRONI_VERSION}" \
    && PGHOME=/home/postgres \
    && mkdir -p $PGHOME \
    && sed -i "s|/var/lib/postgresql.*|$PGHOME:/bin/bash|" /etc/passwd \
    && echo "PATH=\"$PATH\"" > /etc/environment \
    && echo 'Setting permissions for OpenShift' \
    && chmod 664 /etc/passwd \
    && mkdir -p $PGHOME/pgdata/pgroot \
    && chgrp -R 0 $PGHOME \
    && chown -R postgres $PGHOME \
    && chmod -R 775 $PGHOME
    
 RUN echo 'Cleaning up' \
    && apt-get remove -y git build-essential python3.7-dev python3.7-pip python3.7-wheel python3.7-setuptools \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* /root/.cache
    

COPY contrib/root /

VOLUME /home/postgres/pgdata
USER postgres
WORKDIR /home/postgres

EXPOSE 5432 8008

CMD ["/bin/bash", "/usr/bin/entrypoint.sh"]
