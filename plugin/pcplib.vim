" Maintainer	: Nikolai 'pcp' Weibull <da.box@home.se>
" URL		: http://www.pcppopper.org/
" Revised on	: Thu, 13 Jun 2002 23:16:47 +0200

if !exists("g:pcp_plugins_username")
    let g:pcp_plugins_username = "<unknown>"
endif

if !exists("g:pcp_plugins_url")
    let g:pcp_plugins_url = "<unknown>"
endif

if !exists("g:pcp_plugins_timeformat")
    let g:pcp_plugins_timeformat = "%a, %d %b %Y %H:%M:%S %z"
endif

if !exists("g:pcp_plugins_dateformat")
    let g:pcp_plugins_dateformat = "%Y-%m-%d"
endif

" NOTE: stolen from Benji Fisher's foo.vim
" Usage:  :let ma = Mark() ... execute ma
" has the same effect as  :normal ma ... :normal 'a
" without affecting global marks.
" You can also use Mark(17) to refer to the start of line 17 and Mark(17,34)
" to refer to the 34'th (screen) column of the line 17.  The functions
" Line() and Virtcol() extract the line or (screen) column from a "mark"
" constructed from Mark() and default to line() and virtcol() if they do not
" recognize the pattern.
" Update:  :execute Mark() now restores screen position as well as the cursor.
function! Mark(...)
    if a:0 == 0
	let mark = line(".") . "G" . virtcol(".") . "|"
	normal! H
	let mark = "normal!" . line(".") . "Gzt" . mark
	execute mark
	return mark
    elseif a:0 == 1
	return "normal!" . a:1 . "G1|"
    else
	return "normal!" . a:1 . "G" . a:2 . "|"
    endif
endfunction

" See comments above Mark()
function! Line(mark)
    if a:mark =~ '\dG\d\+|$'
	return substitute(a:mark, '.\{-}\(\d\+\)G\d\+|$', '\1', "")
    else
	return line(a:mark)
    endif
endfunction

" See comments above Mark()
function! Virtcol(mark)
    if a:mark =~ '\d\+G\d\+|$'
	return substitute(a:mark, '.*G\(\d\+\)|$', '\1', "")
    else
	return col(a:mark)
    endif
endfunction

" vim: set sw=4 sts=4:
