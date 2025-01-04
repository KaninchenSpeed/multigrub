#!/bin/bash

ROOT_PARTITION='(hd0,gpt2)'
GRUB_UUID='<EFI-partition-id>'
TMP_ROOT='/tmp/multigrub'

grubroot="$TMP_ROOT/grub/boot/grub"

function updateIso {
    isofile=$1
    echo ">>> updating iso $isofile"
    mount -o loop $isofile $TMP_ROOT/iso

    configName=$(echo "$isofile" | sed 's/.iso/.cfg/')
    configPath="$grubroot/iso/$configName"

    cat >> $grubroot/grub.cfg << EOF
menuentry "$isofile" {
    configfile /boot/grub/iso/$configName
}
EOF


    while read filepath; do
        file=$(cat $filepath)
        echo "reading file $filepath"

        while IFS=':' read -ra rline; do
            line=${rline[0]}
#             echo "initrd found in $filepath at $line"
            entryline=$line
            while [[ $(echo "$file" | sed "${entryline}!d") != *"menuentry"* ]]; do
                ((entryline--))
            done

            linuxline=$line
            while [[ $(echo "$file" | sed "${linuxline}!d") != *"linux"* ]]; do
                ((linuxline--))
            done

            #improve this
            if [[ $entryline == "1" ]]; then
                continue
            fi
            if [[ $linuxline == "1" ]]; then
                continue
            fi

            menuentryLine=$(echo "$file" | sed "${entryline}!d")
            menuentryName=$(echo "$menuentryLine" | cut -d '"' -f 2 | sed 's/\n//g')

            initrdLine=$(echo "$file" | sed "${line}!d")
            initrdPath=$(echo "$initrdLine" | xargs | cut -d ' ' -f 2- | sed 's/\n//g')

            kernelLine=$(echo "$file" | sed "${linuxline}!d")
            kernelPath=$(echo "$kernelLine" | xargs | cut -d ' ' -f 2- | sed 's/\n//g' | sed 's/\(.*\)findiso=[^ ]*\(.*\)/\1\2/g' | sed 's/\(.*\)img_dev=[^ ]*\(.*\)/\1\2/g' | sed 's/\(.*\)img_loop=[^ ]*\(.*\)/\1\2/g' | sed 's/\(.*\)driver=[^ ]*\(.*\)/\1\2/g' | sed 's/$2/x86_64/' | sed 's/  / /g')



            echo "found menuentry \"$menuentryName\""
            echo "  initrd: $initrdPath"
            echo "  kernel: $kernelPath"
            echo ">> saved at: $configPath"



            cat >> $configPath << EOF
menuentry "$menuentryName" {
    set root=$ROOT_PARTITION
    set isofile='/$isofile'
    set dri="free"
    search --no-floppy -f --set=root $isofile
    probe -u $root --set=abc
    set pqr="/dev/disk/by-uuid/$abc"
    loopback loop $ROOT_PARTITION\$isofile
    linux (loop)$kernelPath findiso=\${isofile} img_dev=\$pqr img_loop=\$isofile driver=\$dri
    initrd (loop)$(echo $initrdPath | sed 's/ / (loop)/g')
}

EOF
        done < <(echo "$file" | grep -n "\sinitrd\s" | grep ".img" | grep -v "#")
    done < <(ls $TMP_ROOT/iso/boot/grub/*.cfg)

    umount $TMP_ROOT/iso
}



umount /dev/disk/by-uuid/$GRUB_UUID
mkdir -p $TMP_ROOT/grub
mkdir -p $TMP_ROOT/iso
mount /dev/disk/by-uuid/$GRUB_UUID $TMP_ROOT/grub

rm $grubroot/grub.cfg
cp $grubroot/grub.base.cfg $grubroot/grub.cfg
mkdir -p $grubroot/iso
rm $grubroot/iso/*

while read isofile; do
    updateIso $isofile
done < <(ls *.iso)

umount $TMP_ROOT/grub
