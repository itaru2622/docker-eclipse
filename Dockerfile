ARG base=debian:bullseye
FROM ${base}
ARG base

RUN apt update; \
    apt install -y openjdk-17-jdk screen bash-completion git make sudo curl \
                   x11-apps libswt-gtk-4-java

ARG eclipse_dl=https://ftp.jaist.ac.jp/pub/eclipse/technology/epp/downloads/release/2023-03/R/eclipse-java-2023-03-R-linux-gtk-x86_64.tar.gz
RUN curl -L "${eclipse_dl}" -o /tmp/eclipse.tgz; \
    mkdir -p /opt; gzip -d < /tmp/eclipse.tgz | tar xvf - -C /opt ; \
    rm -f /tmp/eclipse.tgz

ENV PATH    ${PATH}:/opt/eclipse

# install eclipse-plugin, cf. https://www.lorenzobettini.it/2012/10/installing-eclipse-features-via-the-command-line/
#             https://github.com/SOM-Research/jsonSchema-to-uml
#
RUN eclipse \
      -repository https://som-research.github.io/jsonSchema-to-uml/update/,https://download.eclipse.org/releases/latest \
      -installIUs edu.uoc.som.jsonschematouml,edu.uoc.som.jsonschematouml.test,edu.uoc.som.jsonschematouml.ui \
      -application org.eclipse.equinox.p2.director -noSplash -clean -purgeHistory ; \
    eclipse \
      -repository https://download.eclipse.org/releases/latest \
      -installIUs org.eclipse.papyrus.sdk.feature.feature.group \
      -application org.eclipse.equinox.p2.director -noSplash -clean -purgeHistory

ARG uid=1000
ARG uname=eclipse
RUN addgroup --system --gid ${uid} ${uname} ; \
    adduser  --system --gid ${uid} --uid ${uid} --shell /bin/bash ${uname} ; \
    echo "${uname}:${uname}" | chpasswd; \
    (cd /etc/skel; find . -type f -print | tar cf - -T - | tar xvf - -C/home/${uname} ) ; \
    echo "${uname} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/local-user; \
    mkdir -p /home/${uname}/.ssh ;\
    chown -R ${uname} /home/${uname} /opt/*

ENV DISPLAY :0
USER ${uname}
CMD eclipse
