let s:is_vim = !has('nvim')

" first window id for bufnr
" builtin bufwinid returns window of current tab only
function! coc#compat#buf_win_id(bufnr) abort
  let info = filter(getwininfo(), 'v:val["bufnr"] =='.a:bufnr)
  if empty(info)
    return -1
  endif
  return info[0]['winid']
endfunction

function! coc#compat#win_is_valid(winid) abort
  if exists('*nvim_win_is_valid')
    return nvim_win_is_valid(a:winid)
  endif
  return !empty(getwininfo(a:winid))
endfunction

" clear matches by window id, not throw on none exists window.
" may not work on vim < 8.1.1084 & neovim < 0.4.0
function! coc#compat#clear_matches(winid) abort
  if !coc#compat#win_is_valid(a:winid)
    return
  endif
  let curr = win_getid()
  if curr == a:winid
    call clearmatches()
    return
  endif
  if s:is_vim
    if has('patch-8.1.1084')
      call clearmatches(a:winid)
    endif
  else
    if has('nvim-0.5.0')
      call clearmatches(a:winid)
    elseif exists('*nvim_set_current_win')
      noa call nvim_set_current_win(a:winid)
      call clearmatches()
      noa call nvim_set_current_win(curr)
    endif
  endif
endfunction

" remove keymap for specfic buffer
function! coc#compat#buf_del_keymap(bufnr, mode, lhs) abort
  if !bufloaded(a:bufnr)
    return
  endif
  if exists('*nvim_buf_del_keymap')
    try
      call nvim_buf_del_keymap(a:bufnr, a:mode, a:lhs)
    catch /^Vim\%((\a\+)\)\=:E5555/
      " ignore keymap not exists.
    endtry
    return
  endif
  if bufnr == a:bufnr
    execute 'silent! '.a:mode.'unmap <buffer> '.a:lhs
    return
  endif
  if exists('*win_execute')
    let winid = coc#compat#buf_win_id(a:bufnr)
    if winid != -1
      call win_execute(winid, 'silent! '.a:mode.'unmap <buffer> '.a:lhs)
    endif
  endif
endfunction