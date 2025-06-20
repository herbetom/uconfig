
add umapd agent
set umapd.@agent[-1].verbosity='1'    
add_list umapd.@agent[-1].bridge={{ s(netdev) }}
add_list umapd.@agent[-1].no_ubus={{ b(no_ubus) }}
{% for (let phy in fs.glob('/sys/class/ieee80211/*')): %}
add_list umapd.@agent[-1].radio={{ s(fs.basename(phy)) }}
{% endfor %}

