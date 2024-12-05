# hostadp + freeradius + vlan 
During the first test, you are advised to copy the configured file to avoid modification errors
## 1.set hostapd
Since hostapd.conf is already used by wlan0, we create a new `hostapd2.conf`

```
interface=wlan1
driver=nl80211

ssid=MyTestWifi
wpa_pairwise=CCMP
rsn_pairwise=CCMP
macaddr_acl=0 
own_ip_addr=127.0.0.1
ieee8021x=1 
channel=1
hw_mode=g
auth_algs=1
wpa=2
wpa_key_mgmt=WPA-EAP
nas_identifier=other


auth_server_addr=127.0.0.1
auth_server_port=1812
auth_server_shared_secret=testing123

dynamic_vlan=1
vlan_file=/etc/hostapd/vlan.conf

```
Create the `/etc/hostapd/vlan.conf` file

```
101 vl101
102 vl102
```
Create the `/etc/systemd/system/hostapd2.service` file

```
[Unit]
Description=Hostapd2
After=network.target

[Service]
Type=forking
ExecStart=/usr/sbin/hostapd -B /etc/hostapd/hostapd2.conf

[Install]
WantedBy=multi-user.target
```

Start hostapd2

```
systemctl daemon-reload
systemctl start hostapd2
systemctl enable hostapd2
```

## 2.Configure freeradius

### 2.1 Generate certificate

`cd /etc/freeradius/3.0/certs`

You can change `default_days = 60` in `*.cnf` to change the validity period, password, or other information of the generated certificate. 
The default password of the certificate is `whatever`
Generate the certificate using the `make` command

```
make
chown -Rv freerad:freerad .
```
### 2.2 Generate a client certificate

Modify `emailAddress` and `commonName` to your username in client.cnf

Note: Because of the Makefile restrictions, the username must contain `@`.
   
If you need to manually generate, you need to take the commands in the Makefile and step them

```
[client]
countryName             = FR
stateOrProvinceName     = Radius
localityName            = Somewhere
organizationName        = Example Inc.
emailAddress            = user1@mail.org
commonName              = user1@mail.org
```
Run a command

`make client`

The `user1@mail.org.p12` certificate will then be generated, and you can modify and generate different client certificates

You can then verify it using the `user1@mail.org.p12` certificate

### 2.2 Modify the configuration file
only the default file needs to be modified

/etc/freeradius/3.0/clients.conf

```
	shortname = MyTestWifi
	virtual_server = default
```

/etc/freeradius/3.0/mods-enabled/eap

```
eap {
	default_eap_type = tls

	#leap {
	#}
	
	#gtc {
	#	auth_type = PAP
	#}
	
	
	tls-config tls-common {
		private_key_password = whatever
		private_key_file =  /etc/freeradius/3.0/certs/server.key
		certificate_file = /etc/freeradius/3.0/certs/server.pem
		ca_file = /etc/freeradius/3.0/certs/ca.pem
		dh_file = ${certdir}/dh
		random_file = /dev/urandom
		check_crl = no
		ca_path = ${cadir}
		cipher_list = "HIGH"
		cipher_server_preference = no
		ecdh_curve = "prime256v1"
        check_cert_cn = %{User-Name}

		cache {		
			name = "EAP-TLS"
		}
		
		verify {
		}

	}
	
	tls {
		tls = tls-common
	}
	
	ttls {
		tls = tls-common
		default_eap_type = tls
		virtual_server = "default"
	}

	#peap {
	#	tls = tls-common
	#	default_eap_type = mschapv2
	#	copy_request_to_tunnel = no
	#	use_tunneled_reply = no
	#	virtual_server = "inner-tunnel"
	#}
	
	#mschapv2 {
	#}

}
```

/etc/freeradius/3.0/sites-enabled/default

```
post-auth {
    if ("%{User-Name}" == "user1@email.org") {
        update reply {
            Tunnel-Type = VLAN
            Tunnel-Medium-Type = IEEE-802
            Tunnel-Private-Group-Id = "101"
        }
    }
    elsif ("%{User-Name}" == "user2@email.org") {
        update reply {
            Tunnel-Type = VLAN
            Tunnel-Medium-Type = IEEE-802
            Tunnel-Private-Group-Id = "102"
        }
    }
}
```
Restart freeradius

`systemctl restart freeradius`

Set vlan bridge

```
ip link add link eth0 name eth0.101 type vlan id 101
ip link add link eth0 name eth0.102 type vlan id 102
ip link set dev eth0.101 up
ip link set dev eth0.102 up  
ip link set dev eth0.101 master brvlan101
ip link set dev eth0.102 master brvlan102
```

### 3 Use another Raspberry PI to connect to this wifi
Copy `user1@mail.org.p12` and `ca.pem` in freeradius to the machine to be connected
I copied it to the root directory during testing
Connect using `nmcli`
```
nmcli connection add \
  type wifi \
  con-name "MyTestWifi-user1" \
  ifname wlan1 \
  ssid "MyTestWifi" \
  mode infrastructure \
  wifi-sec.key-mgmt wpa-eap \
  802-1x.eap tls \
  802-1x.identity user1@mail.org \
  802-1x.private-key-password whatever \
  802-1x.client-cert "/root/user1@mail.org.p12" \
  802-1x.private-key "/root/user1@mail.org.p12" \
  802-1x.ca-cert "/root/ca.pem" \
  ipv4.method auto

nmcli connection up MyTestWifi-user1
```

Or connect using user2

```
nmcli connection add \
  type wifi \
  con-name "MyTestWifi-user2" \
  ifname wlan1 \
  ssid "MyTestWifi" \
  mode infrastructure \
  wifi-sec.key-mgmt wpa-eap \
  802-1x.eap tls \
  802-1x.identity user2@mail.org \
  802-1x.private-key-password whatever \
  802-1x.client-cert "/root/user2@mail.org.p12" \
  802-1x.private-key "/root/user2@mail.org.p12" \
  802-1x.ca-cert "/root/ca.pem" \
  ipv4.method auto

nmcli connection up MyTestWifi-user2
```


## Check

Run the `tcpdump -i eth0 -e-n 'ether proto 0x8100'` command to check dhcp requests that contain vlan tags
```
04:27:40.195571 e8:4e:06:ad:f4:0a > ff:ff:ff:ff:ff:ff, ethertype 802.1Q (0x8100), length 338: vlan 101, p 0, ethertype IPv4 (0x0800), 0.0.0.0.68 > 255.255.255.255.67: BOOTP/DHCP, Request from e8:4e:06:ad:f4:0a, length 292
04:27:41.710003 e8:4e:06:ad:f4:0a > 33:33:00:00:00:fb, ethertype 802.1Q (0x8100), length 212: vlan 101, p 0, ethertype IPv6 (0x86dd), fe80::6d30:b8eb:e93d:a01.5353 > ff02::fb.5353: 0*- [0q] 2/0/0 (Cache flush) PTR petabit-wifi-2.local., (Cache flush) AAAA fe80::6d30:b8eb:e93d:a01 (146)
04:27:42.928338 e8:4e:06:ad:f4:0a > 33:33:00:00:00:02, ethertype 802.1Q (0x8100), length 66: vlan 101, p 0, ethertype IPv6 (0x86dd), fe80::6d30:b8eb:e93d:a01 > ff02::2: ICMP6, router solicitation, length 8
04:27:44.242249 e8:4e:06:ad:f4:0a > ff:ff:ff:ff:ff:ff, ethertype 802.1Q (0x8100), length 338: vlan 101, p 0, ethertype IPv4 (0x0800), 0.0.0.0.68 > 255.255.255.255.67: BOOTP/DHCP, Request from e8:4e:06:ad:f4:0a, length 292
```