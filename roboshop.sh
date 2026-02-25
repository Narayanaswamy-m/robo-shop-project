#!/bin/bash
SG_ID="sg-026eda32a5a9ca5d0"
AMI_ID="ami-0220d79f3f480ecf5"
Zone_ID="Z03009921Z8XM6RM874N0"
Domain_Name="swamy.sbs"

for instance in "$@"; do
  instance_id=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type t3.micro \
    --security-group-ids "$SG_ID" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query "Instances[0].InstanceId" \
    --output text )
  if [ "$instance" == "frontend" ]; then
    IP=$(aws ec2 describe-instances \
      --instance-ids "$instance_id" \
      --query "Reservations[*].Instances[*].PrivateIpAddress" \
      --output text )
      Record_Name="$instance.$Domain_Name"
  else
    IP=$(aws ec2 describe-instances \
      --instance-ids "$instance_id" \
      --query "Reservations[*].Instances[*].PublicIpAddress" \
      --output text )
      Record_Name="$instance.$Domain_Name"
  fi
  echo "ipaddress :: $IP"
  aws route53 change-resource-record-sets \
  --hosted-zone-id  $Zone_ID \
  --change-batch ' 
                    {
                    "Comment": "Update record to new IP",
                    "Changes": [
                        {
                        "Action": "UPSERT",
                        "ResourceRecordSet": {
                            "Name": "$Record_Name",
                            "Type": "A",
                            "TTL": 1,
                            "ResourceRecords": [
                            { "Value": "$IP" }
                            ]
                        }
                        }
                    ]
                    }'
                    echo "Record is updated for $instance"

done



