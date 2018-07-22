NAME=dijkstra

all: dijkstra

clean:
	rm -rf dijkstra dijkstra.o

dijkstra: dijkstra.asm
	nasm -f elf -F dwarf -g dijkstra.asm
	gcc -g -m32 -o dijkstra dijkstra.o /usr/local/share/csc314/driver.c /usr/local/share/csc314/asm_io.o
