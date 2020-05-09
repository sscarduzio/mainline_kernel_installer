
for i in `sudo dpkg --list|grep ii  | egrep -i --color 'linux-image|linux-headers' |awk '{print $2}' |grep "$1"` ; do sudo apt remove $i; done
