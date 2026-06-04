#!/usr/bin/env bash
apt-get install --no-install-recommends pigpio

mkdir -p /srv/home-assistant/{zigbee2mqtt,mosquitto,home-assistant}
cd /srv/home-assistant

# Set up home-assistant dependencies
## Set up zigbee2mqtt
useradd -G dialout --no-create-home -s /bin/false zigbee2mqtt
pip3 install zigpy-cli

tee zigbee2mqtt <<-EOF
# Change to false after initial setup for best network security
permit_join: true
frontend: true

mqtt:
  server: mqtt://mqtt:1883
serial:
  port: /dev/ttyUSB0
homeassistant: true

advanced:
  pan_id: GENERATE
  ext_pan_id: GENERATE
  network_key: GENERATE
EOF

## MQTT
tee mosquitto/mosquitto.conf <<-EOF
listener 1883
persistence true
persistence_location /mosquitto/data/
log_dest stdout

## Authentication ##
# By default, Mosquitto >=2.0 allows only authenticated connections. Change to true to enable anonymous connections.
allow_anonymous true
EOF

tee docker-compose.yml <<-EOF
version: '2.4'
services:
  homeassistant:
    image: ghcr.io/home-assistant/home-assistant:2024.9
    volumes:
      - ./home-assistant:/config
    ports:
      - 80:8123
    restart: unless-stopped
    networks:
      - home-assistant

  zigbee2mqtt:
    image: koenkk/zigbee2mqtt:1.40.1
    restart: unless-stopped
    user: zigbee2mqtt
    ports:
      - 8000:8080
    volumes:
      - /run/udev:/run/udev:ro
      - ./zigbee2mqtt:/app/data
    devices:
      - /dev/ttyUSB0:/dev/ttyUSB0
    networks:
      - home-assistant

  mqtt:
    image: eclipse-mosquitto:2
    restart: unless-stopped
    volumes:
      - ./mosquitto/:/mosquitto/config/:ro
      - mosquitto:/mosquitto/data/
    networks:
      - home-assistant
    ports:
      - 1883:1883
      - 9001:9001

  wolbridge:
    image: ghcr.io/mmalecki/wakeupbr-docker:latest
    restart: unless-stopped
    network_mode: host
    command: -l 0.0.0.0:9 -o 255.255.255.255

  pigpiod:
    image: zinen2/alpine-pigpiod
    restart: unless-stopped
    privileged: true
    networks:
      - home-assistant
    ports:
      - 8888:8888

  mpd:
    image: tobi312/rpi-mpd:alpine
    restart: unless-stopped
    networks:
      - home-assistant
    ports:
      - 6600:6600
    devices:
      - /dev/snd:/dev/snd
    volumes:
      - /media/music:/var/lib/mpd/music:ro
      - /media/playlists:/var/lib/mpd/playlists:ro
      - /media/data:/var/lib/mpd/data:rw

volumes:
  mosquitto:

networks:
  home-assistant:
    driver: bridge
EOF

chown -R ${OPERATOR_USER}:${OPERATOR_GROUP} .
chown -R zigbee2mqtt:zigbee2mqtt zigbee2mqtt

mkdir -p /etc/systemd/dnssd

tee /etc/systemd/dnssd/home.dnssd <<-EOF
[Service]
Name=%H
Type=_http._tcp
Port=80
TxtText=path=/
EOF
