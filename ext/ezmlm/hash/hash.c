
#include "hash.h"

/*
 * I originally attemped to just convert surf.c to pure Ruby, but I
 * confess a lack of understanding surrounding the char casts from
 * unsigned ints, etc, and screwing up a hash algo doesn't do anyone
 * any good, least of all, me.  In other words, I don't have to fully
 * understand DJB code to trust in it. :-)
 *
 * The following is copied verbatim from the ezmlm-idx source, version
 * 7.2.2.  See: subhash.c, surf.c, and surfpcs.c.
 *
*/

static
void surf(unsigned int out[8],const unsigned int in[12],const unsigned int seed[32])
{
  unsigned int t[12]; unsigned int x; unsigned int sum = 0;
  int r; int i; int loop;

  for (i = 0;i < 12;++i) t[i] = in[i] ^ seed[12 + i];
  for (i = 0;i < 8;++i) out[i] = seed[24 + i];
  x = t[11];
  for (loop = 0;loop < 2;++loop) {
    for (r = 0;r < 16;++r) {
      sum += 0x9e3779b9;
      MUSH(0,5) MUSH(1,7) MUSH(2,9) MUSH(3,13)
      MUSH(4,5) MUSH(5,7) MUSH(6,9) MUSH(7,13)
      MUSH(8,5) MUSH(9,7) MUSH(10,9) MUSH(11,13)
    }
    for (i = 0;i < 8;++i) out[i] ^= t[i + 4];
  }
}

static
void surfpcs_init(surfpcs *s,const unsigned int k[32])
{
  int i;
  for (i = 0;i < 32;++i) s->seed[i] = k[i];
  for (i = 0;i < 8;++i) s->sum[i] = 0;
  for (i = 0;i < 12;++i) s->in[i] = 0;
  s->todo = 0;
}

static
void surfpcs_add(surfpcs *s,const char *x,unsigned int n)
{
  int i;
  while (n--) {
    data[end[s->todo++]] = *x++;
    if (s->todo == 32) {
      s->todo = 0;
      if (!++s->in[8])
        if (!++s->in[9])
          if (!++s->in[10])
            ++s->in[11];
      surf(s->out,s->in,s->seed);
      for (i = 0;i < 8;++i)
	s->sum[i] += s->out[i];
    }
  }
}

static
void surfpcs_addlc(surfpcs *s,const char *x,unsigned int n)
/* modified from surfpcs_add by case-independence and skipping ' ' & '\t' */
{
  unsigned char ch;
  int i;
  while (n--) {
    ch = *x++;
    if (ch == ' ' || ch == '\t') continue;
    if (ch >= 'A' && ch <= 'Z')
      ch -= 'a' - 'A';

    data[end[s->todo++]] = ch;
    if (s->todo == 32) {
      s->todo = 0;
      if (!++s->in[8])
        if (!++s->in[9])
          if (!++s->in[10])
            ++s->in[11];
      surf(s->out,s->in,s->seed);
      for (i = 0;i < 8;++i)
	  s->sum[i] += s->out[i];
    }
  }
}

static
void surfpcs_out(surfpcs *s,unsigned char h[32])
{
  int i;
  surfpcs_add(s,".",1);
  while (s->todo) surfpcs_add(s,"",1);
  for (i = 0;i < 8;++i) s->in[i] = s->sum[i];
  for (;i < 12;++i) s->in[i] = 0;
  surf(s->out,s->in,s->seed);
  for (i = 0;i < 32;++i) h[i] = outdata[end[i]];
}

static
void makehash(const char *indata,unsigned int inlen,char *hash)
	/* makes hash[COOKIE=20] from stralloc *indata, ignoring case and */
	/* SPACE/TAB */
{
  unsigned char h[32];
  surfpcs s;
  unsigned int seed[32];
  int i;

  for (i = 0;i < 32;++i) seed[i] = 0;
  surfpcs_init(&s,seed);
  surfpcs_addlc(&s,indata,inlen);
  surfpcs_out(&s,h);
  for (i = 0;i < 20;++i)
    hash[i] = 'a' + (h[i] & 15);
}

static
unsigned int subhashb(const char *s,long len)
{
  unsigned long h;
  h = 5381;
  while (len-- > 0)
    h = (h + (h << 5)) ^ (unsigned int)*s++;
  return h % 53;
}

static
unsigned int subhashs(const char *s)
{
  return subhashb(s,strlen(s));
}

/* end copy of ezmlm-idx source */




/*
 * call-seq:
 *   Ezmlm::Hash.address( email ) -> String
 *
 * Call the Surf hashing function on an +email+ address, returning
 * the hashed string.  This is specific to how ezmlm is seeding
 * the hash, and parsing email addresses from messages (prefixed with
 * the '<' character.)
 *
 */
static VALUE
address( VALUE klass, VALUE email ) {
	char hash[20];
	char *input;

	Check_Type( email, T_STRING );

	email = rb_str_plus( rb_str_new2("<"), email );
	input = StringValueCStr( email );

	makehash( input, strlen(input), hash );

	return rb_str_new( hash, 20 );
}


/*
 * call-seq:
 *   Ezmlm::Hash.subscriber( address ) -> String
 *
 * Call the subscriber hashing function on an email +address+, returning
 * the index character referring to the file containing subscriber presence.
 *
 */
static VALUE
subscriber( VALUE klass, VALUE email ) {
	unsigned int prefix;

	Check_Type( email, T_STRING );

	email  = rb_str_plus( rb_str_new2("T"), email);
	prefix = subhashs( StringValueCStr(email) ) + 64;

	return rb_sprintf( "%c", (char)prefix );
}



void
Init_hash()
{
	rb_mEzmlm  = rb_define_module( "Ezmlm" );
	rb_cEZHash = rb_define_class_under( rb_mEzmlm, "Hash", rb_cObject );

	rb_define_module_function( rb_cEZHash, "address", address, 1 );
	rb_define_module_function( rb_cEZHash, "subscriber", subscriber, 1 );

	return;
}

