# Wrk container for load tests

This container will run a number of `wrk` processes. The exact number is determined by the number of
cores in the system multiplied by the `CPU_SCALING` factor. 

If you want to use fewer cores, then set `$CPU_CORES` to the number of cores you want to use.
If `CPU_CORES` is greater than cores in the system or it's set to zero (0) then it will be ignored.

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
ENV CPU_CORES="0"
ENV DURATION="60"
ENV MIN_DURATION="5"
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

If you want the duration to have a minimum then set `MIN_DURATION` to that value, but this will result in 
a range of: `$MIN_DURATION` to `$DURATION + $MIN_DURATION`

The concurrency is also randomised, if you want a fixed concurrency, then set `CONCURRENT_FIXED=true`

Download from docker hub: [tuxinvader/wrkit](https://hub.docker.com/r/tuxinvader/wrkit)

