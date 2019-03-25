#!/bin/sh
set -e

if [ $(id -u) -ne 0 ]; then
  echo "Error: Please run as root"
  exit 1
fi

if [ -z ${name+x} ] || [ -z ${cmd+x} ]; then
	echo "Error: Please set name and cmd parameter"
        echo "usage: cat create.sh | name=\"x\" cmd=\"y\" [user dir desc deps (escape \$ with \\)] bash"
	exit 1
fi

if [ -f "/etc/init.d/$name" ]; then
	echo "Error: Service '$name' already exists"
	exit 1
fi

serviceTemplate="`cat service.template`"
logrotateTemplate="`cat logrotate.template`"

serviceTemplate="${serviceTemplate//<CMD>/$cmd}"
serviceTemplate="${serviceTemplate//<NAME>/$name}"
serviceTemplate="${serviceTemplate//<USER>/${user:-}}"
serviceTemplate="${serviceTemplate//<DIR>/${dir:-}}"
serviceTemplate="${serviceTemplate//<DESC>/${desc:-Starting $name}}"
serviceTemplate="${serviceTemplate//<DEPS>/${deps:-\$remote_fs \$syslog}}"

logrotateTemplate="${logrotateTemplate//<NAME>/$name}"

echo "...creating service in /etc/init.d"
echo -e "$serviceTemplate" > "/etc/init.d/$name"
chmod +x "/etc/init.d/$name"
echo "...creating log files in /var/log"
touch "/var/log/$name.log"
chown "$user" "/var/log/$name.log"
touch "/var/log/$name.err"
chown "$user" "/var/log/$name.err"
echo "...adding logrotate configuration"
echo -e "$logrotateTemplate" > "/etc/logrotate.d/$name"
echo "...adding service for startup at boot"
update-rc.d "$name" defaults
echo "finished"

service "$name" start
