(() => {
  const button = document.querySelector('[data-menu-toggle]');
  const menu = document.querySelector('[data-mobile-menu]');
  if (!button || !menu) return;

  const setOpen = (open) => {
    button.setAttribute('aria-expanded', String(open));
    menu.hidden = !open;
    document.documentElement.classList.toggle('menu-open', open);
  };

  button.addEventListener('click', () => setOpen(button.getAttribute('aria-expanded') !== 'true'));
  menu.querySelectorAll('a').forEach((link) => link.addEventListener('click', () => setOpen(false)));
  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') setOpen(false);
  });
})();
