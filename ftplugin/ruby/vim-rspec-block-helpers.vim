if exists("g:rspec_block_helpers")
  finish
endif
let g:rspec_block_helpers = 1

" From vim ruby - https://github.com/vim-ruby/vim-ruby/blob/074200ffa39b19baf9d9750d399d53d97f21ee07/indent/ruby.vim#L81-L85
let s:beginning_prefix = '\C\%(^\s*\|[=,*/%+\-|;{]\|<<\|>>\|:\s\)\s*\zs'
let s:start_pattern =
      \ s:beginning_prefix .
      \ '\<\%(module\|class\|if\|for\|while\|until\|case\|unless\|begin' .
      \ '\|\%(public\|protected\|private\)\=\s*def\):\@!\>' .
      \ '\|\%(^\|[^.:@$]\)\@<=\<do:\@!\>'

" From vim-ruby - https://github.com/vim-ruby/vim-ruby/blob/074200ffa39b19baf9d9750d399d53d97f21ee07/indent/ruby.vim#L91
let s:end_pattern = '\%(^\|[^.:@$]\)\@<=\<end:\@!\>'

let s:group_prefix = s:beginning_prefix . '\<\%('
let s:suffix = '\):\@!\>'
let s:non_test_block_keywords = 'class\|module\|def'
let s:test_block_keywords = 'describe\|context\|it\|shared_examples\|shared_contexts'
let s:non_test_block_pattern = s:group_prefix . s:non_test_block_keywords . s:suffix
let s:test_block_pattern = s:group_prefix . s:test_block_keywords . s:suffix
let s:next_block_pattern = s:group_prefix . s:test_block_keywords . '\|' . s:non_test_block_keywords . s:suffix
let s:env_pattern =
      \ '\C^\s*\zs' .
      \ '\%(\<let[!]\=\>' .
      \ '\|subject\%((:.*)\)\=\%(\s\%({\|do\)\)' .
      \ '\|@[a-zA-Z0-9_]\+\s*=\)'

command! NextBlock :call NextBlock()
command! BlockEnd :call BlockEnd()
command! ParentBlock :call ParentBlock()
command! PreviousBlock :call PreviousBlock()
command! BlockHierarchy :call BlockHierarchy()

noremap ]b :NextBlock<CR>
noremap [b :PreviousBlock<CR>
noremap ]e :BlockEnd<CR>
noremap ]p :ParentBlock<CR>
noremap ]h :BlockHierarchy<CR>

function! BlockEnd()
  let s:flags = "W"
  call _GoToEndIfDo()
  call searchpair(s:start_pattern,'',s:end_pattern, s:flags)
endfunction

function! NextBlock()
  " TODO: Go to all matchers, not just do
  call _GoToEndIfDo()
  let s:flags = "W"
  call searchpair(s:start_pattern,'',s:end_pattern, s:flags)
  call search(s:next_block_pattern, s:flags)
endfunction

function! PreviousBlock()
  call _GoToEndIfDo()
  let s:flags = "Wb"
  if match(getline('.'), s:next_block_pattern) == -1
    call searchpair(s:start_pattern,'',s:end_pattern, s:flags)
  end
  normal ^
  " TODO: look for correct indentation
  call search(s:next_block_pattern, s:flags)
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
  if match(getline('.'), '\zs\<do\>\%( |.\+|\)\=$') > -1
    normal $
  endif
endfunction
