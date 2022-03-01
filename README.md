# Vim Ruby Block Helpers

This adds mappings/keystrokes to vim to allow you to more easily maneuver and
traverse ruby blocks. Additionally it adds some very helpful features for
showing context/describe hierarchy in rspec.

Jump to [setup](#setup).

## Mappings

```
]b                Goes to next sibling block, or next sibling of parent block
[b        Goes to previous sibling block, or previous sibling of parent block
]p                            Goes to the beginning of the first parent block
]c     Go to the beginning of the first spec context block (describe/context)
]s                                             Goes to start of current block
]e                                               Goes to end of current block
]h                               Print the block hierachy to the current line
]v                  Prints the various 'lets', 'subjects', and '@=' variables
```

### Functions

#### RubyBlockNext

This will go to the beginning of the line of the next block at the sibling
level. If run on the last block inside another block, it will go to the
first sibling of the parent block.

#### RubyBlockPrevious

This will go to the beginning of the line of the previous block at the sibling
level. If run on the first block inside another block, it will go to the first
previous sibling of the parent block.

#### RubyBlockParent

This will go to the beginning of the line of the immediate block surrounding
the block you are currently in.

#### RubyBlockSpecParentContext

This will go to the beginning of the line of the immediate rspec block
surrounding the block you are currently in. Limited to
describe/context/shared_example.

#### RubyBlockStart

This will go to the start of the current block.

#### RubyBlockEnd

This will go to the end of the current block.

#### RubyBlockHierarchy

This will print the hierarchy of surrounding parent blocks of the current
line. This can be useful in large spec files to learn where you are. For 
example, it will print:

```ruby
describe "foo" do
  context "bar" do
    it "baz" do
```

#### RubyBlockSpecEnv

*EXPERIMENTAL* This should really only be used in RSpec style files, and it
is tailored to those. It will print out the first line all `let/subject`
blocks, as well as anytime an `@=` varable is defined in a setup section for
a test. So it will show you your "environment" for a given spec.
For example, it will print:

```ruby
describe "foo" do
  let(:thing1) { "thing 1" }
  context "bar" do
    @thing2 = Thing2.new
    it "baz" do
```

## Setup

With [vim-plug](https://github.com/junegunn/vim-plug)

1. Add an entry to your `.vimrc`:

```
Plug 'dewyze/vim-ruby-block-helpers'
```

2. Reload your `.vimrc`
```
source %
```
3. Run `:PlugInstall`

## Contributing

See the [CONTRIBUTING](CONTRIBUTING.md) doc.


## Code of Conduct

See the [Code of Conduct](CODE_OF_CONDUCT.md) doc.
