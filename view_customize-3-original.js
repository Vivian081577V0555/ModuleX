$(function() {
  var logoUrl = "http://localhost:8080/dmsf/files/1/view";

  var homeHubHtml = `
    <div id="ultimate-hub">
      <div class="visual-concept">
        <div class="logo-core">
          <img src="${logoUrl}" alt="Module X">
          <div class="core-tag">核心中樞</div>
        </div>
        
        <div class="concept-node node-rd">
          <div class="node-icon">🎨</div>
          <div class="node-text"><h3>產品研發 (R&D)</h3><p>設計與變更管理</p></div>
        </div>
        <div class="concept-node node-service">
          <div class="node-icon">🎧</div>
          <div class="node-text"><h3>客戶服務 (Service)</h3><p>售後與客戶回饋</p></div>
        </div>
        <div class="concept-node node-mfg">
          <div class="node-icon">🏭</div>
          <div class="node-text"><h3>生產製造 (MFG)</h3><p>製程與品質追蹤</p></div>
        </div>
        <div class="concept-node node-sales">
          <div class="node-icon">💰</div>
          <div class="node-text"><h3>銷售推廣 (Sales)</h3><p>訂單與市場預測</p></div>
        </div>

        <svg class="connecting-lines">
          <line x1="50%" y1="50%" x2="25%" y2="28%" />
          <line x1="50%" y1="50%" x2="75%" y2="28%" />
          <line x1="50%" y1="50%" x2="25%" y2="72%" />
          <line x1="50%" y1="50%" x2="75%" y2="72%" />
        </svg>
      </div>

      <div class="quick-nav">
        <a href="/projects" class="nav-btn">進入專案清單</a>
        <a href="/my/page" class="nav-btn">我的工作台</a>
        <a href="/dmsf" class="nav-btn">文件管理中心</a>
      </div>
    </div>

    <style>
      #header { 
        height: 110px !important; /* 稍微縮小標頭高度 */
        background: #2b3a4a !important; 
        display: flex !important;
        flex-direction: column !important;
        justify-content: center !important;
        align-items: center !important;
      }
      #quick-search, #header .project-selector, #header #main-menu, .nosidebar #main, #header h1 a { display: none !important; }

      #header h1 { display: flex !important; flex-direction: column !important; align-items: center !important; color: #fff !important; }
      #header h1::before { content: "Module X Digital Process"; font-size: 32px !important; font-weight: 800 !important; letter-spacing: 2px !important; }
      #header h1::after { content: "產品全生命週期數位化整合平台"; font-size: 16px !important; color: rgba(255,255,255,0.7) !important; }

      html, body, #wrapper, #main, #content { overflow: hidden !important; height: 100vh !important; margin: 0 !important; padding: 0 !important; }

      #ultimate-hub {
        width: 100%; 
        height: calc(100vh - 110px);
        display: flex; 
        flex-direction: column; 
        justify-content: flex-start; /* 改為從頂部開始排列，由 margin 控制間距 */
        align-items: center;
        background: radial-gradient(circle, #ffffff 0%, #f9fbfd 100%);
        padding: 20px 0; /* 減少頂部內縮，讓內容上移 */
        box-sizing: border-box;
      }

      .visual-concept { 
        position: relative; 
        width: 1000px; 
        height: 440px; /* 稍微壓縮圖形高度 */
        margin-top: 20px; /* 控制圖形與標頭的距離 */
        flex-shrink: 0; 
      }

      .logo-core {
        position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%);
        background: white; padding: 10px; /* 保持緊湊 */
        border-radius: 50%; z-index: 10;
        box-shadow: 0 15px 50px rgba(0,0,0,0.12); border: 8px solid #fff;
        display: flex; flex-direction: column; align-items: center; justify-content: center;
      }
      .logo-core img { width: 310px; display: block; } /* 保持霸氣大 Logo */
      .core-tag { margin-top: 5px; color: #0066cc; font-weight: bold; font-size: 16px; text-align:center; }

      .concept-node {
        position: absolute; width: 300px; background: white; border-radius: 15px;
        padding: 18px; display: flex; align-items: center;
        box-shadow: 0 10px 30px rgba(0,0,0,0.06); border: 1px solid #f0f0f0;
      }
      .node-icon { font-size: 36px; margin-right: 12px; }
      .node-text h3 { margin: 0; color: #222; font-size: 19px; font-weight: 800; }
      .node-text p { margin: 3px 0 0; color: #777; font-size: 13px; }

      /* 調整節點垂直分佈，讓整體更往中間靠攏 */
      .node-rd { top: 5%; left: 0; border-top: 6px solid #3498db; }
      .node-service { top: 5%; right: 0; border-top: 6px solid #e74c3c; }
      .node-mfg { bottom: 5%; left: 0; border-top: 6px solid #f1c40f; }
      .node-sales { bottom: 5%; right: 5%; border-top: 6px solid #2ecc71; }

      .connecting-lines { position: absolute; width: 100%; height: 100%; top: 0; left: 0; stroke: #d9e2ec; stroke-width: 2; stroke-dasharray: 8; z-index: 1; }

      /* 按鈕區調整：增加上方間距，遠離底邊 */
      .quick-nav { 
        margin-top: auto; /* 推到底部 */
        margin-bottom: 40px; /* 增加與螢幕底部的距離 */
        display: flex; 
        gap: 30px; 
        flex-shrink: 0; 
      }
      .nav-btn { 
        padding: 15px 45px; 
        background: #004a80; 
        color: white !important; 
        text-decoration: none !important; 
        border-radius: 50px; 
        font-weight: bold; 
        font-size: 17px; 
        box-shadow: 0 6px 15px rgba(0,0,0,0.1); 
      }
      .nav-btn:hover { background: #0066cc; transform: translateY(-2px); }
    </style>
  `;

  $('#content').html(homeHubHtml);
});