{%
	if (length(ssid.encryption) && (!ssid.encryption.proto || !ssid.encryption.key)) {
		warn('Invalid encryption settings');
		return;
	}
	ssid.encryption ??= {
		proto: 'none'
	};
	for (let band in ssid.wifi_radios) {
		if (wiphy.lookup(band))
			continue;
		warn(`Invalid radio ${band}`);
		return;
	}
%}

{% for (let band in ssid.wifi_radios): %}
add umapd fronthaul
set umapd.@fronthaul[-1].ssid={{s(ssid.ssid)}}
set umapd.@fronthaul[-1].band={{lc(band)}}
set umapd.@fronthaul[-1].authentication={{s(ssid.encryption.proto)}}
set umapd.@fronthaul[-1].key={{s(ssid.encryption.key)}}
set umapd.@fronthaul[-1].ciphers='ccmp'
{% endfor %}
