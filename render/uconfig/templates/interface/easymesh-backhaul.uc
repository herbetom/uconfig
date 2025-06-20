{%
	if (!length(ssid.encryption) && (!ssid.encryption.proto || !ssid.encryption.key)) {
		warn('Invalid encryption settings');
		return;
	}
	for (let band in ssid.wifi_radios) {
		if (wiphy.lookup(band))
			continue;
		warn(`Invalid radio ${band}`);
		return;
	}
%}

{% for (let band in ssid.wifi_radios): %}
add umapd backhaul
set umapd.@backhaul[-1].ssid={{s(ssid.ssid)}}
set umapd.@backhaul[-1].band={{lc(band)}}
set umapd.@backhaul[-1].authentication={{s(ssid.encryption.proto)}}
set umapd.@backhaul[-1].key={{s(ssid.encryption.key)}}
set umapd.@backhaul[-1].hidden='1'
set umapd.@backhaul[-1].ciphers='ccmp'
{% endfor %}
