(() => {
  'use strict';

  const navItems = [
    { label: '首頁', href: '/', icon: '⌂' },
    { label: '報修', href: '/projects/my-home/issues/new', icon: '+' },
    { label: '投票', href: '/projects/my-home/community-polls', icon: '✓' },
    { label: '財務', href: '/projects/my-home/community-finance', icon: '$' }
  ];

  const addBodyState = () => {
    document.body.classList.toggle('cs-logged-in', !!document.querySelector('#loggedas'));
  };

  const buildMobileDock = () => {
    if (document.querySelector('.cs-mobile-dock')) return;

    const dock = document.createElement('nav');
    dock.className = 'cs-mobile-dock';
    dock.setAttribute('aria-label', '社區服務快捷列');

    navItems.forEach((item) => {
      const link = document.createElement('a');
      link.href = item.href;
      link.innerHTML = `<span>${item.icon}</span><strong>${item.label}</strong>`;
      if (window.location.pathname === item.href) link.classList.add('is-active');
      dock.appendChild(link);
    });

    document.body.appendChild(dock);
  };

  const labelHeader = () => {
    const header = document.querySelector('#header h1');
    if (!header || header.dataset.communityLabeled === 'true') return;
    header.dataset.communityLabeled = 'true';
    header.insertAdjacentHTML('afterend', '<p class="cs-header-subtitle">社區服務、案件追蹤與公告管理平台</p>');
  };

  const syncProjectTitle = () => {
    if (!/^\/projects\/my-home(\/|$)/.test(window.location.pathname)) return;

    const header = document.querySelector('#header h1');
    if (!header || header.dataset.projectTitleSynced === 'true') return;

    header.dataset.projectTitleSynced = 'true';
    header.textContent = '惠丞精工建築，智慧永續服務';
  };

  const boot = () => {
    addBodyState();
    syncProjectTitle();
    labelHeader();
    buildMobileDock();
  };

  document.addEventListener('DOMContentLoaded', boot, { once: true });
  window.addEventListener('load', boot, { once: true });
})();
