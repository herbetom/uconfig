
# Configure interface's bridge-vlan
add network bridge-vlan
set network.@bridge-vlan[-1].device={{ bridgedev }}
set network.@bridge-vlan[-1].vlan={{ this_vid }}
{#- add all wired ports #}
{%  for (let port in keys(eth_ports)): -%}
add_list network.@bridge-vlan[-1].ports={{ port }}{{ ethernet.port_vlan(interface, eth_ports[port]) }}
{%  endfor %}
{# add the batman interface to the bridge if the interface has mesh support #}
{% if (batman_adv): -%}
add_list network.@bridge-vlan[-1].ports=batman{{ ethernet.has_vlan(interface) ? "." + this_vid + ":t" : '' }}
{% endif %}
{% if (easymesh_agent): %}
add_list network.@bridge-vlan[-1].ports='umapagent'
{% endif -%}
set network.@bridge-vlan[-1].isolate={{ b(interface.isolate_hosts) }}

# add the bridge's vlan to the interface
add network device
set network.@device[-1].type=8021q
set network.@device[-1].name={{ netdev }}
set network.@device[-1].ifname={{ bridgedev }}
set network.@device[-1].vid={{ this_vid }}
set network.@device[-1].stp='1'
{% if (easymesh_agent): %}
set network.@device[-1].bridge_empty='1'
{% endif %}
