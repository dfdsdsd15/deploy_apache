#!/bin/bash
#set -x
## Variables
ANS_HOST_FILE=/root/deploy_apache/ansible/hosts
JEN_PLUGIN_FILE=/var/lib/jenkins/jenkins.plugins.publish_over_ssh.BapSshPublisherPlugin.xml
CONF_FILES=($ANS_HOST_FILE $JEN_PLUGIN_FILE)
## Colors ##
LYELLOW='\033[1;33m'    #  ${LYELLOW}
# Asking new apache address
 
echo -e ${LYELLOW} enter apache address
tput sgr0
read -p 'Apache EC2 Public Addr: ' IPVAR 
 
echo "Your's new ip Apache address is $IPVAR"
ping 127.0.0.1 -c 3 > /dev/null 2>&1
echo "It will be set in next files:"
ping 127.0.0.1 -c 1 > /dev/null 2>&1
echo

for t in ${CONF_FILES[@]}; do
  echo -e ${LYELLOW} - $t
  sed -i "s/XXX.XXX.XXX.XXX/$IPVAR/" $t
done
echo 
tput sgr0

#read -p "Waiting 10 seconds " -t 10 -n 1
#for m in ${CONF_FILES[@]}; do
#  sed -i "s/XXX.XXX.XXX.XXX/$IPVAR/" $m
#done
echo "Changed!"
systemctl restart jenkins.service

read -p "Waiting 180 seconds for changing httpd.conf" -t 180 -n 1

cd /root/MyWebSite
curl -o index.html http://$IPVAR:81 && git add ./index.html && git commit -m "Apache_configured" && git push
echo "Check your's web address: http://$IPVAR:81"
echo "Now you can make a commit in GitHub and watch, how it works!"

exit 0
