FROM johnwu/ubuntu:latest
MAINTAINER sameer@damagehead.com

#国内构建默认
ARG BUILD_IN_CHINA=false 

#修改国内镜像
ENV GITLAB_VERSION=8.8.7-zh \
    GOLANG_VERSION=1.5.3 \
    GITLAB_SHELL_VERSION=3.2.1 \
    GITLAB_WORKHORSE_VERSION=0.7.8 \
    GITLAB_USER="git" \
    GITLAB_HOME="/home/git" \
    GITLAB_LOG_DIR="/var/log/gitlab" \
    GITLAB_CACHE_DIR="/etc/docker-gitlab" \
    RAILS_ENV=production

ENV GITLAB_INSTALL_DIR="${GITLAB_HOME}/gitlab" \
    GITLAB_SHELL_INSTALL_DIR="${GITLAB_HOME}/gitlab-shell" \
    GITLAB_WORKHORSE_INSTALL_DIR="${GITLAB_HOME}/gitlab-workhorse" \
    GITLAB_DATA_DIR="${GITLAB_HOME}/data" \
    GITLAB_BUILD_DIR="${GITLAB_CACHE_DIR}/build" \
    GITLAB_RUNTIME_DIR="${GITLAB_CACHE_DIR}/runtime"

COPY china_mirrors /etc/apt/sources.list

RUN apt-get update \
 &&  DEBIAN_FRONTEND=noninteractive apt-get install -y supervisor logrotate locales curl \
      nginx openssh-server mysql-client postgresql-client redis-tools \
      git ruby python2.7 python-docutils nodejs gettext-base \
      libmysqlclient-dev libpq5 zlib1g libyaml-0-2 libssl1.0.0 \
      libgdbm3 libreadline6 libncurses5 libffi6 \
      libxml2 libxslt1.1 libcurl3 libicu55 \
 && update-locale LANG=C.UTF-8 LC_MESSAGES=POSIX \
 && locale-gen en_US.UTF-8 \
 && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales \
 && gem install --no-document bundler \
 && rm -rf /var/lib/apt/lists/* 


# RUN if [ "${BUILD_IN_CHINA}" == "true" ]; \
#     then \
#         gem sources --remove https://rubygems.org/ \
#      && gem sources --add https://gems.ruby-china.org/ \
#      && gem install --no-document bundler \
#      && bundle config mirror.https://rubygems.org https://gems.ruby-china.org; \
#     else \
#         gem install --no-document bundler ; \
#     fi
# RUN rm -rf /var/lib/apt/lists/*   

COPY assets/build/ ${GITLAB_BUILD_DIR}/
RUN bash ${GITLAB_BUILD_DIR}/install.sh

COPY assets/runtime/ ${GITLAB_RUNTIME_DIR}/
COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

EXPOSE 22/tcp 80/tcp 443/tcp

VOLUME ["${GITLAB_DATA_DIR}", "${GITLAB_LOG_DIR}"]
WORKDIR ${GITLAB_INSTALL_DIR}
ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["app:start"]
