#!/bin/bash 
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Run as root! Will need to install packages."
    exit
fi
rm -rf /tmp/fetchLatestKernel-*
TMPDIR=`mktemp -d -t fetchLatestKernel-XXXXXX`

VER=$(wget -S -O - -o /dev/null  https://kernel.ubuntu.com/~kernel-ppa/mainline/daily/current/ \
|grep linux- | grep -v lowlatency |grep amd64| sed -e 's/<[^>]*>//g' |awk -Flinux-headers- '{print $2}' |awk -F_amd64.deb '{print $1}' |head -1 |awk -Fgeneric_ '{print $2}')

INSTALLED_VERS=`dpkg --list| grep 'ii' | grep linux-image| awk '{print $3}'`

if [[ "$INSTALLED_VERS" == *$VER* ]]; then
  echo 
  echo "Latest version $VER already installed! Exiting."
  echo
  exit 1
fi

echo ">> Installed kernel versions:"
echo "$INSTALLED_VERS"
echo "--------------------"
read -p "$VER is the daily current build available. Download and install it? " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

FILENAMES=$(wget -S -O - -o /dev/null  https://kernel.ubuntu.com/~kernel-ppa/mainline/daily/current/ |egrep -e '_amd64|_all' |awk -Fhref= '{print $2}'|awk -F'>' '{print $1}'|sort |uniq |grep linux|grep -v lowlatency |sed 's/\"//g')
for i in $FILENAMES
do
URL="https://kernel.ubuntu.com/~kernel-ppa/mainline/daily/current/$i"
echo ">>> will download $URL <<<"
DEST_FILE=`echo $URL | awk -Fmainline '{print $2}'`
DEST_FILE=`basename $DEST_FILE`
wget $URL -O "$TMPDIR/$DEST_FILE" || echo "DOWNLOAD FAILED!!"
done

echo "donwload is over"
echo "> installing $i"

# Enforcing an installation order because image depends on modules
#linux-modules-5.7.0-999-generic_5.7.0-999.202005060358_amd64.deb
#linux-headers-5.7.0-999-generic_5.7.0-999.202005060358_amd64.deb
#linux-headers-5.7.0-999_5.7.0-999.202005060358_all.deb
#linux-image-unsigned-5.7.0-999-generic_5.7.0-999.202005060358_amd64.deb

sudo dpkg -i $TMPDIR/`ls $TMPDIR -1 |grep linux-headers|grep all` || echo "already installed?"
sudo dpkg -i $TMPDIR/`ls $TMPDIR -1 |grep linux-headers|grep amd64`|| echo "already installed?"
sudo dpkg -i $TMPDIR/`ls $TMPDIR -1 |grep modules`|| echo "already installed?"
sudo dpkg -i $TMPDIR/`ls $TMPDIR -1 |grep image`|| echo "already installed?"

