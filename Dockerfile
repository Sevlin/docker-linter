FROM sevoid/slackware:current

LABEL maintainer="sev@nix.org.ua"

ENV TERM=xterm

ENV SHELLCHECK_VER=0.7.2
ENV YAMLLINT_VER=1.26.3
ENV HADOLINT_VER=2.7.0
ENV PHP_CS_FIXER_VER=3.1.0
ENV PHPCS_VER=3.6.0
ENV PYLINT_VER=2.10.2
ENV ANSIBLE_LINT=5.1.3

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY linter.template /etc/slackpkg/templates/

RUN slackpkg update gpg
RUN slackpkg update
RUN slackpkg upgrade-all
RUN slackpkg install-template linter

RUN mkdir -p /usr/local/etc

COPY ./scripts/entrypoint.sh /usr/local/sbin/
COPY ./scripts/lib/lint-common.sh /usr/local/share/lint/
COPY ./scripts/bin/lint-shell /usr/local/bin/
COPY ./scripts/bin/lint-yaml /usr/local/bin/
COPY ./scripts/bin/lint-dockerfile /usr/local/bin/
COPY ./scripts/bin/lint-php /usr/local/bin/

#
# SYS: add user
#
RUN useradd -c 'User for code linters' -m -s /bin/bash linter
RUN usermod -a -G wheel linter

#
# INST: yamllint
#
COPY conf/yamllint.yml /usr/local/etc/
RUN pip install --no-cache-dir -q yamllint==${YAMLLINT_VER}

#
# INST: pylint
#
RUN pip install --no-cache-dir -q pylint==${PYLINT_VER}

#
# INST: shellcheck
#
RUN wget --quiet --output-document - \
        https://github.com/koalaman/shellcheck/releases/download/v${SHELLCHECK_VER}/shellcheck-v${SHELLCHECK_VER}.linux.x86_64.tar.xz \
    | tar -C /usr/local/bin \
          --strip-components=1 \
          -Jxf - shellcheck-v${SHELLCHECK_VER}/shellcheck

#
# INST: hadolint
#
RUN wget --quiet --output-document /usr/local/bin/hadolint \
        https://github.com/hadolint/hadolint/releases/download/v${HADOLINT_VER}/hadolint-Linux-x86_64

#
# INST: php-cs-fixer
#
COPY ./php.ini /etc/
RUN wget --quiet --output-document /usr/local/bin/php-cs-fixer \
       https://github.com/FriendsOfPHP/PHP-CS-Fixer/releases/download/v${PHP_CS_FIXER_VER}/php-cs-fixer.phar

#
# INST: phpcs
#
RUN wget --quiet --output-document /usr/local/bin/phpcs \
       https://github.com/squizlabs/PHP_CodeSniffer/releases/download/${PHPCS_VER}/phpcs.phar

#
# INST: ansible-lint
#
#RUN pip install --no-cache-dir -q "ansible-lint[community]"==${ANSIBLE_LINT}

#
# MISK: owner & permissions
#
RUN chown -v root:root /usr/local/bin/*
RUN chmod -v 0755 /usr/local/bin/*

USER linter
WORKDIR /home/linter

#
# Check that linters can execute
#
RUN echo "=== VERSIONS ===" \
 && shellcheck --version \
 && echo \
 && yamllint --version \
 && echo \
 && hadolint --version \
 && echo \
 && php-cs-fixer --version \
 && echo \
 && phpcs --version \
 && echo \
 && pylint --version \
 && echo

ENTRYPOINT ["/usr/local/sbin/entrypoint.sh"]
