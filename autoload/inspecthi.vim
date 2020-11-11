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
  if has('nvim')
      " use floating window for nvim
      if !empty(text)
          let buf = nvim_create_buf(v:false, v:true)
          call nvim_buf_set_lines(buf, 0, -1, v:true, [' ' . text])
          let opts = {'relative': 'cursor', 'width': len(text)+2, 'height': 1, 'col': 0,
                      \ 'row': 1, 'anchor': 'NW', 'style': 'minimal'}
          let b:inspecthi.inspector_win_handle = nvim_open_win(buf, 0, opts)
      endif
  else
      let b:inspecthi.inspector_win_id = popup_create(text, {
            \   'col': 'cursor',
            \   'line': 'cursor+1',
            \ })
  endif
endfunction


function! s:close_popup() abort
  if has('nvim')
      " use floating window for nvim
      if index(nvim_list_wins(), b:inspecthi.inspector_win_handle) >= 0
          call nvim_win_close(b:inspecthi.inspector_win_handle, 1)
      endif
  else
      let win_id = b:inspecthi.inspector_win_id
      if win_id != 0
        call popup_close(win_id)
        let b:inspecthi.inspector_win_id = 0
      endif
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


function! inspecthi#show_inspector() abort
  augroup inspecthi_vim
    autocmd CursorMoved <buffer> call inspecthi#on_cursormoved()
    autocmd BufLeave <buffer> call inspecthi#on_bufleave()
  augroup END

  call s:init_vars()
  call s:show_popup()
  let b:inspecthi.shows_inspector = 1
endfunction


function! inspecthi#hide_inspector() abort
  call s:init_vars()
  call s:close_popup()
  let b:inspecthi.shows_inspector = 0

  augroup inspecthi_vim
    autocmd! * <buffer>
  augroup END
endfunction


function! inspecthi#on_cursormoved() abort
  call s:init_vars()
  if !b:inspecthi.shows_inspector
    return
  endif

  call s:close_popup()
  call s:reserve_popup()
endfunction


function! inspecthi#on_bufleave() abort
  call s:init_vars()
  if !b:inspecthi.shows_inspector
    return
  endif

  call s:close_popup()
endfunction


let &cpoptions = s:save_cpo
