FROM mcr.microsoft.com/devcontainers/base:noble

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive && \
    apt-get -y install --no-install-recommends \
        build-essential \
        libuv1-dev \
        libxml2-dev \
        r-base-dev \
        r-recommended && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/local/lib/R/site-library && \
    chown -R vscode:vscode /usr/local/lib/R/site-library

USER vscode

RUN R -e "install.packages('languageserver')" && \
    R -e "install.packages('minpack.lm')"
