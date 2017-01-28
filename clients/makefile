
all: client client.class

client: client.c
	gcc -o $@ client.c

client.class: client.java
	javac client.java

clean:
	rm -f client client.class
