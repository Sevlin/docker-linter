FROM vbatts/slackware:current

ENV PYLINT_VER=2.6.0

COPY slackpkg.conf /etc/slackpkg/

RUN touch /var/lib/slackpkg/current \
 && slackpkg update \
 && slackpkg install perl ca-certificates dcron \
 && echo 'https://mirrors.nix.org.ua/linux/slackware/slackware64-current/' > /etc/slackpkg/mirrors \
 && slackpkg update gpg \
 && slackpkg update \
 && slackpkg upgrade-all \
 && slackpkg install python3 python-pip python-setuptools \
 && pip install -q pylint==${PYLINT_VER}

LABEL maintainer="sev@nix.org.ua"

