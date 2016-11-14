#!/bin/bash

# 获取脚本当前路径
sh_path=$(cd `dirname $0`; pwd)

read -t 20 -p "请输入ansible访问节点的方式，默认回车是秘钥认证方式（ 秘钥认证：1 密码认证：2 ）:" num

# 默认为秘钥认证方式
[ ! $num ] && echo "默认是秘钥认证" && num=1

# 判断密码是否一致
if [ $num -eq 2 ];then
    read -p "请输入节点服务器密码（注：节点服务器密码要求是一样的）:" -s passwd
    echo
    read -p "请再次输入节点服务器密码:" -s passwd2
    if [ "$passwd" != "$passwd2" ];then
        echo “两次输入密码不一致，请重试”
        read -p "请输入节点服务器密码（注：节点服务器密码要求是一样的）:" -s passwd
        echo
        read -p "请再次输入节点服务器密码:" -s passwd2
        if [ "$passwd" != "$passwd2" ];then
            echo “两次输入密码不一致，退出程序”
            exit
        fi
    fi
fi

# 选择认证方式
case $num in
1)
rm -f $sh_path/host_file && cp $sh_path/host_key_file $sh_path/host_file
ansible sync '-i' $sh_path/host_file -m ping
if [ $? -ne 0 ];then
    echo "私钥认证方式不对，脚本已退出，请重试"
    exit 1
fi

;;
2)
rm -f $sh_path/host_file && cp $sh_path/host_pass_file $sh_path/host_file
sed '-i' "s#passwd_d#$passwd#" $sh_path/host_file
ansible sync '-i' $sh_path/host_file -m ping
if [ $? -ne 0 ];then
    echo "密码认证方式不成功，脚本已退出，请重试"
    exit 1
fi
;;

*)
exit 1
esac

# 修改同步目录 
n=1
for dir in `cat $sh_path/host_file | grep 'dir' | awk -F '=' '{print $NF}'`
  do
    num_file=`cat $sh_path/host_file | grep 'dir' |  awk -F '=' '{print $2}' | wc -w`  
    if [ $n -eq 1 ];then 
         sed -i '/\[heketi\]/{n;d}' $sh_path/roles/rsync_install/templates/rsyncd.conf
         sed -i "/\[heketi\]/apath = $dir/" $sh_path/roles/rsync_install/templates/rsyncd.conf
#        sed '-i' "1,20 s#^path = .*#path = $dir#" $sh_path/roles/rsync_install/files/rsyncd.conf
    fi
    if [ $n -eq 2 ];then 
         sed -i '/\[heketi_db\]/{n;d}' $sh_path/roles/rsync_install/templates/rsyncd.conf
         sed -i "/\[heketi_db\]/apath = $dir/" $sh_path/roles/rsync_install/templates/rsyncd.conf
#         sed -i "'/'[heketi_db']'/{ n; s/path = .*/path = $dir/;}" $sh_path/roles/rsync_install/files/rsyncd.conf
#        sed '-i' "21,25 s#^path = .*#path = $dir#" $sh_path/roles/rsync_install/files/rsyncd.conf
    fi
    n=$((n+1))
done


# 执行ansible剧本
ansible sync '-i' $sh_path/host_file '-s' '-m' shell '-a' "mkdir -p {{ dir1 }} {{ dir2 }}"
ansible-playbook '-i' $sh_path/host_file all.yml

# 删除临时文件
rm -f $sh_path/host_file
