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
