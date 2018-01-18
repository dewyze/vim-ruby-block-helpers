if exists("g:loaded_ruby_block_misc")
  finish
endif
let g:loaded_ruby_block_misc = 1

" let s:start_pattern = '\C\%(^\|[^.:@$]\)\@<=\<do:\@!\>'
let s:start_pattern =
      \ '\C\%(^\s*\|[=,*/%+\-|;{]\|<<\|>>\|:\s\)\s*\zs' .
      \ '\<\%(module\|class\|if\|for\|while\|until\|case\|unless\|begin' .
      \ '\|\%(public\|protected\|private\)\=\s*def\):\@!\>' .
      \ '\|\%(^\|[^.:@$]\)\@<=\<do:\@!\>'

let s:end_pattern = '\%(^\|[^.:@$]\)\@<=\<end:\@!\>'
let s:test_matchers =
      \ '\C\%(^\s*\|[=,*/%+\-|;{]\|<<\|>>\|:\s\)\s*\zs' .
      \ '\<\%(describe\|context\|it\|shared_examples\|shared_contexts\):\@!\>'


command! NextBlock :call NextBlock()
command! BlockEnd :call BlockEnd()
command! GoToEndIfBlock :call _GoToDoIfBlock()
command! ParentBlock :call ParentBlock()
" command! PreviousBlock :call PreviousBlock()
" command! BlockHierarchy :call BlockHierarchy()
" command! BlockEnvironment :call BlockEnvironment()

noremap ]b :NextBlock<CR>
noremap ]e :BlockEnd<CR>
noremap ]g :GoToEndIfBlock<CR>
noremap ]p :ParentBlock<CR>

" TODO:
" - Add ability to repeat action with `.`
" - Add ability to do count?
" - Add ability to do inside/around

function! BlockEnd()
  let s:flags = "W"
  call _GoToDoIfBlock()
  call searchpair(s:start_pattern,'',s:end_pattern, s:flags)
endfunction

function! NextBlock()
  call _GoToDoIfBlock()
  let s:flags = "W"
  call searchpair(s:start_pattern,'',s:end_pattern, s:flags)
  call search(s:test_matchers, s:flags)
endfunction

function! ParentBlock()
  call _GoToDoIfBlock()
  let s:flags = "W"
  call searchpair(s:start_pattern,'',s:end_pattern, s:flags)
  let indentation = matchend(getline('.'), '\s*')
  echo indentation
endfunction

function! _GoToDoIfBlock()
  call search('\zs\<do\>\%( |.\+|\)\=$','',line('.'))
endfunction


" function! PreviousBlock()
" endfunction

" function! BlockHierarchy()
" endfunction
"
" function! BlockEnvironment()
" endfunction

" function! s:select_a()
"   let s:flags = 'W'
"
"   call searchpair(s:start_pattern,'',s:end_pattern, s:flags, s:skip_pattern)
"   let end_pos = getpos('.')
"
"   " Jump to match
"   normal %
"   let start_pos = getpos('.')
"
"   return ['V', start_pos, end_pos]
" endfunction
"
" function! s:select_i()
"   let s:flags = 'W'
"   if expand('<cword>') == 'end'
"     let s:flags = 'cW'
"   endif
"
"   call searchpair(s:start_pattern,'',s:end_pattern, s:flags, s:skip_pattern)
"
"   " Move up one line, and save position
"   normal k^
"   let end_pos = getpos('.')
"
"   " Move down again, jump to match, then down one line and save position
"   normal j^%j
"   let start_pos = getpos('.')
"
"   return ['V', start_pos, end_pos]
" endfunction
