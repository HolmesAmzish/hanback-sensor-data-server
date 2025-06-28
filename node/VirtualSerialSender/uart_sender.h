#ifndef UART_SENDER_H
#define UART_SENDER_H

int open_serial_port(const char *device);
void send_sensor_data(int fd);

#endif
