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

fun! s:searchpos(str, ...)
  return call(function("searchpos"), [escape(a:str, ".*")] + a:000)
endf

fun! s:is_exist_import_impl(namespaces, qualified_name)
  let [lnum, col] = s:searchpos("import " . join(a:namespaces + [a:qualified_name], ".") . ";")
  if lnum == 0 && col == 0
    let [lnum, col] = s:searchpos("import " . join(a:namespaces + ["*"]) . ";")
    if lnum == 0 && col == 0
      return 0
    endif
    return 1
  endif
  return 1
endf

fun! s:is_exist_import(namespaces, qualified_name)
  let pos = getpos(".")
  let result = s:is_exist_import_impl(a:namespaces, a:qualified_name)
  call setpos(".", pos)
  return result
endf

fun! s:find_line(namespaces)
  if empty(a:namespaces)
    return 0
  endif

  call cursor(1, 0)
  let [lnum, col] = s:searchpos("import " . join(a:namespaces + [""], "."), "b")
  if lnum == 0 && col == 0
    return s:find_line(a:namespaces[0:-2])
  endif

  return lnum
endf

fun! s:create_append_arg_impl(namespaces, import)
  let lnum = s:find_line(a:namespaces)
  if lnum > 0
    return [lnum, a:import]
  endif

  " search last 'import'
  call cursor(1, 0)
  let [lnum, col] = s:searchpos("import", "b")

  if lnum == 0 && col == 0
    " sarch 'package'
    let [lnum, col] = s:searchpos("package")
    if lnum == 0 && col == 0
      return [0, [a:import, ""]]
    endif

    return [lnum, ["", a:import]]
  endif

  return [lnum, a:import]
endf

fun! s:create_append_arg(namespaces, import)
  let pos = getpos(".")
  let result = s:create_append_arg_impl(a:namespaces, a:import)
  call setpos(".", pos)
  return result
endf

fun! s:refroid_import(class)
  let selected = s:refroid_select(a:class)
  if empty(selected)
    return
  endif
  let namespaces = split(selected[1], "/")
  let qualified_name = selected[2]

  if s:is_exist_import(namespaces, qualified_name)
    return
  endif

  let namespace_path = join(namespaces + [qualified_name], ".") . ";"
  let import = "import " . namespace_path
  let [lnum, expr] = s:create_append_arg(namespaces, import)
  call append(lnum, expr)
endf

fun! s:refroid_import_cursor()
  call s:refroid_import(expand("<cword>"))
endf

command! -nargs=1 Refroid call s:refroid(expand("<args>"))
command! -nargs=0 RefroidCursor call s:refroid_cursor()

command! -nargs=1 RefroidImport call s:refroid_import(expand("<args>"))
command! -nargs=0 RefroidImportCursor call s:refroid_import_cursor()

