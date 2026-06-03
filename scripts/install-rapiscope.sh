#!/usr/bin/env bash
useradd -G video -d rapiscope

tee /etc/systemd/user/rapiscope.service <<-EOF
[Unit]
Description=Rapiscope preview

[Service]
ExecStart=libcamera-vid --signal --initial pause --inline --split -o 'recordings/%%03d.h264' -t 0 --hflip --vflip

[Install]
WantedBy=default.target
EOF

tee /etc/systemd/logind.conf <<-EOF
[Login]
NAutoVTs=6
EOF

tee /usr/local/bin/toggle-record <<-EOF
#!/usr/bin/env bash
kill -SIGUSR1 $$(pidof libcamera-vid)
EOF

chmod +x /usr/local/bin/toggle-record

tee /etc/systemd/system/getty@tty1.service.d/autologin.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -f -- \\\\u' --noclear --autologin rapiscope %I \$TERM
EOF

systemctl enable getty@tty1.service
systemctl --user -M rapiscope@ enable rapiscope.service

apt-get install -y gstreamer1.0-tools gstreamer1.0-plugins-good gstreamer1.0-plugins-bad
