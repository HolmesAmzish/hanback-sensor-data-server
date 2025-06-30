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
