# 无线传感网课程设计 PC 端程序设计

## 课程设计总体介绍

### 程序设计题目

完成节点数据采集和标签信息的洪泛传输,能够在与 Sink 节点相连接的 PC 上看到结果(标签信息、感知的数据)。其中,节点感知数据采集仅包括:光照值、温度值、湿度值,采集节点每 4s 采集一次温湿 度、每 2s 采集一次光照。标签数据的访问周期为 3s。 

提醒: 

1. 记录编译、运行过程中出现的错误和现象,及解决方法、心得体会。这一部分重要,考  核占比大。
2. 应在本地 PC 上,采用 Python 或 Java 或 C 语言编写串口读写程序,实现串口数据收发功  能;前期可直接在 PC 上选用相关串口工具读写串口数据。
3. 在本地 PC 上串口数据的读写完成后,将数据远程传输到云服务器,然后,远程 PC 能访  问到云上的数据。远程 PC 能发命令控制节点运行。

### 项目框架

> [!NOTE]
>
> 课程设计项目文件全部托管在我的 Github 仓库中 [sensor-data-server](https://github.com/HolmesAmzish/hanback-sensor-data-server)。

后端采用 Java 语言 Spring 框架。

前端采用 TypeScript 语言 React 框架。

## 数据库设计

### 数据映射

首先需要定义持久层对象，用于存储数据到数据库中，对传感器数据对象的定义如下

```java
/**
 * SensorDataEntity
 * @version 1.0 2025-06-29
 */
public class SensorDataEntity {
    private Long id;
    private Float lightValue;
    private Float temperatureValue;
    private Float humidityValue;
    private LocalDateTime timestamp;

    // Getters and setters
   	...
}
```

数据库定义如下，在 Spring 项目 resource 资源下设置 schema.sql 作为数据库初始化脚本

```sql
CREATE TABLE IF NOT EXISTS sensor_data (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    light FLOAT NOT NULL COMMENT '光照值（单位：lux）',
    temperature FLOAT NOT NULL COMMENT '温度值（单位：℃）',
    humidity FLOAT NOT NULL COMMENT '湿度值（单位：%RH）',
    rfid_data VARCHAR(20) COMMENT 'RFID标签（十六进制字符串，如"A1B2C3D4E5"）',
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '记录时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='传感器数据表';
```

随后需要创建对应的数据对象和数据库操作映射，首先定义映射接口

```java
package cn.arorms.hanback.mapper;

import cn.arorms.hanback.entity.SensorDataEntity;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDateTime;
import java.util.List;

/**
 * SensorDataMapper
 * @version 1.0 2025-06-29
 */
@Mapper
public interface SensorDataMapper {
    List<SensorDataEntity> selectByPageAndDate(
        @Param("offset") int offset,
        @Param("limit") int limit,
        @Param("startTime") LocalDateTime startTime,
        @Param("endTime") LocalDateTime endTime
    );
    SensorDataEntity selectById(@Param("id") Long id);
    int deleteById(@Param("id") Long id);
    void insert(SensorDataEntity data);
}
```

最后在类的资源路径下定义映射接口与数据库操作的行为

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper
  PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN"
  "http://mybatis.org/dtd/mybatis-3-mapper.dtd">

<mapper namespace="cn.arorms.hanback.mapper.SensorDataMapper">

    <resultMap id="SensorDataMap" type="cn.arorms.hanback.entity.SensorDataEntity">
        <result property="temperature" column="temperature"/>
        <result property="humidity" column="humidity"/>
        <result property="light" column="light"/>
        <result property="rfidData" column="rfid_data"/>
        <result property="timestamp" column="timestamp"/>
    </resultMap>

    <select id="selectByPageAndDate" resultMap="SensorDataMap">
        SELECT * FROM sensor_data
        <where>
            <if test="startTime != null">
                AND timestamp &gt;= #{startTime}
            </if>
            <if test="endTime != null">
                AND timestamp &lt;= #{endTime}
            </if>
        </where>
        ORDER BY timestamp DESC
        LIMIT #{limit} OFFSET #{offset}
    </select>

    <select id="selectById" resultMap="SensorDataMap">
        SELECT * FROM sensor_data WHERE id = #{id}
    </select>

    <delete id="deleteById">
        DELETE FROM sensor_data WHERE id = #{id}
    </delete>

    <insert id="insert" parameterType="cn.arorms.hanback.entity.SensorDataEntity">
        INSERT INTO sensor_data (
            temperature, humidity, light, rfid_data, timestamp
        ) VALUES (
            #{temperature}, #{humidity}, #{light}, #{rfidData}, #{timestamp}
        )
    </insert>

</mapper>

```

编写一个单元测试程序运行一下

```java
package cn.arorms.hanback;

import cn.arorms.hanback.entity.SensorDataEntity;
import cn.arorms.hanback.service.SensorDataService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
public class SensorDataTest {
    @Autowired
    private SensorDataService sensorDataService;

    @Test
    public void testDataInsert() {
        SensorDataEntity data = new SensorDataEntity();
        data.setTemperature(25.5f);
        data.setHumidity(60.0f);
        data.setLight(300f);
        data.setRfidData("A655573B1D");
        sensorDataService.insertData(data);
        System.out.println("Done");
    }
}
```

> [!CAUTION]
>
> 运行本程序后出现了一个错误
>
> ```
> org.apache.ibatis.binding.BindingException: Invalid bound statement (not found): cn.arorms.hanback.mapper.SensorDataMapper.insert
> 
> 	at org.apache.ibatis.binding.MapperMethod$SqlCommand.<init>(MapperMethod.java:229)
> 	at org.apache.ibatis.binding.MapperMethod.<init>(MapperMethod.java:53)
> 	at org.apache.ibatis.binding.MapperProxy.lambda$cachedInvoker$0(MapperProxy.java:96)
> 	at java.base/java.util.concurrent.ConcurrentHashMap.computeIfAbsent(ConcurrentHashMap.java:1708)
> 	at org.apache.ibatis.util.MapUtil.computeIfAbsent(MapUtil.java:36)
> 	at org.apache.ibatis.binding.MapperProxy.cachedInvoker(MapperProxy.java:94)
> 	at org.apache.ibatis.binding.MapperProxy.invoke(MapperProxy.java:86)
> 	at jdk.proxy2/jdk.proxy2.$Proxy67.insert(Unknown Source)
> 	at cn.arorms.hanback.service.SensorDataService.insertData(SensorDataService.java:30)
> 	at cn.arorms.hanback.SensorDataTest.testDataInsert(SensorDataTest.java:20)
> 	at java.base/java.lang.reflect.Method.invoke(Method.java:580)
> 	at java.base/java.util.ArrayList.forEach(ArrayList.java:1596)
> 	at java.base/java.util.ArrayList.forEach(ArrayList.java:1596)
> 
> 2025-06-29T16:13:26.214+08:00  INFO 26619 --- [HanbackSerialSensorServer] [ionShutdownHook] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Shutdown initiated...
> 2025-06-29T16:13:26.219+08:00  INFO 26619 --- [HanbackSerialSensorServer] [ionShutdownHook] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Shutdown completed.
> 
> Process finished with exit code 255
> ```

从中得知，无法找到定义接口的映射的函数，在这里检查了映射接口与 xml 映射，发现准确内容准确无误。在根据本人前面数据库项目的对比后发现忘记定义 mapper xml 设置的路径，导致之前定义的 xml 文件没有被自动扫描。回到 spring 项目中，在 application.properties 文件下追加一行，用于扫描所有映射。

```properties
mybatis.mapper-locations=classpath:mapper/*.xml
```

设置完成后重新运行程序，此时发现已经成功插入到数据库中

```
mysql> select * from sensor_data;
+----+-------+-------------+----------+------------+-----------+
| id | light | temperature | humidity | rfid_data  | timestamp |
+----+-------+-------------+----------+------------+-----------+
|  1 |   300 |        25.5 |       60 | A655573B1D | NULL      |
+----+-------+-------------+----------+------------+-----------+
1 row in set (0.01 sec)
```

> [!CAUTION]
>
> 这里有个小错误，timestamp 键是 NULL，然而在前面定义这个键的时候会发现已经定义了自动取当前时间
>
> ```sql
> timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '记录时间'
> ```
>
> 原因在于定义映射出现的错误：
>
> ```sql
> INSERT INTO sensor_data (temperature, humidity, light, rfid_data, timestamp)
> VALUES (#{temperature}, #{humidity}, #{light}, #{rfidData}, #{timestamp})
> ```
>
> 由于对象中 timestamp 为 NULL，那么这里的语句意思就是强制插入对象的 NULL 导致自动截取时间戳失效，将此处 timestamp 插入部分直接删掉以解决问题。

### 数据接口

完成数据映射之后，说明对数据库方面的操作已经基本完成，接下来设置 service 与 controller 层，后者由前者实现，同时 service 还需暴露比 controller 层更多的接口用作给程序自己用。

**SensorDataController**

```java
package cn.arorms.hanback.controller;

import cn.arorms.hanback.entity.SensorDataEntity;
import cn.arorms.hanback.service.SensorDataService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

/**
 * SensorDataController
 * @version 1.0 2025-06-29
 */
@RestController
@RequestMapping("/api/data")
public class SensorDataController {

    @Autowired
    private SensorDataService sensorDataService;

    // Get all datas by page and date time if searched
    @GetMapping
    public List<SensorDataEntity> getDataByPageAndDate(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startTime,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endTime
    ) {
        return sensorDataService.getDataByPageAndDate(page, size, startTime, endTime);
    }

    // Get data by data id
    @GetMapping("/{id}")
    public SensorDataEntity getDataById(@PathVariable Long id) {
        return sensorDataService.getDataById(id);
    }

    // delete data by data id
    @DeleteMapping("/{id}")
    public boolean deleteDataById(@PathVariable Long id) {
        return sensorDataService.deleteDataById(id);
    }
}
```

这里留下诸多接口，控制器层作为 web 应用最核心的 api 调用方法，暴露了接口给前端进行查询与操作

**SensorDataService**

```java
package cn.arorms.hanback.service;

import cn.arorms.hanback.entity.SensorDataEntity;
import cn.arorms.hanback.mapper.SensorDataMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

/**
 * SensorDataService
 * @version 1.0 2025-06-29
 */
@Service
public class SensorDataService {
    @Autowired
    private SensorDataMapper sensorDataMapper;

    public List<SensorDataEntity> getDataByPageAndDate(
        int page, int size, LocalDateTime startTime, LocalDateTime endTime
    ) {
        int offset = (page - 1) * size;
        return sensorDataMapper.selectByPageAndDate(offset, size, startTime, endTime);
    }
    public SensorDataEntity getDataById(Long id) {
        return sensorDataMapper.selectById(id);
    }
    public boolean deleteDataById(Long id) {
        return sensorDataMapper.deleteById(id) > 0;
    }
    public void insertData(SensorDataEntity data) {
        sensorDataMapper.insert(data);
    }
}
```

至此完成数据库部分的基本设计



## 串口传输

### 虚拟串口模拟

课程设计分工中，本人负责 PC 端服务器程序开发，由于还没有等到节点端的程序和测试，不得不首先写一个虚拟串口模拟程序进行测试，这里设计一个 C 语言程序向指定串口发送类似于传感器数据的内容，以 CSV 格式传输。

**main.c**

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

**uart_sender.h**

```c
#ifndef UART_SENDER_H
#define UART_SENDER_H

int open_serial_port(const char *device);
void send_sensor_data(int fd);

#endif
```

**uart_sender.c**

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
    printf("Trying to open serial port: %s\n", device);
    int fd = open(device, O_RDWR | O_NOCTTY | O_SYNC);
    if (fd < 0) {
        perror("open");
        return -1;
    }
    printf("Serial port opened successfully\n");

    struct termios tty;
    if (tcgetattr(fd, &tty) != 0) {
        perror("tcgetattr");
        close(fd);
        return -1;
    }

    cfsetospeed(&tty, B9600);
    cfsetispeed(&tty, B9600);

    tty.c_cflag = (tty.c_cflag & ~CSIZE) | CS8;
    tty.c_iflag &= ~IGNBRK;
    tty.c_lflag = 0;
    tty.c_oflag = 0;
    tty.c_cc[VMIN] = 0;
    tty.c_cc[VTIME] = 5;

    tty.c_iflag &= ~(IXON | IXOFF | IXANY);
    tty.c_cflag |= (CLOCAL | CREAD);
    tty.c_cflag &= ~(PARENB | PARODD);
    tty.c_cflag &= ~CSTOPB;
    tty.c_cflag &= ~CRTSCTS;

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

void generate_rfid_data(unsigned char *data) {
    for (int i = 0; i < 5; i++) {
        data[i] = rand() % 256;
    }
}

void send_sensor_data(int fd) {
    float temperature = random_float(20.0, 30.0);
    float humidity = random_float(40.0, 70.0);
    float light = random_float(300.0, 1000.0);
    unsigned char rfid_data[5];
    generate_rfid_data(rfid_data);

    char buffer[256];
    snprintf(buffer, sizeof(buffer), 
            "%.2f,%.2f,%.0f,%02X%02X%02X%02X%02X\n",
            temperature, humidity, light,
            rfid_data[0], rfid_data[1], rfid_data[2], rfid_data[3], rfid_data[4]);

    int bytes_written = write(fd, buffer, strlen(buffer));
    if (bytes_written < 0) {
        perror("write failed");
    } else {
        printf("Sent: %s", buffer);
    }
}

```

**makefile**

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

完成虚拟串口发送程序之后进行编译

```bash
make
```

完成了程序编译，这里需要创建虚拟串口对进行测试，使用指令创建虚拟串口对

```bash
sudo apt install socat
socat -d -d pty,raw,echo=0 pty,raw,echo=0
```

其中 socat 通过 Ubuntu 的 apt 软件管理直接下载到本系统中。

```
cacc@paradiso [05:53:03 PM] [~] 
-> % 
socat -d -d pty,raw,echo=0 pty,raw,echo=0
2025/06/29 17:53:04 socat[41893] N PTY is /dev/pts/5
2025/06/29 17:53:04 socat[41893] N PTY is /dev/pts/6
2025/06/29 17:53:04 socat[41893] N starting data transfer loop with FDs [5,5] and [7,7]
```

这里说明完成了虚拟串口对的设计，并且从程序输出可以看到，虚拟串口对为 `/dev/pts/5` 和 `/dev/pts/6`。那么可以利用刚才编写的虚拟串口程序进行数据发送：

```
cacc@paradiso [05:54:49 PM] [~/Repositories/HanbackSerialSensorServer/node/VirtualSerialSender] [master *]
-> % ./virtual_uart_sender.out /dev/pts/5
Sending data to serial port: /dev/pts/5
Sent: 28.40,51.83,848
Sent: 27.98,67.35,438
```

可以看到虚拟串口程序每三秒向串口发送一次数据，现在检查接收串口

```
cacc@paradiso [05:55:47 PM] [~] 
-> % cat /dev/pts/6
28.40,51.83,848
27.98,67.35,438
```



### 串口数据处理

利用 Spring 反转控制容器（Inversion of Control Container）创建一个串口数据监听器，主要逻辑是初始化对串口数据的监听并跟随服务器一起运行，首先需要使用 `@Component` 注解将监听器定义为 Spring 项目的组件。

```java
@Component
public class SerialPortListener
```

创建这个类之后，通过自动注入管理依赖（Dependency Injection，DI），因为这里需要程序收到串口数据之后自动将数据存储到数据库中，使用到了上面写的数据库接口

```java
private final SensorDataService sensorDataService;

@Autowired
public SerialPortListener(SensorDataService sensorDataService) {
    this.sensorDataService = sensorDataService;
}
```

设置串口监听器初始化

```java
@PostConstruct
public void init() {
    String serialPortName = "/dev/pts/6";
    SerialPort port = SerialPort.getCommPort(serialPortName);
    port.setBaudRate(9600);
    port.setComPortTimeouts(SerialPort.TIMEOUT_READ_SEMI_BLOCKING, 5000, 0);

    if (!port.openPort()) {
        System.err.println("Cannot open serial port！" + serialPortName);
        return;
    }

        System.out.println("Opened serial port, listening at " + serialPortName);

     new Thread(() -> {
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(port.getInputStream()))) {
            String line;
            while ((line = reader.readLine()) != null) {
                handleSerialData(line.trim());
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            port.closePort();
        }
    }).start();
}
```

设计串口数据处理插入数据库逻辑

```java
private void handleSerialData(String line) {
    try {
        System.out.println(line);
        String[] parts = line.split(",");
        if (parts.length != 3) {
            System.err.println("Invalid data length: " + line);
            return;
        }

        float temperature = Float.parseFloat(parts[0]);
        float humidity = Float.parseFloat(parts[1]);
        float light = Float.parseFloat(parts[2]);

        SensorDataEntity data = new SensorDataEntity();
        data.setTemperatureValue(temperature);
        data.setHumidityValue(humidity);
        data.setLightValue(light);
        data.setTimestamp(LocalDateTime.now());

        sensorDataService.insertData(data);
        System.out.printf("Inserted： Temp=%.2f, Hum=%.2f, Light=%.0f [%s]\n", temperature, humidity, light, "success");
    } catch (NumberFormatException e) {
        System.err.println("Cannot parse data: " + line);
    }
}
```

这样就完成了串口数据的基本设计，这里可以运行一下这个程序，检查监听器是否运行。

```bash
mvn spring-boot:run
```

> [!CAUTION]
>
> 这里出现了错误
>
> ```
> Error starting ApplicationContext. To display the condition evaluation report re-run your application with 'debug' enabled.
> 2025-06-29T23:53:31.787+08:00 ERROR 234494 --- [HanbackSerialSensorServer] [           main] o.s.boot.SpringApplication               : Application run failed
> 
> org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'serialPortListener': Invocation of init method failed
> 	at org.springframework.beans.factory.annotation.InitDestroyAnnotationBeanPostProcessor.postProcessBeforeInitialization(InitDestroyAnnotationBeanPostProcessor.java:222) ~[spring-beans-6.2.8.jar:6.2.8]
> 	at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.applyBeanPostProcessorsBeforeInitialization(AbstractAutowireCapableBeanFactory.java:429) ~[spring-beans-6.2.8.jar:6.2.8]
> 	at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.initializeBean(AbstractAutowireCapableBeanFactory.java:1818) ~[spring-beans-6.2.8.jar:6.2.8]
> 	at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.doCreateBean(AbstractAutowireCapableBeanFactory.java:607) ~[spring-beans-6.2.8.jar:6.2.8]
> 	at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.createBean(AbstractAutowireCapableBeanFactory.java:529) ~[spring-beans-6.2.8.jar:6.2.8]
> 	at org.springframework.beans.factory.support.AbstractBeanFactory.lambda$doGetBean$0(AbstractBeanFactory.java:339) ~[spring-beans-6.2.8.jar:6.2.8]
> 	at org.springframework.beans.factory.support.DefaultSingletonBeanRegistry.getSingleton(DefaultSingletonBeanRegistry.java:373) ~[spring-beans-6.2.8.jar:6.2.8]
> 	at org.springframework.beans.factory.support.AbstractBeanFactory.doGetBean(AbstractBeanFactory.java:337) ~[spring-beans-6.2.8.jar:6.2.8]
> 	at org.springframework.beans.factory.support.AbstractBeanFactory.getBean(AbstractBeanFactory.java:202) ~[spring-beans-6.2.8.jar:6.2.8]
> 	at org.springframework.beans.factory.support.DefaultListableBeanFactory.instantiateSingleton(DefaultListableBeanFactory.java:1222) ~[spring-beans-6.2.8.jar:6.2.8]
> 	at org.springframework.beans.factory.support.DefaultListableBeanFactory.preInstantiateSingleton(DefaultListableBeanFactory.java:1188) ~[spring-beans-6.2.8.jar:6.2.8]
> 	at org.springframework.beans.factory.support.DefaultListableBeanFactory.preInstantiateSingletons(DefaultListableBeanFactory.java:1123) ~[spring-beans-6.2.8.jar:6.2.8]
> 	at org.springframework.context.support.AbstractApplicationContext.finishBeanFactoryInitialization(AbstractApplicationContext.java:987) ~[spring-context-6.2.8.jar:6.2.8]
> 	at org.springframework.context.support.AbstractApplicationContext.refresh(AbstractApplicationContext.java:627) ~[spring-context-6.2.8.jar:6.2.8]
> 	at org.springframework.boot.web.servlet.context.ServletWebServerApplicationContext.refresh(ServletWebServerApplicationContext.java:146) ~[spring-boot-3.4.7.jar:3.4.7]
> 	at org.springframework.boot.SpringApplication.refresh(SpringApplication.java:752) ~[spring-boot-3.4.7.jar:3.4.7]
> 	at org.springframework.boot.SpringApplication.refreshContext(SpringApplication.java:439) ~[spring-boot-3.4.7.jar:3.4.7]
> 	at org.springframework.boot.SpringApplication.run(SpringApplication.java:318) ~[spring-boot-3.4.7.jar:3.4.7]
> 	at org.springframework.boot.SpringApplication.run(SpringApplication.java:1361) ~[spring-boot-3.4.7.jar:3.4.7]
> 	at org.springframework.boot.SpringApplication.run(SpringApplication.java:1350) ~[spring-boot-3.4.7.jar:3.4.7]
> 	at cn.arorms.hanback.SerialSensorDataServer.main(SerialSensorDataServer.java:9) ~[classes/:na]
> Caused by: com.fazecast.jSerialComm.SerialPortInvalidPortException: Unable to create a serial port object from the invalid port descriptor: /dev/6
> 	at com.fazecast.jSerialComm.SerialPort.getCommPort(SerialPort.java:410) ~[jSerialComm-2.9.3.jar:2.9.3]
> 	at cn.arorms.hanback.serial.SerialPortListener.init(SerialPortListener.java:27) ~[classes/:na]
> 	at java.base/jdk.internal.reflect.DirectMethodHandleAccessor.invoke(DirectMethodHandleAccessor.java:103) ~[na:na]
> 	at java.base/java.lang.reflect.Method.invoke(Method.java:580) ~[na:na]
> 	at org.springframework.beans.factory.annotation.InitDestroyAnnotationBeanPostProcessor$LifecycleMethod.invoke(InitDestroyAnnotationBeanPostProcessor.java:457) ~[spring-beans-6.2.8.jar:6.2.8]
> 	at org.springframework.beans.factory.annotation.InitDestroyAnnotationBeanPostProcessor$LifecycleMetadata.invokeInitMethods(InitDestroyAnnotationBeanPostProcessor.java:401) ~[spring-beans-6.2.8.jar:6.2.8]
> 	at org.springframework.beans.factory.annotation.InitDestroyAnnotationBeanPostProcessor.postProcessBeforeInitialization(InitDestroyAnnotationBeanPostProcessor.java:219) ~[spring-beans-6.2.8.jar:6.2.8]
> 	... 20 common frames omitted
> Caused by: java.io.IOException: null
> 	at com.fazecast.jSerialComm.SerialPort.getCommPort(SerialPort.java:407) ~[jSerialComm-2.9.3.jar:2.9.3]
> 	... 26 common frames omitted
> 
> 
> Process finished with exit code 1
> ```
>
> 仔细查看发现，由于之前在代码中硬编码了串口设备号 `/dev/pts/6` 实际上由于串口号经常变动，需要设置一个容易改变的串口号或者动态改变串口，这里通过 application.properties 文件对项目环境进行更改。

在 `application.properties` 中设置

```ini
serial.port=/dev/pts/10
```

在串口监听类中设置环境变量

```java
@Value("${serial.port}")
private String serialPortName;
```

重新运行后发现可以正常运行

```
  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v3.4.7)

2025-06-30T00:01:24.248+08:00  INFO 239465 --- [HanbackSerialSensorServer] [           main] c.arorms.hanback.SerialSensorDataServer  : Starting SerialSensorDataServer using Java 21.0.7 with PID 239465 (/home/cacc/Repositories/HanbackSerialSensorServer/target/classes started by cacc in /home/cacc/Repositories/HanbackSerialSensorServer)
2025-06-30T00:01:24.249+08:00  INFO 239465 --- [HanbackSerialSensorServer] [           main] c.arorms.hanback.SerialSensorDataServer  : No active profile set, falling back to 1 default profile: "default"
2025-06-30T00:01:24.655+08:00  INFO 239465 --- [HanbackSerialSensorServer] [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat initialized with port 8080 (http)
2025-06-30T00:01:24.661+08:00  INFO 239465 --- [HanbackSerialSensorServer] [           main] o.apache.catalina.core.StandardService   : Starting service [Tomcat]
2025-06-30T00:01:24.661+08:00  INFO 239465 --- [HanbackSerialSensorServer] [           main] o.apache.catalina.core.StandardEngine    : Starting Servlet engine: [Apache Tomcat/10.1.42]
2025-06-30T00:01:24.677+08:00  INFO 239465 --- [HanbackSerialSensorServer] [           main] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring embedded WebApplicationContext
2025-06-30T00:01:24.677+08:00  INFO 239465 --- [HanbackSerialSensorServer] [           main] w.s.c.ServletWebServerApplicationContext : Root WebApplicationContext: initialization completed in 410 ms
2025-06-30T00:01:24.725+08:00  INFO 239465 --- [HanbackSerialSensorServer] [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Starting...
2025-06-30T00:01:24.895+08:00  INFO 239465 --- [HanbackSerialSensorServer] [           main] com.zaxxer.hikari.pool.HikariPool        : HikariPool-1 - Added connection com.mysql.cj.jdbc.ConnectionImpl@307e4c44
2025-06-30T00:01:24.896+08:00  INFO 239465 --- [HanbackSerialSensorServer] [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Start completed.
Opened serial port, listening at /dev/pts/10
22.67,56.19,563,A141E1FC67
Inserted： Temp=22.67, Hum=56.19, Light=563 RFID=A141E1FC67, [success]
24.38,67.96,952,97EADC6B96
Inserted： Temp=24.38, Hum=67.96, Light=952 RFID=97EADC6B96, [success]
26.88,44.98,608,2AECB03BFB
Inserted： Temp=26.88, Hum=44.98, Light=608 RFID=2AECB03BFB, [success]
23.50,60.60,970,54EC18DB5C
Inserted： Temp=23.50, Hum=60.60, Light=970 RFID=54EC18DB5C, [success]
23.98,64.44,779,43FBFAAA3A
Inserted： Temp=23.98, Hum=64.44, Light=779 RFID=43FBFAAA3A, [success]
21.48,66.43,749,E6053C7C94
```

根据日志输出看到监听器检查到了虚拟串口传输的数据，这里检查一下数据库

```sql
SELECT * FROM sensor_data
ORDER BY timestamp DESC
LIMIT 10;
```

返回结果如下

```
mysql> SELECT * FROM sensor_data ORDER BY timestamp DESC LIMIT 10;
+----+-------+-------------+----------+------------+---------------------+
| id | light | temperature | humidity | rfid_data  | timestamp           |
+----+-------+-------------+----------+------------+---------------------+
|  6 |   302 |       29.64 |    57.62 | E94DAD3B31 | 2025-06-30 00:03:37 |
|  5 |   825 |       28.34 |    48.23 | EF8ED24AA6 | 2025-06-30 00:03:34 |
|  4 |   555 |       21.57 |    69.15 | 6813415DC5 | 2025-06-30 00:03:31 |
|  3 |   476 |       21.31 |    40.88 | 27AE42C4D8 | 2025-06-30 00:03:28 |
|  2 |   397 |        22.2 |    66.88 | 40B964C751 | 2025-06-30 00:03:25 |
|  1 |   355 |       26.51 |    51.04 | 59DAD8B35A | 2025-06-30 00:03:22 |
+----+-------+-------------+----------+------------+---------------------+
6 rows in set (0.00 sec)
```

## 前端部分

前端设计使用 Node.js 作为依赖管理工具，使用 Vite 创建 React 框架项目进行处理，同时使用 TailwindCSS 原子化样式控制。

### 组件设计



### 总体页面



## 云平台设计

### 端口转发

如果需要上云实现应用的远程访问，在当前的环境下我认为有三种方案：

1. 在物联网云平台课程设计中使用的 MQTT 协议，利用阿里云提供的 MQTT 中继器（broker），对传感器数据进行转发。
2. 使用无服务器模式（Serverless），利用云平台创建存储对象和函数接口，实现不需要开发者自己管理维护服务器的云端访问。
3. 利用公网服务器，与本地主机建立反向连接，转发数据，利用服务器的公网资源将本地主机的特定端口转发出去，即内网穿透。

综合考虑当前环境，最整洁的方法应该为第三个方案。

**公网资源**

![image-20250629173839613](/home/cacc/Documents/NotesOfCacc/学校文件/无线传感网/课程设计日志/assets/image-20250629173839613.png)

同时，在阿里云已经创建虚拟云服务器实例，并分配主机域名 frp.arorms.cn 作为内网穿透服务器地址。服务器环境为 Ubuntu 20.04 LTS。

> [!NOTE]
>
> 这里使用了开源项目作为流量转发程序，Github 地址在 [frp](https://github.com/fatedier/frp)，

为服务器安装内网穿透服务器程序，暴露接口 7000 和 7500 分别作为内网穿透程序的连接端口和当前内网穿透的数据看板，设置好服务器。

```toml
bindPort = 7000
vhostHTTPPort = 80
vhostHTTPSPort = 443
token = "***********"

webServer.addr = "0.0.0.0"
webServer.port = 7500
webServer.user = "admin"
webServer.password = "**********"
```

这里设置了监听虚拟 HTTP 和 HTTPS 端口，分别是 80 和 443，然后启动穿透服务器

```bash
./frps -c ./frps.toml
```



### API 交互

