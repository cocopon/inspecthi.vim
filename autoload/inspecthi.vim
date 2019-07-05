let s:save_cpo = &cpoptions
set cpoptions&vim


function! s:inspect() abort
  let synid = synID(line('.'), col('.'), 1)
  let names = exists(':ColorSwatchGenerate')
        \ ? s:hi_chain_with_colorswatch(synid)
        \ : s:hi_chain(synid)
  return join(names, ' -> ')
endfunction


function! inspecthi#inspect() abort
  echo s:inspect()
endfunction


function! s:hi_chain(synid) abort
  let name = synIDattr(a:synid, 'name')
  let names = []

  call add(names, name)

  let original = synIDtrans(a:synid)
  if a:synid != original
    call add(names, synIDattr(original, 'name'))
  endif

  return names
endfunction


" Trace hi-group link with colorswatch.vim.
" (It can show more detailed information)
function! s:hi_chain_with_colorswatch(synid) abort
  let entries = colorswatch#source#all#collect()
  let entryset = colorswatch#entryset#new(entries)

  let name = synIDattr(a:synid, 'name')
  let entry = entryset.find_entry(name)
  let names = []

  while !empty(entry)
    let name = entry.get_name()
    call add(names, name)

    if !entry.has_link()
      break
    endif

    let entry = entryset.find_entry(entry.get_link())
  endwhile

  return names
endfunction


function! s:init_vars() abort
  let b:inspecthi = get(b:, 'inspecthi', {
        \   'inspector_win_id': 0,
        \   'shows_inspector': 0,
        \   'timer_id': 0,
        \ })
endfunction


function! s:show_popup(...) abort
  let win_id = b:inspecthi.inspector_win_id

  if win_id != 0
    call popup_close(win_id)
  endif

  let text = s:inspect()
  let b:inspecthi.inspector_win_id = popup_create(text, {
        \   'col': 'cursor',
        \   'line': 'cursor+1',
        \ })
endfunction


function! s:close_popup() abort
  let win_id = b:inspecthi.inspector_win_id
  if win_id != 0
    call popup_close(win_id)
    let b:inspecthi.inspector_win_id = 0
  endif
endfunction


function! s:reserve_popup() abort
  let timer_id = get(b:inspecthi, 'timer_id', 0)
  if timer_id != 0
    call timer_stop(timer_id)
  endif

  let b:inspecthi.timer_id = timer_start(
        \ 500,
        \ function('s:show_popup'))
endfunction


function! s:show_floatwin(...) abort
  let win_id = b:inspecthi.inspector_win_id

  if win_id != 0
    call nvim_win_close(win_id, v:true)
  endif

  let text = s:inspect()
  if len(text) == 0
    let text = ' '
  endif

  let buf = nvim_create_buf(v:false, v:true)
  call nvim_buf_set_lines(buf, 0, 1, 0, [text])
  let win_id = nvim_open_win(buf, v:false, {
        \ 'relative': 'cursor',
        \ 'height': 1, 'width': len(text),
        \ 'row': 1, 'col': 1,
        \ 'focusable': v:false,
        \ })
  call nvim_win_set_option(win_id, 'colorcolumn', '')
  call nvim_win_set_option(win_id, 'list', v:false)
  call nvim_win_set_option(win_id, 'number', v:false)
  call nvim_win_set_option(win_id, 'relativenumber', v:false)
  call nvim_win_set_option(win_id, 'spell', v:false)
  call nvim_win_set_option(win_id, 'winblend', g:inspecthi_floatwin_blend)
  call nvim_win_set_option(win_id, 'winhighlight', 'Normal:' . g:inspecthi_floatwin_hl)
  let b:inspecthi.inspector_win_id = win_id
endfunction


function! s:close_floatwin() abort
  let win_id = b:inspecthi.inspector_win_id
  if win_id != 0
    call nvim_win_close(win_id, v:true)
    let b:inspecthi.inspector_win_id = 0
  endif
endfunction


function! s:reserve_floatwin() abort
  let timer_id = get(b:inspecthi, 'timer_id', 0)
  if timer_id != 0
    call timer_stop(timer_id)
  endif

  let b:inspecthi.timer_id = timer_start(
        \ 500,
        \ function('s:show_floatwin'))
endfunction


function! inspecthi#show_inspector() abort
  call s:init_vars()
  if has('nvim')
    call s:show_floatwin()
  else
    call s:show_popup()
  endif
  let b:inspecthi.shows_inspector = 1
endfunction


function! inspecthi#hide_inspector() abort
  call s:init_vars()
  if has('nvim')
    call s:close_floatwin()
  else
    call s:close_popup()
  endif
  let b:inspecthi.shows_inspector = 0
endfunction


function! inspecthi#on_cursormoved() abort
  call s:init_vars()
  if !b:inspecthi.shows_inspector
    return
  endif

  if has('nvim')
    call s:close_floatwin()
    call s:reserve_floatwin()
  else
    call s:close_popup()
    call s:reserve_popup()
  endif
endfunction


function! inspecthi#on_bufleave() abort
  call s:init_vars()
  if !b:inspecthi.shows_inspector
    return
  endif

  if has('nvim')
    call s:close_floatwin()
  else
    call s:close_popup()
  endif
endfunction


let &cpoptions = s:save_cpo
