" Attempt to determine the type of a file based on its name and possibly its
" contents. Use this to allow intelligent auto-indenting for each filetype,
" and for plugins that are filetype specific.
filetype indent plugin on
 
" Enable syntax highlighting
syntax on

" Better command-line completion
set wildmenu
set wildmode=list:longest,full

" Disable use of the mouse 
set mouse=

" Indentation settings for using 4 spaces instead of tabs.
" Do not change 'tabstop' from its default value of 8 with this setup.
set shiftwidth=2
set softtabstop=2

" Show invisible characters, if triggered with :set list!
set listchars=eol:¬,tab:>·,trail:~,extends:>,precedes:<,space:␣

" It hides buffers instead of closing them.
set hidden
