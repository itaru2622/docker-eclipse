ARG base=debian:bullseye
FROM ${base}
ARG base

# use bash instead of sh in RUN command
SHELL ["/bin/bash", "-c"]

RUN apt update;

RUN if [[ ${base} != *"jdk"* ]] || [[ ${base} != *"java"* ]] ; \
    then \
        apt install -y openjdk-17-jdk; \
    fi

RUN  apt install -y screen bash-completion git make sudo curl \
                    x11-apps libswt-gtk-4-java webkit2gtk-driver graphviz

# download URLs:
#  choice 1:  normal edition       https://ftp.jaist.ac.jp/pub/eclipse/technology/epp/downloads/release/2023-03/R/eclipse-java-2023-03-R-linux-gtk-x86_64.tar.gz
#  choice 2:  modeling edition     https://ftp.jaist.ac.jp/pub/eclipse/technology/epp/downloads/release/2023-03/R/eclipse-modeling-2023-03-R-linux-gtk-x86_64.tar.gz

ARG eclipse_dl=https://ftp.jaist.ac.jp/pub/eclipse/technology/epp/downloads/release/2023-03/R/eclipse-modeling-2023-03-R-linux-gtk-x86_64.tar.gz
RUN curl -L "${eclipse_dl}" -o /tmp/eclipse.tgz ; \
    mkdir -p /opt; gzip -d < /tmp/eclipse.tgz | tar xvf - -C /opt ; rm -f /tmp/eclipse.tgz

ENV PATH    ${PATH}:/opt/eclipse

# install eclipse-plugin, cf. https://www.lorenzobettini.it/2012/10/installing-eclipse-features-via-the-command-line/
#             https://www.eclipse.org/papyrus/
#             https://github.com/hallvard/plantuml.git
#             https://github.com/SOM-Research/jsonSchema-to-uml.git
#
RUN eclipse \
      -repository https://download.eclipse.org/releases/latest \
      -installIUs org.eclipse.papyrus.sdk.feature.feature.group,org.eclipse.ocl.examples.feature.group \
      -application org.eclipse.equinox.p2.director -noSplash -clean -purgeHistory ; \
    eclipse \
      -repository http://hallvard.github.io/plantuml \
      -installIUs net.sourceforge.plantuml.ecore.feature,net.sourceforge.plantuml.feature,net.sourceforge.plantuml.lib.elk.feature,net.sourceforge.plantuml.lib.feature \
      -application org.eclipse.equinox.p2.director -noSplash -clean -purgeHistory ; \
    eclipse \
      -repository https://som-research.github.io/jsonSchema-to-uml/update/,https://download.eclipse.org/releases/latest \
      -installIUs edu.uoc.som.jsonschematouml,edu.uoc.som.jsonschematouml.ui,edu.uoc.som.jsonschematouml.test \
      -application org.eclipse.equinox.p2.director -noSplash -clean -purgeHistory ;

ARG uid=1000
ARG uname=eclipse
RUN addgroup --system --gid ${uid} ${uname} ; \
    adduser  --system --gid ${uid} --uid ${uid} --shell /bin/bash ${uname} ; \
    echo "${uname}:${uname}" | chpasswd; \
    (cd /etc/skel; find . -type f -print | tar cf - -T - | tar xvf - -C/home/${uname} ) ; \
    echo "${uname} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/local-user; \
    mkdir -p /home/${uname}/.ssh /work ;\
    chown -R ${uname}:${uname} /home/${uname} /opt/* /work

WORKDIR /work
ENV DISPLAY :0
USER ${uname}
CMD eclipse
