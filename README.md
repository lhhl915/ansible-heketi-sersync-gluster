# ansible-heketi-sersync

- 脚本功能：

~~~~
    通过ansible一键部署实现heketi工作目录的实时同步（因脚本的特殊性，仅公司内部使用）
~~~~

- 示意图：（heketi主 通过sersync主动监听并实时向heketi备同步）

```
                实时同步
heketi主 ----------------------> heketi备
```

### 操作方法：

#### 1.下载代码


```
git clone https://github.com/lhhl915/ansible-gluster-heketi.git

cd ansible-gluster-heketi

```

#### 2.修改inventory（主机及主机组配置文件,以下配置文件修改其一即可）

- 如果是ssh是密码验证方式，修改以下文件：

```
# cat ./host_pass_file

[sync]
192.168.11.18 ansible_ssh_pass=passwd_d id=master transfer=192.168.11.19   #只需修改两个ip即可
192.168.11.19 ansible_ssh_pass=passwd_d id=slave transfer=192.168.11.18   #同上，只需修改ip即可

[sync:vars]       
sync_name=yx_sync1       #定义rsync同步账号
sync_pass=pass%#&!2016   #定义rsync同步密码
dir1=/etc/heketi         #需要实时同步的目录1
dir2=/var/lib/heketi/db  #需要实时同步的目录2
```

- 如果是ssh是秘钥认证方式，修改以下文件：

```
# cat ./host_key_file

[sync]
192.168.11.18  id=master transfer=192.168.11.19   #只需修改两个ip即可
192.168.11.19  id=slave transfer=192.168.11.18   #同上，只需修改ip即可

[sync:vars]       
sync_name=yx_sync1       #定义rsync同步账号
sync_pass=pass%#&!2016   #定义rsync同步密码
dir1=/etc/heketi         #需要实时同步的目录1
dir2=/var/lib/heketi/db  #需要实时同步的目录2
```

#### 3. 执行脚本(通过shell调取ansible-playbook)：

```
sh ansible_heketi_sync.sh
```

以下为执行截图：
![image](https://github.com/lhhl915/ansible-gluster-heketi/blob/master/%E6%89%A7%E8%A1%8C%E8%84%9A%E6%9C%AC.jpg)


#### 4.登录测试命令： 

```
heketi-cli -s http://localhost:8080 volume create --size=10 -name test1

heketi-cli -s http://localhost:8080 volume delete #id
```

### 代码说明：
- ./roles/rsync_install #路径下是rsync的安装与配置
- ./roles/sersync_install #路径下是sersync的安装与配置
- ./roles/check_heketi #凌晨四点自动主备进行切换，默认未开启
