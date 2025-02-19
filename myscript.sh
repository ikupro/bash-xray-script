#!/bin/sh

#input uuid & domain

#configure timezone to sri lanka standards

rm -rf /etc/localtime
cp /usr/share/zoneinfo/Asia/Colombo /etc/localtime
date -R

#disable ubuntu firewall
ufw disable

#running xray install script for linux - systemd

bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

#adding new configuration files 

rm -rf /usr/local/etc/xray/config.json
cat << EOF > /usr/local/etc/xray/config.json
{
  "inbounds":[
    {
      "port": 80,
      "protocol": "vless",
      "settings": {
        "decryption": "none",
        "clients": [
          {
            "id": "5d70c0ef-a9ff-41e9-b835-9b5b51b73dd1"
          }
        ]
      },
      "streamSettings": {
        "network": "ws"
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF

#accuring a ssl certificate (self-sigend openssl)

openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
    -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com" \
    -keyout xray.key  -out xray.crt
mkdir /etc/xray
cp xray.key /etc/xray/xray.key
cp xray.crt /etc/xray/xray.crt
chmod 644 /etc/xray/xray.key

#starting xray core on sytem startup

cat << EOF > /etc/systemd/system/xray.service.d/10-donot_touch_single_conf.conf
# In case you have a good reason to do so, duplicate this file in the same directory and make your customizes there.
# Or all changes you made will be lost!  # Refer: https://www.freedesktop.org/software/systemd/man/systemd.unit.html
[Service]
ExecStart=
ExecStart=/usr/local/bin/xray run -confdir /usr/local/etc/xray/
EOF
systemctl daemon-reload
systemctl enable xray
systemctl restart xray

#install bbr

mkdir ~/across
git clone https://github.com/teddysun/across ~/across
chmod 777 ~/across
bash ~/across/bbr.sh

# run xray
/usr/local/bin/xray run -config /etc/config.json
/usr/local/bin/xray run -confdir /usr/local/etc/xray/
