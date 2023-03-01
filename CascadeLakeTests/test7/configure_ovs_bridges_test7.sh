#!/bin/bash


function get_cpumask() {
        local cpu_list=$1
        local pmd_cpu_mask=0
        local bc_math=""
        for cpu in `echo $cpu_list | sed -e 's/,/ /'g`; do
                bc_math="$bc_math + 2^$cpu"
        done
        bc_math=`echo $bc_math | sed -e 's/\+//'`
        pmd_cpu_mask=`echo "obase=16; $bc_math" | bc`
        echo "$pmd_cpu_mask"
}

/opt/greg/dpdk-rhel-perf-tools/start-vswitch.sh --devices=0000:3b:00.0,0000:3b:00.1 --dataplane=dpdk --dpdk-nic-kmod=mlx5_core --switch=ovs --topology=pv,vp --use-ht=y --numa-mode=preferred --switch-mode=l2-bridge --nr-queues=2 --print-config


pmd_cpus="2,4,50,52,3,51,5,53,10,58,12,60"

pmd_cpu_mask=`get_cpumask $pmd_cpus`

echo "pmd-cpu_mask = $pmd_cpu_mask"
/usr/bin/ovs-vsctl set Open_vSwitch . other_config:pmd-cpu-mask=$pmd_cpu_mask
ovs-appctl dpif-netdev/pmd-rxq-show
ovs-vsctl set Interface dpdk-0 options:"n_rxq=2" other_config:pmd-rxq-affinity="0:2,1:50"
ovs-vsctl set Interface dpdk-1 options:"n_rxq=2" other_config:pmd-rxq-affinity="0:4,1:52"

ovs-vsctl set Interface vhost-user-0-n0 options:"n_rxq=2" other_config:pmd-rxq-affinity="0:3,1:51"
ovs-vsctl set Interface vhost-user-1-n0 options:"n_rxq=2" other_config:pmd-rxq-affinity="0:5,1:53"

echo ""
echo "New PMD thread affinities"
ovs-appctl dpif-netdev/pmd-rxq-show

