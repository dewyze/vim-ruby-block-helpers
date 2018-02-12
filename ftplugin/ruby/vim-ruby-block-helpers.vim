if exists("g:ruby_block_helpers")
  finish
endif
let g:ruby_block_helpers = 1

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
let s:context_block_keywords = 'describe\|context\|shared_examples\|shared_context'
let s:test_block_keywords = s:context_block_keywords . '\|it'
let s:non_test_block_pattern = s:group_prefix . s:non_test_block_keywords . s:suffix
let s:test_block_pattern = s:group_prefix . s:test_block_keywords . s:suffix
let s:context_block_pattern = s:group_prefix . s:context_block_keywords . s:suffix . '\s.*\zs\<do\>'
let s:next_block_pattern = s:group_prefix . s:test_block_keywords . '\|' . s:non_test_block_keywords . s:suffix
let s:env_pattern =
      \ '\C^\s*\zs' .
      \ '\%(\<let[!]\=\>' .
      \ '\|subject\%((:.*)\)\=\%(\s\%({\|do\)\)' .
      \ '\|@[a-zA-Z0-9_]\+\s*=\)'

" TODO
" Set marks
" Return to column/line when appropriate

""
" This will go to the beginning of the line of the next block at the sibling
" level. If run on the last block inside another block, it will go to the first
" sibling of the parent block.
command! RubyBlockNext :call RubyBlockNext()

""
" This will go to the end of the current block.
command! RubyBlockEnd :call RubyBlockEnd()

""
" This will go to the beginning of the line of the immediate block surrounding
" the block you are currently in.
command! RubyBlockParent :call RubyBlockParent()

""
" This will go to the beginning of the line of the immediate rspec block
" surrounding the block you are currently in. Limited to
" describe/context/shared_example.
command! RubyBlockNearestSpecContext :call RubyBlockNearestSpecContext()

""
" This will go to the beginning of the line of the previous block at the
" sibling level. If run on the first block inside another block, it will go to
" the first previous sibling of the parent block.
command! RubyBlockPrevious :call RubyBlockPrevious()

""
" This will print the hierarchy of surrounding blocks of the current line.
command! RubyBlockHierarchy :call RubyBlockHierarchy()

""
" *EXPERIMENTAL*
" This should really only be used in RSpec style files, and it is tailored to
" those. It will print out the first line all `let/subject` blocks, as well as
" anytime an `@=` varable is defined in a setup section for a test.
command! RubyBlockSpecEnv :call RubyBlockSpecEnv()

""
" @section Mappings, mappings
" ]b                Goes to next sibling block, or next sibling of parent block
" [b        Goes to previous sibling block, or previous sibling of parent block
" ]e                                               Goes to end of current block
" ]p                            Goes to the beginning of the first parent block
" ]h                               Print the block hierachy to the current line
" ]v                  Prints the various 'lets', 'subjects', and '@=' variables

noremap <silent> ]b :RubyBlockNext<CR>
noremap <silent> [b :RubyBlockPrevious<CR>
noremap <silent> ]e :RubyBlockEnd<CR>
noremap <silent> ]p :RubyBlockParent<CR>
noremap <silent> ]s :RubyBlockNearestSpecContext<CR>
noremap <silent> ]h :RubyBlockHierarchy<CR>
noremap <silent> ]v :RubyBlockSpecEnv<CR>

function! RubyBlockEnd()
  let flags = "W"
  call _GoToMatcher()
  call searchpair(s:start_pattern,'',s:end_pattern, flags)
endfunction

function! RubyNextBlock()
  let flags = "W"
  call _GoToMatcher()
  call searchpair(s:start_pattern,'',s:end_pattern, flags)
  call search(s:next_block_pattern, flags)
endfunction

function! RubyBlockPrevious()
  let flags = "Wb"
  call _GoToMatcher()
  if match(getline('.'), s:next_block_pattern) == -1
    call searchpair(s:start_pattern,'',s:end_pattern, flags)
  end
  normal ^
  " TODO: look for correct indentation
  call search(s:next_block_pattern, flags)
endfunction

function! RubyBlockParent()
  let flags = "Wb"
  if _GoToMatcher() < 1
    call searchpair(s:start_pattern,'',s:end_pattern, flags)
  endif
  call searchpair(s:start_pattern,'',s:end_pattern, flags)
  normal ^
endfunction

function! RubyBlockNearestSpecContext()
  let flags = "Wb"
  if getline('.') !~ s:context_block_pattern
    let prev_line = line('.')
    while line('.') != 1
      call searchpair(s:start_pattern, '', s:end_pattern, flags)
      if getline('.') =~ s:context_block_pattern || line('.') == prev_line
        break
      endif
      let prev_line = line('.')
    endwhile
  endif
  normal ^
endfunction

function! RubyBlockHierarchy()
  let firstline = line('.')
  let firstcol = col('.')
  call RubyBlockEnd()
  normal ^%
  let curline = line('.')
  let hierarchy = getline('.')
  call RubyBlockParent()
  while line('.') != curline
    let hierarchy = getline('.') . "\n" . hierarchy
    let curline = line('.')
    call RubyBlockParent()
  endwhile
  call cursor(firstline, firstcol)
  echo hierarchy
endfunction

function! RubyBlockSpecEnv()
  let l:origline = line('.')
  let l:origcol = col('.')
  call RubyBlockEnd()
  normal ^%
  let l:curline = line('.')
  let l:curcol = col('.')
  let l:env = getline('.')
  call RubyBlockParent()
  while line('.') != l:curline
    let [l:vars, l:curline, l:curcol] = _SearchForEnv(l:curline)
    call cursor(l:curline, l:curcol)
    let l:env = getline('.') . "\n" . l:vars . l:env
    call RubyBlockParent()
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
