" General settings {{{
set iskeyword+=-         " Treat dash separated words as a word text object "

syntax enable          " Enables syntax highlighing
set hidden             " Required to keep multiple buffers open
set nowrap             " Display long lines as just one line
set encoding=utf-8     " The encoding displayed
set fileencoding=utf-8 " The encoding written to file
set pumheight=10       " Makes popup menu smaller
set ruler              " Show the cursor position all the time
set mouse=a            " Enable your mouse
set splitbelow         " Horizontal splits will automatically be below
set splitright         " Vertical splits will automatically be to the right
set t_Co=256           " Support 256 colors
set conceallevel=0     " So that I can see `` in markdown files
set tabstop=2          " Insert 2 spaces for a tab
set shiftwidth=2       " Change the number of space characters inserted for indentation
set smarttab           " Makes tabbing smarter will realize you have 2 vs 4
set expandtab          " Converts tabs to spaces
set smartindent        " Makes indenting smart
set autoindent         " Good auto indent
set laststatus=2       " Always display the status line
set number             " Line numbers
set cursorline         " Enable highlighting of the current line
set background=dark    " Tell vim what the background color looks like
set showtabline=2      " Always show tabs
set nobackup           " This is recommended by coc
set nowritebackup      " This is recommended by coc
set shortmess+=c       " Don't pass messages to |ins-completion-menu|
set signcolumn=yes     " Always show the signcolumn, otherwise it would shift the text each time
set updatetime=300     " Faster completion
set timeoutlen=250     " By default timeoutlen is 1000 ms. Not 100, because vim-commentary breaks
set ttimeout           " Enable latency descrease for typing `<Esc>`
set ttimeoutlen=50     " Decrease latency for typing `<Esc>`
set incsearch          " Show search results while typing
set hlsearch           " Highlight search results
set noshowmode         " Don't show things like -- INSERT -- (it is handled in statusline)
set termguicolors      " Enable gui colors
set switchbuf=usetab   " Use already opened buffers when switching
set colorcolumn=+1     " Draw colored column one step to the right of desired maximum width
set virtualedit=block  " Allow going past the end of line in visual block mode
set nostartofline      " Don't position cursor on line start after certain operations
set breakindent        " Indent wrapped lines to match line start
set modeline           " Allow modeline

set completeopt=menuone,noinsert,noselect " Customize completions

set foldenable         " Enable folding by default
set foldmethod=indent  " Set "indent" folding method
set foldlevel=0        " Display all folds
set foldnestmax=3      " Create folds only for some number of nested levels
set foldcolumn=0       " Disable fold column

" Set Vim-specific sequences for RGB colors (needed to work in `st` terminal)
let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"

" Set up persistent undo
let vimDir = '$HOME/.vim'

if stridx(&runtimepath, expand(vimDir)) == -1
  " vimDir is not on runtimepath, add it
  let &runtimepath.=','.vimDir
endif

if has('persistent_undo')
    let myUndoDir = expand(vimDir . '/undodir')
    " Create dirs
    call system('mkdir ' . vimDir)
    call system('mkdir ' . myUndoDir)
    let &undodir = myUndoDir
    set undofile " Enable persistent undo
endif

" Enable filetype plugins and indentation
filetype plugin indent on

" Don't auto-wrap comments and don't insert comment leader after hitting 'o'
autocmd FileType * setlocal formatoptions-=c formatoptions-=o
" But insert comment leader after hitting <CR>
autocmd FileType * setlocal formatoptions+=r

"" Automatically save the session (but not load on enter) when leaving Vim
"" Not using default file name '~/Session.vim' because it conflicts with Neovim
autocmd! VimLeave * mksession! $HOME/VimSession.vim

" Spelling
"" Define spelling dictionaries
set spelllang=en,ru
"" Add spellcheck options for autocomplete
set complete+=kspell
" }}}

" Mappings {{{
" Russian keyboard mappings
set langmap=ё№йцукенгшщзхъфывапролджэячсмитьбюЁЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ;`#qwertyuiop[]asdfghjkl\\;'zxcvbnm\\,.~QWERTYUIOP{}ASDFGHJKL:\\"ZXCVBNM<>

nmap Ж :
" yank
nmap Н Y
nmap з p
nmap ф a
nmap щ o
nmap г u
nmap З P

" Disable `s` shortcut (as it can be replaced with `cl`) for safer usage of
" 'sandwich.vim'
nmap s <Nop>
xmap s <Nop>

" Copy/paste with system clipboard
nnoremap gy "+y
xnoremap gy "+y
nnoremap gp "+p
xnoremap gp "+P

" Write current buffer with sudo privileges
cmap w!! w !sudo tee %

" Create a variable that stores an '<Alt>' key modifier. In my current setup
" this is a single symbol denoted as '^['. It is needed to make mappings with
" 'Alt' key as this is exactly what terminal actually sends instead of 'Alt'.
" Like, for example, mapping '<M-h>' (or '<A-h>') is identical to mapping
" `s:alt . 'h'`.
" NOTE: this makes this file not copy-pasteable from internet as next line
" appears as `let s:alt = ''`. Paste appropriate symbol by typing `<C-v><A-h>`
" and deleting 'h' letter.
let s:alt = ''
if s:alt == ''
  echom "To use mappings with Alt, define `s:alt` in '.vimrc'."
endif

if s:alt != ''
  " Move with <Alt-hjkl> in non-normal mode
  exe 'inoremap ' . s:alt . 'h <Left>'
  exe 'inoremap ' . s:alt . 'j <Down>'
  exe 'inoremap ' . s:alt . 'k <Up>'
  exe 'inoremap ' . s:alt . 'l <Right>'

  exe 'tnoremap ' . s:alt . 'h <Left>'
  exe 'tnoremap ' . s:alt . 'j <Down>'
  exe 'tnoremap ' . s:alt . 'k <Up>'
  exe 'tnoremap ' . s:alt . 'l <Right>'

  exe 'cnoremap ' . s:alt . 'h <Left>'
  exe 'cnoremap ' . s:alt . 'l <Right>'

  " Use alt + hjkl to resize windows
  exe 'nnoremap <silent> ' . s:alt . 'j :resize -2<CR>'
  exe 'nnoremap <silent> ' . s:alt . 'k :resize +2<CR>'
  exe 'nnoremap <silent> ' . s:alt . 'h :vertical resize -2<CR>'
  exe 'nnoremap <silent> ' . s:alt . 'l :vertical resize +2<CR>'
endif

" Move between buffers
nnoremap <silent> ]b :bnext<CR>
nnoremap <silent> [b :bprevious<CR>

" Better window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
"" Go to previous window (very useful with "pop-up" 'coc.nvim' documentation)
nnoremap <C-p> <C-w>p
"" When in terminal, use this as escape to normal mode (might be handy when
"" followed by <C-l> to, almost always, return to terminal)
tnoremap <C-h> <C-\><C-N><C-w>h

" Alternate way to save
"" For this to work add `stty -ixon -ixoff` to shells dotfile ('.bashrc' or
"" '.zshrc')
nnoremap <C-s> :w<CR>
inoremap <C-s> <Esc>:w<CR>

" Move inside completion list with <TAB>
inoremap <silent> <expr> <TAB> pumvisible() ? "\<C-n>" : "\<TAB>"
inoremap <silent> <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

" Extra jumps between folds
"" Jump to the beginning of previous fold
nnoremap zK zk[z
"" Jump to the end of next fold
nnoremap zJ zj]z

" Reselect previously changed, put or yanked text
nnoremap gV `[v`]

" Make `q:` do nothing instead of opening command-line-window, because it is
" often hit by accident
" Use c_CTRL-F or fzf's analogue
nnoremap q: <nop>

" " Packages
" set runtimepath^=~/.vim/bundle/vim-fugitive,~/.vim/bundle/vim-airline,~/.vim/bundle/rainbow_csv,~/.vim/bundle/vimtex
" }}}

" Leader mappings {{{
" These are copies and 'no-plugin modifications' of my Neovim leader mappings
" which don't need plugins
let mapleader = "\<Space>"

" Alternative buffer
nnoremap <silent> <Leader>ba :b#<CR>
" Delete buffer
nnoremap <silent> <Leader>bd :Bclose<CR>
nnoremap <silent> <Leader>bD :Bclose!<CR>
" Switch (find) buffer
nnoremap <silent> <Leader>fb :ls<CR>:buffer 
" Explore file tree
nnoremap <silent> <Leader>et :Explore<CR>
" Toggle 'spell' option
nnoremap <silent> <Leader>os :setlocal spell!<CR>
" Toggle 'wrap' option
nnoremap <silent> <Leader>ow :call ToggleWrap()<CR>

" Open terminal
nnoremap <silent> <Leader>ts :belowright term<CR>
nnoremap <silent> <Leader>tv :vertical term<CR>

" Vim-targeted mappings
"" Load latest session (the one create with autocommand on exit)
nnoremap <silent> <Leader>oS :source ~/VimSession.vim<CR>
" }}}

" General color scheme {{{
" Copy of https://github.com/ayu-theme/ayu-vim/blob/master/colors/ayu.vim
" Initialisation:"{{{2
" ----------------------------------------------------------------------------
hi clear
if exists("syntax_on")
  syntax reset
endif

let s:style = get(g:, 'ayucolor', 'mirage')
"}}}2

" Palettes:"{{{2
" ----------------------------------------------------------------------------

let s:palette = {}

let s:palette.bg        = {'dark': "#0F1419",  'light': "#FAFAFA",  'mirage': "#212733"}

let s:palette.comment   = {'dark': "#5C6773",  'light': "#ABB0B6",  'mirage': "#5C6773"}
let s:palette.markup    = {'dark': "#F07178",  'light': "#F07178",  'mirage': "#F07178"}
let s:palette.constant  = {'dark': "#FFEE99",  'light': "#A37ACC",  'mirage': "#D4BFFF"}
let s:palette.operator  = {'dark': "#E7C547",  'light': "#E7C547",  'mirage': "#80D4FF"}
let s:palette.tag       = {'dark': "#36A3D9",  'light': "#36A3D9",  'mirage': "#5CCFE6"}
let s:palette.regexp    = {'dark': "#95E6CB",  'light': "#4CBF99",  'mirage': "#95E6CB"}
let s:palette.string    = {'dark': "#B8CC52",  'light': "#86B300",  'mirage': "#BBE67E"}
let s:palette.function  = {'dark': "#FFB454",  'light': "#F29718",  'mirage': "#FFD57F"}
let s:palette.special   = {'dark': "#E6B673",  'light': "#E6B673",  'mirage': "#FFC44C"}
let s:palette.keyword   = {'dark': "#FF7733",  'light': "#FF7733",  'mirage': "#FFAE57"}

let s:palette.error     = {'dark': "#FF3333",  'light': "#FF3333",  'mirage': "#FF3333"}
let s:palette.accent    = {'dark': "#F29718",  'light': "#FF6A00",  'mirage': "#FFCC66"}
let s:palette.panel     = {'dark': "#14191F",  'light': "#FFFFFF",  'mirage': "#272D38"}
let s:palette.guide     = {'dark': "#2D3640",  'light': "#D9D8D7",  'mirage': "#3D4751"}
let s:palette.line      = {'dark': "#151A1E",  'light': "#F3F3F3",  'mirage': "#242B38"}
let s:palette.selection = {'dark': "#253340",  'light': "#F0EEE4",  'mirage': "#343F4C"}
let s:palette.fg        = {'dark': "#E6E1CF",  'light': "#5C6773",  'mirage': "#D9D7CE"}
let s:palette.fg_idle   = {'dark': "#3E4B59",  'light': "#828C99",  'mirage': "#607080"}

"}}}2

" Highlighting Primitives:"{{{2
" ----------------------------------------------------------------------------

function! s:build_prim(hi_elem, field)
  let l:vname = "s:" . a:hi_elem . "_" . a:field " s:bg_gray
  let l:gui_assign = "gui".a:hi_elem."=".s:palette[a:field][s:style] " guibg=...
  exe "let " . l:vname . " = ' " . l:gui_assign . "'"
endfunction

let s:bg_none = ' guibg=NONE ctermbg=NONE'
let s:fg_none = ' guifg=NONE ctermfg=NONE'
for [key_name, d_value] in items(s:palette)
  call s:build_prim('bg', key_name)
  call s:build_prim('fg', key_name)
endfor
" }}}2

" Formatting Options:"{{{2
" ----------------------------------------------------------------------------
let s:none   = "NONE"
let s:t_none = "NONE"
let s:n      = "NONE"
let s:c      = ",undercurl"
let s:r      = ",reverse"
let s:s      = ",standout"
let s:b      = ",bold"
let s:u      = ",underline"
let s:i      = ",italic"

exe "let s:fmt_none = ' gui=NONE".          " cterm=NONE".          " term=NONE"        ."'"
exe "let s:fmt_bold = ' gui=NONE".s:b.      " cterm=NONE".s:b.      " term=NONE".s:b    ."'"
exe "let s:fmt_bldi = ' gui=NONE".s:b.      " cterm=NONE".s:b.      " term=NONE".s:b    ."'"
exe "let s:fmt_undr = ' gui=NONE".s:u.      " cterm=NONE".s:u.      " term=NONE".s:u    ."'"
exe "let s:fmt_undb = ' gui=NONE".s:u.s:b.  " cterm=NONE".s:u.s:b.  " term=NONE".s:u.s:b."'"
exe "let s:fmt_undi = ' gui=NONE".s:u.      " cterm=NONE".s:u.      " term=NONE".s:u    ."'"
exe "let s:fmt_curl = ' gui=NONE".s:c.      " cterm=NONE".s:c.      " term=NONE".s:c    ."'"
exe "let s:fmt_ital = ' gui=NONE".s:i.      " cterm=NONE".s:i.      " term=NONE".s:i    ."'"
exe "let s:fmt_stnd = ' gui=NONE".s:s.      " cterm=NONE".s:s.      " term=NONE".s:s    ."'"
exe "let s:fmt_revr = ' gui=NONE".s:r.      " cterm=NONE".s:r.      " term=NONE".s:r    ."'"
exe "let s:fmt_revb = ' gui=NONE".s:r.s:b.  " cterm=NONE".s:r.s:b.  " term=NONE".s:r.s:b."'"
"}}}2

" Vim Highlighting: (see :help highlight-groups)"{{{2
" ----------------------------------------------------------------------------
exe "hi! Normal"        .s:fg_fg          .s:bg_bg          .s:fmt_none
exe "hi! ColorColumn"   .s:fg_none        .s:bg_line        .s:fmt_none
" Conceal, Cursor, CursorIM
exe "hi! CursorColumn"  .s:fg_none        .s:bg_line        .s:fmt_none
exe "hi! CursorLine"    .s:fg_none        .s:bg_line        .s:fmt_none
exe "hi! CursorLineNr"  .s:fg_accent      .s:bg_line        .s:fmt_none
exe "hi! LineNr"        .s:fg_guide       .s:bg_none        .s:fmt_none

exe "hi! Directory"     .s:fg_fg_idle     .s:bg_none        .s:fmt_none
exe "hi! DiffAdd"       .s:fg_string      .s:bg_panel       .s:fmt_none
exe "hi! DiffChange"    .s:fg_tag         .s:bg_panel       .s:fmt_none
exe "hi! DiffText"      .s:fg_fg          .s:bg_panel       .s:fmt_none
exe "hi! ErrorMsg"      .s:fg_fg          .s:bg_error       .s:fmt_stnd
exe "hi! VertSplit"     .s:fg_bg          .s:bg_none        .s:fmt_none
exe "hi! Folded"        .s:fg_fg_idle     .s:bg_panel       .s:fmt_none
exe "hi! FoldColumn"    .s:fg_none        .s:bg_panel       .s:fmt_none
exe "hi! SignColumn"    .s:fg_none        .s:bg_panel       .s:fmt_none
"   Incsearch"

exe "hi! MatchParen"    .s:fg_fg          .s:bg_bg          .s:fmt_undr
exe "hi! ModeMsg"       .s:fg_string      .s:bg_none        .s:fmt_none
exe "hi! MoreMsg"       .s:fg_string      .s:bg_none        .s:fmt_none
exe "hi! NonText"       .s:fg_guide       .s:bg_none        .s:fmt_none
exe "hi! Pmenu"         .s:fg_fg          .s:bg_selection   .s:fmt_none
exe "hi! PmenuSel"      .s:fg_fg          .s:bg_selection   .s:fmt_revr
"   PmenuSbar"
"   PmenuThumb"
exe "hi! Question"      .s:fg_string      .s:bg_none        .s:fmt_none
exe "hi! Search"        .s:fg_bg          .s:bg_constant    .s:fmt_none
exe "hi! SpecialKey"    .s:fg_selection   .s:bg_none        .s:fmt_none
exe "hi! SpellCap"      .s:fg_tag         .s:bg_none        .s:fmt_undr
exe "hi! SpellLocal"    .s:fg_keyword     .s:bg_none        .s:fmt_undr
exe "hi! SpellBad"      .s:fg_error       .s:bg_none        .s:fmt_undr
exe "hi! SpellRare"     .s:fg_regexp      .s:bg_none        .s:fmt_undr
exe "hi! StatusLine"    .s:fg_fg          .s:bg_panel       .s:fmt_none
exe "hi! StatusLineNC"  .s:fg_fg_idle     .s:bg_panel       .s:fmt_none
exe "hi! WildMenu"      .s:fg_bg          .s:bg_markup      .s:fmt_none
exe "hi! TabLine"       .s:fg_fg          .s:bg_panel       .s:fmt_revr
"   TabLineFill"
"   TabLineSel"
exe "hi! Title"         .s:fg_keyword     .s:bg_none        .s:fmt_none
exe "hi! Visual"        .s:fg_none        .s:bg_selection   .s:fmt_none
"   VisualNos"
exe "hi! WarningMsg"    .s:fg_error       .s:bg_none        .s:fmt_none

" TODO LongLineWarning to use variables instead of hardcoding
hi LongLineWarning  guifg=NONE        guibg=#371F1C     gui=underline ctermfg=NONE        ctermbg=NONE        cterm=underline
"   WildMenu"

"}}}2

" Generic Syntax Highlighting: (see :help group-name)"{{{2
" ----------------------------------------------------------------------------
exe "hi! Comment"         .s:fg_comment   .s:bg_none        .s:fmt_none

exe "hi! Constant"        .s:fg_constant  .s:bg_none        .s:fmt_none
exe "hi! String"          .s:fg_string    .s:bg_none        .s:fmt_none
"   Character"
"   Number"
"   Boolean"
"   Float"

exe "hi! Identifier"      .s:fg_tag       .s:bg_none        .s:fmt_none
exe "hi! Function"        .s:fg_function  .s:bg_none        .s:fmt_none

exe "hi! Statement"       .s:fg_keyword   .s:bg_none        .s:fmt_none
"   Conditional"
"   Repeat"
"   Label"
exe "hi! Operator"        .s:fg_operator  .s:bg_none        .s:fmt_none
"   Keyword"
"   Exception"

exe "hi! PreProc"         .s:fg_special   .s:bg_none        .s:fmt_none
"   Include"
"   Define"
"   Macro"
"   PreCondit"

exe "hi! Type"            .s:fg_tag       .s:bg_none        .s:fmt_none
"   StorageClass"
exe "hi! Structure"       .s:fg_special   .s:bg_none        .s:fmt_none
"   Typedef"

exe "hi! Special"         .s:fg_special   .s:bg_none        .s:fmt_none
"   SpecialChar"
"   Tag"
"   Delimiter"
"   SpecialComment"
"   Debug"
"
exe "hi! Underlined"      .s:fg_tag       .s:bg_none        .s:fmt_undr

exe "hi! Ignore"          .s:fg_none      .s:bg_none        .s:fmt_none

exe "hi! Error"           .s:fg_fg        .s:bg_error       .s:fmt_none

exe "hi! Todo"            .s:fg_markup    .s:bg_none        .s:fmt_none

" Quickfix window highlighting
exe "hi! qfLineNr"        .s:fg_keyword   .s:bg_none        .s:fmt_none
"   qfFileName"
"   qfLineNr"
"   qfError"

exe "hi! Conceal"         .s:fg_guide     .s:bg_none        .s:fmt_none
exe "hi! CursorLineConceal" .s:fg_guide   .s:bg_line        .s:fmt_none


" Terminal
" ---------
if has("nvim")
  let g:terminal_color_0 =  s:palette.bg[s:style]
  let g:terminal_color_1 =  s:palette.markup[s:style]
  let g:terminal_color_2 =  s:palette.string[s:style]
  let g:terminal_color_3 =  s:palette.accent[s:style]
  let g:terminal_color_4 =  s:palette.tag[s:style]
  let g:terminal_color_5 =  s:palette.constant[s:style]
  let g:terminal_color_6 =  s:palette.regexp[s:style]
  let g:terminal_color_7 =  "#FFFFFF"
  let g:terminal_color_8 =  s:palette.fg_idle[s:style]
  let g:terminal_color_9 =  s:palette.error[s:style]
  let g:terminal_color_10 = s:palette.string[s:style]
  let g:terminal_color_11 = s:palette.accent[s:style]
  let g:terminal_color_12 = s:palette.tag[s:style]
  let g:terminal_color_13 = s:palette.constant[s:style]
  let g:terminal_color_14 = s:palette.regexp[s:style]
  let g:terminal_color_15 = s:palette.comment[s:style]
  let g:terminal_color_background = g:terminal_color_0
  let g:terminal_color_foreground = s:palette.fg[s:style]
else
  let g:terminal_ansi_colors =  [s:palette.bg[s:style],      s:palette.markup[s:style]]
  let g:terminal_ansi_colors += [s:palette.string[s:style],  s:palette.accent[s:style]]
  let g:terminal_ansi_colors += [s:palette.tag[s:style],     s:palette.constant[s:style]]
  let g:terminal_ansi_colors += [s:palette.regexp[s:style],  "#FFFFFF"]
  let g:terminal_ansi_colors += [s:palette.fg_idle[s:style], s:palette.error[s:style]]
  let g:terminal_ansi_colors += [s:palette.string[s:style],  s:palette.accent[s:style]]
  let g:terminal_ansi_colors += [s:palette.tag[s:style],     s:palette.constant[s:style]]
  let g:terminal_ansi_colors += [s:palette.regexp[s:style],  s:palette.comment[s:style]]
endif


" NerdTree
" ---------
exe "hi! NERDTreeOpenable"          .s:fg_fg_idle     .s:bg_none        .s:fmt_none
exe "hi! NERDTreeClosable"          .s:fg_accent      .s:bg_none        .s:fmt_none
" exe "hi! NERDTreeBookmarksHeader"   .s:fg_pink        .s:bg_none        .s:fmt_none
" exe "hi! NERDTreeBookmarksLeader"   .s:fg_bg          .s:bg_none        .s:fmt_none
" exe "hi! NERDTreeBookmarkName"      .s:fg_keyword     .s:bg_none        .s:fmt_none
" exe "hi! NERDTreeCWD"               .s:fg_pink        .s:bg_none        .s:fmt_none
exe "hi! NERDTreeUp"                .s:fg_fg_idle    .s:bg_none        .s:fmt_none
exe "hi! NERDTreeDir"               .s:fg_function   .s:bg_none        .s:fmt_none
exe "hi! NERDTreeFile"              .s:fg_none       .s:bg_none        .s:fmt_none
exe "hi! NERDTreeDirSlash"          .s:fg_accent     .s:bg_none        .s:fmt_none


" GitGutter
" ---------
exe "hi! GitGutterAdd"          .s:fg_string     .s:bg_none        .s:fmt_none
exe "hi! GitGutterChange"       .s:fg_tag        .s:bg_none        .s:fmt_none
exe "hi! GitGutterDelete"       .s:fg_markup     .s:bg_none        .s:fmt_none
exe "hi! GitGutterChangeDelete" .s:fg_function   .s:bg_none        .s:fmt_none

"}}}2

" Diff Syntax Highlighting:"{{{2
" ----------------------------------------------------------------------------
" Diff
"   diffOldFile
"   diffNewFile
"   diffFile
"   diffOnly
"   diffIdentical
"   diffDiffer
"   diffBDiffer
"   diffIsA
"   diffNoEOL
"   diffCommon
hi! link diffRemoved Constant
"   diffChanged
hi! link diffAdded String
"   diffLine
"   diffSubname
"   diffComment

"}}}2

" This is needed for some reason: {{{2

" let &background = s:style

" }}}2
" }}}

" Custom colors {{{
let python_highlight_all = 1

syntax on

" Highlight punctuation
"" General Vim buffers
"" Sources: https://stackoverflow.com/a/18943408 and https://superuser.com/a/205058
function! s:hi_base_syntax()
  " Highlight parenthesis
  syntax match parens /[(){}[\]]/
  hi parens ctermfg=208 guifg=#FF8700
  " Highlight dots, commas, colons and semicolons with contrast color
  syntax match punc /[.,:;=]/
  if &background == "light"
    hi punc ctermfg=Black guifg=#000000 cterm=bold gui=bold
  else
    hi punc ctermfg=White guifg=#FFFFFF cterm=bold gui=bold
  endif
endfunction

autocmd VimEnter,BufWinEnter * call <SID>hi_base_syntax()

" " Use terminal's background (needed if transparent background is used)
" hi! Normal ctermbg=NONE guibg=NONE
" hi! NonText ctermbg=NONE guibg=NONE guifg=NONE ctermfg=NONE

" Use custom colors for highlighting spelling information
hi SpellBad     guisp=#CC0000   gui=undercurl
hi SpellCap     guisp=#7070F0   gui=undercurl
hi SpellLocal   guisp=#70F0F0   gui=undercurl
hi SpellRare    guisp=#FFFFFF   gui=undercurl

" Use custom color for highlighting 'maximum width' column
highlight ColorColumn ctermbg=grey guibg=#555555

" Btline (custom tabline) colors (from Gruvbox palette)
hi BtlineCurrent         guibg=#7C6F64 guifg=#EBDBB2 gui=bold
hi BtlineActive          guibg=#3C3836 guifg=#EBDBB2 gui=bold
hi link BtlineHidden StatusLineNC

hi BtlineModifiedCurrent guibg=#458588 guifg=#EBDBB2 gui=bold
hi BtlineModifiedActive  guibg=#076678 guifg=#EBDBB2 gui=bold
hi BtlineModifiedHidden  guibg=#076678 guifg=#BDAE93

hi BtlineFill NONE
" }}}

" Custom functions {{{
" Wrap-unwrap text
function ToggleWrap()
  if &wrap
    echo "Wrap OFF"
    setlocal nowrap
    silent! nunmap <buffer> <Up>
    silent! nunmap <buffer> <Down>
    silent! nunmap <buffer> <Home>
    silent! nunmap <buffer> <End>
    silent! iunmap <buffer> <Up>
    silent! iunmap <buffer> <Down>
    silent! iunmap <buffer> <Home>
    silent! iunmap <buffer> <End>
  else
    echo "Wrap ON"
    setlocal wrap linebreak nolist
    setlocal display+=lastline
    noremap  <buffer> <silent> <Up>   gk
    noremap  <buffer> <silent> <Down> gj
    noremap  <buffer> <silent> <Home> g0
    noremap  <buffer> <silent> <End>  g$
    inoremap <buffer> <silent> <Up>   <C-o>gk<CR>
    inoremap <buffer> <silent> <Down> <C-o>gj<CR>
    inoremap <buffer> <silent> <Home> <C-o>g0<CR>
    inoremap <buffer> <silent> <End>  <C-o>g$<CR>
  endif
endfunction
" }}}

" Custom statusline {{{
" Helper functions
function s:IsTruncated(width)
  return winwidth(0) < a:width
endfunction

function IsTruncated(width)
  return winwidth(0) < a:width
endfunction

function s:IsntNormalBuffer()
  " For more information see ':h buftype'
  return &buftype != ''
endfunction

function s:CombineSections(sections)
  let l:res = ''
  for s in a:sections
    if type(s) == v:t_string
      let l:res = l:res . s
    elseif s['string'] != ''
      if s['hl'] != v:null
        let l:res = l:res . printf('%s %s ', s['hl'], s['string'])
      else
        let l:res = l:res . printf('%s ', s['string'])
      endif
    endif
  endfor

  return l:res
endfunction

" MiniStatusline behavior
augroup MiniStatusline
  au!
  au WinEnter,BufEnter * setlocal statusline=%!MiniStatuslineActive()
  au WinLeave,BufLeave * setlocal statusline=%!MiniStatuslineInactive()
augroup END

" MiniStatusline colors (from Gruvbox bright palette)
hi MiniStatuslineModeNormal  guibg=#BDAE93 guifg=#1D2021 gui=bold ctermbg=7 ctermfg=0
hi MiniStatuslineModeInsert  guibg=#83A598 guifg=#1D2021 gui=bold ctermbg=4 ctermfg=0
hi MiniStatuslineModeVisual  guibg=#B8BB26 guifg=#1D2021 gui=bold ctermbg=2 ctermfg=0
hi MiniStatuslineModeReplace guibg=#FB4934 guifg=#1D2021 gui=bold ctermbg=1 ctermfg=0
hi MiniStatuslineModeCommand guibg=#FABD2F guifg=#1D2021 gui=bold ctermbg=3 ctermfg=0
hi MiniStatuslineModeOther   guibg=#8EC07C guifg=#1D2021 gui=bold ctermbg=6 ctermfg=0

hi link MiniStatuslineInactive StatusLineNC
hi link MiniStatuslineDevinfo  StatusLine
hi link MiniStatuslineFilename StatusLineNC
hi link MiniStatuslineFileinfo StatusLine

" High-level definition of statusline content
function MiniStatuslineActive()
  let l:mode_info = s:statusline_modes[mode()]

  let l:mode = s:SectionMode(l:mode_info, 120)
  let l:spell = s:SectionSpell(120)
  let l:wrap = s:SectionWrap()
  let l:git = s:SectionGit(75)
  " Diagnostics section is missing as this is a script for Vim
  let l:filename = s:SectionFilename(140)
  let l:fileinfo = s:SectionFileinfo(120)
  let l:location = s:SectionLocation()

  return s:CombineSections([
    \ {'string': l:mode,     'hl': l:mode_info['hl']},
    \ {'string': l:spell,    'hl': v:null},
    \ {'string': l:wrap,     'hl': v:null},
    \ {'string': l:git,      'hl': '%#MiniStatuslineDevinfo#'},
    \ '%<',
    \ {'string': l:filename, 'hl': '%#MiniStatuslineFilename#'},
    \ '%=',
    \ {'string': l:fileinfo, 'hl': '%#MiniStatuslineFileinfo#'},
    \ {'string': l:location, 'hl': l:mode_info['hl']},
    \ ])
endfunction

function MiniStatuslineInactive()
  return '%#MiniStatuslineInactive#%F%='
endfunction

" Mode
let s:statusline_modes = {
  \ 'n'     : {'long': 'Normal'  , 'short': 'N'  , 'hl': '%#MiniStatuslineModeNormal#'},
  \ 'v'     : {'long': 'Visual'  , 'short': 'V'  , 'hl': '%#MiniStatuslineModeVisual#'},
  \ 'V'     : {'long': 'V-Line'  , 'short': 'V-L', 'hl': '%#MiniStatuslineModeVisual#'},
  \ "\<C-V>": {'long': 'V-Block' , 'short': 'V-B', 'hl': '%#MiniStatuslineModeVisual#'},
  \ 's'     : {'long': 'Select'  , 'short': 'S'  , 'hl': '%#MiniStatuslineModeVisual#'},
  \ 'S'     : {'long': 'S-Line'  , 'short': 'S-L', 'hl': '%#MiniStatuslineModeVisual#'},
  \ "\<C-S>": {'long': 'S-Block' , 'short': 'S-B', 'hl': '%#MiniStatuslineModeVisual#'},
  \ 'i'     : {'long': 'Insert'  , 'short': 'I'  , 'hl': '%#MiniStatuslineModeInsert#'},
  \ 'R'     : {'long': 'Replace' , 'short': 'R'  , 'hl': '%#MiniStatuslineModeReplace#'},
  \ 'c'     : {'long': 'Command' , 'short': 'C'  , 'hl': '%#MiniStatuslineModeCommand#'},
  \ 'r'     : {'long': 'Prompt'  , 'short': 'P'  , 'hl': '%#MiniStatuslineModeOther#'},
  \ '!'     : {'long': 'Shell'   , 'short': 'Sh' , 'hl': '%#MiniStatuslineModeOther#'},
  \ 't'     : {'long': 'Terminal', 'short': 'T'  , 'hl': '%#MiniStatuslineModeOther#'},
  \ }

function s:SectionMode(mode_info, trunc_width)
  return s:IsTruncated(a:trunc_width) ?
    \ a:mode_info['short'] :
    \ a:mode_info['long']
endfunction

" Spell
function s:SectionSpell(trunc_width)
  if &spell == 0 | return '' | endif

  if s:IsTruncated(a:trunc_width) | return 'SPELL' | endif

  return printf('SPELL(%s)', &spelllang)
endfunction

" Wrap
function s:SectionWrap()
  if &wrap == 0 | return '' | endif

  return 'WRAP'
endfunction

" Git
function s:GetGitBranch()
  if exists('*FugitiveHead') == 0 | return '<no fugitive>' | endif

  " Use commit hash truncated to 7 characters in case of detached HEAD
  let l:branch = FugitiveHead(7)
  if l:branch == '' | return '<no branch>' | endif
  return l:branch
endfunction

function s:GetGitSigns()
  if exists('*GitGutterGetHunkSummary') == 0 | return '' | endif

  let l:signs = GitGutterGetHunkSummary()
  let l:res = []
  if l:signs[0] > 0 | let l:res = l:res + ['+' . l:signs[0]] | endif
  if l:signs[1] > 0 | let l:res = l:res + ['~' . l:signs[1]] | endif
  if l:signs[2] > 0 | let l:res = l:res + ['-' . l:signs[2]] | endif

  if len(l:res) == 0 | return '' | endif
  return join(l:res, ' ')
endfunction

function s:SectionGit(trunc_width)
  if s:IsntNormalBuffer() | return '' | endif

  " NOTE: this information doesn't change on every entry but these functions
  " are called on every statusline update (which is **very** often). Currently
  " this doesn't introduce noticeable overhead because of a smart way used
  " functions of 'vim-gitgutter' and 'vim-fugitive' are written (seems like
  " they just take value of certain buffer variable, which is quick).
  " If ever encounter overhead, write 'update_val()' wrapper which updates
  " module's certain variable and call it only on certain event. Example:
  " ```lua
  " MiniStatusline.git_signs_str = ''
  " MiniStatusline.update_git_signs = function(self)
  "   self.git_signs_str = get_git_signs()
  " end
  " vim.api.nvim_exec([[
  "   au BufEnter,User GitGutter lua MiniStatusline:update_git_signs()
  " ]], false)
  " ```
  let l:res = s:GetGitBranch()

  if s:IsTruncated(a:trunc_width) == 0
    let l:signs = s:GetGitSigns()
    if l:signs != '' | let l:res = printf('%s %s', l:res, l:signs) | endif
  endif

  if l:res == '' | let l:res = '-' | endif
  return printf(' %s', l:res)
endfunction

" File name
function s:SectionFilename(trunc_width)
  " In terminal always use plain name
  if &buftype == 'terminal'
    return '%t'
  " File name with 'truncate', 'modified', 'readonly' flags
  elseif s:IsTruncated(a:trunc_width)
    " Use relative path if truncated
    return '%f%m%r'
  else
    " Use fullpath if not truncated
    return '%F%m%r'
  endif
endfunction

" File information
function s:GetFilesize()
  let l:size = getfsize(getreg('%'))
  if l:size < 1024
    let l:data = l:size . 'B'
  elseif l:size < 1048576
    let l:data = printf('%.2fKiB', l:size / 1024.0)
  else
    let l:data = printf('%.2fMiB', l:size / 1048576.0)
  end

  return l:data
endfunction

function s:GetFiletypeIcon()
  if exists('*WebDevIconsGetFileTypeSymbol') != 0
    return WebDevIconsGetFileTypeSymbol()
  endif

  return ''
endfunction

function s:SectionFileinfo(trunc_width)
  let l:filetype = &filetype

  " Don't show anything if can't detect file type or not inside a 'normal
  " buffer'
  if ((l:filetype == '') || s:IsntNormalBuffer()) | return '' | endif

  " Add filetype icon
  let l:icon = s:GetFiletypeIcon()
  if l:icon != '' | let l:filetype = l:icon . ' ' . l:filetype | endif

  " Construct output string if truncated
  if s:IsTruncated(a:trunc_width) | return l:filetype | endif

  " Construct output string with extra file info
  let l:encoding = &fileencoding
  if l:encoding == '' | let l:encoding = &encoding | endif
  let l:format = &fileformat
  let l:size = s:GetFilesize()

  return printf('%s %s[%s] %s', l:filetype, l:encoding, l:format, l:size)
endfunction

" Location inside buffer
function s:SectionLocation()
  " Use virtual column number to allow update when paste last column
  return '%l|%L│%2v|%-2{col("$") - 1}'
endfunction
" }}}

" Custom tabline {{{
" Vimscript code for custom minimal tabline (called 'mini-tabline'). This is
" meant to be a standalone file which when sourced in 'init.*' file provides a
" working minimal tabline.
"
" General idea: show all listed buffers in case of one tab, fall back for
" deafult otherwise. NOTE: this is superseded by a more faster Lua
" implementation ('lua/mini-tabline.lua'). Kept here for historical reasons.
"
" This code is a truncated version of 'ap/vim-buftabline' with the following
" options:
" - let g:buftabline_numbers    = 0
" - let g:buftabline_indicators = 0
" - let g:buftabline_separators = 0
" - let g:buftabline_show       = 2
" - let g:buftabline_plug_max   = <removed manually>
"
" NOTE that I also removed handling of certain isoteric edge cases which I
" don't fully understand but in truncated code they seem to be redundant:
" - Having extra 'centerbuf' variable which is said to 'prevent tabline
"   jumping around when non-user buffer current (e.g. help)'.
" - Having `set guioptions+=e` and `set guioptions-=e` in update function.

function! UserBuffers() " help buffers are always unlisted, but quickfix buffers are not
  return filter(range(1,bufnr('$')),'buflisted(v:val) && "quickfix" !=? getbufvar(v:val, "&buftype")')
endfunction

function! s:SwitchBuffer(bufnum, clicks, button, mod)
  execute 'buffer' a:bufnum
endfunction

function s:SID()
  return matchstr(expand('<sfile>'), '<SNR>\d\+_')
endfunction

let s:dirsep = fnamemodify(getcwd(),':p')[-1:]
let s:centerbuf = winbufnr(0)
let s:tablineat = has('tablineat')
let s:sid = s:SID() | delfunction s:SID

" Track all scratch and unnamed buffers for disambiguation. These dictionaries
" are designed to store 'sequential' buffer identifier. This approach allows
" to have the following behavior:
" - Create three scratch (or unnamed) buffers.
" - Delete second one.
" - Tab label for third one remains the same.
let s:unnamed_tabs = {}

function! MiniTablineRender()
  " Pick up data on all the buffers
  let tabs = []
  let path_tabs = []
  let tabs_per_tail = {}
  let currentbuf = winbufnr(0)
  for bufnum in UserBuffers()
    let tab = { 'num': bufnum }

    " Functional label for possible clicks (see ':h statusline')
    let tab.func_label = '%' . bufnum . '@' . s:sid . 'SwitchBuffer@'

    " Determine highlight group
    let hl_type =
    \ currentbuf == bufnum
    \ ? 'Current'
    \ : bufwinnr(bufnum) > 0 ? 'Active' : 'Hidden'
    if getbufvar(bufnum, '&modified')
      let hl_type = 'Modified' . hl_type
    endif
    let tab.hl = '%#MiniTabline' . hl_type . '#'

    if currentbuf == bufnum | let s:centerbuf = bufnum | endif

    let bufpath = bufname(bufnum)
    if strlen(bufpath)
      " Process buffers which have path
      let tab.path = fnamemodify(bufpath, ':p:~:.')
      let tab.sep = strridx(tab.path, s:dirsep, strlen(tab.path) - 2) " Keep trailing dirsep
      let tab.label = tab.path[tab.sep + 1:]
      let tabs_per_tail[tab.label] = get(tabs_per_tail, tab.label, 0) + 1
      let path_tabs += [tab]
    elseif -1 < index(['nofile','acwrite'], getbufvar(bufnum, '&buftype'))
      " Process scratch buffer
      if has_key(s:unnamed_tabs, bufnum) == 0
        let s:unnamed_tabs[bufnum] = len(s:unnamed_tabs) + 1
      endif
      let tab_id = s:unnamed_tabs[bufnum]
      "" Only show 'sequential' id starting from second tab
      if tab_id == 1
        let tab.label = '!'
      else
        let tab.label = '!(' . tab_id . ')'
      endif
    else
      " Process unnamed buffer
      if has_key(s:unnamed_tabs, bufnum) == 0
        let s:unnamed_tabs[bufnum] = len(s:unnamed_tabs) + 1
      endif
      let tab_id = s:unnamed_tabs[bufnum]
      "" Only show 'sequential' id starting from second tab
      if tab_id == 1
        let tab.label = '*'
      else
        let tab.label = '*(' . tab_id . ')'
      endif
    endif

    let tabs += [tab]
  endfor

  " Disambiguate same-basename files by adding trailing path segments
  " Algorithm: iteratively add parent directories to duplicated buffer labels
  " until there are no duplicates
  while len(filter(tabs_per_tail, 'v:val > 1'))
    let [ambiguous, tabs_per_tail] = [tabs_per_tail, {}]
    for tab in path_tabs
      " Add one parent directory if there is any and if tab's label is
      " duplicated
      if -1 < tab.sep && has_key(ambiguous, tab.label)
        let tab.sep = strridx(tab.path, s:dirsep, tab.sep - 1)
        let tab.label = tab.path[tab.sep + 1:]
      endif
      let tabs_per_tail[tab.label] = get(tabs_per_tail, tab.label, 0) + 1
    endfor
  endwhile

  " Now keep the current buffer center-screen as much as possible:

  " 1. Setup
  let lft = { 'lasttab':  0, 'cut':  '.', 'indicator': '<', 'width': 0, 'half': &columns / 2 }
  let rgt = { 'lasttab': -1, 'cut': '.$', 'indicator': '>', 'width': 0, 'half': &columns - lft.half }

  " 2. Sum the string lengths for the left and right halves
  let currentside = lft
  for tab in tabs
    let tab.width = 1 + strwidth(tab.label) + 1
    let tab.label = ' ' . substitute(strtrans(tab.label), '%', '%%', 'g') . ' '
    if s:centerbuf == tab.num
      let halfwidth = tab.width / 2
      let lft.width += halfwidth
      let rgt.width += tab.width - halfwidth
      let currentside = rgt
      continue
    endif
    let currentside.width += tab.width
  endfor
  if currentside is lft " Centered buffer not seen?
    " Then blame any overflow on the right side, to protect the left
    let [lft.width, rgt.width] = [0, lft.width]
  endif

  " 3. Toss away tabs and pieces until all fits:
  if ( lft.width + rgt.width ) > &columns
    let oversized
    \ = lft.width < lft.half ? [ [ rgt, &columns - lft.width ] ]
    \ : rgt.width < rgt.half ? [ [ lft, &columns - rgt.width ] ]
    \ :                        [ [ lft, lft.half ], [ rgt, rgt.half ] ]
    for [side, budget] in oversized
      let delta = side.width - budget
      " Toss entire tabs to close the distance
      while delta >= tabs[side.lasttab].width
        let delta -= remove(tabs, side.lasttab).width
      endwhile
      " Then snip at the last one to make it fit
      let endtab = tabs[side.lasttab]
      while delta > ( endtab.width - strwidth(strtrans(endtab.label)) )
        let endtab.label = substitute(endtab.label, side.cut, '', '')
      endwhile
      let endtab.label = substitute(endtab.label, side.cut, side.indicator, '')
    endfor
  endif

  " If available add possibility of clicking on buffer tabs
  if s:tablineat
    let tab_strings = map(tabs, 'v:val.hl . v:val.func_label . v:val.label')
  else
    let tab_strings = map(tabs, 'v:val.hl . v:val.label')
  endif

  return join(tab_strings, '') . '%#MiniTablineFill#'
endfunction

function! MiniTablineUpdate()
  if tabpagenr('$') > 1
    set tabline=
  else
    set tabline=%!MiniTablineRender()
  endif
endfunction

" Ensure tabline is displayed properly
augroup MiniTabline
  autocmd!
  autocmd VimEnter   * call MiniTablineUpdate()
  autocmd TabEnter   * call MiniTablineUpdate()
  autocmd BufAdd     * call MiniTablineUpdate()
  autocmd FileType  qf call MiniTablineUpdate()
  autocmd BufDelete  * call MiniTablineUpdate()
augroup END

" Colors
hi MiniTablineCurrent         guibg=#7C6F64 guifg=#EBDBB2 gui=bold ctermbg=15 ctermfg=0
hi MiniTablineActive          guibg=#3C3836 guifg=#EBDBB2 gui=bold ctermbg=7  ctermfg=0
hi MiniTablineHidden          guifg=#A89984 guibg=#3C3836          ctermbg=8  ctermfg=7

hi MiniTablineModifiedCurrent guibg=#458588 guifg=#EBDBB2 gui=bold ctermbg=14 ctermfg=0
hi MiniTablineModifiedActive  guibg=#076678 guifg=#EBDBB2 gui=bold ctermbg=6  ctermfg=0
hi MiniTablineModifiedHidden  guibg=#076678 guifg=#BDAE93          ctermbg=6  ctermfg=0

hi MiniTablineFill NONE
" }}}

" Custom autopairs {{{
" Custom minimal autopairs plugin rewritten in Vimscript (to be used in Vim,
" not in Neovim). For more information see 'lua/mini-pairs.lua'.

" Helpers
function s:IsInList(val, l)
  return index(a:l, a:val) >= 0
endfunction

function s:GetCursorChars(start, finish)
  if mode() == 'c'
    let l:line = getcmdline()
    let l:col = getcmdpos()
  else
    let l:line = getline('.')
    let l:col = col('.')
  endif

  return l:line[(l:col + a:start - 2):(l:col + a:finish - 2)]
endfunction

" NOTE: use `s:GetArrowKey()` instead of `keys.left` or `keys.right`
let s:keys = {
  \ 'above'    : "\<C-o>O",
  \ 'bs'       : "\<bs>",
  \ 'cr'       : "\<cr>",
  \ 'del'      : "\<del>",
  \ 'keep_undo': "\<C-g>U",
  \ 'left'     : "\<left>",
  \ 'right'    : "\<right>"
\ }

" Using left/right keys in insert mode breaks undo sequence and, more
" importantly, dot-repeat. To avoid this, use 'i_CTRL-G_U' mapping.
function s:GetArrowKey(key)
  if mode() == 'i'
    return s:keys['keep_undo'] . s:keys[a:key]
  else
    return s:keys[a:key]
  endif
endfunction

" Pair actions.
" They are intended to be used inside `_noremap <expr> ...` type of mappings,
" as they return sequence of keys (instead of other possible approach of
" simulating them with `feedkeys()`).
function g:MiniPairsActionOpen(pair)
  return a:pair . s:GetArrowKey('left')
endfunction

"" NOTE: `pair` as argument is used for consistency (when `right` is enough)
function g:MiniPairsActionClose(pair)
  let l:close = a:pair[1:1]
  if s:GetCursorChars(1, 1) == l:close
    return s:GetArrowKey('right')
  else
    return l:close
  endif
endfunction

function g:MiniPairsActionCloseopen(pair)
  if s:GetCursorChars(1, 1) == a:pair[1:1]
    return s:GetArrowKey('right')
  else
    return a:pair . s:GetArrowKey('left')
  endif
endfunction

"" Each argument should be a pair which triggers extra action
function g:MiniPairsActionBS(pair_set)
  let l:res = s:keys['bs']

  if s:IsInList(s:GetCursorChars(0, 1), a:pair_set)
    let l:res = l:res . s:keys['del']
  endif

  return l:res
endfunction

function g:MiniPairsActionCR(pair_set)
  let l:res = s:keys['cr']

  if s:IsInList(s:GetCursorChars(0, 1), a:pair_set)
    let l:res = l:res . s:keys['above']
  endif

  return l:res
endfunction

" Helper for remapping auto-pair from '""' quotes to '\'\''
function g:MiniPairsRemapQuotes()
  " Map '"' to original key (basically, unmap it)
  inoremap <buffer> " "

  " Map '\''
  inoremap <buffer> <expr> ' g:MiniPairsActionCloseopen("''")
endfunction

" Setup mappings
"" Insert mode
inoremap <expr> ( g:MiniPairsActionOpen('()')
inoremap <expr> [ g:MiniPairsActionOpen('[]')
inoremap <expr> { g:MiniPairsActionOpen('{}')

inoremap <expr> ) g:MiniPairsActionClose('()')
inoremap <expr> ] g:MiniPairsActionClose('[]')
inoremap <expr> } g:MiniPairsActionClose('{}')

inoremap <expr> " g:MiniPairsActionCloseopen('""')
""" No auto-pair for '\'' because it messes up with plain English used in
""" comments (like can't, etc.)
inoremap <expr> ` g:MiniPairsActionCloseopen('``')

inoremap <expr> <BS> g:MiniPairsActionBS(['()', '[]', '{}', '""', "''", '``'])
inoremap <expr> <CR> g:MiniPairsActionCR(['()', '[]', '{}'])

"" Command mode
cnoremap <expr> ( g:MiniPairsActionOpen('()')
cnoremap <expr> [ g:MiniPairsActionOpen('[]')
cnoremap <expr> { g:MiniPairsActionOpen('{}')

cnoremap <expr> ) g:MiniPairsActionClose('()')
cnoremap <expr> ] g:MiniPairsActionClose('[]')
cnoremap <expr> } g:MiniPairsActionClose('{}')

cnoremap <expr> " g:MiniPairsActionCloseopen('""')
cnoremap <expr> ' g:MiniPairsActionCloseopen("''")
cnoremap <expr> ` g:MiniPairsActionCloseopen('``')

cnoremap <expr> <BS> g:MiniPairsActionBS(['()', '[]', '{}', '""', "''", '``'])

"" Terminal mode
tnoremap <expr> ( g:MiniPairsActionOpen('()')
tnoremap <expr> [ g:MiniPairsActionOpen('[]')
tnoremap <expr> { g:MiniPairsActionOpen('{}')

tnoremap <expr> ) g:MiniPairsActionClose('()')
tnoremap <expr> ] g:MiniPairsActionClose('[]')
tnoremap <expr> } g:MiniPairsActionClose('{}')

tnoremap <expr> " g:MiniPairsActionCloseopen('""')
cnoremap <expr> ' g:MiniPairsActionCloseopen("''")
tnoremap <expr> ` g:MiniPairsActionCloseopen('``')

tnoremap <expr> <BS> g:MiniPairsActionBS(['()', '[]', '{}', '""', "''", '``'])
tnoremap <expr> <CR> g:MiniPairsActionCR(['()', '[]', '{}'])


"" Remap quotes in certain filetypes
au FileType lua call g:MiniPairsRemapQuotes()
au FileType vim call g:MiniPairsRemapQuotes()
" }}}

" Filetype autocommands {{{
autocmd BufEnter *.csv set filetype=csv
" }}}

" Close buffer (copy of 'bclose') {{{
" Delete buffer while keeping window layout (don't close buffer's windows).
" Source: https://vim.fandom.com/wiki/Deleting_a_buffer_without_closing_the_window
if v:version < 700 || exists('loaded_bclose') || &cp
  finish
endif
let loaded_bclose = 1
if !exists('bclose_multiple')
  let bclose_multiple = 1
endif

" Display an error message.
function! s:Warn(msg)
  echohl ErrorMsg
  echomsg a:msg
  echohl NONE
endfunction

" Command ':Bclose' executes ':bd' to delete buffer in current window.
" The window will show the alternate buffer (Ctrl-^) if it exists,
" or the previous buffer (:bp), or a blank buffer if no previous.
" Command ':Bclose!' is the same, but executes ':bd!' (discard changes).
" An optional argument can specify which buffer to close (name or number).
function! s:Bclose(bang, buffer)
  if empty(a:buffer)
    let btarget = bufnr('%')
  elseif a:buffer =~ '^\d\+$'
    let btarget = bufnr(str2nr(a:buffer))
  else
    let btarget = bufnr(a:buffer)
  endif
  if btarget < 0
    call s:Warn('No matching buffer for '.a:buffer)
    return
  endif
  if empty(a:bang) && getbufvar(btarget, '&modified')
    call s:Warn('No write since last change for buffer '.btarget.' (use :Bclose!)')
    return
  endif
  " Numbers of windows that view target buffer which we will delete.
  let wnums = filter(range(1, winnr('$')), 'winbufnr(v:val) == btarget')
  if !g:bclose_multiple && len(wnums) > 1
    call s:Warn('Buffer is in multiple windows (use ":let bclose_multiple=1")')
    return
  endif
  let wcurrent = winnr()
  for w in wnums
    execute w.'wincmd w'
    let prevbuf = bufnr('#')
    if prevbuf > 0 && buflisted(prevbuf) && prevbuf != btarget
      buffer #
    else
      bprevious
    endif
    if btarget == bufnr('%')
      " Numbers of listed buffers which are not the target to be deleted.
      let blisted = filter(range(1, bufnr('$')), 'buflisted(v:val) && v:val != btarget')
      " Listed, not target, and not displayed.
      let bhidden = filter(copy(blisted), 'bufwinnr(v:val) < 0')
      " Take the first buffer, if any (could be more intelligent).
      let bjump = (bhidden + blisted + [-1])[0]
      if bjump > 0
        execute 'buffer '.bjump
      else
        execute 'enew'.a:bang
      endif
    endif
  endfor
  execute 'bdelete'.a:bang.' '.btarget
  execute wcurrent.'wincmd w'
endfunction
command! -bang -complete=buffer -nargs=? Bclose call <SID>Bclose(<q-bang>, <q-args>)

" }}}

" vim: set sw=2 ts=2 sts=2 et tw=80 ft=vim fdm=marker:
