# llfcrypt

## 安装
- 从https://gitee.com/zxllf23/RRUti.git clone RRUti最新代码，存放地址和llfstr在同级目录
- 在llfstr目录下执行`pod install`

## Description
a simple encryption and decryption tool for mac

## Useage
- `llfcrypt fenc file` 表示对文件进行加密（file为文件路径），加密文件会自动输出到子目录encryption下
- `llfcrypt fenc directory` 表示对目录下（directory为目录路径）所有文件进行加密(不包括子目录),加密文件会自动输出到子目录encryption下
- `llfcrypt fdec file` 表示对文件进行解密（file为文件路径），解密文件会自动输出到子目录decryption下
- `llfcrypt fdec directory` 表示对目录下（directory为目录路径）所有文件进行解密(不包括子目录),解密文件会自动输出到子目录decryption下


# tingleetool
将文件上传到云端 mac端命令行工具，使用方式输入`tingleetool help`查看；   
功能包括
- 将资源自动上传到leancloud
- 合并srt文件到merge.srtx
- 自动拆分双语srt文件成两个
- 拆分srtx成中英双语的srt文件
- 设置srtx/srt文件偏移时间
- 根据srtx/srt时间自动分割音频、字幕

