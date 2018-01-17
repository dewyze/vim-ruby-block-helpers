if exists("g:loaded_ruby_block_misc")
  finish
endif
let g:loaded_ruby_block_misc = 1

let s:comment_escape = '\v^[^#]*'
let s:block_openers = '\zs\<\%(def\|if\|do\|module\|class\)\>'
let s:end_pattern = '\%(^\|[^.:@$]\)\@<=\<end:\@!\>'
let s:test_matchers = '^\s\+it \|^\s\+ context \|^\s\+ describe '
let s:next_block_matchers = '^\s\+def \|^\s\+if \|^\s\+module \|^\s\+class \| do$\| do |.*|$'
let s:start_pattern =  s:block_openers
let s:skip_pattern = 'getline(".") =~ "\\v\\S\\s<(if|unless)>\\s\\S"'

command! NextBlock :call NextBlock()
command! BlockEnd :call BlockEnd()
command! GoToEndIfBlock :call _GoToDoIfBlock()
command! ParentBlock :call ParentBlock()
command! BlockHierarchy :call BlockHierarchy()
command! BlockEnvironment :call BlockEnvironment()

function! BlockEnd()
  call _GoToDoIfBlock()
  " let s:flags = "W"
  let cur_line = getline('.')
  call searchpair(s:start_pattern,'',s:end_pattern, s:flags, s:skip_pattern)
  " call searchpair(s:start_pattern,'',s:end_pattern, s:flags, s:skip_pattern)
endfunction

function! NextBlock()
  call _GoToDoIfBlock()
  let s:flags = "W"
  " let cur_line = getline('.')
  " let it_line = match(cur_line, s:test_matchers)
  " if it_line > -1
  "   echo "hi"
  " endif
  call searchpair(s:start_pattern,'',s:end_pattern, s:flags, s:skip_pattern)
  " let end_pos = getpos('.')

" check if on block line
"   if on block, go to end, and look for next
"   if at end of surrounding block, find the next outer block?
" if not on block line, go to inside block?
"   then go outside of that block and go to next sibling
"   otherwise, go to first parent block, then next outside block?
" if on end, then what?
endfunction

function! _GoToDoIfBlock()
  call search('\zs\<do\>\%( |.\+|\)\=$','',line('.'))
endfunction

noremap ]b :NextBlock<CR>
noremap ]e :BlockEnd<CR>
noremap ]g :GoToEndIfBlock<CR>

function! PreviousBlock()
endfunction

function! BlockHierarchy()

endfunction

function! BlockEnvironment()

endfunction

noremap ]b :NextBlock<CR>

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
