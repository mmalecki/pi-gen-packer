#!/usr/bin/env bash

if [[ -n "$WIFI_SSID" ]] && [[ -n "$WIFI_PASS" ]]; then
  wpa_passphrase "${WIFI_SSID}" "${WIFI_PASS}" | tee -a "/etc/wpa_supplicant/wpa_supplicant-wlan0.conf"
fi
