# loop

简易杀毒脚本，用来删除删除病毒本体和还原被感染u盘中的文件。

## 运行

### 设置ps1脚本运行权限

> 首次运行脚本需要设置脚本运行权限

1. 以管理员身份打开powershell
2. 输入并运行
```ps1
Set-ExecutionPolicy RemoteSigned
```
3. 看到后提示输入 Y

### 运行脚本

下载 `loop.ps1` 脚本，右键点击，选择`以 powershell 运行`

## 功能

- 处理病毒本体和还原被感染u盘中的文件。
- 自动检测插入的磁盘并处理

### 支持处理

- hypertrm
- AvastSvc