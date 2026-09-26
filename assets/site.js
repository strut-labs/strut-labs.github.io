(() => {
  const button = document.querySelector('[data-menu-toggle]');
  const menu = document.querySelector('[data-mobile-menu]');
  const setOpen = (open) => {
    if (!button || !menu) return;
    button.setAttribute('aria-expanded', String(open));
    menu.hidden = !open;
    document.documentElement.classList.toggle('menu-open', open);
  };
  if (button && menu) {
    button.addEventListener('click', () => setOpen(button.getAttribute('aria-expanded') !== 'true'));
    menu.querySelectorAll('a').forEach((link) => link.addEventListener('click', () => setOpen(false)));
    document.addEventListener('keydown', (event) => { if (event.key === 'Escape') setOpen(false); });
  }

  const here = new URL(location.href).pathname.replace(/\/$/, '/index.html');
  document.querySelectorAll('.docs-nav').forEach((nav) => {
    let activeDetails = null;
    nav.querySelectorAll('a').forEach((link) => {
      const path = new URL(link.href, location.href).pathname.replace(/\/$/, '/index.html');
      if (path === here) {
        link.setAttribute('aria-current', 'page');
        activeDetails = link.closest('details');
      }
    });
    nav.querySelectorAll('details').forEach((details) => { details.open = details === activeDetails; });
  });

  const esc = (value) => value.replace(/[&<>]/g, (c) => ({'&':'&amp;','<':'&lt;','>':'&gt;'}[c]));
  const strutKeywords = new Set(['async','await','break','case','catch','const','continue','default','else','enum','for','function','if','include','match','new','operator','return','struct','switch','throw','try','type','unsafe','void','while']);
  const strutTypes = new Set(['bool','int','uint','int_8','int_16','int_32','int_64','uint_8','uint_16','uint_32','uint_64','double','double_32','double_64','string','json','map','ptr','weak_ptr','istream','ostream','sstream','ifstream','ofstream','exec_result']);
  const strutLiterals = new Set(['true','false','null']);

  function highlightStrut(source) {
    let out = '', i = 0;
    const isStart = (c) => /[A-Za-z_]/.test(c);
    const isPart = (c) => /[A-Za-z0-9_]/.test(c);
    while (i < source.length) {
      if (source.startsWith('//', i)) { const e = source.indexOf('\n', i); const j = e < 0 ? source.length : e; out += '<span class="tok-comment">'+esc(source.slice(i,j))+'</span>'; i=j; continue; }
      if (source.startsWith('/*', i)) { const e = source.indexOf('*/', i+2); const j = e < 0 ? source.length : e+2; out += '<span class="tok-comment">'+esc(source.slice(i,j))+'</span>'; i=j; continue; }
      const c = source[i];
      if (c === '"') { let j=i+1; while(j<source.length){ if(source[j]==='\\'){j+=2;continue;} if(source[j]==='"'){j++;break;} j++; } out += '<span class="tok-string">'+esc(source.slice(i,j))+'</span>'; i=j; continue; }
      if (/\d/.test(c)) { let j=i+1; while(j<source.length && /[0-9A-Fa-f_xX.eE+-]/.test(source[j])) j++; out += '<span class="tok-number">'+esc(source.slice(i,j))+'</span>'; i=j; continue; }
      if (isStart(c)) { let j=i+1; while(j<source.length && isPart(source[j])) j++; const word=source.slice(i,j); let cls=''; if(strutKeywords.has(word)) cls='tok-keyword'; else if(strutTypes.has(word) || /^[A-Z][A-Z0-9_]*$/.test(word)) cls='tok-type'; else if(strutLiterals.has(word)) cls='tok-literal'; else if(source.slice(j).trimStart().startsWith('(')) cls='tok-function'; out += cls ? `<span class="${cls}">${word}</span>` : word; i=j; continue; }
      if ('+-*/%=<>!&|^~?:'.includes(c)) { let j=i+1; while(j<source.length && '+-*/%=<>!&|^~?:'.includes(source[j])) j++; out += '<span class="tok-operator">'+esc(source.slice(i,j))+'</span>'; i=j; continue; }
      out += esc(c); i++;
    }
    return out;
  }

  document.querySelectorAll('pre > code').forEach((code) => {
    const source = code.textContent;
    if (code.classList.contains('language-strut')) code.innerHTML = highlightStrut(source);
    const pre = code.parentElement;
    if (!pre || pre.parentElement?.classList.contains('code-block')) return;
    const wrapper = document.createElement('div'); wrapper.className='code-block';
    pre.parentNode.insertBefore(wrapper, pre); wrapper.appendChild(pre);
    const copy = document.createElement('button'); copy.type='button'; copy.className='code-copy'; copy.setAttribute('aria-label','Copy code'); copy.title='Copy code';
    copy.innerHTML='<svg viewBox="0 0 24 24" aria-hidden="true"><rect x="8" y="8" width="11" height="11" rx="2"></rect><path d="M16 8V6a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h2"></path></svg>';
    copy.addEventListener('click', async () => { await navigator.clipboard.writeText(source); copy.classList.add('copied'); copy.title='Copied'; setTimeout(()=>{copy.classList.remove('copied');copy.title='Copy code';},1200); });
    wrapper.appendChild(copy);
  });
})();
