#!/bin/bash
###deploy new monitoring to agents
###vars
work_dir=/usr/lib/zabbix/externalscripts/

mkdir -p $work_dir
cd $work_dir
touch $work_dir/clusterstatus
touch $work_dir/status

#Depoloy clusterstatus script

cat <<EOT > $work_dir/clusterstatus
#!/bin/bash
###exit status###
#Severity status down           1       critical
#Severity status unknown        2       critical
#Severity status starting       3       warning
#Severity state halted          4       warning
#Severity state failed          5       critical
#Severity state unknown         6       critical
#Severity state reforming       7       warning
#Severity auto_run disabled     8       warning
###Vars###
cmd=/usr/local/cmcluster/bin/cmviewcl
log=/var/log/cluster_status
###


if $cmd |awk '{print $2}'|grep 'down'; then
        date >> $log
        echo 'Severity status down' >> $log
        $cmd -f table -l package|grep 'down'  >> $log
        exit 1

        elif $cmd |awk '{print $2}'|grep 'unknown'; then
        date >> $log
        echo 'Severity status unknown' >> $log
        $cmd -f table -l package|grep 'unknown'  >> $log
        exit 2

        elif  $cmd |awk '{print $2}'|grep 'starting';then
        date >> $log
        echo 'Severity status starting '
        $cmd -f table -l package|grep 'starting'  >> $log
        exit 3

        elif  $cmd |awk '{print $3}'|grep 'halted';then
        date >> $log
        echo 'Severity state halted' >> $log
        $cmd -f table -l package|grep 'halted'  >> $log
        exit 4

        elif  $cmd |awk '{print $3}'|grep 'failed';then
        date >> $log
        echo 'Severity state failed' >> $log
        $cmd -f table -l package|grep 'failed'  >> $log
        exit 5

        elif  $cmd |awk '{print $3}'|grep 'unknown';then
        date >> $log
        echo 'Severity state unknown'   >> $log
        $cmd -f table -l package|grep 'unknown'  >> $log
        exit 6

        elif  $cmd |awk '{print $3}'|grep 'reforming';then
        date >> $log
        echo 'Severity state reforming' >> $log
        $cmd -f table -l package|grep 'reforming'  >> $log
        exit 7

        elif  $cmd |awk '{print $4}'|grep 'disabled';then
        date >> $log
        echo 'Severity auto_run disabled' >> $log
        $cmd -f table -l package|grep 'disabled'  >> $log
        exit 8

        else
        date >> $log
        echo 'Cluster is in good state' >> $log
        exit 0


fi
EOT
#Deploy stats script
cat <<EOT > $work_dir/status
#!/bin/bash

log=/var/log/cluster_status

/lib/zabbix/externalscripts/./clusterstatus > $log


echo $?
EOT
#make scripts executable with corect permitions
chmod +x *
chown -R zabbix: /usr/lib/zabbix/
touch /var/log/cluster_status
chown  zabbix:  /var/log/cluster_status
#add new script to zabbix-agents
echo 'UserParameter=clusterstatus,/usr/lib/zabbix/externalscripts/status' >> /etc/zabbix/zabbix_agent2.d/userparams.conf
  
#restart agent and check
systemctl stop zabbix-agent2.service
systemctl start zabbix-agent2.service
systemctl status zabbix-agent2.service
ss -lpnt|grep zab
zabbix_agent2 -p
