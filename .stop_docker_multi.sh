#!/bin/bash
docker_stop(){
    docker stop $1
}
docker_rm(){
    docker rm $1
}

while getopts "s:d:" opt; do
  case $opt in
    s)
        for i in "$OPTARG"
        do
            echo "stopping  "$i
            docker_stop $i
        done
        ;;
    d)
        for i in "$OPTARG"
        do
            echo "deleting  "$i
            docker_rm $i
        done
        ;;
    \?)
      echo "Invalid option: -$OPTARG" 
      ;;
  esac
done


