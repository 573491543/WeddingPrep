// ==================== components.js ====================
// 可复用 UI 组件：环形图、进度条、标签、模态框等

const UI = {

  // ====== Ring Chart (Canvas) ======
  ringChart(segments, centerNum, centerLabel) {
    const total = segments.reduce((s, seg) => s + seg.value, 0) || 1;
    const colors = segments.map(s => s.color);
    const values = segments.map(s => s.value);
    const id = 'ring_' + Math.random().toString(36).slice(2, 9);
    return `
      <div class="ring-chart-container">
        <div class="ring-chart">
          <canvas id="${id}" width="120" height="120"></canvas>
          <div class="ring-center">
            <div class="ring-center-num">${centerNum}</div>
            <div class="ring-center-label">${centerLabel}</div>
          </div>
        </div>
        <div class="ring-legend">
          ${segments.map(s => `
            <div class="legend-item">
              <span class="legend-dot" style="background:${s.color}"></span>
              <span>${s.label}</span>
              <span class="text-secondary">${s.value}</span>
            </div>
          `).join('')}
        </div>
      </div>
      <script>
        (function() {
          const cv = document.getElementById('${id}');
          if (!cv) return;
          const ctx = cv.getContext('2d');
          const cx = 60, cy = 60, r = 45, lw = 12;
          const total = ${total};
          const segs = ${JSON.stringify(values)};
          const cols = ${JSON.stringify(colors)};
          let angle = -Math.PI / 2;
          ctx.clearRect(0, 0, 120, 120);
          // Background ring
          ctx.beginPath();
          ctx.arc(cx, cy, r, 0, Math.PI * 2);
          ctx.strokeStyle = 'rgba(0,0,0,0.05)';
          ctx.lineWidth = lw;
          ctx.stroke();
          // Segments
          segs.forEach((val, i) => {
            if (val <= 0) return;
            const arc = (val / total) * Math.PI * 2;
            ctx.beginPath();
            ctx.arc(cx, cy, r, angle, angle + arc);
            ctx.strokeStyle = cols[i];
            ctx.lineWidth = lw;
            ctx.lineCap = 'round';
            ctx.stroke();
            angle += arc;
          });
        })();
      </script>`;
  },

  // ====== Progress Bar ======
  progressBar(percent, color) {
    const pct = Math.min(100, Math.max(0, percent || 0));
    const c = color || 'var(--primary)';
    return `<div class="progress-bar"><div class="progress-fill" style="width:${pct}%;background:${c}"></div></div>`;
  },

  // ====== Tag ======
  tag(text, color) {
    const map = { '绿': 'tag-green', '黄': 'tag-yellow', '红': 'tag-red', '蓝': 'tag-blue', '粉': 'tag-pink', '灰': 'tag-gray' };
    let cls = 'tag-gray';
    for (const k in map) if (text.includes(k)) cls = map[k];
    if (color) {
      if (color.includes('#7DCE') || color.includes('green')) cls = 'tag-green';
      else if (color.includes('#F7DC') || color.includes('yellow')) cls = 'tag-yellow';
      else if (color.includes('#E74C') || color.includes('red')) cls = 'tag-red';
      else if (color.includes('#85C1') || color.includes('blue')) cls = 'tag-blue';
      else if (color.includes('#E8A0') || color.includes('pink')) cls = 'tag-pink';
    }
    return `<span class="tag ${cls}">${text}</span>`;
  },

  // ====== Search Bar ======
  searchBar(placeholder, value, onInput) {
    const id = 'search_' + Math.random().toString(36).slice(2, 9);
    setTimeout(() => {
      const el = document.getElementById(id);
      if (el) el.addEventListener('input', e => onInput(e.target.value));
    }, 0);
    return `<div class="search-bar"><span>🔍</span><input id="${id}" type="text" placeholder="${placeholder}" value="${value || ''}"></div>`;
  },

  // ====== Filter Chips ======
  chipRow(chips, activeIndex, onSelect) {
    const id = 'chips_' + Math.random().toString(36).slice(2, 9);
    setTimeout(() => {
      document.querySelectorAll(`#${id} .chip`).forEach((el, i) => {
        el.addEventListener('click', () => onSelect(i));
      });
    }, 0);
    return `<div class="chip-row" id="${id}">${chips.map((c, i) => `<button class="chip ${i === activeIndex ? 'active' : ''}">${c}</button>`).join('')}</div>`;
  },

  // ====== Empty State ======
  emptyState(icon, text) {
    return `<div class="empty-state"><div class="empty-state-icon">${icon}</div><div class="empty-state-text">${text}</div></div>`;
  },

  // ====== FAB ======
  fab(onClick, icon) {
    setTimeout(() => {
      const fab = document.getElementById('app-fab');
      if (fab) fab.onclick = onClick;
    }, 0);
    return `<button class="fab" id="app-fab">${icon || '+'}</button>`;
  },

  // ====== Modal/Sheet ======
  showSheet(title, bodyHTML) {
    const container = document.getElementById('modal-container');
    container.innerHTML = `
      <div class="modal-overlay" id="modal-overlay">
        <div class="modal-sheet">
          <div class="modal-header">
            <div class="modal-title">${title}</div>
            <button class="modal-close" onclick="UI.closeSheet()">×</button>
          </div>
          <div id="modal-body">${bodyHTML}</div>
        </div>
      </div>`;
    container.classList.add('show');
    document.getElementById('modal-overlay').addEventListener('click', e => {
      if (e.target.id === 'modal-overlay') UI.closeSheet();
    });
  },
  closeSheet() {
    const container = document.getElementById('modal-container');
    container.classList.remove('show');
    container.innerHTML = '';
  },

  // ====== Toast ======
  toast(msg) {
    const t = document.createElement('div');
    t.style.cssText = 'position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);background:rgba(0,0,0,0.7);color:#fff;padding:12px 24px;border-radius:12px;z-index:9999;font-size:14px;pointer-events:none;transition:opacity 0.3s';
    t.textContent = msg;
    document.body.appendChild(t);
    setTimeout(() => { t.style.opacity = '0'; setTimeout(() => t.remove(), 300); }, 1500);
  },

  // ====== Confirm Dialog ======
  confirm(msg, onConfirm) {
    this.showSheet('确认', `
      <p style="margin-bottom:20px;font-size:15px;line-height:1.5">${msg}</p>
      <div style="display:flex;gap:12px">
        <button class="btn btn-outline btn-block" onclick="UI.closeSheet()">取消</button>
        <button class="btn btn-danger btn-block" id="confirm-yes">确定</button>
      </div>`);
    setTimeout(() => {
      document.getElementById('confirm-yes').onclick = () => { UI.closeSheet(); onConfirm(); };
    }, 0);
  },
};
