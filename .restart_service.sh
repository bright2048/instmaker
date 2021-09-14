#!/bin/bash
instance_name=$1
docker start $instance_name 
docker exec $instance_name bash -c "service ssh restart"
docker exec $instance_name bash -c "kill  -9 `ps -ef|grep vncc|grep -v grep |awk '{print $2}'` 2> /dev/null"
docker exec $instance_name bash -c "supervisord -c /etc/supervisor/supervisord.conf"
docker exec $instance_name bash -c "supervisorctl restart all"
docker exec $instance_name bash -c "source /root/.jupyter_token;nohup jupyter-notebook --ip 0.0.0.0 --port 8888 --no-browser --allow-root --NotebookApp.token=${jupterToken} &"

