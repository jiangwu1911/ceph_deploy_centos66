#!/bin/sh

#Copy rpm files from CentOS66 cd-rom
ISODIR=../iso

rm -f $ISODIR/repodata/*
cp comps.xml $ISODIR
createrepo -g comps.xml $ISODIR

cp ks.cfg $ISODIR
cp configuration.sh $ISODIR/software/cobbler/
cp storage_node.ks $ISODIR/software/cobbler/centos66/
cp bootstrap_admin_node.conf $ISODIR/software/cobbler/

mkisofs -o ceph.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -R -J -V -T $ISODIR
