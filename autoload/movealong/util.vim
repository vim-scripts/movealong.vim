" movealong.txt - Context-aware motion commands
" Author:       Markus Koller <http://github.com/toupeira/>
" Version:      1.0
" License:      Same as Vim itself.  See :help license

" get a setting from either a buffer or global variable
function! movealong#util#setting(key)
  let key = 'movealong_' . a:key
  if exists('b:' . key)
    return eval('b:' . key)
  else
    return eval('g:' . key)
  endif
endfunction

" set or show last error message
function! movealong#util#whatswrong(...)
  if a:0 > 0
    if type(a:1) == type('')
      let s:error = a:1
    else
      let s:error_pos = [ a:1, a:2 ]
    endif
  elseif exists('s:error')
    echohl WarningMsg
    let message = "[movealong] " . s:error
    if exists('s:error_pos')
      let message .= " [position:" . join(s:error_pos[0], '/') . "]"
      let message .= " [last:"     . join(s:error_pos[1], '/') . "]"
    endif
    echomsg message
    echohl none
  else
    echohl MoreMsg
    echomsg "[movealong] Nothing to see here, move along!"
    echohl none
  endif
endfunction

" show an error and reset the cursor position
function! movealong#util#error(message)
  call movealong#util#whatswrong(a:message)
  echoerr "[movealong] " . a:message
  normal ``
endfunction

" store an error and reset the cursor position
function! movealong#util#abort(message)
  call movealong#util#whatswrong(a:message)
  normal ``
endfunction

" get the syntax names for the current cursor position
function! movealong#util#syntax()
  let id       = synID(line('.'), col('.'), 1)
  let name     = synIDattr(synIDtrans(id), 'name')
  let original = synIDattr(id, 'name')

  return {
    \ 'id'       : id,
    \ 'name'     : name,
    \ 'original' : original,
  \ }
endfunction

" check if the syntax names match any of the given groups
function! movealong#util#match_syntax(syntax, pattern)
  return (has_key(a:syntax, 'name')     && match(a:syntax['name'],     a:pattern) > -1)
    \ || (has_key(a:syntax, 'original') && match(a:syntax['original'], a:pattern) > -1)
endfunction
