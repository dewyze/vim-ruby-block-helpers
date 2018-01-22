if exists("g:rspec_block_helpers")
  finish
endif
let g:rspec_block_helpers = 1

" From vim ruby - https://github.com/vim-ruby/vim-ruby/blob/074200ffa39b19baf9d9750d399d53d97f21ee07/indent/ruby.vim#L81-L85
let s:beginning_prefix = '\C\%(^\s*\|[=,*/%+\-|;{]\|<<\|>>\|:\s\)\s*\zs'
let s:start_pattern =
      \ s:beginning_prefix .
      \ '\<\%(module\|class\|if\|for\|while\|until\|case\|unless\|begin\|' .
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
command! BlockEnv :call BlockEnv()

noremap ]b :NextBlock<CR>
noremap [b :PreviousBlock<CR>
noremap ]e :BlockEnd<CR>
noremap ]p :ParentBlock<CR>
noremap ]h :BlockHierarchy<CR>
noremap ]v :BlockEnv<CR>
noremap ]s :SearchNextBlockPattern<CR>
noremap ]r :SearchNextPair<CR>

function! BlockEnd()
  let flags = "W"
  call _GoToMatcher()
  call searchpair(s:start_pattern,'',s:end_pattern, flags)
endfunction

function! NextBlock()
  let flags = "W"
  call _GoToMatcher()
  call searchpair(s:start_pattern,'',s:end_pattern, flags)
  call search(s:next_block_pattern, flags)
endfunction

function! PreviousBlock()
  let flags = "Wb"
  call _GoToMatcher()
  if match(getline('.'), s:next_block_pattern) == -1
    call searchpair(s:start_pattern,'',s:end_pattern, flags)
  end
  normal ^
  " TODO: look for correct indentation
  call search(s:next_block_pattern, flags)
endfunction

function! ParentBlock()
  let flags = "Wb"
  if _GoToMatcher() < 1
    call searchpair(s:start_pattern,'',s:end_pattern, flags)
  endif
  call searchpair(s:start_pattern,'',s:end_pattern, flags)
  normal ^
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

function! BlockEnv()
  let l:origline = line('.')
  let l:origcol = col('.')
  call BlockEnd()
  normal ^%
  let l:curline = line('.')
  let l:curcol = col('.')
  let l:env = getline('.')
  call ParentBlock()
  while line('.') != l:curline
    let [l:vars, l:curline, l:curcol] = _SearchForEnv(l:curline)
    call cursor(l:curline, l:curcol)
    let l:env = getline('.') . "\n" . l:vars . l:env
    call ParentBlock()
  endwhile
  call cursor(l:origline, l:origcol)
  echo l:env
endfunction

function! _SearchForEnv(stopline)
  let curline = line('.')
  let curcol = col('.')
  let new_stop_line = search(s:test_block_pattern, 'Wn', a:stopline)
  let stopline = 0
  if new_stop_line == 0
    let stopline = a:stopline
  else
    let stopline = new_stop_line
  endif
  let l:next_outside_test_block_matcher_line = search(s:non_test_block_pattern, 'Wn', stopline)

  if l:next_outside_test_block_matcher_line != 0
    let [vars_1, _, _] = _SearchForEnv(l:next_outside_test_block_matcher_line - 1)
    call cursor(l:next_outside_test_block_matcher_line, 1)
    normal ^%j
    let [vars_2, _, _] = _SearchForEnv(stopline)
    return [vars_1 . vars_2, curline, curcol]
  else
    let vars = ''
    while 1
      let l:flags = 'W'
      if search(s:env_pattern, l:flags, stopline) == 0
        break
      else
        let vars = vars . getline('.') . "\n"
      endif
    endwhile
    return [vars, curline, curcol]
  endif
endfunction

function! _GoToMatcher()
  normal ^
  return search(s:start_pattern, 'c', line('.'))
endfunction
