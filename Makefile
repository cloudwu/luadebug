remotedebug.dll : remotedebug.c debugvar.h
	gcc -Wall -g --shared -o $@ $< -I/usr/local/include -L/usr/local/bin -llua53

clean :
	rm remotedebug.dll

