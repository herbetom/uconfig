add umapd controller
set umapd.@controller[-1].verbosity='1'
add_list umapd.@controller[-1].interface='umapctrl'

set network.umapctrl=interface
set network.@interface[-1].proto='static'
set network.@interface[-1].device='umapctrl'

add network device
set network.@device[-1].type='veth'
set network.@device[-1].name='umapctrl'
set network.@device[-1].peer_name='umapagent'
