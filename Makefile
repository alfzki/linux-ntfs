# SPDX-License-Identifier: GPL-2.0

ifneq ($(KERNELRELEASE),)
CONFIG_NTFS_FS ?= m
CONFIG_NTFS_FS_WOF_COMPRESSION ?= y
obj-$(CONFIG_NTFS_FS) += ntfs.o

ntfs-y := aops.o attrib.o collate.o dir.o file.o index.o inode.o \
	  mft.o mst.o namei.o runlist.o super.o unistr.o attrlist.o ea.o \
	  upcase.o bitmap.o lcnalloc.o logfile.o reparse.o compress.o \
	  iomap.o debug.o sysctl.o object_id.o bdev-io.o

ntfs-$(CONFIG_NTFS_FS_WOF_COMPRESSION) += wof.o \
	lib/decompress_common.o lib/lzx_decompress.o lib/xpress_decompress.o

ccflags-$(CONFIG_NTFS_DEBUG) += -DDEBUG
ccflags-$(CONFIG_FS_POSIX_ACL) += -DCONFIG_NTFS_FS_POSIX_ACL=1
ccflags-$(CONFIG_NTFS_FS_WOF_COMPRESSION) += -DCONFIG_NTFS_FS_WOF_COMPRESSION=1
else
# Called from external kernel module build

KERNELRELEASE	?= $(shell uname -r)
KDIR	?= /lib/modules/${KERNELRELEASE}/build
MDIR	?= /lib/modules/${KERNELRELEASE}
PWD	:= $(shell pwd)

export CONFIG_NTFS_FS := m

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean

help:
	$(MAKE) -C $(KDIR) M=$(PWD) help

install: ntfs.ko
	rm -f ${MDIR}/kernel/fs/ntfs/ntfs.ko
	install -m644 -b -D ntfs.ko ${MDIR}/kernel/fs/ntfs/ntfs.ko
	depmod -aq

uninstall:
	rm -rf ${MDIR}/kernel/fs/ntfs
	depmod -aq

PACKAGE_NAME ?= ntfs
PACKAGE_VERSION ?= 1.0
SRC_DIR ?= /usr/src/$(PACKAGE_NAME)-$(PACKAGE_VERSION)

dkms_install dkms-install:
	dkms remove -m $(PACKAGE_NAME) -v $(PACKAGE_VERSION) --all || true
	rm -rf $(SRC_DIR)
	mkdir -p $(SRC_DIR)
	cp -r * $(SRC_DIR)/
	$(MAKE) -C $(SRC_DIR) clean || true
	dkms add -m $(PACKAGE_NAME) -v $(PACKAGE_VERSION)
	dkms build -m $(PACKAGE_NAME) -v $(PACKAGE_VERSION)
	dkms install -m $(PACKAGE_NAME) -v $(PACKAGE_VERSION)

dkms_uninstall dkms-uninstall:
	dkms remove -m $(PACKAGE_NAME) -v $(PACKAGE_VERSION) --all || true
	rm -rf $(SRC_DIR)

endif

.PHONY : all clean install uninstall dkms_install dkms_uninstall dkms-install dkms-uninstall
