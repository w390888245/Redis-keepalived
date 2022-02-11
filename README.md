# Redis-keepalived
Redis+keepalived实现一主一从高可用



# 测试环境机器分配
机器：192.168.1.81Redis主机  端口6389keepalived，vip地址：192.168.1.230（以后Java服务配置redis的地址都为这个，不会直接访问redis的IP，相当于keepalived给Redis做了请求分发）机器：    192.168.1.82Redis从机  端口6389keepalived，vip地址：192.168.1.230

所用文件
redis-6.2.6.gar.gz
keepalived-2.2.4


# redis安装和配置
## Redis主机配置
```
//存放目录 
/usr/local/redis6/master6389
//redis6389.conf 放入到 
/usr/local/redis6/master6389
根据需求修改配置内容： 端口号、密码、文件输出路径等


//复制redis-cli 和redis-server到redis下
cp /usr/local/redis6/redis-6.2.6/src/redis-cli /usr/local/redis6/master6389/
cp /usr/local/redis6/redis-6.2.6/src/redis-server /usr/local/redis6/master6389/

//配置开机启动，注意ip、 密码、路径
cat >/etc/systemd/system/redis-server6389.service<<eof
[Unit]
Description=redis-server6389
After=network.target
[Service]
Type=forking
ExecStart=/usr/local/redis6/master6389/redis-server /usr/local/redis6/master6389/redis6389.conf
ExecStop=/usr/local/redis6/master6389/redis-cli -h 127.0.0.1 -p12sinaqqmsn63 6389 shutdown
PrivateTmp=true
[Install]
WantedBy=multi-user.target
eof

chmod 777 /usr/local/redis6/master6389/*
chmod 777 /etc/systemd/system/redis-server6389.service

//防火墙开启端口号
firewall-cmd --zone=public --add-port=6389/tcp --permanent

// 运行开机自动启动 redis的版本
systemctl enable redis-server6389
//刷新配置
systemctl daemon-reload
//重启防火墙
firewall-cmd --reload
systemctl restart firewalld
```
## Redis从机配置
```
//存放目录
/usr/local/redis6/slave6389
根据需求修改配置内容： 端口号、密码、文件输出路径等


//复制redis-cli 和redis-server到redis下
cp /usr/local/redis6/redis-6.2.6/src/redis-cli /usr/local/redis6/slave6389/
cp /usr/local/redis6/redis-6.2.6/src/redis-server /usr/local/redis6/slave6389/

//配置开机启动，注意ip、 密码、路径
cat >/etc/systemd/system/redis-server6389.service<<eof
[Unit]
Description=redis-server6389
After=network.target
[Service]
Type=forking
ExecStart=/usr/local/redis6/slave6389/redis-server /usr/local/redis6/slave6389/redis6389.conf
ExecStop=/usr/local/redis6/slave6389/redis-cli -h 127.0.0.1 -p12sinaqqmsn63 6389 shutdown
PrivateTmp=true
[Install]
WantedBy=multi-user.target
eof

//给执行文件赋予权限
chmod 777 /usr/local/redis6/slave6389/*
chmod 777 /etc/systemd/system/redis-server6389.service
//防火墙开启端口号
firewall-cmd --zone=public --add-port=8861/tcp --permanent
// 运行开机自动启动 redis的版本
systemctl enable redis-server6389
//刷新配置
systemctl daemon-reload
//重启防火墙
firewall-cmd --reload
systemctl restart firewalld
```


# keepalive安装
81和82的每台机器都用以下步骤
```
//$INSTALL_DIR=解压的目录
//解压文件
cd /usr/local/keepalived2.2/
tar -zvxf keepalived-2.2.4.tar.gz

cd  keepalived-2.2.4
//安装
./configure  make  && make install

//创建配置文件目录
mkdir /etc/keepalived
//keepalived脚本目录
mkdir /etc/keepalived/scripts

//复制文件，设置开机启动
cp /usr/local/keepalived2.2/keepalived/etc/sysconfig/keepalived /etc/sysconfig/keepalived
cp /usr/local/keepalived2.2/keepalived/etc/sysconfig/keepalived /etc/init.d/keepalived
cp /usr/local/keepalived2.2/keepalived/etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf.bak

systemctl enable keepalived
cp /usr/lib/systemd/system/keepalived.service /etc/systemd/system
systemctl daemon-reload
//分配权限
chmod 644 /etc/keepalived/keepalived.conf
chmod 775 /etc/keepalived/scripts/redis*


//(坑)解决keepalived的VIP问题，多个keepalived同时抢vip
// ens160：网卡地址，通过ifconfig查看 ； 224.0.0.18 ：keepalived组播地址，默认写死
firewall-cmd --direct --permanent --add-rule ipv4 filter INPUT 0 --in-interface ens160 --destination 224.0.0.18 --protocol vrrp -j ACCEPT
//增加完成后两台机器刷新
firewall-cmd --reload
systemctl restart firewalld
```
将↑主机配置keepalived.conf 放入主机的 /etc/keepalived/  
将↑从机配置keepalived.conf 放入从机的 /etc/keepalived/  

将以上5个.sh脚本文件放入主机和从机中	/etc/keepalived/scripts/
检查以上几个文件内容，IP地址、网卡地址、文件路径等内容


# Redis数据迁移
注意新旧Redis都做好备份
1.在旧Redis主节点启动的情况下，启动新Redis从节点，主从节点都执行keys *，检查数据是否一致，
2.新从Redis执行  save ,会生成  dump.rdb 和appendonly.aof文件，这是Redis的数据文件
3.将这两个文件放到新主redis.config中配置的dir路径下，启动新主redis将恢复成旧Redis的数据

# Redis单机转主从节点的迭代
1.新的Redis端口依然使用旧Redis的IP和端口
2.等新Redis和keepalived都搭建好后，数据都备份好后，旧Redis服务停止，紧接着启动新Redis和keepalived
3.Java服务可以无需重启或发版即可衔接新的Redis，因为IP和端口都一样，只不过还是单机使用，一定要保持单机为主节点，如果变成从节点就只能读取数据不可写入数据了
4. Java服务只需将Redis配置的IP改成keepalived的VIP虚拟IP即可，全部服务都改好发版后，就可以正常的Redis主从高可用了


# 常用命令
```
//进入Redis
./redis-cli -h 127.0.0.1 -p 6389 -a 12sinaqqmsn63
//从机设为主机 （在redis里）
SLAVEOF no one
//指定的Redis设为从机（在redis里）
slaveof  172.20.200.82 6389
//查看防火墙端口配置
vim /etc/firewalld/zones/public.xml

//防火墙开启端口号
firewall-cmd --zone=public --add-port=8861/tcp --permanent
//关闭防火墙端口
firewall-cmd --zone=public --remove-port=8861/tcp --permanent
//启动或关闭redis
systemctl start  redis-server6389
systemctl stop  redis-server6389
//启动或关闭keepalived
systemctl start keepalived
systemctl stop keepalived
//查看Redis和keepalived启动状态
ps -ef |grep 'redis\|keepalived'
//查看Redis主从权限
./redis-cli -h 127.0.0.1 -p 6389 -a 12sinaqqmsn63 INFO|grep role
//中文转码
./redis-cli -h 127.0.0.1 -p 6389 -a 12sinaqqmsn63  --raw
 
// 81启动旧redis5 6379
cd /usr/local/redis5/
./src/redis-server ./etc/redis.conf
//停止redis
redis-cli -h 127.0.0.1 -p 6379 shutdown

ps -ef |grep redis
kill -9 端口号

//查看redis安装目录
ls -l /proc/13802/cwd

//Redis批量删除
./redis-cli -h 127.0.0.1 -p 6379 -a 12sinaqqmsn63 keys 'FL_*'  |  xargs ./redis-cli -h 127.0.0.1 -p 6379 -a 12sinaqqmsn63 del

./redis-cli -h 172.20.105.61 -p 6379 -a 12sinaqqmsn63 keys 'syncOrderData_*'  |  xargs ./redis-cli -h 172.20.105.61 -p 6379 -a 12sinaqqmsn63 del
```


# 分布式锁的使用

1.pom.xml引入redisson包
```
<dependency>
    <groupId>org.redisson</groupId>
    <artifactId>redisson-spring-boot-starter</artifactId>
    <version>3.9.1</version>
</dependency>
```

2.配置redisson的bean； 注意@Value是从配置文件中读取的，配置文件一定要有该属性
```
import org.redisson.Redisson;
import org.redisson.api.RedissonClient;
import org.redisson.config.Config;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.io.IOException;

@Configuration
public class MyRedissonConfig {

    @Value("${spring.redis.host:172.20.200.230}")
    String ip = "";

    @Value("${spring.redis.port:6379}")
    int port = 6379;

    @Value("${spring.redis.password:12sinaqqmsn63}")
    String password = "";

    @Bean(destroyMethod = "shutdown")
    RedissonClient redisson() throws IOException {
        //1、创建配置
        Config config = new Config();
        config.useSingleServer()
                .setAddress("redis://"+ip + ":" + port).setPassword(password);

        return Redisson.create(config);
    }

}
```
3.redlock的使用
```
@Autowired
private RedissonClient redissonClient;
private ExecutorService executorService = Executors.newCachedThreadPool();

public void test() throws Exception {
    RLock redLock = redissonClient.getLock("test-lock");
    int[] count = {0};
    for (int i = 0; i < 2; i++) {
        executorService.submit(() -> {
            try {
                //拿到锁,如果锁被别的进程抢到会进行锁等待,直到拿到锁在往后执行程序
                redLock.lock();
                count[0]++;
            } catch (Exception e) {
                e.printStackTrace();
            } finally {
                try {
                    //程序执行完后，一定要解锁！一定要解锁！一定要解锁！！！
                    redLock.unlock();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        });
    }
    executorService.shutdown();
    executorService.awaitTermination(1, TimeUnit.HOURS);
    System.out.println(count[0]);
}
```
