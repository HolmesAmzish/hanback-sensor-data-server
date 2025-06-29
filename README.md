# 服务器端

## 串口数据处理

### 虚拟串口

由于首先对服务器进行开发，预先定义了一个虚拟串口程序进行实验。设计虚拟串口传感器，每三秒向指定串口发送传感器数据。

```c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "uart_sender.h"

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s /dev/ttyX\n", argv[0]);
        return 1;
    }

    const char *port_path = argv[1];
    int fd = open_serial_port(port_path);
    if (fd < 0) {
        fprintf(stderr, "Failed to open serial port %s\n", port_path);
        return 1;
    }

    printf("Sending data to serial port: %s\n", port_path);
    while (1) {
        send_sensor_data(fd);
        sleep(3);
    }

    close(fd);
    return 0;
}
```

```c
#include "uart_sender.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <termios.h>
#include <time.h>

int open_serial_port(const char *device) {
    int fd = open(device, O_RDWR | O_NOCTTY | O_SYNC);
    if (fd < 0) {
        perror("open");
        return -1;
    }

    struct termios tty;
    if (tcgetattr(fd, &tty) != 0) {
        perror("tcgetattr");
        close(fd);
        return -1;
    }

    cfsetospeed(&tty, B9600);
    cfsetispeed(&tty, B9600);

    tty.c_cflag = (tty.c_cflag & ~CSIZE) | CS8;     // 8-bit chars
    tty.c_iflag &= ~IGNBRK;                         // disable break processing
    tty.c_lflag = 0;                                // no signaling chars, no echo
    tty.c_oflag = 0;                                // no remapping, no delays
    tty.c_cc[VMIN]  = 0;                            // read doesn't block
    tty.c_cc[VTIME] = 5;                            // 0.5 seconds read timeout

    tty.c_iflag &= ~(IXON | IXOFF | IXANY);         // shut off xon/xoff ctrl

    tty.c_cflag |= (CLOCAL | CREAD);                // ignore modem controls
    tty.c_cflag &= ~(PARENB | PARODD);              // no parity
    tty.c_cflag &= ~CSTOPB;                         // 1 stop bit
    tty.c_cflag &= ~CRTSCTS;                        // no hardware flow ctrl

    if (tcsetattr(fd, TCSANOW, &tty) != 0) {
        perror("tcsetattr");
        close(fd);
        return -1;
    }

    return fd;
}

float random_float(float min, float max) {
    return min + ((float)rand() / RAND_MAX) * (max - min);
}

void send_sensor_data(int fd) {
    float temperature = random_float(20.0, 30.0);
    float humidity = random_float(40.0, 70.0);
    float light = random_float(300.0, 1000.0);

    char buffer[128];
    snprintf(buffer, sizeof(buffer), "%.2f,%.2f,%.0f\n", temperature, humidity, light);
    write(fd, buffer, strlen(buffer));
    printf("Sent: %s", buffer);
}
```

```c
#ifndef UART_SENDER_H
#define UART_SENDER_H

int open_serial_port(const char *device);
void send_sensor_data(int fd);

#endif
```

```makefile
CC = gcc
CFLAGS = -Wall -O2
OBJS = main.o uart_sender.o
TARGET = virtual_uart_sender.out

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^

clean:
	rm -f $(TARGET) $(OBJS)
```

使用方法：

首先创建虚拟串口对

```bash
socat -d -d pty,raw,echo=0 pty,raw,echo=0
```

运行本程序，指定串口

```bash
./virtual_uart_sender.out /dev/pts/3
```

![image-20250628194724099](/home/cacc/Repositories/HanbackSerialSensorServer/assets/image-20250628194724099.png)

## 数据处理

### 数据库设计

首先手动创建数据库 `hanback`

```sql
CREATE DATABASE hanback;
USE hanback;
```

创建数据表，此处的数据表由 Spring 自动初始化，内容于资源根目录的 `schema.sql`

```sql
CREATE TABLE IF NOT EXISTS sensor_data (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    light_value FLOAT NOT NULL COMMENT '光照值（单位：lux）',
    temperature_value FLOAT NOT NULL COMMENT '温度值（单位：℃）',
    humidity_value FLOAT NOT NULL COMMENT '湿度值（单位：%RH）',
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '记录时间'
);
```

### 映射层

```xml
```



## HTTP API

