#
# ** THIS IS AN AUTO-GENERATED FILE **
#

################################################################################
# Build stage 0
# Extract Kibana and make various file manipulations.
################################################################################
FROM centos:7 AS prep_files

ADD kibana /usr/share/kibana

RUN mkdir -p /usr/local/ssl/lib/
COPY libcrypto.a /usr/local/ssl/lib/
COPY libssl.a /usr/local/ssl/lib/
COPY libcurl.a /usr/local/lib/ 


ENV PATH=/usr/share/kibana/node/bin:$PATH
RUN ls -l /usr/share/kibana/node/bin
RUN npm -v


RUN yum update -y && yum install -y gcc gcc-c++ make openssl-libs openssl-devel libstdc++ libstdc++-devel libstdc++-static 
RUN rm -rf /usr/share/kibana/node_modules/@elastic/nodegit/build/Release/
RUN chmod -R 777 /usr/share/kibana/node_modules/@elastic/nodegit/
RUN cd /usr/share/kibana/node_modules/@elastic/nodegit/ \
    && npm i -g npm@3.10.10 \
    && npm i -f || true \
    && npm reinstall || true \
    && npm run install

COPY enums.js  /usr/share/kibana/node_modules/@elastic/nodegit/dist/enums.js
RUN yum clean all
WORKDIR /usr/share/kibana


# Ensure that group permissions are the same as user permissions.
# This will help when relying on GID-0 to run Kibana, rather than UID-1000.
# OpenShift does this, for example.
# REF: https://docs.openshift.org/latest/creating_images/guidelines.html


RUN chmod -R g=u /usr/share/kibana


RUN find /usr/share/kibana -type d -exec chmod g+s {} \;


################################################################################
# Build stage 1
# Copy prepared files from the previous stage and complete the image.
################################################################################
FROM centos:7
EXPOSE 5601

# Add Reporting dependencies.
RUN yum update -y && yum install -y fontconfig freetype git wget && yum clean all

# Add an init process, check the checksum to make sure it's a match
COPY dumb-init_1.2.2_arm64 /usr/local/bin/
RUN mv /usr/local/bin/dumb-init_1.2.2_arm64 /usr/local/bin/dumb-init

RUN chmod +x /usr/local/bin/dumb-init


# Bring in Kibana from the initial stage.
COPY --from=prep_files --chown=1000:0 /usr/share/kibana /usr/share/kibana
WORKDIR /usr/share/kibana

ENV ELASTIC_CONTAINER true
ENV PATH=/usr/share/kibana/bin:$PATH

# Set some Kibana configuration defaults.
#COPY --chown=1000:0 kibana/config/kibana.yml /usr/share/kibana/config/kibana.yml

# Add the launcher/wrapper script. It knows how to interpret environment
# variables and translate them to Kibana CLI options.
COPY  --chown=1000:0 kibana-docker /usr/local/bin/

# Ensure gid 0 write permissions for OpenShift.
RUN chmod g+ws /usr/share/kibana && find /usr/share/kibana -gid 0 -and -not -perm /g+w -exec chmod g+w {} \;

# Provide a non-root user to run the process.

LABEL org.label-schema.schema-version="1.0" org.label-schema.vendor="Elastic" org.label-schema.name="kibana" org.label-schema.version="7.5.2" org.label-schema.url="https://www.elastic.co/products/kibana" org.label-schema.vcs-url="https://github.com/elastic/kibana" org.label-schema.license="Elastic License" license="Elastic License"

RUN groupadd --gid 1000 kibana && useradd --uid 1000 --gid 1000 --home-dir /usr/share/kibana --no-create-home kibana
USER kibana

RUN /usr/share/kibana/bin/kibana-plugin remove x-pack


ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]

CMD ["/usr/local/bin/kibana-docker"]
