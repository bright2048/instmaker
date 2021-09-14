#!/bin/bash
instance_name=$1
docker stop $instance_name 
docker start $instance_name 
bash .restart_service.sh $instance_name 