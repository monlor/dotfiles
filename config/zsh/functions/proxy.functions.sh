#!/bin/bash

setproxy() {
    export HTTP_PROXY=${HTTP_PROXY_ADDR:-127.0.0.1:7890}
    export HTTPS_PROXY=${HTTP_PROXY_ADDR:-127.0.0.1:7890}
    export NO_PROXY=localhost,127.0.0.1,.example.com
}

unsetproxy() {
    unset HTTP_PROXY
    unset HTTPS_PROXY
}