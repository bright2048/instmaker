#!/usr/bin/env bash
#Create Instance
#agent server :
#   210.16.188.193
#   180.168.160.138
#

source confenv
init_var(){
    read -p "input your instance name: "  ins_user
    read -p "input the idle gpuid: " nvgpu
    read -p "rent duration: " rent_duration
    read -p "agentip: 210.16.188.193 , 210.16.180.213, 210.16.180.216,  103.21.143.204,  1.183.72.203, host.dbcloud.pro : " agentip

    if [[ -z ${ins_user} ]] || [[ -z ${rent_duration} ]] || [[ -z ${agentip} ]]
    then
        echo "essential parameter is empty , please check and try again"
        exit 111
    fi
}
is_available(){
    var_ip=$1
    var_port=$2
    flag=$(echo >/dev/tcp/$var_ip/$var_port > /dev/null 2>&1 && echo "used" || echo "free")
    echo $flag
}
check_port(){
    local port=$1
    while true; do
    res=$(is_available ${agentip} ${port})
    if [[ $res = 'free' ]]
    then
        echo $port
        break
    fi
    ((port++))
done
}

init_var


imagename="registry.dbcloud.pro:8088/cuda11_conda_pure:v3.1"
mkdir -p /remote-home/${ins_user}
pdir="/remote-home/${ins_user}"
vdir="/remote-home"

sshp=$(bash .get_avail_port.sh ${agentip})
jnp=`check_port $((sshp+1))`
tensorbdPort=`check_port  $((jnp+1))`
vncport=`check_port  $((tensorbdPort+1))`

create_time=$(date +'%Y%m%d')
end_time=$(date -d "+${rent_duration} day" +'%Y%m%d')
name=$(echo "${ins_user}_${create_time}_${end_time}_g${nvgpu}"|tr  "[:]" "_"|tr  -d ",")
rootPwd=$(</dev/urandom tr -dc 'A-Za-z0-9'|head -c8;echo)
vncPwd=${rootPwd:0:6}
jupterToken=$(</dev/urandom tr -dc 'A-Za-z0-9'|head -c16;echo)
gpu_server=""

echo "instance name:"$name
echo "root passwd:"$rootPwd
echo "jupyter token:"$jupterToken
echo "imagename:"$imagename
echo "nvgpu:"$nvgpu
echo "jupyterPort:"$jnp
echo "ssh Port:"$sshp
echo "vnc port:"$vncport
echo "tensorbdPort:"$tensorbdPort

cat >vncc.conf <<EOF
[common]
server_addr = ${agentip}
server_port = ${server_port:-7000}
privilege_token = 12345678
[${name}_ssh]
type = tcp
local_ip =localhost
local_port = 22
bandwith_limit = 1MB
remote_port = ${sshp}
[${name}_jupyter]
type = tcp
local_ip =localhost
local_port = 8888
remote_port = ${jnp}
bandwith_limit = 1MB
[${name}_tensorbdPort]
type = tcp
local_ip =localhost
local_port = 6006
remote_port = ${tensorbdPort}
bandwith_limit = 1MB
[${name}_vnc]
type = tcp
local_ip =localhost
local_port = 5906
remote_port = ${vncport}
bandwith_limit = 1MB
EOF

getServerID(){
    serverip=$(sed -n '2p' /root/vncc/vncc.conf)
    serverssh=$(sed -n '9p' /root/vncc/vncc.conf)
    gpu_server="${serverip#*= }":"${serverssh#*= }"
}

if [ -z ${nvgpu} ]  #判断是否有gpu参数，如果gpu参数为空，则为CPU实例
then
        nvidia-docker create -it --shm-size 64G -v ${pdir}:${vdir} -p ${jnp}:8888 -p ${sshp}:22 -p ${vncport}:5906 -p ${tensorbdPort}:6006  --name=${name} ${imagename} /bin/bash
else
        NV_GPU=${nvgpu} nvidia-docker create -it --shm-size 64G -v ${pdir}:${vdir} -p ${jnp}:8888 -p ${sshp}:22 -p ${vncport}:5906 -p ${tensorbdPort}:6006  --name=${name} ${imagename} /bin/bash
fi
docker start $name
docker exec --user root $name bash -c "mkdir /etc/vncc"
docker cp vncc ${name}:/etc/vncc/
docker cp vncc.conf ${name}:/etc/vncc/vncc.conf
docker exec --user root $name bash -c "echo root:${rootPwd} | chpasswd"
docker exec --user root $name bash -c "service ssh start"
docker exec --user root $name bash -c "cd /etc/vncc; bash chvncpwd.sh ${vncPwd};nohup ./vncc -c vncc.conf&"
docker exec --user root $name bash -c " echo jupterToken=${jupterToken} > .jupyter_token"
docker exec --user root $name bash -c "nohup jupyter notebook --no-browser --ip=0.0.0.0 --allow-root --NotebookApp.token=$jupterToken --notebook-dir='/' >/dev/null 2>&1 &"
docker exec --user root $name bash -c "conda init bash;echo 'conda activate dl10'>>/root/.bashrc "

getServerID
inst_dir=$(echo "inst_info_${gpu_server}"|tr ":" "_")
cd ~/
test -d ${inst_dir} || mkdir -p ${inst_dir}
log_path="${inst_dir}/${name}.log"
localIP=$(ifconfig|grep "inet addr"|grep -v -E "172.|127."|awk -F: '{print $2}'|tr -d "  Bcast")
gpu_info=$(nvidia-smi -L|awk -F'(' '{print $1}'|awk -F: '{print $2}'|uniq -c)
echo -e "gpu_server:\t ${gpu_server}"|tee -a $log_path
echo -e "localip:\t ${localIP}"|tee -a $log_path
echo -e "gpu info:\t ${gpu_info}"|tee -a $log_path
echo -e "instance info:\t ${name}" |tee -a $log_path
echo -e "ssh info:\t ssh -p $sshp root@${agentip}  pwd:\t ${rootPwd}" |tee -a $log_path
echo -e "jupyter info:\t http://${agentip}:${jnp}/?token=${jupterToken}" |tee -a $log_path
echo -e "vnc info:\t ${agentip}:${vncport}; \t pwd: ${vncPwd}" |tee -a $log_path
echo -e "tensorb info:\t ${agentip}:${tensorbdPort}" |tee -a $log_path
echo -e "create time:\t $(date +'%F %T')" |tee -a $log_path
echo -e "end time:\t $(date -d "+${rent_duration} day" +'%F %T')" |tee -a $log_path