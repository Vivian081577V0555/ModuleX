$(function() {
  if ($('#ultimate-hub').length) return;

  const homeHubHtml = `
    <main id="ultimate-hub" class="mx-hub">
      <section class="mx-hub__intro">
        <div class="mx-hub__eyebrow"><span></span> MODULE X / DIGITAL PROCESS</div>
        <h2>讓每一次協作<br><strong>都留下清晰軌跡</strong></h2>
        <p>從需求、研發、製造到客戶回饋，在同一個工作空間掌握決策、責任與交付節奏。</p>

        <div class="mx-hub__actions">
          <a href="/projects" class="mx-hub-button mx-hub-button--primary">進入專案清單</a>
          <a href="/my/page" class="mx-hub-button mx-hub-button--secondary">我的工作台</a>
          <a href="/dmsf" class="mx-hub-button mx-hub-button--secondary">文件管理中心</a>
        </div>

        <div class="mx-hub__principles">
          <span><b>FLOW</b> 流程透明</span>
          <span><b>TRACE</b> 全程可追溯</span>
          <span><b>ALIGN</b> 跨團隊對齊</span>
        </div>
      </section>

      <section class="mx-network" aria-label="Module X process network">
        <header class="mx-network__header">
          <div><span class="mx-live-dot"></span> PROCESS NETWORK</div>
          <small>4 ACTIVE DOMAINS</small>
        </header>

        <div class="mx-network__canvas">
          <svg class="mx-network__lines" viewBox="0 0 100 100" preserveAspectRatio="none" aria-hidden="true">
            <line x1="50" y1="50" x2="22" y2="22"></line>
            <line x1="50" y1="50" x2="78" y2="22"></line>
            <line x1="50" y1="50" x2="22" y2="78"></line>
            <line x1="50" y1="50" x2="78" y2="78"></line>
          </svg>

          <a href="/projects" class="mx-domain mx-domain--rd">
            <span class="mx-domain__code">RD</span>
            <span><strong>產品研發</strong><small>R&amp;D / 設計與變更管理</small></span>
          </a>
          <a href="/projects" class="mx-domain mx-domain--service">
            <span class="mx-domain__code">CS</span>
            <span><strong>客戶服務</strong><small>SERVICE / 售後與客戶回饋</small></span>
          </a>
          <a href="/projects" class="mx-domain mx-domain--mfg">
            <span class="mx-domain__code">MF</span>
            <span><strong>生產製造</strong><small>MFG / 製程與品質追蹤</small></span>
          </a>
          <a href="/projects" class="mx-domain mx-domain--sales">
            <span class="mx-domain__code">SL</span>
            <span><strong>銷售推廣</strong><small>SALES / 訂單與市場預測</small></span>
          </a>

          <div class="mx-network__core" aria-hidden="true">
            <span>MX</span>
            <small>CORE</small>
          </div>
        </div>
      </section>

      <footer class="mx-hub__status">
        <span><i class="mx-live-dot"></i> SYSTEM ONLINE</span>
        <span>REGION / AP-NORTHEAST</span>
        <span>WORKSPACE / MODULE X</span>
        <time class="mx-hub-clock"></time>
      </footer>
    </main>`;

  $('#content').html(homeHubHtml);
});
