#!/bin/bash

#Author: Marcelo dos Santos
#Version: 1.0
#Last update: Aug 9, 2020
#Description: This script is for creating an ec2 windows instance with keypair, group security and on a specific subnet and during startup changes the computer name.
#Repo: https://github.com/marceloeliassantos/run-ec2
#Website: https://bluehat.site/
#License: MIT License

#Prerequisite steps
# 1. Install AWS Cli 
# 2. Then we need to configure aws to identify your account.
# 3. For that you need Access Key and Security Access Key which can be obtained from AWS Security Credentials
# and download the file or save it where it is secure and don't provide that or share that information with anybody.


echo "===Welcome to BlueHat Tech EC2 instance creation shell script!==="
echo "====================================================================="

#Just in case the user changes the default value, makes a temporary copy of this script to keep the last change.
cp run-ec2.sh run-ec2.tmp

echo
echo "Enter the name of the instance:"
read -p "EC2 instance name:" EC2_TagName
until [[ $EC2_TagName = *[!\ ]* ]]; do
		echo "Blank value is not acceptable!"
		read -p "EC2 instance name:" EC2_TagName
	done
echo

echo "Enter the hostname for Windows Server:"
read -p "Windows Server HostName:" HostName
until [[ $HostName = *[!\ ]* ]]; do
		echo "Blank value is not acceptable!"
		read -p "Windows Server HostName:" HostName
	done
	
#Removes special characters or spaces	
HostName=$(sed 's/[^0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-]//g' <<< "$HostName")

echo

#Add SG to security group naming standard
SG_Name+=${EC2_TagName}" SG" 

#The Key Pair will be the name of the hostname plus the word keypair.
KeyPairName+=${HostName}"-keypair"

#Check parameter changes
changed=0

default_inst_type="m4.xlarge"
echo "Enter the instance type:"
read -p "AMI ID [$default_inst_type]:" inst_Type 
[[ -z "$inst_Type" ]] && inst_Type="$default_inst_type"
echo

#If the user changes the default value, makes a temporary copy of this script to keep the last change.
if [[ $inst_Type != $default_inst_type ]]; then
   changed=1
   echo "$(sed 's/'${default_inst_type}'/'$inst_Type'/g' run-ec2.tmp)" > run-ec2.tmp
fi

default_AMI_Key="ami-0f38562b9d4de0dfe"
echo "Enter the AMI ID:"
read -p "AMI ID [$default_AMI_Key]:" AMI_Key
[[ -z "$AMI_Key" ]] && AMI_Key="$default_AMI_Key"
echo

if [[ $AMI_Key != $default_AMI_Key ]]; then
   changed=1     
   echo "$(sed 's/'${default_AMI_Key}'/'$AMI_Key'/g' run-ec2.tmp)" > run-ec2.tmp
fi

default_SubnetId="subnet-b44222f9"
echo "Enter the Subnet ID:"
read -p "Subnet ID[$default_SubnetId]:" SubnetId
[[ -z "$SubnetId" ]] && SubnetId="$default_SubnetId"
echo

if [[ $SubnetId != $default_SubnetId ]]; then
   changed=1
   echo "$(sed 's/'$default_SubnetId'/'$SubnetId'/g' run-ec2.tmp)" > run-ec2.tmp
fi

echo "Checking the VPC of the provided subnet..."
vpc_id=$(aws ec2 describe-subnets --subnet-ids $SubnetId --query 'Subnets[0].VpcId' --output text)

echo

echo "EC2 instance creation script is ready to begin."
read -n1 -r -p "If all of the above information is correct, Press any key to continue or CTRL+C to exit..."
echo

echo "Crating the security group..."
###Create Security Group
SgId=$(aws ec2 create-security-group --group-name "$SG_Name" --description "$SG_Name" --vpc-id $vpc_id --output text --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value='"$SG_Name"'}]' --query GroupId)

#Get the Public IP
public_ip=$(grep -m 1 -oE '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' <<< "$(wget -T 10 -t 1 -4qO- "http://ip1.dynupdate.no-ip.com/" || curl -m 10 -4Ls "http://ip1.dynupdate.no-ip.com/")")

#If you do not get the public IP, allow general access
[[ -z "$public_ip" ]] && public_ip="0.0.0.0/0"

#If it discover the IP Public, add /32
if [[ $public_ip != "0.0.0.0/0" ]]; then
   public_ip=${public_ip}"/32"
fi

###Create Security Group Rules
echo "Creating group security rules... "
#RDPs
aws ec2 authorize-security-group-ingress --group-id $SgId --ip-permissions IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges='[{CidrIp='$public_ip',Description="Access from Home"}]' > /dev/null

#SSH
#aws ec2 authorize-security-group-ingress --group-id $SgId --ip-permissions IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges='[{CidrIp=172.16.0.0/24,Description="Access from somewhere"}]' > /dev/null

###Http & Https
aws ec2 authorize-security-group-ingress --group-id $SgId --ip-permissions IpProtocol=tcp,FromPort=80,ToPort=80,IpRanges='[{CidrIp=0.0.0.0/0}]' > /dev/null
aws ec2 authorize-security-group-ingress --group-id $SgId --ip-permissions IpProtocol=tcp,FromPort=443,ToPort=443,IpRanges='[{CidrIp=0.0.0.0/0}]' > /dev/null

###DNS, Also its a example of All protocol, All port
aws ec2 authorize-security-group-ingress --group-id $SgId --ip-permissions IpProtocol="-1",FromPort=-1,ToPort=-1,IpRanges='[{CidrIp=9.9.9.9/32,Description="Quad9"}]' > /dev/null
aws ec2 authorize-security-group-ingress --group-id $SgId --ip-permissions IpProtocol="-1",FromPort=-1,ToPort=-1,IpRanges='[{CidrIp=1.1.1.1/32,Description="Cloudflare"}]' > /dev/null

echo "Creating keypair..."
####Create Key-pair
aws ec2 create-key-pair --key-name $KeyPairName --query 'KeyMaterial' --output text > "$KeyPairName.pem"

echo "Creating instance..."

#Change the hostname inside of the userdata.conf
echo "$(sed 's/ComputerName/'$HostName'/g' userdata.conf)" > userdata.conf

####EC2 Creation
instanceId=$(aws ec2 run-instances --image-id $AMI_Key --count 1 --instance-type $inst_Type --key-name $KeyPairName --subnet-id  $SubnetId --associate-public-ip-address --user-data file://userdata.conf --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value='"$EC2_TagName"'}]' 'ResourceType=volume,Tags=[{Key=Name,Value='"$EC2_TagName"'}]'  --security-group-ids $SgId --query 'Instances[0].InstanceId' --output text)

aws ec2 wait instance-running --instance-ids $instanceId

#Change the hostname inside of the userdata.conf back to ComputerName
echo "$(sed 's/'$HostName'/ComputerName/g' userdata.conf)" > userdata.conf

echo "Creation finished. This is the instance ID: $instanceId"
PrivateIP=$(aws ec2 describe-instances --instance-ids $instanceId --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
echo "Private IP: $PrivateIP"
echo "Key pair: "
cat $KeyPairName.pem

#Replaces the temporary file with the original one to get the latest updated parameters.
if [[ $changed -eq 1 ]]; then
   mv run-ec2.tmp run-ec2.sh
   chmod +x run-ec2.sh 
fi
