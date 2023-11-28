FROM alpine:latest

ENV CONCURRENT="50"
ENV THREADS="1"
ENV CPU_SCALING="1"
ENV DURATION="60"
ENV MIN_DURATION="5"
ENV HOST="www.example.com"
ENV IPS="127.0.0.1 127.0.1.1"
ENV URI="/"
ENV PROTO="http"
ENV PAUSE="1"
ENV RANDOMIZE="false"

WORKDIR "/"

RUN apk add bash wrk util-linux-misc

COPY run.sh /run.sh

ENTRYPOINT ["/run.sh"]

