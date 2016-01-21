#!/bin/bash

STAGING_DIR=/home/alex/openwrt/openwrt/staging_dir
export STAGING_DIR
$STAGING_DIR/toolchain-mipsel_gcc-4.6-linaro_uClibc-0.9.33.2/bin/mipsel-openwrt-linux-uclibc-gcc \
 -I$STAGING_DIR/target-mipsel_uClibc-0.9.33.2/usr/include/modbus \
 -L$STAGING_DIR/target-mipsel_uClibc-0.9.33.2/usr/lib \
 -lmodbus modserver.c -o modserver
