/*  Copyright (C) 2002     Manuel Novoa III
 *  From my (incomplete) stdlib library for linux and (soon) elks.
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Library General Public
 *  License as published by the Free Software Foundation; either
 *  version 2 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Library General Public License for more details.
 *
 *  You should have received a copy of the GNU Library General Public
 *  License along with this library; if not, write to the Free
 *  Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

/*
 * From uClibc-0.9.33/libc/stdlib/stdlib.c
 */

#include <wchar.h>

int mblen(register const char *s, size_t n)
{
	static mbstate_t state;
	size_t r;

	if (!s) {
		//state.__mask = 0;
		/*
			In this case we have to return 0 because the only multibyte supported encoding
			is utf-8, that is a stateless encoding. See mblen() documentation.
		*/
		return 0;
	}

	if (*s == '\0')
		/* According to the ISO C 89 standard this is the expected behaviour.  */
		return 0;

	if ((r = mbrlen(s, n, &state)) == (size_t) -2) {
		/* TODO: Should we set an error state? */
		//state.__wc = 0xffffU;	/* Make sure we're in an error state. */
		return -1;		/* TODO: Change error code above? */
	}
	return r;
}

int mbtowc(wchar_t *__restrict pwc, register const char *__restrict s, size_t n)
{
	static mbstate_t state;
	size_t r;

	if (!s) {
		//state.__mask = 0;
		/*
			In this case we have to return 0 because the only multibyte supported encoding
			is utf-8, that is a stateless encoding. See mbtowc() documentation.
		*/

		return 0;
	}

	if (*s == '\0')
		/* According to the ISO C 89 standard this is the expected behaviour.  */
		return 0;

	if ((r = mbrtowc(pwc, s, n, &state)) == (size_t) -2) {
		/* TODO: Should we set an error state? */
		//state.__wc = 0xffffU;	/* Make sure we're in an error state. */
		return -1;		/* TODO: Change error code above? */
	}
	return r;
}

/* Note: We completely ignore state in all currently supported conversions. */
int wctomb(register char *__restrict s, wchar_t swc)
{
	return (!s)
		?
		/*
			In this case we have to return 0 because the only multibyte supported encoding
			is utf-8, that is a stateless encoding. See wctomb() documentation.
		*/

		0
		: ((ssize_t) wcrtomb(s, swc, NULL));
}

size_t mbstowcs(wchar_t * __restrict pwcs, const char * __restrict s, size_t n)
{
	mbstate_t state;
	const char *e = s;			/* Needed because of restrict. */

	//state.__mask = 0;			/* Always start in initial shift state. */
	return mbsrtowcs(pwcs, &e, n, &state);
}


/* Note: We completely ignore state in all currently supported conversions. */
size_t wcstombs(char * __restrict s, const wchar_t * __restrict pwcs, size_t n)
{
	const wchar_t *e = pwcs;	/* Needed because of restrict. */

	return wcsrtombs(s, &e, n, NULL);
}
