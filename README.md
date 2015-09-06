# agrep

## Description

This library implements the Wu-Manber algorithm for string searching
with errors, popularized by the `agrep` Unix command and the
`glimpse` file indexing tool.  It was developed as part of a search
engine for a largish MP3 collection; the "with error" searching comes
handy for those who can't spell Liszt or Shostakovitch.

Given a search pattern and a string, this algorithm determines whether
the string contains a substring that matches the pattern up to a
parameterizable number N of errors.  An error is either a substitution
(replace a character of the string with another character), a deletion
(remove a character) or an insertion (add a character to the string).
In more scientific terms, the number of errors is the Levenshtein edit
distance between the pattern and the matched substring.

The search patterns are roughly those of the Unix shell, including
one-character wildcard (?), character classes ([0-9]) and
multi-character wildcard (*).  In addition, conjunction (&) and
alternative (|) are supported.  General regular expressions are not
supported, however.

The algorithm is described in S. Wu and U. Manber, `Fast Text
Searching With Errors`, tech. rep. TR 91-11, University of Arizona,
1991.  


## Library Procedures

<procedure>(pattern STRING [TRANSL]) => PATTERN</procedure>

Compiles a search pattern.  The syntax for patterns is similar to that of the Unix shell.  
The following constructs are recognized:

- `?`:  match any single character
- `*`:  match any sequence of characters
- `[..]`:  character set: ranges are denoted with -, as in `[a-z]`; an initial `^`, as in `[^0-9]`, complements the set
- `&`:  conjunction (e.g. `sweet&sour`)
- `|`:  alternative (e.g. `high|low`)
- `(..)`: grouping
- `\`:  escape special characters; the special characters are `\?*[]&|()`.

The optional argument `TRANSL` is a character translation table.

<procedure>(string->pattern STRING [TRANSL]) => PATTERN</procedure>

Returns a pattern that matches exactly the given string  and nothing else.

<procedure>(string-match PAT STRING [NUMERRS] [WHOLEWORD]) => BOOL</procedure>

Tests whether the string `STRING` matches the compiled pattern
`PAT`.  The optional keyword parameter `NUMERRS` is the number of
errors permitted.  One error corresponds to a substitution, an
insertion or a deletion of a character.  `NUMERRS` default to 0
(exact match).  The optional keyword parameter `WHOLEWORD` is true
if the pattern must match a whole word, false if it can match inside a
word.  It defaults to false (match inside words).

<procedure>(substring-match PAT STRING POS LEN [NUMERRS] [WHOLEWORD] )</procedure>

Same as `string-match`, but restricts the match to the substring of
the given string starting at character number `POS` and extending
`LEN` characters. 

<procedure>(errors-substring-match PAT STRING POS LEN [NUMERRS] [WHOLEWORD])</procedure>

Same as `substring-match`, but returns the smallest number of errors
such that the substring matches the pattern.  That is, it returns 0
if the substring matches exactly, 1 if the substring matches with
one error, etc.  Returns -1 if the substring does not match the
pattern with at most `NUMERRS` errors. 


## License

>
> agrep was originally written by Xavier Leroy and ported to Chicken
> by Ivan Raikov.
>
>  Copyright 2009-2015 Ivan Raikov.
> 
> 
>  This program is free software: you can redistribute it and/or modify
>  it under the terms of the GNU General Public License as published by
>  the Free Software Foundation, either version 3 of the License, or
>  (at your option) any later version.
> 
>  This program is distributed in the hope that it will be useful, but
>  WITHOUT ANY WARRANTY; without even the implied warranty of
>  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
>  General Public License for more details.
> 
>  A full copy of the GPL license can be found at
>  <http://www.gnu.org/licenses/>.
>