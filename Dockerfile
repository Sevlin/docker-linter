FROM vbatts/slackware:current

LABEL maintainer="sev@nix.org.ua"

ENV SHELLCHECK_VER=0.7.1 \
    YAMLLINT_VER=1.25.0 \
    HADOLINT_VER=1.19.0 \
    PYLINT_VER=2.6.0 \
    ANSIBLE_LINT=4.3.7

COPY slackpkg.conf /etc/slackpkg/
COPY sudoers /etc/sudoers

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

#
# SYS: configuration and upgrades
#
RUN chmod 440 /etc/sudoers \
 && touch /var/lib/slackpkg/current \
 && slackpkg update \
 && slackpkg install perl ca-certificates dcron \
 && echo 'https://mirrors.nix.org.ua/linux/slackware/slackware64-current/' > /etc/slackpkg/mirrors \
 && slackpkg update gpg \
 && slackpkg update \
 && slackpkg upgrade-all \
 && slackpkg install sudo \
                     python3 \
                     python-pip \
                     python-setuptools \
 && rm -rf /var/lib/slackpkg/* \
           /var/cache/packages/*

#
# SYS: add user
#
RUN useradd -c 'User for code linters' -m -s /bin/bash linter \
 && usermod -a -G wheel linter

#
# INST: pylint
#
RUN pip install --no-cache-dir -q yamllint==${YAMLLINT_VER}

#
# INST: pylint
#
RUN pip install --no-cache-dir -q pylint==${PYLINT_VER}

#
# INST: shellcheck
#
RUN wget --quiet --no-check-certificate --output-document - \
        https://github.com/koalaman/shellcheck/releases/download/v${SHELLCHECK_VER}/shellcheck-v${SHELLCHECK_VER}.linux.x86_64.tar.xz \
    | tar -C /usr/local/bin \
          --strip-components=1 \
          -Jxf - shellcheck-v${SHELLCHECK_VER}/shellcheck

#
# INST: hadolint
#
RUN wget --quiet --no-check-certificate --output-document /usr/local/bin/hadolint \
        https://github.com/hadolint/hadolint/releases/download/v${HADOLINT_VER}/hadolint-Linux-x86_64

#
# INST: ansible-lint
#
RUN pip install --no-cache-dir -q "ansible-lint[community]"==${ANSIBLE_LINT}

#
# MISK: owner & permissions
#
RUN chown root:root /usr/local/bin/* \
 && chmod 0755 /usr/local/bin/*

USER linter

#
# Check that linters can execute
#
RUN echo "=== VERSIONS ===" \
 && for LINTER in shellcheck \
                  yamllint \
                  hadolint \
                  pylint \
                  ansible-lint; \
    do \
        ${LINTER} --version; \
        echo ""; \
    done
