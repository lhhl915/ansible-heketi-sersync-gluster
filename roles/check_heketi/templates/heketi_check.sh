#!/bin/bash
list="{{ groups.all }}"

# 过滤list
list_filter=`echo $list | tr -d "[|]|u|'|,"`

# 获取脚本当前路径
sh_path=$(cd `dirname $0`; pwd)

# 检查锁文件
check=`tail -1 $sh_path/check.txt`

for i in $list_filter
  do
    if [ $i = $check ];then
        # 判断rsync服务是否启动
        ssh $i -a "netstat -ntlp | awk '{print \$4}' | awk -F \":\" '{print \$NF}' |grep \"873$\"" >/dev/null
        if [ $? -ne 0 ];then
            ssh $i -a "/bin/systemctl start rsyncd.service"
        fi
        # 关闭heketi服务
        ssh $i -a '/bin/systemctl stop  heketi.service'
        kl=`ssh $i -a "curl -l -m 10 -s -o /dev/null -w %{http_code} http://localhost:8080/hello"`
        if [ $kl -eq 200 ];then
            echo -e "`date` $i heketi服务关闭时失败，请检查原因" >> $sh_path/error.log
        fi
        # 关闭sersync
        ssh $i -a "systemctl stop sersync.service ; systemctl stop sersync2.service"
        wait
        serpid=`ssh $i -a 'ps -ef | grep sersync2 | grep -v grep |wc -l'`
        if [ $serpid -ne 0 ];then
            echo -e "`date` $i serysnc服务关闭时失败，请检查原因" >> $sh_path/error.log
        fi
    else
        # 开启sersync
        ssh $i -a 'systemctl restart sersync.service'
        wait
        ssh $i -a 'systemctl restart sersync2.service'
        wait
        serpid2=`ssh $i -a 'ps -ef | grep sersync2 | grep -v grep |wc -l'`
        if [ $serpid2 -eq 0 ];then
            echo -e  "`date` $i serysnc服务启动时失败，请检查原因" >> $sh_path/error.log
        fi
        # 启动heketi
        ssh $i -a '/bin/systemctl restart  heketi.service'
        bl=`ssh $i -a "curl -l -m 10 -s -o /dev/null -w %{http_code} http://localhost:8080/hello"`
        if [ $bl -ne 200 ];then
            echo -e "`date` $i heketi服务启动时失败，请检查原因" >> $sh_path/error.log
          else
            echo -e "`date` $i heketi服务启动时成功" >> $sh_path/error.log
            echo "$i" >> $sh_path/check.txt
        fi
    fi
done
