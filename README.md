# KBS Deploy

## Prerequisite

- 安装docker和docker-compose
- 安装Intel PCCS, 监听端口8080, 能够接收外部访问
- 安装openssl

## Deploy

### 部署：
首先在`ssl.conf`的`[alt_names]`中配置KBS服务使用的IP或域名。然后用如下命令一键部署KBS：
```
./script.sh deploy
```
这条命令会使用我们提供的一个本地CA为KBS server签发HTTPS证书，KBS服务会在本地启动，监听本机IP (0.0.0.0)的8080端口

### 上传密钥数据：
```
./script.sh set_key --key-tag [TAG] --key-file [KEY_FILE_PATH]
```
上述命令中的`KEY_FILE_PATH`需替换为密钥的文件路径，`TAG`是为该密钥分配的索引路径，路径是自定义的，但是需要符合格式规范：`[TOP]/[MIDDLE]/[TAIL]`, 如`my_key/rsa/key_1`.

### 设置证据参考值（可选）
打开`rv.conf`, 向其中增加或删改想要设置的证据参考值. 支持设置的字段名称见`rv.conf`文件内注释。

修改好后，用如下命令将参考值设置给KBS：
```
./script.sh set_rv
```

### Clean

```
./script.sh clean
```
这条命令会停止KBS服务，并清除Server端证书和本地存储的所有相关数据，请谨慎使用。

## TEE

为了在TEE内执行Attestation并获取密钥数据，我们提供了一个二进制的Client命令行工具（for AnolisOS 8.6）：
```
tar xzvf kbs-client.tar.gz
```

把二进制文件安装到到TEE内，并将KBS所使用的CA根证书复制到TEE内。然后在TEE内使用如下命令执行Attestation并获取密钥：
```
kbs-client --url http://[IP]:8080 --cert-file [KBS_CA_CERT_PATH] get-resource --path [TAG]
```

命令中的`IP`需要替换为部署KBS的机器的IP，`KBS_CA_CERT_PATH`需要替换为KBS的CA根证书的路径，`TAG`是上传密钥数据到KBS时设置的索引路径，如`my_key/rsa/key_1`.
