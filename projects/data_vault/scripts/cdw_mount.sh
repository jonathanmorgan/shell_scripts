#!/bin/bash
SCRIPTDIR="$(dirname $0)"
VOLUMEDIR=/data/volumes
WAREHOUSE=/data/warehouse

# must be run as root
if [[ $EUID != 0 ]]; then
  echo "This must be run as root."
  exit 1
fi


echo -n "Enter Passphrase: "
stty -echo
read keyPass
stty echo
echo

for i in {0..7}
do
    volPath=$(printf "${VOLUMEDIR}/warehouse.%02d.tc" $i)
    loopDev=$(losetup -f $volPath --show)
    expect <<EOF
spawn tcplay -k ${SCRIPTDIR}/warehouse.key -d ${loopDev} -m dw${i}
set prompt ":|#|\\\$"
expect "Passphrase:"
send "${keyPass/\$/\\\$}\n"
expect eof
EOF
done

vgchange -ay vg_warehouse
mount -t ext4 /dev/vg_warehouse/lv_warehouse ${WAREHOUSE}
