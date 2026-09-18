(function () {
  'use strict';

  function renderCommunityHome() {
    var isRoot = window.location.pathname === '/' || window.location.pathname === '';
    if (!isRoot) return;

    var content = document.getElementById('content');
    if (!content || content.dataset.communityHome === 'true') return;
    content.dataset.communityHome = 'true';

    content.innerHTML = [
    '<section class="cs-home">',
    '  <div class="cs-hero">',
    '    <div class="cs-hero__copy">',
    '      <span class="cs-kicker">ModuleX Community Portal</span>',
    '      <h1><span>惠丞精工建築</span><span>智慧永續服務</span></h1>',
    '      <p>把報修、公告、投票與財務資訊集中成建商專屬的社區服務入口，讓住戶有感、管委會好追蹤，也讓品牌口碑延續到交屋之後。</p>',
    '      <div class="cs-hero__actions">',
    '        <a class="cs-btn cs-btn--primary" href="/login">住戶登入</a>',
    '        <a class="cs-btn cs-btn--ghost" href="/projects">查看社區服務</a>',
    '      </div>',
    '    </div>',
    '    <div class="cs-phone-card" aria-label="手機社區服務預覽">',
    '      <div class="cs-phone-card__top">我的社區</div>',
    '      <div class="cs-phone-grid">',
    '        <a href="/projects/my-home/issues/new"><span>維修</span><strong>線上報修</strong></a>',
    '        <a href="/projects/my-home/community-polls"><span>投票</span><strong>投票專區</strong></a>',
    '        <a href="/projects/my-home/community-finance"><span>財務</span><strong>財務公告</strong></a>',
    '        <a href="/issues"><span>進度</span><strong>我的案件</strong></a>',
    '      </div>',
    '      <div class="cs-status-card">',
    '        <small>今日服務狀態</small>',
    '        <strong>3 件待處理 · 12 則公告</strong>',
    '      </div>',
    '    </div>',
    '  </div>',
    '  <div class="cs-service-row">',
    '    <a class="cs-service-card" href="/projects/my-home/issues/new"><small>01</small><strong>線上報修</strong><span>拍照、描述問題，建立可追蹤案件。</span></a>',
    '    <a class="cs-service-card" href="/projects/my-home/community-polls"><small>02</small><strong>投票專區</strong><span>住戶議題集中公告與表決。</span></a>',
    '    <a class="cs-service-card" href="/projects/my-home/community-finance"><small>03</small><strong>財務管理</strong><span>管理費、支出與公告透明化。</span></a>',
    '    <a class="cs-service-card" href="/projects"><small>04</small><strong>社區公告</strong><span>重要事項與服務入口集中管理。</span></a>',
    '  </div>',
    '</section>'
    ].join('');
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', renderCommunityHome, { once: true });
  } else {
    renderCommunityHome();
  }
})();
