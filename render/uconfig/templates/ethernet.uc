{%
/**
 * force specific link speed and duplex values on linux netdevs
 */
for (let i, ports in state.ethernet):
	let eth_ports = ethernet.lookup_by_select_ports(ports.select_ports);
	for (let port in eth_ports):
		if (!ports.speed)
			continue;
%}

# force link speed and duplex on {{ port }}
add network device
set network.@device[-1].name={{ s(port) }}
set network.@device[-1].ifname={{ s(port) }}
set network.@device[-1].speed={{ ports.speed }}
set network.@device[-1].duplex={{ b(ports.duplex == "full" ? true : false) }}
{%	endfor %}
{% endfor %}

# untagged wan ports
add network wan_ports
{% for (let port in wan_ports):%}
add_list network.@wan_ports[-1].port={{ s(port) }}
{% endfor %}
