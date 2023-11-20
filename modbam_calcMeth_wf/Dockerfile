FROM ubuntu:20.04

LABEL maintainer="Shloka Negi, shnegi@ucsc.edu"

RUN mkdir -p /home/apps

RUN cd /home/apps && \
    apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends vim git wget make build-essential cmake \
    tabix python3.8 python3.8-dev python3-pip \
    protobuf-compiler pkg-config libprotobuf-dev libjansson-dev libhts-dev libncurses-dev \
    libbz2-dev liblzma-dev zlib1g-dev autoconf libcurl4-openssl-dev curl libomp-dev libssl-dev python3-tk && \
    pip3 install modbamtools

ENV PATH="/home/apps/:${PATH}"

WORKDIR /home