FROM ubuntu:latest

ENV XDG_CONFIG_HOME /github/workspace
ENV WRANGLER_HOME /github/workspace

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y build-essential curl nodejs
RUN curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain nightly -y && \
    curl -fsSL https://deb.nodesource.com/setup_current.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g wrangler && \
    npm update -g && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]