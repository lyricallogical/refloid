if !exists("g:refroid_apilevel")
  let g:refroid_apilevel = 8
endif

if !exists("g:refroid_browser")
  let g:refroid_browser = "firefox --new-tab"
endif

fun! s:refroid_select(class)
  let comm = "ruby ~/.vim/ruby/refroid.rb " . a:class . " " . g:refroid_apilevel
  let candidates = split(system(comm), '\n')
  call map(candidates, 'split(v:val)')
  if empty(candidates)
    return
  endif

  let index = 0
  if len(candidates) > 1
    let index = inputlist(map(copy(candidates), 'v:key + 1 . ". " . v:val[0]')) - 1
  endif

  if index < 0 || len(candidates) <= index
    return
  endif

  return candidates[index]
endf


fun! s:refroid(class)
  let selected = s:refroid_select(a:class)
  if empty(selected)
    return
  endif
  echo selected
  let namespaces = selected[1]
  let qualified_name = selected[2]
  let path = namespaces . "/" . qualified_name . ".html"
  let url_base = "http://developer.android.com/reference/"
  let comm_browser = g:refroid_browser . " " . url_base . path
  call system(comm_browser)
endf

fun! s:refroid_cursor()
  call s:refroid(expand("<cword>"))
endf

command! -nargs=1 Refroid call s:refroid(expand("<args>"))
command! -nargs=0 RefroidCursor call s:refroid_cursor()

