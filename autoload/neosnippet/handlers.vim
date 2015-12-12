"=============================================================================
" FILE: handlers.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! neosnippet#handlers#_complete_done() "{{{
  if empty(v:completed_item) || !g:neosnippet#enable_complete_done
    return
  endif

  let item = v:completed_item

  let abbr = (item.abbr != '') ? item.abbr : item.word
  if len(item.menu) > 5
    " Combine menu.
    let abbr .= ' ' . item.menu
  endif

  if item.info != ''
    let abbr = split(item.info, '\n')[0]
  endif

  if abbr !~ '('
    return
  endif

  " Make snippet arguments
  let cnt = 1
  let snippet = ''
  if item.word !~ '()\?$'
    let snippet .= '('
  endif

  for arg in split(substitute(neosnippet#handlers#_get_in_paren(abbr),
        \ '(\zs.\{-}\ze)', '', 'g'), '[^[]\zs\s*,\s*')
    if cnt != 1
      let snippet .= ', '
    endif
    let snippet .= printf('${%d:#:%s}', cnt, escape(arg, '{}'))
    let cnt += 1
  endfor

  if s:is_auto_pairs()
    " Remove auto pair from the snippet
    let snippet = substitute(snippet, ')$', '', '')
  else
    if snippet =~ '($'
      let snippet .= '${'. cnt .'})'
    elseif snippet !~ ')$'
      let snippet .= ')'
    endif

    let snippet .= '${0}'
  endif

  let [cur_text, col, expr] = neosnippet#mappings#_pre_trigger()
  call neosnippet#view#_insert(snippet, {}, cur_text, col)
endfunction"}}}

function! neosnippet#handlers#_cursor_moved() "{{{
  let expand_stack = neosnippet#variables#expand_stack()

  " Get patterns and count.
  if !&l:modifiable || !&l:modified
        \ || empty(expand_stack)
    return
  endif

  let expand_info = expand_stack[-1]
  if expand_info.begin_line == expand_info.end_line
        \ && line('.') != expand_info.begin_line
    call neosnippet#commands#_clear_markers()
  endif
endfunction"}}}

function! neosnippet#handlers#_get_in_paren(str) abort "{{{
  let s = ''
  let level = 0
  for c in split(a:str, '\zs')
    if c == '('
      let level += 1

      if level == 1
        continue
      endif
    elseif c == ')'
      if level == 1
        return s
      else
        let level -= 1
      endif
    endif

    if level > 0
      let s .= c
    endif
  endfor

  return ''
endfunction"}}}

function! s:is_auto_pairs() abort "{{{
  return get(g:, 'neopairs#enable', 0)
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
