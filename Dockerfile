FROM vbatts/slackware:current

LABEL maintainer="sev@nix.org.ua"

ENV SHELLCHECK_VER=0.7.1 \
    YAMLLINT_VER=1.26.0 \
    HADOLINT_VER=2.1.0 \
    PYLINT_VER=2.7.2 \
    ANSIBLE_LINT=4.3.7

COPY slackpkg.conf /etc/slackpkg/
COPY sudoers /etc/sudoers.d/10-wheel

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

#
# SYS: configuration and upgrades
#
RUN echo 'http://mirrors.nix.org.ua/linux/slackware/slackware64-current/' > /etc/slackpkg/mirrors \
 && touch /var/lib/slackpkg/current \
 && slackpkg update \
 && slackpkg update gpg \
 && slackpkg install glibc aaa_libraries \
                     perl ca-certificates \
                     dcron sudo acl attr \
                     libcap elogind libpwquality \
                     e2fsprogs cracklib \
                     krb5 pam slackpkg \
                     sysklogd libnsl libtirpc \
 && rm -rf /var/lib/slackpkg/* \
           /var/cache/packages/*

COPY slackpkg.conf.new /etc/slackpkg/slackpkg.conf

RUN echo 'http://mirrors.nix.org.ua/linux/slackware/slackware64-current/' > /etc/slackpkg/mirrors \
 && touch /var/lib/slackpkg/current \
 && slackpkg new-config \
 && slackpkg update \
 && slackpkg upgrade-all \
 && slackpkg install python3 \
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
