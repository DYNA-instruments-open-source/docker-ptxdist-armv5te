#!/bin/bash

exec docker build --build-arg http_proxy=$http_proxy --tag dynainstrumentsoss/ptxdist-arm-v5te .
