;;
;; Approximate grep library. Code ported from the Caml agrep library by
;; Xavier Leroy.
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


(module agrep

	(string-match
	 substring-match
	 errors-substring-match
	 pattern
	 string->pattern
	 iso8859_15_case_insensitive
	 iso8859_15_accent_insensitive	 
	 iso8859_15_case_and_accent_insensitive	 
	 )

	(import scheme chicken)
	(require-extension datatype )
	(require-library srfi-1 srfi-4 srfi-13 srfi-14)
	(import (only srfi-1 every fold)
		(only srfi-4 make-u32vector u32vector? )
		(only srfi-13 string-length)
		srfi-14)

(include "engine.scm")


;; Deep syntax for patterns 

(define-datatype pattern pattern?
  (CBase (len integer?) (bm u32vector?))
  (CAnd  (p1 pattern?)  (p2 pattern?))
  (COr   (p1 pattern?)  (p2 pattern?)))
  

;; String matching 

(define (string-match pat text #!key (numerrs 0) (wholeword #f))
  (if (negative? numerrs) (error 'string-match "numerrs < 0"))
  (let recur ((pat pat))
    (cases pattern pat
	   (CBase (len bm)
		  (positive?
		   (agrep-match text 0 (string-length text) len bm numerrs wholeword)))
	   (CAnd (p1 p2)
		 (and (recur p1) (recur p2)))
	   (Cor (p1 p2)
		(or (recur p1) (recur p2))))))

(define (substring-match pat text pos len  #!key (numerrs 0) (wholeword #f))
  (if (or (< pos 0) (< (string-length text) (+ pos len)))
      (error 'substring-match "invalid pos len arguments" pos len))
  (if (negative? numerrs) (error 'string-match "numerrs < 0"))
  (let recur ((pat pat))
    (cases pattern pat
	   (CBase (plen bm)
		  (positive?
		   (agrep-match text pos len plen bm numerrs wholeword)))
	   (CAnd (p1 p2)
		 (and (recur p1) (recur p2)))
	   (Cor (p1 p2)
		(or (recur p1) (recur p2))))))
    

(define (errors-substring-match pat text pos len #!key (numerrs 0) (wholeword #f))
  (if (or (< pos 0) (< (string-length text) (+ pos len)))
      (error 'substring-match "invalid pos len arguments" pos len))
  (if (negative? numerrs) (error 'string-match "numerrs < 0"))
  (let recur ((pat pat))
    (cases pattern pat
	   (CBase (plen bm)
		  (positive?
		   (agrep-match text pos len plen bm numerrs wholeword)))
	   (CAnd (p1 p2)
		 (max (recur p1) (recur p2)))
	   (Cor (p1 p2)
		(min (recur p1) (recur p2))))))



;; Shallow syntax for patterns 

(define-datatype simple-pattern simple-pattern?
  (Char (c char?))
  (String (s string?))
  (Charset (cs char-set?))
  (Wildcard))

(define-datatype complex-pattern complex-pattern?
  (Simple (ps (lambda (x) (every simple-pattern? x))))
  (PAnd (p1 complex-pattern?) (p2 complex-pattern?))
  (POr (p1 complex-pattern?) (p2 complex-pattern?)))


;; Compilation of shallow syntax into deep syntax 

(define (add-char transl bm len c r)
  (if (not transl)
      (let ((t (char->integer c)))
	(agrep-set-bit bm len t r))
      (let ((t (transl c)))
	(agrep-set-bit bm len t r))))


(define (simple-pattern-len sp)
  (fold (lambda (p len)
	  (cases simple-pattern p
		 (Char (c)      (+ 1 len))
		 (String (s)    (+ (string-length s) len))
		 (Charset (cs)  (+ 1 len))
		 (Wildcard ()   len)))
	  0 sp))

(define (compile-simple-pattern sp #!key (transl #f) (nentries 257))
  (let* ((len (simple-pattern-len sp))
	 (bm  (agrep-alloc-bitmatrix len (+ 1 nentries))))
    (let fill ((pos 0) (sp sp))
      (if (pair? sp)
	  (cases simple-pattern (car sp)
		 (Char (c)
		       (add-char transl bm len c pos)
		       (fill (+ 1 pos) (cdr sp)))
		 (String (s)
			 (let ((pos1 (fold (lambda (c pos) (add-char transl bm len c pos)
						   (+ 1 pos))
					   pos (string->list s))))
			   (fill pos1 (cdr sp))))
		 (Charset (cs)
			  (for-each (lambda (c) (add-char transl bm len c pos))
				    (char-set->list cs))
			  (fill (+ 1 pos) (cdr sp)))
		 (Wildcard ()
			   (agrep-set-bit bm len nentries pos)
			   (fill pos (cdr sp))))
	  '()))
    (CBase len bm)))
		 
(define (compile-pattern pat #!key (transl #f) (nentries 257))
  (cases complex-pattern pat
	 (Simple (sp)   (compile-simple-pattern sp transl: transl nentries: nentries))
	 (PAnd (p1 p2)  (CAnd (compile-pattern p1 transl: transl nentries: nentries) 
			      (compile-pattern p2 transl: transl nentries: nentries)))
	 (POr (p1 p2)   (COr  (compile-pattern p1 transl: transl nentries: nentries)
			      (compile-pattern p2 transl: transl nentries: nentries)))))



;; From concrete syntax to shallow abstract syntax 

(define (parse-pattern s)

  (define (parse-class cls lst)
    (cond ((null? lst) 
	   (error 'parse-pattern "syntax error"))
	  ((eq? (car lst) #\]) 
	   (values cls (cdr lst)))
	  ((and (eq? (car lst) #\\) (pair? (cdr lst)))
	   (parse-class (char-set-union cls (char-set (cadr lst))) (cddr lst)))
	  ((and (pair? (cdr lst)) (pair? (cddr lst))
		(eq? (cadr lst) #\-) (not (eq? (caddr lst) #\])))
	   (let ((l (char->integer (car lst))) (u (char->integer (caddr lst))))
	     (values (char-set-union cls (ucs-range->char-set  l u)) (cdddr lst))))
	  (else
	   (values (char-set-union cls (char-set (car lst))) (cdr lst)))))

  (define (parse-char-class lst)
    (let ((cls (char-set)))
      (cond ((and (pair? lst) (eq? (car lst) #\^))
	     (let-values (((cls j) (parse-class cls (cdr lst))))
	       (values (char-set-complement cls) j)))
	    (else
	     (parse-class cls lst)))))


  (define (parse-simple-list sl lst)
    (if (null? lst)  (values sl lst)
	(case (car lst)
	  ((#\) #\| #\&)  (values sl lst))
	  ((#\()
	   (error 'parse-pattern "syntax error" lst))
	  ((#\?)
	   (parse-simple-list (cons (Charset char-set:full) sl) (cdr lst)))
	  ((#\*)
	   (parse-simple-list (cons (Wildcard) sl) (cdr lst)))
	  ((#\\)
	   (parse-simple-list (cons (Char (cadr lst)) sl) (cddr lst)))
	  ((#\[)
	   (let-values (((cls lst1)  (parse-char-class (cdr lst))))
	     (parse-simple-list (cons (Charset cls) sl) lst1)))
	  (else
	   (parse-simple-list (cons (Char (car lst)) sl) (cdr lst))))))

  (define (parse-base lst)
    (if (null? lst) (values (Simple '()) lst)
	(let ((s (car lst)))
	  (case s
	    ((#\) #\| #\&)  (values (Simple '()) lst))
	    ((#\()   
	     (let-values (((p lst1) (parse-or (cdr lst))))
	       (values p lst1)))
	    (else
	     (let-values (((sl lst1)  (parse-simple-list '() lst)))
	       (values (Simple (reverse sl)) lst1)))))))

  (define (parse-ands p1 lst)
    (if (null? lst) (values p1 lst)
        (let ((s (car lst)))
          (case s
                ((#\) #\|)  (values p1 lst))
                ((#\&)     
                 (let-values (((p2 lst2)  (parse-base (cdr lst) )))
                    (parse-ands (PAnd p1 p2) lst2)))
                (else (error 'parse-pattern "syntax error" lst))))))


  (define (parse-and lst)
    (let-values (((p1 lst1) (parse-base lst)))
      (parse-ands p1 lst1)))



  (define (parse-ors p1 lst1)
    (if (null? lst1)  (values p1 lst1)
	(let ((s (car lst1)))
	  (case s
	    ((#\))  (values p1 lst1))
	    ((#\|)  (let-values (((p2 lst2) (parse-and (cdr lst1))))
		      (parse-ors (POr p1 p2) lst2)))
	    (else   (error 'parse-pattern "syntax error in pattern" lst1))))))

  (define (parse-or lst)
    (let-values (((p1 lst1) (parse-and lst)))
      (parse-ors p1 lst1)))

  (let ((lst s))
    (let-values (((p lst1) (parse-or lst)))
       (assert (null? lst1))
       p)))


(define (pattern s #!key (transl #f))
  (if (not (string? s)) (error 'pattern "argument is not a string" s))
  (compile-pattern (parse-pattern (string->list s)) transl: transl))

(define (string->pattern s #!key (transl #f))
  (compile-pattern (Simple (list (String s))) transl: transl))


;; Translation tables for ISO 8859-15 (Latin 1 with Euro) 

(define iso8859_15_case_insensitive
  (let ((case_insensitive 
	 (list->vector (string->list "\u0000\u0001\u0002\u0003\u0004\u0005\u0006\u0007\u0008\t\n\u0011\u0012\u0013\u0014\u0015\u0016\u0017\u0018\u0019\u0020\u0021\u0022\u0023\u0024\u0025\u0026\u0027\u0028\u0029\u0030\u0031 !\"#$%&'()*+,-./0123456789:;<=>?@abcdefghijklmnopqrstuvwxyz[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~\u0127\u0128\u0129\u0130\u0131\u0132\u0133\u0134\u0135\u0136\u0137\u0138\u0139\u0140\u0141\u0142\u0143\u0144\u0145\u0146\u0147\u0148\u0149\u0150\u0151\u0152\u0153\u0154\u0155\u0156\u0157\u0158\u0159 ¡¢£¤¥¨§¨©ª«¬­®¯°±²³¸µ¶·¸¹º»½½ÿ¿àáâãäåæçèéêëìíîïðñòóôõö×øùúûüýþßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ"))))
    (lambda (c) (vector-ref case_insensitive (char->integer c)))
    ))

(define iso8859_15_accent_insensitive
  (let ((accent_insensitive 
	 "\u0000\u0001\u0002\u0003\u0004\u0005\u0006\u0007\u0008\t\n\u0011\u0012\u0013\u0014\u0015\u0016\u0017\u0018\u0019\u0020\u0021\u0022\u0023\u0024\u0025\u0026\u0027\u0028\u0029\u0030\u0031 !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~\u0127\u0128\u0129\u0130\u0131\u0132\u0133\u0134\u0135\u0136\u0137\u0138\u0139\u0140\u0141\u0142\u0143\u0144\u0145\u0146\u0147\u0148\u0149\u0150\u0151\u0152\u0153\u0154\u0155\u0156\u0157\u0158\u0159 ¡¢£¤¥S§s©ª«¬­®¯°±²³Zµ¶·z¹º»OoY¿AAAAAAACEEEEIIIIÐNOOOOO×OUUUUYÞsaaaaaaaceeeeiiiiðnooooo÷ouuuuyþy"))
    (lambda (c) (string-ref accent_insensitive (char->integer c)))
    ))

(define iso8859_15_case_and_accent_insensitive
  (let ((case_and_accent_insensitive 
	 "\u0000\u0001\u0002\u0003\u0004\u0005\u0006\u0007\u0008\t\n\u0011\u0012\u0013\u0014\u0015\u0016\u0017\u0018\u0019\u0020\u0021\u0022\u0023\u0024\u0025\u0026\u0027\u0028\u0029\u0030\u0031 !\"#$%&'()*+,-./0123456789:;<=>?@abcdefghijklmnopqrstuvwxyz[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~\u0127\u0128\u0129\u0130\u0131\u0132\u0133\u0134\u0135\u0136\u0137\u0138\u0139\u0140\u0141\u0142\u0143\u0144\u0145\u0146\u0147\u0148\u0149\u0150\u0151\u0152\u0153\u0154\u0155\u0156\u0157\u0158\u0159 ¡¢£¤¥s§s©ª«¬­®¯°±²³zµ¶·z¹º»ooy¿aaaaaaaceeeeiiiiðnooooo×ouuuuyþsaaaaaaaceeeeiiiiðnooooo÷ouuuuyþy"))
    (lambda (c) (string-ref case_and_accent_insensitive (char->integer c)))
    ))


)


