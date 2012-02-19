#ifndef LIBBOTBREW_OPENPTY_H
#define LIBBOTBREW_OPENPTY_H

#include <termios.h>

int openpty(int *amaster, int *aslave, char *name, struct termios *termp, struct winsize *winp);

#endif
