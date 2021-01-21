FROM registry.access.redhat.com/ubi8/ubi:latest

# https://jfrog.com/getcli/
RUN curl -fL https://getcli.jfrog.io | bash && cp jfrog /usr/local/bin

RUN yum install -y git

COPY artigit.bash /usr/local/bin

ENTRYPOINT /usr/local/bin/artigit.bash
