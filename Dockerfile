FROM alpine:latest

ENV CONCURRENT="500"
ENV THREADS="1"
ENV CPU_SCALING="1"
ENV DURATION="1h"
ENV HOST="www.example.com"
ENV IPS="127.0.0.1 127.0.1.1"
ENV URI="/"
ENV PROTO="http"

WORKDIR "/"

RUN apk add bash wrk util-linux-misc

COPY wrk.sh /wrk.sh

ENTRYPOINT ["/wrk.sh"]

