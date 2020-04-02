#!/usr/bin/env bash
set -ueo pipefail
echo 'Configuring prometheus EBS'
# adapted from
# https://medium.com/@moonape1226/mount-aws-ebs-on-ec2-automatically-with-cloud-init-e5e837e5438a
# [Last accessed on 2020-04-02]
vol=$(lsblk | grep -e disk | awk '{sub("G","",$4)} {if ($4+0 == ${volume_size}) print $1}')
mkdir -p /srv/prometheus
while true; do
  lsblk | grep -q "$vol" && break
  echo "still waiting for volume /dev/$vol ; sleeping 5"
  sleep 5
done
echo "found volume /dev/$vol"
if [ -z "$(lsblk | grep "$vol" | awk '{print $7}')" ] ; then
  if file -s "/dev/$vol" | grep -q ": data" ; then
    echo "volume /dev/$vol is not formatted ; formatting"
    mkfs -F -t ext4   "/dev/$vol"
  fi
  echo "volume /dev/$vol is formatted"
  if [ -z "$(lsblk | grep "$vol" | awk '{print $7}')" ] ; then
    echo "volume /dev/$vol is not mounted ; mounting"
    mount "/dev/$vol" /srv/prometheus
  fi
  echo "volume /dev/$vol is mounted ; writing fstab entry"
  if grep -qv "/dev/$vol" /etc/fstab ; then
    UUID=$(blkid /dev/$vol -s UUID -o value)
    echo "UUID=$UUID /srv/prometheus ext4 defaults,nofail 0 2" >> /etc/fstab
  fi
fi

echo "This string will be used to cause the instance to cycle."
