#!/bin/bash
gpu_server=""
getServerID(){
    serverip=$(sed -n '2p' /root/vncc/vncc.conf)
    serverssh=$(sed -n '9p' /root/vncc/vncc.conf)
    gpu_server="${serverip#*= }":"${serverssh#*= }"
}
get_inst_gpu(){
    for i in `docker ps |awk '{print $NF}'|grep -v NAMES`
    do
    gpuid=$(docker inspect $i|grep NVIDIA_VISIBLE_DEVICES|tr -d "NVIDIA_VISIBLE_DEVICES=")
    for gid in ${gpuid//,/ }
    do
      echo -e "$gpu_server:\t ${gid} \t"$i|sed 's/\"//g'
    done
    #echo $i:`docker inspect $i|grep NVIDIA_VISIBLE_DEVICES|tr -d "NVIDIA_VISIBLE_DEVICES="`
    done
}
getServerID
get_gpulist(){
    echo -e "${gpu_server}:\t"`nvidia-smi -L |cut -d\( -f1|sed 's/GPU //g'`
}
get_inst_gpu
get_gpulist

