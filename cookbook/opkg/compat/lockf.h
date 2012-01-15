#include <unistd.h>

#define F_ULOCK	LOCK_UN			/* 0: Unlock a previously locked region. */
#define F_LOCK	LOCK_EX			/* 1: Lock a region for exclusive use. */
#define F_TLOCK	LOCK_EX|LOCK_NB	/* 2: Test and lock a region for exclusive use. */
#define F_TEST	16				/* 3: Test a region for other processes locks. */

inline int lockf(int fd, int cmd, off_t len) {
	if(cmd != F_TEST) return flock(fd,cmd);
	if(flock(fd,LOCK_EX|LOCK_NB) < 0) return -1;
	flock(fd,LOCK_UN);
	return 0;
}
