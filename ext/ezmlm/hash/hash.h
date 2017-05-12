
#include <ruby.h>

static VALUE rb_mEzmlm;
static VALUE rb_cEZHash;


#ifndef SURF_H
#define SURF_H

#define ROTATE(x,b) (((x) << (b)) | ((x) >> (32 - (b))))
#define MUSH(i,b) x = t[i] += (((x ^ seed[i]) + sum) ^ ROTATE(x,b));

typedef struct {
	unsigned int seed[32];
	unsigned int sum[8];
	unsigned int out[8];
	unsigned int in[12];
	int todo;
} surfpcs;

static const unsigned int littleendian[8] = {
  0x03020100, 0x07060504, 0x0b0a0908, 0x0f0e0d0c,
  0x13121110, 0x17161514, 0x1b1a1918, 0x1f1e1d1c
} ;
#define end ((unsigned char *) &littleendian)
#define data ((unsigned char *) s->in)
#define outdata ((unsigned char *) s->out)

extern void surf( unsigned int out[8], const unsigned int in[12], const unsigned int seed[32] );
extern void surfpcs_init( surfpcs *s, const unsigned int k[32] );
extern void surfpcs_add( surfpcs *s, const char *x,unsigned int n );
extern void surfpcs_addlc( surfpcs *s, const char *x,unsigned int n );
extern void surfpcs_out( surfpcs *s, unsigned char h[32] );
#endif


#ifndef SUBHASH_H
#define SUBHASH_H

unsigned int subhashs(const char *s);
unsigned int subhashb(const char *s,long len);
#define subhashsa(SA) subhashb((SA)->s,(SA)->len)

#endif

