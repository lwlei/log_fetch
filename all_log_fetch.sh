#!/bin/bash
# -*- coding: utf-8 -*-

# 定义日志的起始时间
start_time="2023-12-07 14:30"
end_time="2023-12-08 11:54"

# 定义FE相关信息
fe_ip_list=("cs01" "cs02" "cs03")
fe_ssh_port=22
user="root"
password="sr@2023"
fe_port=8232

# 定义BE相关信息
be_ip_list=("cs01" "cs03")
be_ssh_port=22
be_port=8242

# 定义日志的临时存储目录
des_log_dir="/tmp/all_log-$(date +'%Y-%m-%d_%H-%M')"
mkdir -p "$des_log_dir"

fetch_all_log(){
    # 循环远程执行脚本，并获取文件列表
    for ip in "${ip_list[@]}"; do
        echo ""
        echo $(date "+%Y-%m-%d %H:%M:%S") "Begin to fetch $file_name_patten logs from IP: $ip ..."
        # 将脚本发送到远程主机
        mkdir -p "$des_log_dir"
        scp -P $ssh_port log_fetch.sh $ip:/tmp/log_fetch.sh

        echo $(date "+%Y-%m-%d %H:%M:%S") "Collecting $file_name_patten logs on IP: $ip ..."
        # 在远程主机上执行脚本，并获取文件列表
        remote_files=$(ssh -p"$ssh_port" "$ip" "bash /tmp/log_fetch.sh -i $ip $script_args")
        # 判断remote_files是否为空
        if [ ${#remote_files[@]} -eq 0 ]; then
            echo $(date "+%Y-%m-%d %H:%M:%S") "No files found on $ip. Skipping..."
            continue
        fi

        echo $(date "+%Y-%m-%d %H:%M:%S") "Fetching $file_name_patten logs from IP: $ip ..."
        # 将远程文件拉取到本地
        echo "${remote_files[@]}"
        mkdir -p $des_log_dir/"$ip"_"$file_name_patten"_log
        for remote_file in "${remote_files[@]}"; do
            if [[ $remote_file =~ /tmp/.*${ip}.* ]]; then
                scp -P $ssh_port $ip:"$remote_file" $des_log_dir/"$ip"_"$file_name_patten"_log/
                # 删除远程主机上的脚本1和文件列表中的文件
                # ssh $ip "rm "$remote_file""
            else
                echo $remote_file
            fi
        done
        # ssh $ip "rm $des_log_dir/log_fetch.sh"

        echo $(date "+%Y-%m-%d %H:%M:%S") "Compressing $file_name_patten logs on localhost ..."
        # 压缩打包文件
        tar -cvzPf $des_log_dir/"$ip"_"$file_name_patten"_log.tar.gz $des_log_dir/"$ip"_"$file_name_patten"_log >/dev/null

        # 删除本地文件夹
        # rm -rf $des_log_dir/"$ip"_"$file_name_patten"_log
    done
}

if [ ${#be_ip_list[@]} -gt 0 ]; then
    ip_list=("${be_ip_list[@]}")
    ssh_port=$be_ssh_port
    script_args="-P $be_port -s \"$start_time\" -e \"$end_time\""
    file_name_patten="be"
    fetch_all_log
fi

if [ ${#fe_ip_list[@]} -gt 0 ]; then
    ip_list=("${fe_ip_list[@]}")
    ssh_port=$fe_ssh_port
    script_args="-u $user -p $password -P $fe_port -s \"$start_time\" -e \"$end_time\""
    file_name_patten="fe"
    fetch_all_log
fi