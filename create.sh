#!/bin/bash
set -e

serviceTemplate="`cat service.template`"
logrotateTemplate="`cat logrotate.template`"

if [ $(id -u) -ne 0 ]; then 
  echo "Error: Please run as root"
  exit 1
fi

if [ -z ${name+x} ] || [ -z ${command+x} ]; then
	echo "Error: Please set name and command parameter"
	exit 1
fi
serviceTemplate="${serviceTemplate//<COMMAND>/$(printf %q "$command")}"

if [ -f "/etc/init.d/$name" ]; then
	echo "Error: Service '$name' already exists"
	exit 1
fi
serviceTemplate="${serviceTemplate//<NAME>/$name}"
logrotateTemplate="${logrotateTemplate//<NAME>/$name}"

if ! id -u "$username" &> /dev/null; then
	echo "Error: User '$username' not found"
	exit 1
fi
serviceTemplate="${serviceTemplate//<USER>/$user}"

serviceTemplate="${serviceTemplate//<DIRECTORY>/${directory:-.}}"
serviceTemplate="${serviceTemplate//<DESCRIPTION>/${description:-Starts '$name'-Service}}"
serviceTemplate="${serviceTemplate//<REQUIRED-START>/${required-start:-\$remote_fs \$syslog}}"
serviceTemplate="${serviceTemplate//<REQUIRED-STOP>/${required-stop:-\$remote_fs \$syslog}}"

#install
echo -e "$serviceTemplate" > "/etc/init.d/$name"
chmod +x "/etc/init.d/$name"
touch "/var/log/$name.log"
chown "$user" "/var/log/$name.log"
touch "/var/log/$name.err"
chown "$user" "/var/log/$name.err"
echo -e "$logrotateTemplate" > "/etc/logrotate.d/$name"
update-rc.d "$name" defaults
service "$name" start
