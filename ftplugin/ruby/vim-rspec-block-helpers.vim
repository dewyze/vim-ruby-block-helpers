if exists("g:loaded_ruby_block_misc")
  finish
endif
let g:loaded_ruby_block_misc = 1

" From vim ruby - https://github.com/vim-ruby/vim-ruby/blob/074200ffa39b19baf9d9750d399d53d97f21ee07/indent/ruby.vim#L81-L85
let s:start_pattern =
      \ '\C\%(^\s*\|[=,*/%+\-|;{]\|<<\|>>\|:\s\)\s*\zs' .
      \ '\<\%(module\|class\|if\|for\|while\|until\|case\|unless\|begin' .
      \ '\|\%(public\|protected\|private\)\=\s*def\):\@!\>' .
      \ '\|\%(^\|[^.:@$]\)\@<=\<do:\@!\>'

" From vim-ruby - https://github.com/vim-ruby/vim-ruby/blob/074200ffa39b19baf9d9750d399d53d97f21ee07/indent/ruby.vim#L91
let s:end_pattern = '\%(^\|[^.:@$]\)\@<=\<end:\@!\>'
let s:test_matchers =
      \ '\C\%(^\s*\|[=,*/%+\-|;{]\|<<\|>>\|:\s\)\s*\zs' .
      \ '\<\%(describe\|context\|it\|shared_examples\|shared_contexts\):\@!\>'

command! NextBlock :call NextBlock()
command! BlockEnd :call BlockEnd()
command! ParentBlock :call ParentBlock()
command! PreviousBlock :call PreviousBlock()
command! BlockHierarchy :call BlockHierarchy()

noremap ]b :NextBlock<CR>
noremap ]B :PreviousBlock<CR>
noremap ]e :BlockEnd<CR>
noremap ]p :ParentBlock<CR>
noremap ]h :BlockHierarchy<CR>

function! BlockEnd()
  let s:flags = "W"
  call _GoToEndIfDo()
  call searchpair(s:start_pattern,'',s:end_pattern, s:flags)
endfunction

function! NextBlock()
  call _GoToEndIfDo()
  let s:flags = "W"
  call searchpair(s:start_pattern,'',s:end_pattern, s:flags)
  call search(s:test_matchers, s:flags)
endfunction

function! PreviousBlock()
  let s:flags = "Wb"
  call searchpair(s:start_pattern,'',s:end_pattern, s:flags)
  normal ^^
  call search(s:test_matchers, s:flags)
endfunction

function! ParentBlock()
  let s:flags = "Wb"
  if match(getline('.'), '\zs\<do\>\%( |.\+|\)\=$') > -1
    normal ^^
  else
    call searchpair(s:start_pattern,'',s:end_pattern, s:flags)
  endif
  call searchpair(s:start_pattern,'',s:end_pattern, s:flags)
  normal ^^
endfunction

function! BlockHierarchy()
  let firstline = line('.')
  let firstcol = col('.')
  call BlockEnd()
  normal ^%
  let curline = line('.')
  let hierarchy = getline('.')
  call ParentBlock()
  while line('.') != curline
    let hierarchy = getline('.') . "\n" . hierarchy
    let curline = line('.')
    call ParentBlock()
  endwhile
  call cursor(firstline, firstcol)
  echo hierarchy
endfunction

function! _GoToEndIfDo()
  call search('\zs\<do\>\%( |.\+|\)\=$','',line('.'))
endfunction
