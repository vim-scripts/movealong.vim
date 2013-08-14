" movealong.txt - Context-aware motion commands
" Author:       Markus Koller <http://github.com/toupeira/>
" Version:      1.0
" License:      Same as Vim itself.  See :help license

"  repeat a motion until the given condition is met
function! movealong#until(motion, ...)
  let last_arg = a:0 > 0 ? a:000[a:0 - 1] : 0
  let options = extend({
    \ 'inline'       : 0,
    \ 'initial'      : 1,
    \ 'expression'   : '',
    \ 'max_motions'  : movealong#util#setting('max_motions'),
    \ 'syntax'       : [],
    \ 'words'        : [],
    \ 'skip_blank'   : 1,
    \ 'skip_punct'   : 1,
    \ 'skip_syntax'  : movealong#util#setting('skip_syntax'),
    \ 'skip_words'   : movealong#util#setting('skip_words'),
    \ 'cross_lines'  : 1,
    \ 'cross_eof'    : 0,
  \ }, (type(last_arg) == type({})) ? last_arg : {})

  " merge last argument to options if it's a Dict passed as a string
  if a:0 > 0
    let last = a:000[a:0 - 1]
    if type(last) == type('') && last[0] == '{'
      let options = extend(options, eval(last))
    endif
  endif

  " look for other string arguments
  if a:0 > 0 && type(a:1) == type('')
    if options['expression'] == 1
      " use the first argument as the expression
      let options['expression'] = a:1
    elseif options['words'] == 1
      " use the first argument as a list of words
      let options['words'] = split(a:1, ',')
    else
      " use the first argument as a list of syntax groups
      let options['syntax'] = split(a:1, ',')

      if a:0 > 1 && type(a:2) == type('')
        " use the second argument as a list of ignored syntax groups
        let options['skip_syntax'] = split(a:2, ',')
      endif
    endif
  endif

  " don't skip noise by default if an expression or words are given
  if !has_key(options, 'skip_noise')
    let options['skip_noise'] = (empty(options['expression']) && empty(options['words']))
  endif

  " transform syntax groups and skipwords into regexes
  let options['syntax']      = empty(options['syntax'])      ? '' : '\v^(' . join(options['syntax'], '|') . ')$'
  let options['words']       = empty(options['words'])       ? '' : '\v^(' . join(options['words'], '|') . ')$'
  let options['skip_syntax'] = empty(options['skip_syntax']) ? '' : '\v^(' . join(options['skip_syntax'], '|') . ')$'
  let options['skip_words']  = empty(options['skip_words'])  ? '' : '\v^(' . join(options['skip_words'], '|') . ')$'

  let word = ''
  let line_text = ''
  let syntax = {}
  let motions = 0

  let pos = []
  let last_pos = []
  let last_two_pos = []

  " add current position to jumplist
  normal m`

  while 1
    if motions > options['max_motions']
      " stop if the maximum number of motions was reached
      call movealong#util#error("Stopped because maximum number of motions '" . options['max_motions'] . "' was reached")
      return
    endif

    " run the motion
    if options['initial'] || motions > 0
      " open folds on the current line
      if foldclosed('.') > -1
        foldopen!
      endif

      let last_pos = [ line('.'), col('.') ]
      silent! execute "normal " . a:motion
      let pos = [ line('.'), col('.') ]

      " store position for error messages
      call movealong#util#whatswrong(pos, last_pos)

      if !options['cross_lines'] && pos[0] != last_pos[0]
        " stop at beginning or end of line
        call movealong#util#abort("Stopped because motion '" . a:motion . "' crossed line")
        return
      elseif !options['cross_eof'] && ((pos[1] == 1 && last_pos[1] == line('$')) || (pos[1] == line('$') && last_pos[1] == 1))
        " stop at first or last line
        call movealong#util#abort("Stopped at beginning/end of file")
        return
      elseif pos == last_pos
        " stop if the motion didn't change the cursor position
        call movealong#util#abort("Stopped because motion '" . a:motion . "' didn't change cursor position")
        return
      elseif [ pos, last_pos ] == last_two_pos
        " stop if the motion doesn't seem to actually move
        call movealong#util#abort("Stopped because motion '" . a:motion . "' seems to be stuck")
        return
      endif
    endif

    let motions += 1
    let last_two_pos = [ pos, last_pos ]

    " get inner word under cursor
    let register = $"
    silent! normal yiw
    let word = getreg()
    call setreg('', register)

    " get text of current line, strip whitespace
    let line_text = substitute(getline('.'), '\v^\s*(.*)\s*$', '\1', 'g')
    let match_text = options['inline'] ? word : line_text

    " get current syntax group
    let syntax = movealong#util#syntax()

    if !empty(options['words'])
      if match(match_text, options['words']) > -1
        call movealong#util#whatswrong("Stopped because word '" . match_text . "' was matched")
        break
      else
        call movealong#util#whatswrong("Skipped because word '" . match_text . "' didn't match")
        continue
      endif
    endif

    if options['skip_blank'] && match(match_text, '[^ \t]') == -1
      " skip blank lines
      call movealong#util#whatswrong("Skipped blank line")
      continue
    elseif options['skip_punct'] && word != line_text && match(match_text, '\v^[[:punct:]]+$') > -1
      " skip punctuation
      call movealong#util#whatswrong("Skipped punctuation '" . match_text . "'")
      continue
    endif

    if !empty(options['expression'])
      if eval(options['expression'])
        call movealong#util#whatswrong("Stopped because expression returned true")
        break
      else
        call movealong#util#whatswrong("Skipped because expression returned false")
        continue
      endif
    endif

    if !empty(options['syntax'])
      if movealong#util#match_syntax(syntax, options['syntax'])
        " stop if syntax matches
        call movealong#util#whatswrong("Stopped because syntax matched")
        break
      else
        " skip lines that don't match the syntax
        call movealong#util#whatswrong("Skipped syntax")
        continue
      endif
    endif

    if !empty(options['skip_words']) && match(match_text, options['skip_words']) > -1
      " skip lines that only consist of an ignored word
      call movealong#util#whatswrong("Skipped word '" . match_text . "'")
      continue
    elseif !empty(options['skip_syntax']) && movealong#util#match_syntax(syntax, options['skip_syntax'])
      " skip ignored syntax groups
      let overrides = movealong#util#setting('skip_syntax_overrides')
      if has_key(syntax, 'name') && has_key(overrides, syntax['name'])
        let words = overrides[syntax['name']]
      elseif has_key(syntax, 'original') && has_key(overrides, syntax['original'])
        let words = overrides[syntax['original']]
      else
        let words = ''
      endif

      if !empty(words) && match(match_text, words) > -1
        call movealong#util#whatswrong("Stopped because keyword '" . match_text . "' with syntax group " . syntax['name'] . " was overriden")
        let options['skip_noise'] = 0
        break
      endif

      if syntax['name'] == 'Comment' || line_text == word || options['inline']
        call movealong#util#whatswrong("Skipped ignored syntax")
        continue
      endif
    endif

    break
  endwhile

  " skip noise
  if options['skip_noise']
    call movealong#skip_noise()
  endif
endfunction

" skip over any syntax noise
function! movealong#skip_noise(...)
  let options = extend({
    \ 'inline'      : 1,
    \ 'initial'     : 0,
    \ 'skip_noise'  : 0,
  \ }, a:0 > 0 ? a:1 : {})

  return movealong#until('w', options)
endfunction
