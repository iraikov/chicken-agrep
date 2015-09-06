;;
;; Chicken agrep library interface. Code ported from the Caml agrep
;; library by Xavier Leroy.
;;
;;
;; Copyright 2009-2015 Ivan Raikov.
;;
;; This program is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; A full copy of the GPL license can be found at
;; <http://www.gnu.org/licenses/>.
;;

(import scheme chicken foreign srfi-4)

;; Error handling, initialization and finalization

;; The following three functions are borrowed from the
;; Chicken-specific parts of SWIG
#>
static void chicken_Panic (C_char *) C_noret;
static void chicken_Panic (C_char *msg)
{
  C_word *a = C_alloc (C_SIZEOF_STRING (strlen (msg)));
  C_word scmmsg = C_string2 (&a, msg);
  C_halt (scmmsg);
  exit (5); /* should never get here */
}

static void chicken_ThrowException(C_word value) C_noret;
static void chicken_ThrowException(C_word value)
{
  char *aborthook = C_text("\003sysabort");

  C_word *a = C_alloc(C_SIZEOF_STRING(strlen(aborthook)));
  C_word abort = C_intern2(&a, aborthook);

  abort = C_block_item(abort, 0);
  if (C_immediatep(abort))
    chicken_Panic(C_text("`##sys#abort' is not defined"));

#if defined(C_BINARY_VERSION) && (C_BINARY_VERSION >= 8)
  C_word rval[3] = { abort, C_SCHEME_UNDEFINED, value };
  C_do_apply(3, rval);
#else
  C_save(value);
  C_do_apply(1, abort, C_SCHEME_UNDEFINED);
#endif
}

void chicken_agrep_exception (int code, int msglen, const char *msg) 
{
  C_word *a;
  C_word scmmsg;
  C_word list;

  a = C_alloc (C_SIZEOF_STRING (msglen) + C_SIZEOF_LIST(2));
  scmmsg = C_string2 (&a, (char *) msg);
  list = C_list(&a, 2, C_fix(code), scmmsg);
  chicken_ThrowException(list);
}

<#

; Include into generated code, but don't parse:
#>

#include <stdlib.h>
#include <string.h>
#include <errno.h>

typedef unsigned char uchar;
typedef unsigned int uint;

#define BITS_PER_WORD (8 * sizeof(unsigned int))
#define Setbit(ptr,nbit) \
  ((ptr)[(nbit) / BITS_PER_WORD] |= (1UL << ((nbit) % BITS_PER_WORD)))

unsigned char word_constituent[256] = {
  /* 0 - 31 */
     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  /*   ! " # $ % & ' ( ) * + , - . / 0 1 2 3 4 5 6 7 8 9 : ; < = > ? */
     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,
  /* @ A B C D E F G H I J K L M N O P Q R S T U V W X Y Z [ \ ] ^ _ */
     0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,
  /* ` a b c d e f g h i j k l m n o p q r s t u v w x y z { | } ~ \127 */
     0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,
  /* 128-159 */
     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  /*   ¡ ¢ £ ¤ ¥ ¦ § ¨ © ª « ¬ ­ ® ¯ ° ± ² ³ ´ µ ¶ · ¸ ¹ º » ¼ ½ ¾ ¿ */
     0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,1,1,1,0,
  /* À Á Â Ã Ä Å Æ Ç È É Ê Ë Ì Í Î Ï Ð Ñ Ò Ó Ô Õ Ö × Ø Ù Ú Û Ü Ý Þ ß */
     1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,
  /* à á â ã ä å æ ç è é ê ë ì í î ï ð ñ ò ó ô õ ö ÷ ø ù ú û ü ý þ ÿ */
     1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1
};


/* Specialized versions of string matching code */

#undef WHOLE_WORD

#define FUNCTION_NAME match_0errs
#define NERRS 0
#include "skeleton.h"
#undef FUNCTION_NAME
#undef NERRS

#define FUNCTION_NAME match_1errs
#define NERRS 1
#include "skeleton.h"
#undef FUNCTION_NAME
#undef NERRS

#define FUNCTION_NAME match_2errs
#define NERRS 2
#include "skeleton.h"
#undef FUNCTION_NAME
#undef NERRS

#define FUNCTION_NAME match_3errs
#define NERRS 3
#include "skeleton.h"
#undef FUNCTION_NAME
#undef NERRS

#define WHOLE_WORD

#define FUNCTION_NAME match_word_0errs
#define NERRS 0
#include "skeleton.h"
#undef FUNCTION_NAME
#undef NERRS

#define FUNCTION_NAME match_word_1errs
#define NERRS 1
#include "skeleton.h"
#undef FUNCTION_NAME
#undef NERRS

#define FUNCTION_NAME match_word_2errs
#define NERRS 2
#include "skeleton.h"
#undef FUNCTION_NAME
#undef NERRS

#define FUNCTION_NAME match_word_3errs
#define NERRS 3
#include "skeleton.h"
#undef FUNCTION_NAME
#undef NERRS

<#

(define BITS-PER-WORD (foreign-value "BITS_PER_WORD" int))

;; Allocate bit matrix object

(define (agrep-alloc-bitmatrix patlen nentries)
  (let* ((nwords  (fx/ (fx+ patlen (fx- BITS-PER-WORD 1)) BITS-PER-WORD))
	 (size    (+ nwords nentries)))
    (make-u32vector size 0)))


(define agrep-set-bit
  (foreign-lambda* void  ((u32vector matrix) 
			  (unsigned-int v_patlen)
			  (unsigned-int v_index)
			  (unsigned-int v_bitnum))
#<<END
  uint nwords = (v_patlen + BITS_PER_WORD - 1) / BITS_PER_WORD;

  Setbit((unsigned int *) (matrix + nwords * v_index), v_bitnum);

  C_return (C_SCHEME_UNDEFINED);
END
))

#>

void *stat_alloc (size_t size)
{
   void *p;

   if ((p = malloc (size)) == NULL)
     { 
        chicken_agrep_exception (ENOMEM, 25, "unable to allocate memory"); 
     }

   return p;
}

void stat_free (void *p)
{

   if (p == NULL)
     { 
        chicken_agrep_exception (EINVAL, 18, "null pointer freed"); 
     }

   free (p);
}

/* General code: arbitrary errors, arbitrary pattern length */

ulong match_general(uint * table, uint m,
	           uint nerrs, int wholeword,
         	   uchar * text, size_t length)
{
  uint  nwords, n, j;
  uint  ** R;
  uint  * Rpbefore;
  uint  Found_offset, Found_mask;
  uint  * Ssharp;
  uint  * Rc, * Rp;
  uint  carry;
  uint  match_empty;
  ulong retcode;

  nwords = (m + BITS_PER_WORD - 1) / BITS_PER_WORD;
  R = stat_alloc((nerrs + 1) * sizeof(uint *));
  for (n = 0; n <= nerrs; n++) 
	 R[n] = stat_alloc(nwords * sizeof(uint));
  Rpbefore = stat_alloc(nwords * sizeof(uint));

  /* Initialize Found */
  Found_offset = m / BITS_PER_WORD;
  Found_mask = 1UL << (m % BITS_PER_WORD);
  /* Initialize R */
  for (n = 0; n <= nerrs; n++) 
  {
    memset(R[n], 0, nwords * sizeof(uint));
    for (j = 0; j <= n; j++) Setbit(R[n], j);
  }
  /* Initialize Ssharp & match_empty */
  Ssharp = table + 256 * nwords;
  match_empty = 1;
  /* Main loop */
  for (/*nothing*/; length > 0; length--, text++) {
    uint * S = table + (*text) * nwords;
    if (wholeword)
      match_empty = word_constituent[text[0]] ^ word_constituent[text[1]];
    /* Special case for 0 errors */
    Rc = R[0];
    carry = match_empty;
    for (j = 0; j < nwords; j++) {
      uint Rcbefore = Rc[j];
      uint toshift = Rcbefore & S[j];
      Rc[j] = (toshift << 1) | (Rcbefore & Ssharp[j]) | carry;
      carry = toshift >> (BITS_PER_WORD - 1);
      Rpbefore[j] = Rcbefore;
    }
    if (Rc[Found_offset] & Found_mask && match_empty)
      { retcode = 0; goto exit; }
    /* General case for > 0 errors */
    for (n = 1; n <= nerrs; n++) {
      Rp = Rc;
      Rc = R[n];
      carry = match_empty;
      for (j = 0; j < nwords; j++) {
        uint Rcbefore = Rc[j];
        uint toshift = (Rcbefore & S[j]) | Rpbefore[j] | Rp[j];
        Rc[j] = (toshift << 1)
              | Rpbefore[j]
              | (Rcbefore & Ssharp[j])
              | carry;
        carry = toshift >> (BITS_PER_WORD - 1);
        Rpbefore[j] = Rcbefore;
      }
      if (Rc[Found_offset] & Found_mask && match_empty)
        { retcode = n; goto exit; }
    }
  }

  /* Not found */
  retcode = C_WORD_MAX;

  /* Cleanup */
 exit:
  for (n = 0; n <= nerrs; n++) stat_free(R[n]);
  stat_free(R);
  stat_free(Rpbefore);

  return retcode;
}
<#



(define agrep-match 
    (foreign-primitive int ((c-string v_text)
			    (unsigned-int v_ofs)
			    (unsigned-int v_len)
			    (unsigned-int v_patlen)
			    (u32vector v_table)
			    (unsigned-int v_nerrs)
			    (bool v_wholeword))
						    
#<<END
  uchar * text = (v_text+v_ofs);
  size_t len   = v_len;
  uint patlen  = v_patlen;

  if (patlen < BITS_PER_WORD) 
  {
    switch (((v_nerrs) << 1) | v_wholeword) 
    {
     case 2*0+0: C_return(C_fix( match_0errs((uint *)v_table, patlen, text, len)));
     case 2*0+1: C_return(C_fix( match_word_0errs((uint *) v_table, patlen, text, len)));
     case 2*1+0: C_return(C_fix( match_1errs((uint *) v_table, patlen, text, len)));
     case 2*1+1: C_return(C_fix( match_word_1errs((uint *) v_table, patlen, text, len)));
     case 2*2+0: C_return(C_fix( match_2errs((uint *) v_table, patlen, text, len)));
     case 2*2+1: C_return(C_fix( match_word_2errs((uint *) v_table, patlen, text, len)));
     case 2*3+0: C_return(C_fix( match_3errs((uint *) v_table, patlen, text, len)));
     case 2*3+1: C_return(C_fix( match_word_3errs((uint *) v_table, patlen, text, len)));
    }
  }

  

  C_return(C_fix((uint)match_general((uint *) v_table, patlen,
                                     v_nerrs, v_wholeword,
                                     text, len)));
END
))
