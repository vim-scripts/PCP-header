" Vim plugin file
" Author: Nikolai :: lone-star :: Weibull <lone-star@home.se>
" Latest Revision: 2002-10-24
" Dependencies:
"	plugin/pcplib.vim

if exists("loaded_pcp_header")
	finish
endif

let loaded_pcp_header = 1

command! -nargs=? Header call s:header(<q-args>)

autocmd BufNewFile					*	call s:header(&ft, expand("<afile>:t"))
autocmd BufWritePre,FileWritePre	*	call s:header_update()

" setup reasonable defaults for our needed GLOBAL values
if !exists("g:pcp_header_file_description_regexp")
	let g:pcp_header_file_description_regexp = '<File-Description>'
endif

if !exists("g:pcp_header_copyright_regexp")
	let g:pcp_header_copyright_regexp = '<Copyright>'
endif

if !exists("g:pcp_header_license_regexp")
	let g:pcp_header_license_regexp = '<License>'
endif

if !exists("g:pcp_header_author_regexp")
	let g:pcp_header_author_regexp = '^\(.\{1,3}\<Author\>\s*:\).*$'
endif

if !exists("g:pcp_header_url_regexp")
	let g:pcp_header_url_regexp = '^\(.\{1,3}\<URL\>\s*:\).*$'
endif

if !exists("g:pcp_header_revised_on_regexp")
	let g:pcp_header_revised_on_regexp = 
				\'^\(.\{1,3}\<Latest Revision\>\s*:\).*$'
endif

if !exists("g:pcp_header_template_path")
	let g:pcp_header_template_path = "~/.vim/template/"
endif

" find a variable 'varname' in the bufferlocal namespace or in the global
" namespace
function s:buffer_or_global_var(varname)
	if exists("b:" . a:varname)
		execute "return " . "b:" . a:varname
	elseif exists("g:" . a:varname)
		execute "return " . "g:" . a:varname
	else
		return ""
	end
endfunction

" find a header line
" return the line number if present or 0 otherwise
function s:find_hline(pat)
	let i = 1

	let l = getline(i)
	while l !~ '^\s*$'
		if match(l, a:pat) != -1
			return i
		endif
		let i = i + 1
		let l = getline(i)
	endwhile

	return 0
endfunction

" update a header line if it is present
function s:update_hline(pat, subst)
	let lnum = s:find_hline(a:pat)
	if lnum != 0
		call setline(lnum, substitute(getline(lnum), a:pat, a:subst, ''))
	endif
endfunction

" called by autocmd above.
function s:header_update()
	" if we don't have a template for this kind of file, don't update it.
	if !filereadable(expand(g:pcp_header_template_path . "template." . &ft))
		return
	endif

	" only update if necessary
	let lnum = s:find_hline(s:buffer_or_global_var("pcp_header_revised_on_regexp"))
	let line = getline(lnum)
	let newline = substitute(line,
						\s:buffer_or_global_var("pcp_header_revised_on_regexp"),
						\'\1 ' . strftime(g:pcp_plugins_dateformat), '')
	if line != newline
		call setline(lnum, newline)
	endif
endfunction

function s:join_filenames(head, tail)
	if a:head =~ '/$'
		return a:head . a:tail
	else
		return a:head . '/' . a:tail
	endif
endfunction

" called by autocmd above and Header command.
function s:header(...)
	" get the 'filetype' of the file we're heading and try to find a template
	if a:0 == 0
		let xft	= &ft
	else
		let xft	= a:1
	endif
	let template_file = expand(s:join_filenames(g:pcp_header_template_path,
								\"template." . xft))
	if !filereadable(template_file)
		return
	endif

	" ok, found one, now read it and remove last (empty) line if new file
	silent execute "0read" . template_file
	if !filereadable(expand("%"))
		silent $delete
	endif

	" start by inserting a file-description line
	if a:0 == 2
		let filename = a:2
	else
		let filename = expand("%:t")
	endif
	echohl Question
	let description = input("Description of this file: ", "<unknown>")
	call s:update_hline(g:pcp_header_file_description_regexp,
				\filename . ": " . description)

	" next, insert license and copyright. ask user for choice if needed.
	let copyright = s:buffer_or_global_var("pcp_header_copyright")
	if copyright == ""
		let holder = input("Copyright holder: ", g:pcp_plugins_username)
		let copyright = "Copyright (C) " . strftime("%Y") . " " . holder . "."
	endif
	call s:update_hline(g:pcp_header_copyright_regexp, copyright)

	let licensefile = s:buffer_or_global_var("pcp_header_license")
	if licensefile == ""
		let licensefile = input("License for this file: ", "default")
	endif
	let licensefile = expand(s:join_filenames(g:pcp_header_template_path,
								\licensefile . ".LICENSE"))
	if filereadable(licensefile)
		let lnum = s:find_hline(g:pcp_header_license_regexp)
		if lnum != 0
			silent execute lnum . "read" . licensefile

			" this could be improved by checking if we are actually in a multiline
			" comment.
			let before	= ""
			let middle 	= ""
			let after 	= ""
			if &comments =~ '\%(^\|.*,\)m[bO]\{0,2}:[^,]\+'
				if &comments =~ '\%(^\|.*,\)s[flrbOx]\{0,6}[0-9]\+'
					let rep = substitute(&comments,
								\'\%(^\|.*,\)s[flrbOx]\{0,6}\([0-9]\+\).*$',
								\'\1', '')
					let before = ""
					while rep > 0
						let before = before . " "
						let rep = rep - 1
					endwhile
				endif
				let middle = substitute(&comments,
							\'\%(^\|.*,\)m[bO]\{0,2}:\([^,]\+\).*$', '\1', '')
				if &comments =~ '\%(^\|.*,\)mb:'
					let after = " "
				endif
			elseif &comments =~ '\%(^\|.*,\)[bO]\{0,2}:[^,]\+'
				let before = ""
				let middle = substitute(&comments,
							\'\%(^\|.*,\)[bO]\{0,2}:\([^,]\+\).*$', '\1', '')
				if &comments =~ '\%(^\|.*,\)b:'
					let after = " "
				endif
			else
				let middle = ""
			endif

			silent execute "'[,']s/^/" . before . middle . after . "/"
			silent execute lnum . "delete"
		endif
	else
		call s:update_hline(g:pcp_header_license_regexp,
					\'see the COPYING file for license information.')
	endif

	" now add the stuff we only add/update once (author and url)
	call s:update_hline(s:buffer_or_global_var("pcp_header_author_regexp"),
				\'\1 ' . g:pcp_plugins_username)
	call s:update_hline(s:buffer_or_global_var("pcp_header_url_regexp"),
				\'\1 ' . g:pcp_plugins_url)

	echohl None
	call s:header_update()
	1
	call search('^$', 'W')
	set modified
endfunction

" vim: set sw=4 ts=4:
