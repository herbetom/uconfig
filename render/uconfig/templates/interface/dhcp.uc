{%
let name = interface.name;
let dhcp = ipv4.dhcp_pool || { ignore: 1 };
let dhcpv6 = ipv6.dhcpv6 || {};

if (interface.role == 'downstream')
	if (split(interface.ipv4?.subnet))
		dhcp.use_dns ??= [ split(interface.ipv4.subnet, '/')[0] ];

function use_dns() {
	let ret = '';
	for (let k, v in dhcp.use_dns)
		ret += ',' + v;
	if (length(ret))
		ret = '6' + ret;
	return ret;
}
%}
set dhcp.{{ name }}=dhcp
set dhcp.{{ name }}.interface={{ s(ethernet.calculate_ipv4_name(interface)) }}
set dhcp.{{ name }}.start={{ dhcp.lease_first }}
set dhcp.{{ name }}.limit={{ dhcp.lease_count }}
set dhcp.{{ name }}.leasetime={{ dhcp.lease_time }}
set dhcp.{{ name }}.ignore={{ b(dhcp.ignore) }}
add_list dhcp.{{ name }}.dhcp_option={{ use_dns() }}
{%	if (interface.role != 'upstream'):
		if (dhcpv6.mode == 'hybrid'): %}
set dhcp.{{ name }}.ra=server
set dhcp.{{ name }}.dhcpv6=server
set dhcp.{{ name }}.ndp=disabled
set dhcp.{{ name }}.ra_slaac=1
add_list dhcp.{{ name }}.ra_flags=other-config
add_list dhcp.{{ name }}.ra_flags=managed-config
{%		elif (dhcpv6.mode == 'stateful'): %}
set dhcp.{{ name }}.ra=server
set dhcp.{{ name }}.dhcpv6=server
set dhcp.{{ name }}.ndp=disabled
set dhcp.{{ name }}.ra_slaac=0
add_list dhcp.{{ name }}.ra_flags=other-config
add_list dhcp.{{ name }}.ra_flags=managed-config
{%		elif (dhcpv6.mode == 'stateless'): %}
set dhcp.{{ name }}.ra=server
set dhcp.{{ name }}.dhcpv6=server
set dhcp.{{ name }}.ndp=disabled
set dhcp.{{ name }}.ra_slaac=1
add_list dhcp.{{ name }}.ra_flags=other-config
{%		elif (dhcpv6.mode == 'relay'): %}
set dhcp.{{ name }}.ra=relay
set dhcp.{{ name }}.dhcpv6=relay
set dhcp.{{ name }}.ndp=relay
{%		else %}
set dhcp.{{ name }}.ra=disabled
set dhcp.{{ name }}.dhcpv6=disabled
set dhcp.{{ name }}.ndp=disabled
{%		endif %}
set dhcp.{{ name }}.prefix_filter={{ s(dhcpv6.filter_prefix) }}
set dhcp.{{ name }}.dns_service={{ b(!length(dhcpv6.announce_dns)) }}
{%		for (let i, addr in dhcpv6.announce_dns): %}
add_list dhcp.{{ name }}.dns={{ s(addr) }}
{%		endfor
	else %}
set dhcp.{{ name }}.master={{ b(has_downstream_relays) }}
set dhcp.{{ name }}.ra={{ has_downstream_relays ? 'relay' : 'disabled' }}
set dhcp.{{ name }}.dhcpv6={{ has_downstream_relays ? 'relay' : 'disabled' }}
set dhcp.{{ name }}.ndp={{ has_downstream_relays ? 'relay' : 'disabled' }}
{%	endif
	for (let host, lease in interface.ipv4.dhcp_leases): %}
add dhcp host
set dhcp.@host[-1].name={{ host }}
set dhcp.@host[-1].hostname={{ lease.hostname }}
set dhcp.@host[-1].mac={{ lease.macaddr }}
set dhcp.@host[-1].ip={{ lease.lease_offset }}
set dhcp.@host[-1].leasetime={{ lease.lease_time }}
set dhcp.@host[-1].instance={{ s(name) }}
{%	endfor %}
