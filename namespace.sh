#1. create two network namespaces namely net-ns-1 and net-ns-2 respectively then create a bridge
# network with the name net-bridge
sudo ip link add net-bridge type bridge
sudo ip netns add net-ns-1
sudo ip netns add net-ns-2
#2 we set up our lo interface which was created by default in our namespaces and also set the 
# bridge network up and assign an ip address to the bridge network only.
sudo ip link set net-bridge up
sudo ip netns exec net-ns-1 ip link set lo up
sudo ip netns exec net-ns-2 ip link set lo up
sudo ip addr add 192.168.1.1/24 dev net-bridge
# 3 create two veth interface for both namespaces
sudo ip link add veth-0 type veth peer name veth-1
sudo ip link add meth-0 type veth peer name meth-1
#4 we link one pair of interface to the bridge network "net-bridge" then link the other pair to
# the net work namespaces
sudo ip link set veth-0 master net-bridge
sudo ip link set meth-0 master net-bridge
# we link the veth-1 to the net-ns-1 and link meth-1 to net-ns-2
sudo ip link set veth-1 netns net-ns-1
sudo ip link set meth-1 netns net-ns-2
#5 turn all networks on 
sudo ip netns  exec net-ns-2 ip link set meth-1 up
sudo ip netns  exec net-ns-1 ip link set veth-1 up
sudo ip link set veth-0 up
sudo ip link set meth-0 up
#6. add ip addresses to the network namespaces
sudo ip netns exec net-ns-1 ip addr add 192.168.1.3/24 dev veth-1
sudo ip netns exec net-ns-2 ip addr add 192.168.1.4/24 dev meth-1
# to confirm that there's connectivity between the two network namespaces,ping both net-ns from
# their ip addresses,including the bridge network ip
sudo ip netns exec net-ns-1 ping 192.168.1.4 # net-ns-1 pinging net-ns-2 through ip address
sudo ip netns exec net-ns-2 ping 192.168.1.3 # net-ns-2 pinging net-ns-1 through ip address
#7. we set connectivity to the internet through the bridge-network
sudo ip netns exec net-ns-1 ip route add default via 192.168.1.1
sudo ip netns exec net-ns-2 ip route add default via 192.168.1.1
#8 You will get error trying to ping the 8.8.8.8 default ip but we have to if traffic forwarding#is allowed
sudo cat /proc/sys/net/ipv4/ip_forward #if it displays 0,edit the number to 1,but if it displays
# 1,leave it just the way it is. We proceed to setting iptables rules to allow postrouting.
sudo iptables \
        -t nat \
        -A POSTROUTING \
        -s 192.168.1.0/24 ! -o net-bridge \
        -j MASQUERADE
# we can set iptables to allow network from outside trying to reach our private network namespace using iptables too
sudo iptables \
        -t nat \
        -A PREROUTING \
        -d <ip or hostname> \
        -p <protocol-type e.g tcp --dport <port-number \
        -j DNAT --to-destination 192.168.1.3:5000

#this allows network connection to our network namespace(net-ns-2) from outside source.
