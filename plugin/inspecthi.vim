let s:save_cpo = &cpoptions
set cpoptions&vim


if exists('g:loaded_inspecthi') && g:loaded_inspecthi
  finish
endif


augroup inspecthi_vim
  autocmd! CursorMoved * call inspecthi#on_cursormoved()
  autocmd! BufLeave * call inspecthi#on_bufleave()
augroup END


command! -nargs=0 Inspecthi call inspecthi#inspect()
command! -nargs=0 InspecthiHideInspector call inspecthi#hide_inspector()
command! -nargs=0 InspecthiShowInspector call inspecthi#show_inspector()


let g:loaded_inspecthi = 1


let &cpoptions = s:save_cpo
