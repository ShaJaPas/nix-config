CC = gcc
CFLAGS = -Wall -Wextra -O2 -std=c99
LIBS = -lX11

TARGET = xkb-layout-monitor
SOURCE = xkb_layout_monitor.c

all: $(TARGET)

$(TARGET): $(SOURCE)
	$(CC) $(CFLAGS) -o $(TARGET) $(SOURCE) $(LIBS)

clean:
	rm -f $(TARGET)

install: $(TARGET)
	install -Dm755 $(TARGET) $(PREFIX)/bin/$(TARGET)

.PHONY: all clean install
