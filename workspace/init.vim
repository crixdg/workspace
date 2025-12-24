set number
highlight LineNr ctermfg=8

set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4
set smartindent

set guicursor=
  \n-v-c:block-Cursor/lCursor,
  \ve:ver35-Cursor,
  \o:hor50-Cursor,
  \i-ci:ver25-Cursor/lCursor,
  \r-cr:hor20-Cursor/lCursor,
  \sm:block-Cursor
  \-blinkwait175-blinkoff150-blinkon175

au VimLeave * set guicursor=a:ver25-Cursor-blinkwait700-blinkon400-blinkoff250
