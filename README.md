# Wrk container for load tests

This container will run a number of `wrk` processes. The exact number is determined by the number of
cores in the system multiplied by the `CPU_SCALING` factor.

Each process will run `THREADS` threads and create `CONCURRENT` connections to the target,
and run for `DURATION` (minutes) time.

The targets will be selected randomly from the `IPS`, which is a space seperated list of IP addresses.
The Host header used when connecting will be determined by the `HOST` setting, and the URI Path by the `URI`.

The protocol used will be determined by the `PROTO` (http|https) setting, and the port will be
the standard port unless you provide a `PORT`.

Defaults
```
ENV CONCURRENT="50"
ENV THREADS="1"
ENV CPU_SCALING="1"
ENV DURATION="1"
ENV HOST="www.example.com"
ENV IPS="127.0.0.1 127.0.1.1"
ENV URI="/"
ENV PROTO="http"
ENV PAUSE="10"
ENV RANDOMIZE="false"
```

You may also provide a `PORT` parameter if you are running the `PROTO` (http|https) on a non-standard port.

## RANDOMIZE
If you set `RANDOMIZE=true` then all other values are considered maximums and each wrk process will launch
with a value between 1 and the current setting.

Download from docker hub: [tuxinvader/wrkit](https://hub.docker.com/r/tuxinvader/wrkit)

