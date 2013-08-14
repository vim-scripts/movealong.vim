" movealong.txt - Context-aware motion commands
" Author:       Markus Koller <http://github.com/toupeira/>
" Version:      1.0
" License:      Same as Vim itself.  See :help license

if exists("g:loaded_movealong") || &cp || !has('syntax')
  finish
endif
let g:loaded_movealong = 1

function! s:check_defined(variable, default)
  if !exists(a:variable)
    let {a:variable} = a:default
  endif
endfunction

call s:check_defined('g:movealong_default_keys', 0)

let g:movealong_default_maps = extend({
  \ 'WordForward'   : '<Space>',
  \ 'WordBackward'  : '<Backspace>',
  \ 'LineForward'      : '<Tab>',
  \ 'LineBackward'        : '<S-Tab>',
  \ 'IndentForward'    : '<Leader>i',
  \ 'IndentBackward'      : '<Leader>I',
  \ 'FunctionForward'  : '<Leader>f',
  \ 'FunctionBackward'    : '<Leader>F',
\ }, exists('g:movealong_default_maps') ? g:movealong_default_maps : {})

call s:check_defined('g:movealong_max_motions', 1000)

call s:check_defined('g:movealong_skip_syntax', [
  \ 'Noise',
  \ 'Comment',
  \ 'Statement',
  \ 'cInclude',
  \ 'rubyInclude',
  \ 'rubyDefine',
  \ 'pythonInclude',
  \ 'phpInclude',
  \ 'phpFCKeyword',
\ ])

call s:check_defined('g:movealong_function_syntax', [
  \ 'vimFuncKey',
  \ 'rubyDefine',
  \ 'pythonFunction',
  \ 'phpFCKeyword',
\ ])

call s:check_defined('g:movealong_skip_words', [
  \ 'fi',
  \ 'end',
  \ 'else',
  \ 'done',
  \ 'then',
  \ 'endif',
  \ 'endfor',
  \ 'endwhile',
  \ 'endfunction',
  \ 'class',
  \ 'module',
  \ 'private',
  \ 'protected',
  \ 'public',
  \ 'static',
  \ 'abstract',
\ ])

" overrides for useful keywords that have an ignored syntax group
call s:check_defined('g:movealong_skip_syntax_overrides', {
  \ 'Statement': '(return|super)',
\ })

" set up commands
command! -nargs=+ -complete=syntax     MovealongSyntax            call movealong#until(<f-args>)
command! -nargs=+ -complete=syntax     MovealongSyntaxInline      call movealong#until(<f-args>, { 'inline' : 1 })
command! -nargs=+ -complete=expression MovealongExpression        call movealong#until(<f-args>, { 'expression' : 1 })
command! -nargs=+ -complete=expression MovealongExpressionInline  call movealong#until(<f-args>, { 'expression' : 1, 'inline' : 1 })
command! -nargs=+ -complete=expression MovealongWord              call movealong#until(<f-args>, { 'words' : 1 })
command! -nargs=+ -complete=expression MovealongWordInline        call movealong#until(<f-args>, { 'words' : 1, 'inline' : 1 })
command! -nargs=0                      MovealongNoise             call movealong#skip_noise()
command! -nargs=0                      MovealongWhatsWrong        call movealong#util#whatswrong()

" set up default maps
nnoremap <silent> <Plug>movealongWordForward  :MovealongSyntaxInline w<CR>
nnoremap <silent> <Plug>movealongWordBackward :MovealongSyntaxInline b<CR>

nnoremap <silent> <Plug>movealongLineForward  :MovealongSyntax j^<CR>
nnoremap <silent> <Plug>movealongLineBackward :MovealongSyntax k^<CR>

nnoremap <silent><expr> <Plug>movealongFunctionForward  ":MovealongSyntax j^ " . join(movealong#util#setting('function_syntax'), ',') . "<CR>"
nnoremap <silent><expr> <Plug>movealongFunctionBackward ":MovealongSyntax k^ " . join(movealong#util#setting('function_syntax'), ',') . "<CR>"

nnoremap <silent><expr> <Plug>movealongIndentForward    ":MovealongExpression j^ indent('.')==" . indent('.') . "<CR>"
nnoremap <silent><expr> <Plug>movealongIndentBackward   ":MovealongExpression k^ indent('.')==" . indent('.') . "<CR>"

" map default keys
if g:movealong_default_keys
  for [plug, key] in items(g:movealong_default_maps)
    execute "nmap <silent> " . key . " <Plug>movealong" . plug
  endfor
endif
