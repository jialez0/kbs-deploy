# KBS Deploy

## Prerequisite

- 安装docker和docker-compose
- 安装Intel PCCS, 监听端口8080, 能够接收外部访问
- 安装openssl

## Deploy

### 部署：
```
./script.sh deploy
```
KBS会在本地启动，监听本机IP的8080端口

### 上传密钥数据：
```
./script.sh set_key --key-tag [TAG] --key-file [KEY_FILE_PATH]
```
上述命令中的`KEY_FILE_PATH`需替换为密钥的文件路径，`TAG`是为该密钥分配的索引路径，路径是自定义的，但是需要符合格式规范：`[TOP]/[MIDDLE]/[TAIL]`, 如`my_key/rsa/key_1`.

### 设置证据参考值（可选）
打开`rv.json`, 向其中增加或删改想要设置的证据参考值，TDX平台目前支持设置如下字段：
```
"tdx.quote.header.version"
"tdx.quote.header.att_key_type"
"tdx.quote.header.tee_type"
"tdx.quote.header.reserved"
"tdx.quote.header.vendor_id"
"tdx.quote.header.user_data"
"tdx.quote.body.mr_config_id"
"tdx.quote.body.mr_owner"
"tdx.quote.body.mr_owner_config"
"tdx.quote.body.mr_td"
"tdx.quote.body.mrsigner_seam"
"tdx.quote.body.report_data"
"tdx.quote.body.seam_attributes"
"tdx.quote.body.td_attributes"
"tdx.quote.body.mr_seam"
"tdx.quote.body.tcb_svn"
"tdx.quote.body.xfam"
```
字段内容编码方式均为与quote原文件端序一致的16进制小写字符串.

## TEE

为了在TEE内执行Attestation并获取密钥数据，我们提供了一个二进制的Client命令行工具（for Anolis OS）：
```
tar xzvf aas-client.tar.gz
```

然后把解压出的二进制文件安装到到TEE内，使用如下命令执行Attestation并获取密钥：
```
aas-client --url http://[IP]:8080 get-resource --path [TAG]
```

命令中的`IP`需要替换为部署KBS的机器的IP，`TAG`是上传密钥数据到KBS时设置的索引路径，如`my_key/rsa/key_1`.


