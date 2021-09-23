TARGET = icc release debug

all: $(TARGET)

CC = gcc
CFLAGS= -Wall -Wextra
SRCS = dgesv.c
OBJS = $(SRCS:.c=.o)
OBJS_DBG = $(SRCS:.c=_dbg.o)
LDLIBS= -lm -lopenblas -llapacke

%.o: %.c
	$(CC) $(CFLAGS) -O2 -c $<
	
%_dbg.o: %.c
	$(CC) $(CFLAGS) -g -O0 -c -o $@ $<

release: $(OBJS)
debug: $(OBJS_DBG)

$(TARGET):
	$(CC) $^ $(LDFLAGS) $(LDLIBS) -o $@_b

icc: dgesv.c
	icc $(CFLAGS) -mkl -o$@_b dgesv.c

run:
	echo "Small test"
	./dgesv 2048
	echo "Medium test"
	./dgesv 4096
	echo "Large test"
	./dgesv 8192

clean:
	rm icc_b debug_b release_b

