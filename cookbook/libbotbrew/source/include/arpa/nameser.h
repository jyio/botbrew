#ifndef LIBBOTBREW_ARPA_NAMESER_H
#define LIBBOTBREW_ARPA_NAMESER_H

#include_next <arpa/nameser.h>

/**
 * Inline versions of get/put short/long.  Pointer is advanced.
 */
#define NS_INT32SZ	4	/* #/bytes of data in a u_int32_t */
#define NS_INT16SZ	2	/* #/bytes of data in a u_int16_t */
#define NS_GET16(s, cp) do { \
	register const u_char *t_cp = (const u_char *)(cp); \
	(s) = ((u_int16_t)t_cp[0] << 8) \
		| ((u_int16_t)t_cp[1]) \
		; \
	(cp) += NS_INT16SZ; \
} while (0)
#define NS_GET32(l, cp) do { \
	register const u_char *t_cp = (const u_char *)(cp); \
	(l) = ((u_int32_t)t_cp[0] << 24) \
		| ((u_int32_t)t_cp[1] << 16) \
		| ((u_int32_t)t_cp[2] << 8) \
		| ((u_int32_t)t_cp[3]) \
		; \
	(cp) += NS_INT32SZ; \
} while (0)

#define GETSHORT	NS_GET16
#define GETLONG	NS_GET32

#define ns_c_in		1	/* Internet. */
#define ns_t_srv	33	/* Internet. */
#define C_IN	ns_c_in
#define T_SRV	ns_t_srv

typedef struct {
	unsigned	id :16;		/* query identification number */
		/* fields in third byte */
	unsigned	rd :1;		/* recursion desired */
	unsigned	tc :1;		/* truncated message */
	unsigned	aa :1;		/* authoritive answer */
	unsigned	opcode :4;	/* purpose of message */
	unsigned	qr :1;		/* response flag */
		/* fields in fourth byte */
	unsigned	rcode :4;	/* response code */
	unsigned	cd: 1;		/* checking disabled by resolver */
	unsigned	ad: 1;		/* authentic data from named */
	unsigned	unused :1;	/* unused bits (MBZ as of 4.9.3a3) */
	unsigned	ra :1;		/* recursion available */
		/* remaining bytes */
	unsigned	qdcount :16;	/* number of question entries */
	unsigned	ancount :16;	/* number of answer entries */
	unsigned	nscount :16;	/* number of authority entries */
	unsigned	arcount :16;	/* number of resource entries */
} HEADER;

#endif
