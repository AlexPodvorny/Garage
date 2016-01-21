

STAGING_DIR=home/alex/openwrt/attitude_adjustment/staging_dir/
export STAGING_DIR
OPENWRT = /home/alex/openwrt/attitude_adjustment

KERNEL = ${OPENWRT}/build_dir/linux-brcm47xx/linux-3.3.8
LD=${OPENWRT}/staging_dir/toolchain-mipsel_gcc-4.6-linaro_uClibc-0.9.33.2/bin/mipsel-openwrt-linux-uclibc-ld
CROSS_COMPILE="mipsel-openwrt-linux-uclibc-"
EXTRA_LDSFLAGS="-I${OPENWRT}/build_dir/linux-brcm47xx -include symtab.h"
KBUILD_HAVE_NLS=no
CONFIG_SHELL="/bin/bash" 

obj-m += mydht.o

all:
	make -C ${KERNEL} ARCH="mips" CC="${OPENWRT}/staging_dir/toolchain-mipsel_gcc-4.6-linaro_uClibc-0.9.33.2/bin/mipsel-openwrt-linux-uclibc-gcc"  M=$(PWD) modules
clean:
	make -C ${KERNEL} CC="${OPENWRT}/staging_dir/toolchain-mipsel_gcc-4.6-linaro_uClibc-0.9.33.2/bin/mipsel-openwrt-linux-uclibc-gcc"  M=$(PWD) clean
