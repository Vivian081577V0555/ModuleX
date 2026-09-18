(() => {
  'use strict';

  const enhanceHomepage = () => {
    const clock = document.querySelector('.mx-hub-clock');
    if (!clock || clock.dataset.running === 'true') return;

    clock.dataset.running = 'true';
    const updateClock = () => {
      clock.textContent = new Intl.DateTimeFormat('en-GB', {
        timeZone: 'Asia/Taipei',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        hour12: false
      }).format(new Date()) + ' / TPE';
    };

    updateClock();
    window.setInterval(updateClock, 1000);
  };

  document.addEventListener('DOMContentLoaded', () => window.setTimeout(enhanceHomepage, 0), { once: true });
  window.addEventListener('load', enhanceHomepage, { once: true });
})();
