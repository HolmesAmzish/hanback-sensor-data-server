虚拟串口传感器，每三秒向指定串口发送传感器数据

使用方法：

首先创建虚拟串口对

```bash
socat -d -d pty,raw,echo=0 pty,raw,echo=0
```

运行本程序，指定串口

```bash
./virtual_uart_sender.out /dev/pts/3
```