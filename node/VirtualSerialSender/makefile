CC = gcc
CFLAGS = -Wall -O2
OBJS = main.o uart_sender.o
TARGET = virtual_uart_sender.out

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^

clean:
	rm -f $(TARGET) $(OBJS)
