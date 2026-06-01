FROM ubuntu:22.04

LABEL maintainer="第11组"
LABEL description="Hexo + Docker + GitHub 个人知识库"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

RUN apt-get update && apt-get install -y \
    curl git tzdata openssh-client ca-certificates \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://nodejs.org/dist/v20.19.0/node-v20.19.0-linux-x64.tar.gz \
    | tar -xz -C /usr/local --strip-components=1 \
    && node --version && npm --version

RUN npm config set registry https://registry.npmmirror.com \
    && npm install -g hexo-cli \
    && npm install -g cnpm --registry=https://registry.npmmirror.com

WORKDIR /blog
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
EXPOSE 4000
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
