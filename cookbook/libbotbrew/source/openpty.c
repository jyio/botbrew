#include <stdlib.h>
#include <termios.h>
#include <fcntl.h>
#include <unistd.h>

#include <openpty.h>

int openpty(int *amaster, int *aslave, char *name, struct termios *termp, struct winsize *winp) {
	int master, slave;
	char *name_slave;
	master = open("/dev/ptmx",O_RDWR|O_NONBLOCK);
	if(master == -1) {
#ifdef TRACE
		TRACE(("Fail to open master"))
#endif
		return -1;
	}
	if(grantpt(master)) goto fail;
	if(unlockpt(master)) goto fail;
	name_slave = ptsname(master);
	/*TRACE(("openpty: slave name %s", name_slave))*/
	slave = open(name_slave,O_RDWR|O_NOCTTY);
	if(slave == -1) goto fail;
	if(termp) tcsetattr(slave,TCSAFLUSH,termp);
	if(winp) ioctl(slave,TIOCSWINSZ,winp);
	*amaster = master;
	*aslave = slave;
	if(name != NULL) strcpy(name,name_slave);
	return 0;
fail:
	close(master);
	return -1;
}
