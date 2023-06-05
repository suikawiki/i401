FROM quay.io/wakaba/docker-perl-app-base

ADD Makefile /app/
ADD config/ /app/config/
ADD lib/ /app/lib/
ADD modules/ /app/modules/

RUN cd /app && \
    make deps-docker PMBP_OPTIONS="--execute-system-package-installer --dump-info-file-before-die" && \
    rm -rf /var/lib/apt/lists/* /app/local/pmbp/tmp /app/deps

#CMD ["/server"]

## License: Public Domain.
