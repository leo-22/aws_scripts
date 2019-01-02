#!/bin/bash

#Set variables
snaplist=/tmp/snap_names.txt
snapshotname=mysnapshot
retention=7
targetdate=$(date +%F -d "-$retention days")
deleteid=$(aws ec2 describe-snapshots --filters Name=start-time,Values="$targetdate*" Name=tag-key,Values="Name" Name=tag-value,Values="blogs" --query 'Snapshots[*].{ID:SnapshotId}' --output text)
volid=`aws ec2 describe-volumes --query 'Volumes[*].[VolumeId]' --region us-east-1 |grep [a-z]|sed 's/"//g'`
snapname=`aws ec2 describe-volumes --query 'Volumes[*].[Tags[0].Value]' --region us-east-1 |grep [a-z]|sed 's/"//g'`

rm $snaplist

# Get list of current snapshot names in environment
aws ec2 describe-snapshots --filters Name=tag-value,Values=* --output text --owner-id 181218121805|grep -v SNAPSHOTS|sort -u|awk '{print $3}' > $snaplist

if [ $deleteid ]
    then
        aws ec2 delete-snapshot --snapshot-id $deleteid
fi
instanceid=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
for volumeid in $(aws ec2 describe-volumes --filters Name=attachment.instance-id,Values=$instanceid --query "Volumes[*].{ID:VolumeId}" --output text)
do
    rightnow=$(date)
    snapshotid=$(aws ec2 create-snapshot --volume-id $volumeid --description "$rightnow" --query "{ID:SnapshotId}" --output text)
    aws ec2 create-tags --resources $snapshotid --tags Key=Name,Value=$snapshotname
done