FROM ubuntu:latest

RUN apt-get update && \
    apt-get install -y git curl jq && \
    rm -rf /var/lib/apt/lists/*

COPY temp_cf.sh /usr/bin/tmpl_cf.sh
RUN chmod +x /usr/bin/tmpl_cf.sh

ENTRYPOINT ["/usr/bin/tmpl_cf.sh"]
