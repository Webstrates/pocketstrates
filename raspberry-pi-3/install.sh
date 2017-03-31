#!/bin/bash

# Update package sources
echo "Updating package sources"
apt-get update

# Upgrade system
echo "Upgrading system"
apt-get -y upgrade

# Install hostapd, a daemon for access point and authentication servers.
echo "Installing hostapd"
apt-get install -y hostapd

# Create /etc/network/interfaces
echo "Create /etc/network/interfaces configuration"
cat > /etc/network/interfaces << EOF
# interfaces(5) file used by ifup(8) and ifdown(8)

# Please note that this file is written to be used with dhcpcd
# For static IP, consult /etc/dhcpcd.conf and 'man dhcpcd.conf'

# Include files from /etc/network/interfaces.d:
source-directory /etc/network/interfaces.d

auto lo
iface lo inet loopback

iface eth0 inet manual

allow-hotplug wlan0
iface wlan0 inet static
    address 10.0.0.1
    netmask 255.255.255.0
EOF

# Restart wlan0 interaface to apply static IP.
echo "Restart wlan0 interface"
ifdown wlan0
ifup wlan0

# Configure /etc/default/hostapd
echo "Configuring /etc/default/hostapd"
cat > /etc/default/hostapd << EOF
# Defaults for hostapd initscript
#
# See /usr/share/doc/hostapd/README.Debian for information about alternative
# methods of managing hostapd.
#
# Uncomment and set DAEMON_CONF to the absolute path of a hostapd configuration
# file and hostapd will be started during system boot. An example configuration
# file can be found at /usr/share/doc/hostapd/examples/hostapd.conf.gz
#
DAEMON_CONF="/etc/hostapd/hostapd.conf"

# Additional daemon options to be appended to hostapd command:-
#       -d   show more debug messages (-dd for even more)
#       -K   include key data in debug messages
#       -t   include timestamps in some debug messages
#
# Note that -B (daemon mode) and -P (pidfile) options are automatically
# configured by the init.d script and must not be added to DAEMON_OPTS.
#
#DAEMON_OPTS=""
EOF

# Configure /etc/hostapd/hostapd.conf
echo "Configuring /etc/hostapd/hostapd.conf"
cat > /etc/hostapd/hostapd.conf << EOF
interface=wlan0
driver=nl80211
ctrl_interface=/var/run/hostapd
ctrl_interface_group=0
ssid=pocketstrates
hw_mode=g
channel=8
wpa=2
wpa_passphrase=pocketstrates
wpa_key_mgmt=WPA-PSK
wpa_pairwise=CCMP
rsn_pairwise=CCMP
beacon_int=100
auth_algs=3
wmm_enabled=1
EOF

# Install ifplugd package
echo "Installing ifplugd"
apt-get install -y ifplugd

# Edit /etc/default/ifplugd
cat > /etc/default/ifplugd << EOF
INTERFACES="eth0"
HOTPLUG_INTERFACES="eth0"
ARGS="-q -f -u0 -d10 -w -I"
SUSPEND_ACTION="stop"
EOF

# Install dnsmasq package
echo "Installing dnsmasq"
apt-get install -y dnsmasq

# Configure dnsmasq"
echo "Configuring dnsmasq"
cat > /etc/dnsmasq.conf << EOF
interface=wlan0                                          
dhcp-range=10.0.0.2,10.0.0.50,255.255.255.0,12h
dhcp-option=3,10.0.0.1
EOF

# Configure /etc/sysctl.conf
echo "Configuring /etc/sysctl.conf"
cat > /etc/sysctl.conf << EOF
#
# /etc/sysctl.conf - Configuration file for setting system variables
# See /etc/sysctl.d/ for additional system variables.
# See sysctl.conf (5) for information.
#

#kernel.domainname = example.com

# Uncomment the following to stop low-level messages on console
#kernel.printk = 3 4 1 3

##############################################################3
# Functions previously found in netbase
#

# Uncomment the next two lines to enable Spoof protection (reverse-path filter)
# Turn on Source Address Verification in all interfaces to
# prevent some spoofing attacks
#net.ipv4.conf.default.rp_filter=1
#net.ipv4.conf.all.rp_filter=1

# Uncomment the next line to enable TCP/IP SYN cookies
# See http://lwn.net/Articles/277146/
# Note: This may impact IPv6 TCP sessions too
#net.ipv4.tcp_syncookies=1

# Uncomment the next line to enable packet forwarding for IPv4
net.ipv4.ip_forward=1

# Uncomment the next line to enable packet forwarding for IPv6
#  Enabling this option disables Stateless Address Autoconfiguration
#  based on Router Advertisements for this host
#net.ipv6.conf.all.forwarding=1


###################################################################
# Additional settings - these settings can improve the network
# security of the host and prevent against some network attacks
# including spoofing attacks and man in the middle attacks through
# redirection. Some network environments, however, require that these
# settings are disabled so review and enable them as needed.
#
# Do not accept ICMP redirects (prevent MITM attacks)
#net.ipv4.conf.all.accept_redirects = 0
#net.ipv6.conf.all.accept_redirects = 0
# _or_
# Accept ICMP redirects only for gateways listed in our default
# gateway list (enabled by default)
# net.ipv4.conf.all.secure_redirects = 1
#
# Do not send ICMP redirects (we are not a router)
#net.ipv4.conf.all.send_redirects = 0
#
# Do not accept IP source route packets (we are not a router)
#net.ipv4.conf.all.accept_source_route = 0
#net.ipv6.conf.all.accept_source_route = 0
#
# Log Martian Packets
#net.ipv4.conf.all.log_martians = 1
#
EOF

# Re-read sysctl.conf
echo "Re-read sysctl.conf"
sysctl -p

# Install iptables package
echo "Installing iptabes"
apt-get install -y iptables

# Add script to /etc/network/if-up.d/router
echo "Add script to /etc/network/if-up.d/router"
cat > /etc/network/if-up.d/router << EOF
#!/bin/sh

iptables -F
iptables -X

iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A INPUT -i wlan0 -j ACCEPT
iptables -A OUTPUT -o wlan0 -j ACCEPT

iptables -A POSTROUTING -t nat -o eth0 -j MASQUERADE
iptables -A FORWARD -i wlan0 -j ACCEPT
EOF

# Make /etc/network/if-up.d/router executable
echo "Make /etc/network/if-up.d/router executable"
chmod +x /etc/network/if-up.d/router

# Start router
echo "Starting router"
/etc/network/if-up.d/router

# Remove previous versions of Node.js
echo "Removing Node.js if installed"
apt-get remove -y nodejs

# Download Node.js
echo "Download Node.js version 6.2.0"
wget https://nodejs.org/dist/v6.2.0/node-v6.2.0-linux-armv7l.tar.xz

# Unzip Node.js
echo "Unzip Node.js"
tar -xvf node-v6.2.0-linux-armv7l.tar.xz

# Copy Node.js to /usr/local/bin
echo "Copying Node.js to /usr/local/bin"
cd node-v6.2.0-linux-armv7l
cp -R * /usr/local/
rm -rf node-v6.2.0-linux-armv7l

# Test node and npm command
echo "Testing node and npm command"
node --version
npm -version

# Add webstrates system user
echo "Adding webstrates system user"
adduser --system --no-create-home --group webstrates

# Install mongodb package
echo "Installing mongodb"
apt-get install -y mongodb

# Install git package
echo "Installing git"
apt-get install -y git

# Checkout Webstrates from Github
echo "Checking out Webstrates from Github"
cd /opt/
git clone https://github.com/Webstrates/Webstrates.git

# Webstrates Server update script
echo "Configuring update Webstrates server script"
mkdir /opt/webstrates-admin
cat > /opt/webstrates-admin/webstrates-update << EOF
#!/bin/bash
cd /opt/Webstrates

echo "Pull latest resources from git"
git fetch --all
git reset --hard HEAD
git pull

echo "Running npm install"
npm install

echo "Running npm run build-babel"
npm run build-babel

echo "Setting user:group to webstrates"
chown -R webstrates:webstrates .

echo "Restarting webstrates service"
systemctl restart webstrates

echo "Done!"
EOF

chmod +x /opt/webstrates-admin/webstrates-update
/opt/webstrates-admin/webstrates-update

# Set up Webstrates as a service
echo "Setting up Webstrates as a service"
cat > /lib/systemd/system/webstrates.service << EOF
[Unit]
Description=Webstrates Server

[Service]
User=webstrates
WorkingDirectory=/opt/Webstrates
ExecStart=/usr/local/bin/node webstrates.js
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl enable /lib/systemd/system/webstrates.service
systemctl daemon-reload
systemctl start webstrates.service

# Install nginx package
echo "Installing nginx"
apt-get install -y nginx
rm /etc/nginx/sites-enabled/default
cat > /etc/nginx/sites-available/webstrates << EOF
server {
    listen 80;
    listen [::]:80;

    location / {
        proxy_buffer_size 128k;
        proxy_buffers 8 256k;
        proxy_busy_buffers_size 256k;

        proxy_pass http://127.0.0.1:7007/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        client_max_body_size 102M;
    }
}
EOF

ln -s /etc/nginx/sites-available/webstrates /etc/nginx/sites-enabled/

systemctl restart nginx

# Restart Raspberry Pi
echo "Everything installed and ready. Restarting Raspberry Pi shutdown -r now"
shutdown -r now
