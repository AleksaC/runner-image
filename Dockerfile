FROM ubuntu:focal

RUN : \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        dumb-init \
        gcc \
        g++ \
        git \
        gnupg2 \
        libffi-dev \
        libyaml-dev \
        make \
        python2-dev \
        python3-dev \
        python3-distutils \
        ruby-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && :

RUN : \
    && . /etc/lsb-release \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys F23C5A6CF475977595C89F51BA6932366A755776 \
    && echo deb http://ppa.launchpad.net/deadsnakes/ppa/ubuntu $DISTRIB_CODENAME main > /etc/apt/sources.list.d/deadsnakes.list \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        python3.6-dev \
        python3.7-dev \
        python3.7-distutils \
        python3.9-dev \
        python3.9-distutils \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && :

RUN : \
    && . /etc/lsb-release \
    && curl -sSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - \
    && echo deb https://deb.nodesource.com/node_14.x $DISTRIB_CODENAME main > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && :

ENV \
    PATH=/venv/bin:$PATH \
    PRE_COMMIT_HOME=/pc \
    npm_config_cache=/tmp/npm \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    VIRTUALENV_NO_PERIODIC_UPDATE=1 \
    VIRTUALENV_PIP=embed \
    VIRTUALENV_SETUPTOOLS=embed \
    VIRTUALENV_WHEEL=embed
COPY requirements.txt /tmp/requirements.txt
RUN : \
    && curl --silent --location --output /tmp/virtualenv.pyz https://bootstrap.pypa.io/virtualenv/3.8/virtualenv.pyz \
    && python3 /tmp/virtualenv.pyz /venv \
    && pip install \
        --disable-pip-version-check \
        --no-cache-dir \
        --requirement /tmp/requirements.txt \
    && rm -rf ~/.local /tmp/virtualenv.pyz \
    && :

# ensure virtualenv appdata cache is populated
ENV \
    VIRTUALENV_OVERRIDE_APP_DATA=/opt/virtualenv/cache \
    VIRTUALENV_SYMLINK_APP_DATA=1
COPY build/seed-virtualenv-cache /tmp/seed-virtualenv-cache
RUN /tmp/seed-virtualenv-cache
ENV VIRTUALENV_READ_ONLY_APP_DATA=1

ARG GO=1.15.6
ARG GO_SHA256=3918e6cc85e7eaaa6f859f1bdbaac772e7a825b0eb423c63d3ae68b21f84b844
ENV PATH=/opt/go/bin:$PATH XDG_CACHE_HOME=/tmp/cache GOFLAGS=-modcacherw
RUN : \
    && mkdir -p /opt \
    && curl --location --silent --output go.tgz https://golang.org/dl/go${GO}.linux-amd64.tar.gz \
    && echo "${GO_SHA256}  go.tgz" | sha256sum --check \
    && tar -C /opt -xf go.tgz \
    && rm -rf /opt/go/doc /opt/go/test \
    && rm go.tgz

ENTRYPOINT ["dumb-init", "--"]
