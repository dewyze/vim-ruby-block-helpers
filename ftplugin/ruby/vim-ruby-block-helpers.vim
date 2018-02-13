if exists("g:ruby_block_helpers")
  finish
endif
let g:ruby_block_helpers = 1

" From vim ruby - https://github.com/vim-ruby/vim-ruby/blob/074200ffa39b19baf9d9750d399d53d97f21ee07/indent/ruby.vim#L81-L85
let s:beginning_prefix = '\%(^\s*\|[=,*/%+\-|;{]\|<<\|>>\|:\s\)\s*\zs'
let s:start_pattern =
      \ s:beginning_prefix .
      \ '\<\%(module\|class\|if\|for\|while\|until\|case\|unless\|begin' .
      \ '\|\%(public\|protected\|private\)\=\s*def\):\@!\>' .
      \ '\|\%(^\|[^.:@$]\)\@<=\<do:\@!\>'

" From vim-ruby - https://github.com/vim-ruby/vim-ruby/blob/074202ffa39b19baf9d9750d399d53d97f21ee07/indent/ruby.vim#L91
let s:end_pattern = '\%(^\|[^.:@$]\)\@<=\<end:\@!\>'
let s:ruby_block_keywords = '\%(' . s:start_pattern . '\|' . s:end_pattern . '\)'
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
" Make visual work
" handle do in test description

""
" This will go to the beginning of the line of the next block at the sibling
" level. If run on the last block inside another block, it will go to the first
" sibling of the parent block.
command! RubyBlockNext :call RubyBlockNext()

""
" This will go to the end of the current block.
command! RubyBlockEnd :call RubyBlockEnd()

""
" This will go to the start of the current block.
command! RubyBlockStart :call RubyBlockStart()

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
" For example, it will print:
"
" describe "foo" do
"   context "bar" do
"     it "baz" do
command! RubyBlockHierarchy :call Output(function("BuildHierarchy"))

""
" *EXPERIMENTAL*
" This should really only be used in RSpec style files, and it is tailored to
" those. It will print out the first line all `let/subject` blocks, as well as
" anytime an `@=` varable is defined in a setup section for a test.
" For example, it will print:
"
" describe "foo" do
"   let(:thing1) { "thing 1" }
"   context "bar" do
"     \@thing2 = Thing2.new
"     it "baz" do
command! RubyBlockSpecEnv :call Output(function("BuildEnv"))

""
" @section Mappings, mappings
" ]b                Goes to next sibling block, or next sibling of parent block
" [b        Goes to previous sibling block, or previous sibling of parent block
" ]e                                               Goes to end of current block
" ]s                                             Goes to start of current block
" ]p                            Goes to the beginning of the first parent block
" ]c     Go to the beginning of the first spec context block (describe/context)
" ]h                               Print the block hierachy to the current line
" ]v                  Prints the various 'lets', 'subjects', and '@=' variables

noremap <silent> ]b :RubyBlockNext<CR>
noremap <silent> [b :RubyBlockPrevious<CR>
noremap <silent> ]e :RubyBlockEnd<CR>
noremap <silent> ]s :RubyBlockStart<CR>
noremap <silent> ]p :RubyBlockParent<CR>
noremap <silent> ]c :RubyBlockNearestSpecContext<CR>
noremap <silent> ]h :RubyBlockHierarchy<CR>
noremap <silent> ]v :RubyBlockSpecEnv<CR>

function! RubyBlockEnd()
  let flags = "W"
  call GoToMatcher()
  call searchpair(s:start_pattern,'',s:end_pattern, flags)
endfunction

function! RubyBlockStart()
  call RubyBlockEnd()
  normal %
endfunction

function! RubyBlockNext()
  let flags = "W"
  call RubyBlockEnd()
  call search(s:next_block_pattern, flags)
endfunction

function! RubyBlockPrevious()
  let flags = "Wb"
  call GoToMatcher()
  if match(getline('.'), s:next_block_pattern) == -1
    call searchpair(s:start_pattern,'',s:end_pattern, flags)
  end
  normal ^
  call search(s:ruby_block_keywords, flags)
  if match(getline('.'), s:end_pattern) != -1
    normal %
  endif
  normal ^
endfunction

function! RubyBlockParent()
  let flags = "Wb"
  if GoToMatcher() < 1
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

function! Output(Func)
  let origline = line('.')
  let origcol = col('.')
  call RubyBlockEnd()
  normal ^%
  let curline = line('.')
  let l:output = getline('.')
  call RubyBlockParent()
  let l:output = a:Func(curline, output)
  call cursor(origline, origcol)
  echo l:output
endfunction

function! BuildHierarchy(curline, output)
  let l:output = a:output
  let l:curline = a:curline
  while line('.') != l:curline
    let l:output = getline('.') . "\n" . l:output
    let l:curline = line('.')
    call RubyBlockParent()
  endwhile

  return l:output
endfunction

function! BuildEnv(curline, output)
  let l:output = a:output
  let l:curline = a:curline
  while line('.') != l:curline
    let [l:vars, l:curline] = SearchForEnv(l:curline)
    call cursor(l:curline, 1)
    let l:output = getline('.') . "\n" . l:vars . l:output
    call RubyBlockParent()
  endwhile

  return l:output
endfunction

function! SearchForEnv(stopline)
  let curline = line('.')
  let new_stop_line = search(s:test_block_pattern, 'Wn', a:stopline)
  let stopline = 0
  if new_stop_line == 0
    let stopline = a:stopline
  else
    let stopline = new_stop_line
  endif
  let l:next_outside_test_block_matcher_line = search(s:non_test_block_pattern, 'Wn', stopline)

  if l:next_outside_test_block_matcher_line != 0
    let [vars_1, _] = SearchForEnv(l:next_outside_test_block_matcher_line - 1)
    call cursor(l:next_outside_test_block_matcher_line, 1)
    normal ^%j
    let [vars_2, _] = SearchForEnv(stopline)
    return [vars_1 . vars_2, curline]
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
    return [vars, curline]
  endif
endfunction

function! GoToMatcher()
  normal ^
  return search(s:start_pattern, 'c', line('.'))
endfunction
