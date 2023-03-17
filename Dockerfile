FROM ubuntu:latest

RUN apt-get update && \
    apt-get install -y git curl jq && \
    rm -rf /var/lib/apt/lists/*

COPY update_my_files.sh /usr/bin/update_my_files.sh
RUN chmod +x /usr/bin/update_my_files.sh

ENTRYPOINT ["/usr/bin/update_my_files.sh"]
