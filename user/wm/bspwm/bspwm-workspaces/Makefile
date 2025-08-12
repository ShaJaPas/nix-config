CC = gcc
CFLAGS = -Wall -Wextra -O2 -std=c99
LDFLAGS = -lX11

TARGET = workspaces
SOURCE = workspaces.c

$(TARGET): $(SOURCE)
	$(CC) $(CFLAGS) -o $(TARGET) $(SOURCE) $(LDFLAGS)

clean:
	rm -f $(TARGET)

install: $(TARGET)
	cp $(TARGET) ~/.local/bin/

.PHONY: clean install
