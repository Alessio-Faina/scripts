set nocompatible              " be iMproved, required
filetype off                  " required

"set expandtab
set tabstop=2
set shiftwidth=2
set ignorecase
set smartcase
set incsearch
set number 
set colorcolumn=81
set tags=tags;
set smartindent
set hlsearch

syntax on

set background=dark
hi Cursor ctermfg=17 ctermbg=231 cterm=NONE guifg=#282a36 guibg=#f8f8f0 gui=NONE
hi Visual ctermfg=NONE ctermbg=241 cterm=NONE guifg=NONE guibg=#44475a gui=NONE
hi CursorLine ctermbg=234 cterm=NONE guifg=NONE guibg=#44475a gui=NONE
hi CursorColumn ctermbg=234 cterm=NONE guifg=NONE guibg=#44475a gui=NONE
hi ColorColumn ctermfg=NONE ctermbg=236 cterm=NONE guifg=NONE guibg=#3d3f49 gui=NONE
hi LineNr ctermfg=60 ctermbg=NONE cterm=NONE guifg=#6272a4 guibg=#282a36 gui=NONE
hi CursorLineNr ctermfg=228 ctermbg=234 cterm=NONE guifg=#f1fa8c guibg=#44475a gui=NONE
hi VertSplit ctermfg=231 ctermbg=236 cterm=bold guifg=#64666d guibg=#64666d gui=bold
hi MatchParen ctermfg=212 ctermbg=NONE cterm=underline guifg=#ff79c6 guibg=NONE gui=underline
hi StatusLine ctermfg=231 ctermbg=236 cterm=bold guifg=#f8f8f2 guibg=#64666d gui=bold
hi StatusLineNC ctermfg=231 ctermbg=236 cterm=NONE guifg=#f8f8f2 guibg=#64666d gui=NONE
hi Pmenu ctermfg=NONE ctermbg=NONE cterm=NONE guifg=NONE guibg=NONE gui=NONE
hi PmenuSel ctermfg=NONE ctermbg=236 cterm=NONE guifg=NONE guibg=#44475a gui=NONE
hi IncSearch ctermfg=17 ctermbg=215 cterm=none guifg=#282a36 guibg=#ffb86c gui=none
hi Search ctermfg=17 ctermbg=84 cterm=none guifg=#282a36 guibg=#50fa7b gui=none
hi Directory ctermfg=141 ctermbg=NONE cterm=NONE guifg=#bd93f9 guibg=NONE gui=NONE
hi Folded ctermfg=61 ctermbg=235 cterm=NONE guifg=#6272a4 guibg=#282a36 gui=NONE
hi SignColumn ctermfg=246 ctermbg=235 cterm=NONE guifg=#909194 guibg=#44475a gui=NONE
hi FoldColmun ctermfg=246 ctermbg=235 cterm=NONE guifg=#909194 guibg=#44475a gui=NONE
hi Normal guifg=#f8f8f2 guibg=#282a36 gui=NONE
hi Boolean ctermfg=141 ctermbg=NONE cterm=NONE guifg=#bd93f9 guibg=NONE gui=NONE
hi Character ctermfg=141 ctermbg=NONE cterm=NONE guifg=#bd93f9 guibg=NONE gui=NONE
hi Comment ctermfg=61 ctermbg=NONE cterm=NONE guifg=#6272a4 guibg=NONE gui=NONE
hi Conditional ctermfg=212 ctermbg=NONE cterm=NONE guifg=#ff79c6 guibg=NONE gui=NONE
hi Constant ctermfg=NONE ctermbg=NONE cterm=NONE guifg=NONE guibg=NONE gui=NONE
hi Define ctermfg=212 ctermbg=NONE cterm=NONE guifg=#ff79c6 guibg=NONE gui=NONE
hi DiffAdd ctermfg=231 ctermbg=64 cterm=bold guifg=#f8f8f2 guibg=#468410 gui=bold
hi DiffDelete ctermfg=88 ctermbg=NONE cterm=NONE guifg=#8b080b guibg=NONE gui=NONE
hi DiffChange ctermfg=231 ctermbg=23 cterm=NONE guifg=#f8f8f2 guibg=#243a5f gui=NONE
hi DiffText ctermfg=231 ctermbg=24 cterm=bold guifg=#f8f8f2 guibg=#204a87 gui=bold
hi ErrorMsg ctermfg=231 ctermbg=212 cterm=NONE guifg=#f8f8f0 guibg=#ff79c6 gui=NONE
hi WarningMsg ctermfg=231 ctermbg=212 cterm=NONE guifg=#f8f8f0 guibg=#ff79c6 gui=NONE
hi Float ctermfg=141 ctermbg=NONE cterm=NONE guifg=#bd93f9 guibg=NONE gui=NONE
hi Function ctermfg=84 ctermbg=NONE cterm=NONE guifg=#50fa7b guibg=NONE gui=NONE
hi Identifier ctermfg=117 ctermbg=NONE cterm=NONE guifg=#8be9fd guibg=NONE gui=italic
hi Keyword ctermfg=212 ctermbg=NONE cterm=NONE guifg=#ff79c6 guibg=NONE gui=NONE
hi Label ctermfg=228 ctermbg=NONE cterm=NONE guifg=#f1fa8c guibg=NONE gui=NONE
hi NonText ctermfg=231 ctermbg=NONE cterm=NONE guifg=#525563 guibg=NONE gui=NONE
hi Number ctermfg=141 ctermbg=NONE cterm=NONE guifg=#bd93f9 guibg=NONE gui=NONE
hi Operator ctermfg=212 ctermbg=NONE cterm=NONE guifg=#ff79c6 guibg=NONE gui=NONE
hi PreProc ctermfg=212 ctermbg=NONE cterm=NONE guifg=#ff79c6 guibg=NONE gui=NONE
hi Special ctermfg=231 ctermbg=NONE cterm=NONE guifg=#f8f8f2 guibg=NONE gui=NONE
hi SpecialKey ctermfg=231 ctermbg=235 cterm=NONE guifg=#525563 guibg=NONE gui=NONE
hi Statement ctermfg=212 ctermbg=NONE cterm=NONE guifg=#ff79c6 guibg=NONE gui=NONE
hi StorageClass ctermfg=117 ctermbg=NONE cterm=NONE guifg=#8be9fd guibg=NONE gui=italic
hi String ctermfg=228 ctermbg=NONE cterm=NONE guifg=#f1fa8c guibg=NONE gui=NONE
hi Tag ctermfg=212 ctermbg=NONE cterm=NONE guifg=#ff79c6 guibg=NONE gui=NONE
hi Title ctermfg=231 ctermbg=NONE cterm=bold guifg=#f8f8f2 guibg=NONE gui=bold
hi Todo ctermfg=61 ctermbg=NONE cterm=inverse,bold guifg=#6272a4 guibg=NONE gui=inverse,bold
hi Type ctermfg=117 ctermbg=NONE cterm=NONE guifg=#8be9fd guibg=NONE gui=NONE
hi Underlined ctermfg=NONE ctermbg=NONE cterm=underline guifg=NONE guibg=NONE gui=underline
hi TabLineFill  guifg=#333333 guibg=#282a36 gui=none
hi TabLine      guifg=#666666 guibg=#282a36 gui=none
hi TabLineSel guifg=WHITE guibg=#282a36 gui=none

hi vimGroupName ctermfg=81 ctermbg=NONE cterm=NONE guifg=#66d9ef guibg=NONE
hi vimGroup ctermfg=81 ctermbg=NONE cterm=NONE guifg=#66d9ef guibg=NONE
hi vimOption ctermfg=81 ctermbg=NONE cterm=NONE guifg=#66d9ef guibg=NONE
hi vimHiCtermFgBg ctermfg=NONE ctermbg=NONE cterm=NONE guifg=NONE guibg=NONE
hi vimHiGuiFgBg ctermfg=NONE ctermbg=NONE cterm=NONE guifg=NONE guibg=NONE
"highlight DiffAdd    cterm=bold ctermfg=10 ctermbg=17 gui=none guifg=bg guibg=Red
"highlight DiffDelete cterm=bold ctermfg=10 ctermbg=17 gui=none guifg=bg guibg=Red 
"highlight DiffChange cterm=bold ctermfg=10 ctermbg=17 gui=none guifg=bg guibg=Red
"highlight DiffText   cterm=bold ctermfg=10 ctermbg=88 gui=none guifg=bg guibg=Red

"Remove all trailing whitespace by pressing F5
nnoremap <F5> :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar><CR>
"Remove CTRL-M from a file (Windows line ending
nnoremap <F6> :%s/^M//g<CR>
"nerdtree
map <C-n> :NERDTreeToggle<CR>

fu! SeeTab()
  if !exists("g:SeeTabEnabled")
    let g:SeeTabEnabled = 0
  end
  if g:SeeTabEnabled==0
    syn match leadspace /^\s\+/ contains=syntab
    exe "syn match syntab /\\s\\{" . &sw . "}/hs=s,he=s+1 contained"
    hi syntab guibg=Red
    let g:SeeTabEnabled=1
  else
    syn clear leadspace
    syn clear syntab
    let g:SeeTabEnabled=0
  end
endfunc
com! -nargs=0 SeeTab :call SeeTab()

" Run clang-format
if has("win32")
    let g:clang_format="c:\\Program\ Files\\LLVM\\share\\clang\\clang-format.py"
else
    let g:clang_format="/usr/share/clang/clang-format-6.0/clang-format.py"
endif
if has("python3")
    map <C-K> :py3f <C-R>=g:clang_format<cr><cr>
    imap <C-K> <c-o> :py3f <C-R>=g:clang_format<cr><cr>
elseif has("python")
    map <C-K> :pyf <C-R>=g:clang_format<cr><cr>
    imap <C-K> <c-o> :pyf <C-R>=g:clang_format<cr><cr>
endif

function! AckSign()
	call append(line('$'), "")
	call append(line('$'), "Acked-by: Alessio Faina <alessio.faina@canonical.com>")
endfunction
com! -nargs=0 AckSign :call AckSign()

function! CVEAddDefaultMessage()
	g/Signed-off-by:/z#.1
	call append(line('.'), "(backported from commit <sha1> <provenance>)")
	call append(line('.')+1, "[alessiofaina: <brief explanation of what was changed and why>]")
	call append(line('.')+2, "CVE-<number>")
	call append(line('.')+3, "Signed-off-by: Alessio Faina <alessio.faina@canonical.com>")
endfunction
com! -nargs=0 CVEAddDefaultMessage :call CVEAddDefaultMessage()

"VIMPLUG STUFF                                                                   
"Remember to install git and other stuff beforehand
"First time remember to run :PlugInstall

if empty(glob('~/.vim/autoload/plug.vim'))                                       
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs                       
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim        
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC                        
endif         

call plug#begin()
	Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
	Plug 'junegunn/fzf.vim'
	Plug 'vim-airline/vim-airline'
	Plug 'vim-airline/vim-airline-themes'
	Plug 'godlygeek/tabular'
	Plug 'altercation/vim-colors-solarized'
	Plug 'tpope/vim-fugitive'
	Plug 'powerline/powerline'
	Plug 'scrooloose/nerdtree'
call plug#end()
