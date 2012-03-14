#ifndef LIBBOTBREW_SYS_SHM_H
#define LIBBOTBREW_SYS_SHM_H

#include <sys/syscall.h>
#include <sys/types.h>
#include <linux/shm.h>

static __inline__ void *shmat(int shmid, const void *shmaddr, int shmflg) {
	return (void*)syscall(__NR_shmat,shmid,shmaddr,shmflg);
}

static __inline__ int shmdt(const void *shmaddr) {
	return syscall(__NR_shmdt,shmaddr);
}

static __inline__ int shmget(key_t key, size_t size, int shmflg) {
	return syscall(__NR_shmget,key,size,shmflg);
}

static __inline__ int shmctl(int shmid, int cmd, struct shmid_ds *buf) {
	return syscall(__NR_shmctl,shmid,cmd,buf);
}

#endif
