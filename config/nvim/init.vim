set tabstop=2               " number of columns occupied by a tab
set softtabstop=2           " see multiple spaces as tabstops so <BS> does the right thing
set expandtab               " converts tabs to white space
set shiftwidth=2            " width for autoindents
set clipboard=
set mouse=

" Enable syntax highlighting and true colors
syntax enable
set termguicolors

" Adaptive theme function for macOS
function! SetAdaptiveTheme()
  " Check if we're on macOS
  if has('mac') || has('macunix')
    " Get macOS appearance mode
    let l:mode = system("defaults read -g AppleInterfaceStyle 2>/dev/null || echo Light")
    let l:mode = substitute(l:mode, '\n', '', 'g')

    if l:mode ==# "Dark"
      " Dark mode configuration
      set background=dark
      colorscheme desert
      call SetDarkModeColors()
    else
      " Light mode configuration
      set background=light
      colorscheme default
      call SetLightModeColors()
    endif
  else
    " Non-macOS: use default desert theme
    set background=dark
    colorscheme desert
    call SetDarkModeColors()
  endif

  " Always make background transparent
  call SetTransparentBackground()
endfunction

" Dark mode color scheme
function! SetDarkModeColors()
  highlight Comment ctermfg=244 guifg=#87CEEB
  highlight String ctermfg=114 guifg=#98FB98
  highlight Keyword ctermfg=81 guifg=#87CEFA
  highlight Function ctermfg=226 guifg=#FFD700
  highlight Type ctermfg=141 guifg=#DDA0DD
  highlight Number ctermfg=210 guifg=#FFA07A
  highlight Constant ctermfg=210 guifg=#FFA07A
  highlight Special ctermfg=226 guifg=#FFD700
  highlight PreProc ctermfg=141 guifg=#DDA0DD
  highlight Identifier ctermfg=159 guifg=#AFEEEE
  highlight Statement ctermfg=81 guifg=#87CEFA
  highlight Title ctermfg=226 guifg=#FFD700
  highlight Todo ctermfg=226 guifg=#FFD700
  highlight Error ctermfg=196 guifg=#FF6347
  highlight WarningMsg ctermfg=226 guifg=#FFD700
  highlight Directory ctermfg=81 guifg=#87CEFA
  highlight MoreMsg ctermfg=114 guifg=#98FB98
  highlight Question ctermfg=114 guifg=#98FB98
endfunction

" Light mode color scheme
function! SetLightModeColors()
  highlight Comment ctermfg=240 guifg=#6A6A6A
  highlight String ctermfg=28 guifg=#008000
  highlight Keyword ctermfg=19 guifg=#0000CD
  highlight Function ctermfg=94 guifg=#8B4513
  highlight Type ctermfg=90 guifg=#8B008B
  highlight Number ctermfg=160 guifg=#D2691E
  highlight Constant ctermfg=160 guifg=#D2691E
  highlight Special ctermfg=94 guifg=#8B4513
  highlight PreProc ctermfg=90 guifg=#8B008B
  highlight Identifier ctermfg=17 guifg=#000080
  highlight Statement ctermfg=19 guifg=#0000CD
  highlight Title ctermfg=94 guifg=#8B4513
  highlight Todo ctermfg=94 guifg=#8B4513
  highlight Error ctermfg=160 guifg=#DC143C
  highlight WarningMsg ctermfg=94 guifg=#8B4513
  highlight Directory ctermfg=19 guifg=#0000CD
  highlight MoreMsg ctermfg=28 guifg=#008000
  highlight Question ctermfg=28 guifg=#008000
endfunction

" Transparent background function
function! SetTransparentBackground()
  highlight Normal ctermbg=NONE guibg=NONE
  highlight NonText ctermbg=NONE guibg=NONE
  highlight SignColumn ctermbg=NONE guibg=NONE
  highlight LineNr ctermbg=NONE guibg=NONE
  highlight EndOfBuffer ctermbg=NONE guibg=NONE
  highlight CursorLine ctermbg=NONE guibg=NONE
  highlight ColorColumn ctermbg=NONE guibg=NONE
  highlight StatusLine ctermbg=NONE guibg=NONE
  highlight StatusLineNC ctermbg=NONE guibg=NONE
  highlight VertSplit ctermbg=NONE guibg=NONE
endfunction

" Initialize adaptive theme
call SetAdaptiveTheme()

" Auto-refresh theme when focus is gained (useful for theme changes)
if has('mac') || has('macunix')
  autocmd FocusGained * call SetAdaptiveTheme()
endif

" Additional improvements
set cursorline             " highlight current line
set showmatch              " highlight matching brackets
