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
    // 模拟数据
    unsigned short src_addr = 0x1234;
    unsigned short dst_addr = 0x5678;
    unsigned short dst2 = 0x0000;
    unsigned short dst3 = 0x0000;
    unsigned int seq_num = 0x01;
    unsigned short temperature = (unsigned short)(random_float(20.0, 30.0) * 100);
    unsigned short humidity = (unsigned short)(random_float(40.0, 70.0) * 100);
    unsigned short light = (unsigned short)random_float(300.0, 1000.0);
    unsigned char func_code = 0x01;
    unsigned char data[5] = {0x00, 0x00, 0x00, 0x00, 0x00};

    // 组织数据包
    unsigned char packet[30];
    int pos = 0;
    
    memcpy(packet + pos, &src_addr, 2); pos += 2;
    memcpy(packet + pos, &dst_addr, 2); pos += 2;
    memcpy(packet + pos, &dst2, 2); pos += 2;
    memcpy(packet + pos, &dst3, 2); pos += 2;
    memcpy(packet + pos, &seq_num, 4); pos += 4;
    memcpy(packet + pos, &temperature, 2); pos += 2;
    memcpy(packet + pos, &humidity, 2); pos += 2;
    memcpy(packet + pos, &light, 2); pos += 2;
    packet[pos++] = func_code;
    memcpy(packet + pos, data, 5); pos += 5;

    // 发送数据
    write(fd, packet, pos);
    printf("Sent binary packet (%d bytes)\n", pos);
}
