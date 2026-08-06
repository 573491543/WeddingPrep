// ==================== pages.js ====================
// 6 个页面渲染：首页 / 时间规划 / 预算 / 商家 / 物资 / 提醒

const Pages = {

  // ====== 首页 ======
  home() {
    const profile = DB.getProfile();
    const weddingDate = profile ? profile.weddingDate : null;
    const daysLeft = weddingDate ? DateHelper.daysUntilWedding(weddingDate) : 0;
    const tasks = DB.getTasks();
    const expenses = DB.getExpenses();
    const totalBudget = profile ? profile.totalBudget : 0;
    const totalPaid = expenses.filter(e => e.isPaid).reduce((s, e) => s + e.amount, 0);

    // Task stats
    const completed = tasks.filter(t => t.isCompleted).length;
    const overdue = tasks.filter(t => !t.isCompleted && weddingDate && DateHelper.daysFromToday(DateHelper.dueDate(weddingDate, t.daysBeforeWedding)) < 0).length;
    const pending = tasks.length - completed - overdue;

    return `
      <!-- Countdown Card -->
      <div class="card countdown-card" onclick="Forms.editWedding()">
        <div class="countdown-num">${daysLeft > 0 ? daysLeft : daysLeft === 0 ? '今天' : '已过'}</div>
        <div class="countdown-label">${daysLeft > 0 ? '距离婚礼还有' : daysLeft === 0 ? '婚礼日' : '婚礼已过'}</div>
        ${weddingDate ? `<div class="countdown-date">${DateHelper.formatChineseDate(weddingDate)}</div>` : '<div class="countdown-date">点击设置婚礼日期</div>'}
      </div>

      <!-- Quick Actions -->
      <div class="section">
        <div class="section-title">快捷操作</div>
        <div class="quick-grid">
          <button class="quick-btn" onclick="App.quickAction('task')">
            <div class="quick-icon" style="background:rgba(232,160,191,0.15)">📝</div>
            <span class="quick-label">新增任务</span>
          </button>
          <button class="quick-btn" onclick="App.quickAction('expense')">
            <div class="quick-icon" style="background:rgba(125,206,160,0.15)">💰</div>
            <span class="quick-label">新增支出</span>
          </button>
          <button class="quick-btn" onclick="App.quickAction('vendor')">
            <div class="quick-icon" style="background:rgba(133,193,226,0.15)">🏪</div>
            <span class="quick-label">新增商家</span>
          </button>
          <button class="quick-btn" onclick="App.quickAction('material')">
            <div class="quick-icon" style="background:rgba(247,220,111,0.15)">📋</div>
            <span class="quick-label">新增物资</span>
          </button>
        </div>
      </div>

      <!-- Task Progress -->
      <div class="section">
        <div class="section-title">任务进度</div>
        <div class="card">
          ${UI.ringChart([
            { label: '已完成', value: completed, color: '#7DCEA0' },
            { label: '进行中', value: pending, color: '#E8A0BF' },
            { label: '已逾期', value: overdue, color: '#E74C3C' },
          ], `${completed}/${tasks.length}`, '已完成')}
        </div>
      </div>

      <!-- Budget Overview -->
      <div class="section">
        <div class="section-title">预算概览</div>
        <div class="card">
          <div style="display:flex;justify-content:space-between;margin-bottom:8px">
            <span class="fs-14 text-secondary">总预算</span>
            <span class="fw-600">${DateHelper.formatCurrency(totalBudget)}</span>
          </div>
          <div style="display:flex;justify-content:space-between;margin-bottom:8px">
            <span class="fs-14 text-secondary">已支出</span>
            <span class="fw-600 text-danger">${DateHelper.formatCurrency(totalPaid)}</span>
          </div>
          <div style="display:flex;justify-content:space-between;margin-bottom:12px">
            <span class="fs-14 text-secondary">剩余</span>
            <span class="fw-600 text-success">${DateHelper.formatCurrency(totalBudget - totalPaid)}</span>
          </div>
          ${UI.progressBar(totalBudget > 0 ? (totalPaid / totalBudget * 100) : 0, 'var(--danger)')}
          <div class="text-center mt-8 fs-12 text-secondary">${DateHelper.formatPercent(totalPaid, totalBudget)} 已使用</div>
        </div>
      </div>

      <!-- Data Backup -->
      <div class="section">
        <div class="section-title">数据管理</div>
        <div class="card">
          <button class="btn btn-outline btn-block" onclick="Forms.backup()">📤 导出备份</button>
          <div style="height:8px"></div>
          <button class="btn btn-outline btn-block" onclick="Forms.importBackup()">📥 导入备份</button>
        </div>
      </div>
    `;
  },

  // ====== 时间规划 ======
  timeplan(state = {}) {
    const profile = DB.getProfile();
    const weddingDate = profile ? profile.weddingDate : null;
    const tasks = DB.getTasks();
    const search = state.search || '';
    const stageIdx = state.stageIdx || 0;

    // Filter
    let filtered = tasks;
    if (search) {
      const s = search.toLowerCase();
      filtered = filtered.filter(t => t.title.toLowerCase().includes(s) || (t.notes || '').toLowerCase().includes(s) || t.category.includes(s));
    }
    if (stageIdx > 0) {
      const stage = Enums.TaskStage[stageIdx - 1].value;
      filtered = filtered.filter(t => t.stage === stage);
    }

    // Sort by daysBeforeWedding desc
    filtered.sort((a, b) => b.daysBeforeWedding - a.daysBeforeWedding);

    const completed = tasks.filter(t => t.isCompleted).length;
    const stages = ['全部', ...Enums.TaskStage.map(s => s.value)];

    return `
      <!-- Stats -->
      <div class="stat-grid" style="grid-template-columns:repeat(3,1fr);padding:0 4px;margin-bottom:12px">
        <div class="stat-item"><div class="stat-num">${tasks.length}</div><div class="stat-label">总任务</div></div>
        <div class="stat-item"><div class="stat-num text-success">${completed}</div><div class="stat-label">已完成</div></div>
        <div class="stat-item"><div class="stat-num text-danger">${tasks.length - completed}</div><div class="stat-label">待完成</div></div>
      </div>

      ${UI.searchBar('搜索任务...', search, v => App.render('timeplan', { search: v, stageIdx }))}
      ${UI.chipRow(stages, stageIdx, i => App.render('timeplan', { search, stageIdx: i }))}

      <div class="section mt-12">
        ${filtered.length === 0 ? UI.emptyState('📝', '没有找到任务') : filtered.map(t => Pages._taskRow(t, weddingDate)).join('')}
      </div>
      ${UI.fab(() => Forms.editTask(), '+')}
    `;
  },

  _taskRow(task, weddingDate) {
    const due = weddingDate ? DateHelper.dueDate(weddingDate, task.daysBeforeWedding) : null;
    const days = due ? DateHelper.daysFromToday(due) : 0;
    const isOverdue = !task.isCompleted && days < 0;
    const prio = Enums.Priority[task.priority] || Enums.Priority[1];
    const dueText = due ? (days > 0 ? `${days}天后` : days === 0 ? '今天' : `逾期${-days}天`) : '';

    return `
      <div class="task-row ${isOverdue ? 'overdue' : ''}" onclick="Forms.editTask('${task.id}')">
        <div class="checkbox ${task.isCompleted ? 'checked' : ''}" onclick="event.stopPropagation(); App.toggleTask('${task.id}')">${task.isCompleted ? '✓' : ''}</div>
        <div class="task-content">
          <div class="task-title ${task.isCompleted ? 'done' : ''}">${task.title}</div>
          <div class="task-meta">
            <span style="display:inline-block;width:8px;height:8px;border-radius:50%;background:${prio.color}"></span>
            ${dueText ? UI.tag(dueText, isOverdue ? '#E74C3C' : '#E8A0BF') : ''}
            ${UI.tag(task.stage)}
            ${UI.tag(task.category)}
          </div>
        </div>
      </div>`;
  },

  // ====== 预算管理 ======
  budget() {
    const profile = DB.getProfile();
    const totalBudget = profile ? profile.totalBudget : 0;
    const expenses = DB.getExpenses();
    const categories = DB.getCategories().sort((a, b) => a.order - b.order);

    const totalPaid = expenses.filter(e => e.isPaid).reduce((s, e) => s + e.amount, 0);
    const totalUnpaid = expenses.filter(e => !e.isPaid).reduce((s, e) => s + e.amount, 0);
    const remaining = totalBudget - totalPaid;

    // Category breakdown
    const catSpent = {};
    expenses.forEach(e => { catSpent[e.categoryName] = (catSpent[e.categoryName] || 0) + e.amount; });

    const ringSegments = categories.map(c => ({
      label: c.name, value: catSpent[c.name] || 0, color: c.colorHex,
    })).filter(s => s.value > 0);

    return `
      <!-- Budget Overview -->
      <div class="card">
        <div style="display:flex;justify-content:space-between;margin-bottom:6px"><span class="text-secondary fs-14">总预算</span><span class="fw-700">${DateHelper.formatCurrency(totalBudget)}</span></div>
        <div style="display:flex;justify-content:space-between;margin-bottom:6px"><span class="text-secondary fs-14">已支出</span><span class="fw-600 text-danger">${DateHelper.formatCurrency(totalPaid)}</span></div>
        <div style="display:flex;justify-content:space-between;margin-bottom:6px"><span class="text-secondary fs-14">未付</span><span class="fw-600" style="color:var(--warning)">${DateHelper.formatCurrency(totalUnpaid)}</span></div>
        <div style="display:flex;justify-content:space-between;margin-bottom:12px"><span class="text-secondary fs-14">剩余</span><span class="fw-600 text-success">${DateHelper.formatCurrency(remaining)}</span></div>
        ${UI.progressBar(totalBudget > 0 ? (totalPaid / totalBudget * 100) : 0, 'var(--danger)')}
        <div class="text-center mt-8 fs-12 text-secondary">${DateHelper.formatPercent(totalPaid, totalBudget)} · ${expenses.length} 笔支出</div>
      </div>

      ${ringSegments.length > 0 ? `
      <!-- Category Breakdown -->
      <div class="section">
        <div class="section-title">分类占比</div>
        <div class="card">
          ${UI.ringChart(ringSegments, DateHelper.formatCurrency(totalPaid), '已支出')}
        </div>
      </div>` : ''}

      <!-- Category Ledger -->
      <div class="section">
        <div class="section-title">分类台账</div>
        ${categories.map(c => {
          const spent = catSpent[c.name] || 0;
          const pct = c.budgetLimit > 0 ? (spent / c.budgetLimit * 100) : 0;
          const over = spent > c.budgetLimit;
          return `
            <div class="card budget-cat-row" onclick="Forms.editCategory('${c.id}')">
              <div class="budget-cat-header">
                <span class="budget-cat-name">${c.name}</span>
                <span class="budget-cat-amount">${DateHelper.formatCurrency(spent)} / ${DateHelper.formatCurrency(c.budgetLimit)}</span>
              </div>
              ${UI.progressBar(pct, over ? 'var(--danger)' : c.colorHex)}
              <div class="mt-8 flex" style="justify-content:space-between">
                <span class="fs-12 text-secondary">${DateHelper.formatPercent(spent, c.budgetLimit)}</span>
                ${over ? `<span class="fs-12 text-danger">超支 ${DateHelper.formatCurrency(spent - c.budgetLimit)}</span>` : `<span class="fs-12 text-success">剩 ${DateHelper.formatCurrency(c.budgetLimit - spent)}</span>`}
              </div>
            </div>`;
        }).join('')}
      </div>

      <!-- Recent Expenses -->
      <div class="section">
        <div class="section-title">支出记录</div>
        ${expenses.length === 0 ? UI.emptyState('💰', '暂无支出记录') : expenses.slice().reverse().map(e => `
          <div class="card" onclick="Forms.editExpense('${e.id}')">
            <div class="flex" style="justify-content:space-between;align-items:center">
              <div>
                <span class="fw-600">${e.categoryName}</span>
                ${e.vendorName ? `<span class="fs-12 text-secondary"> · ${e.vendorName}</span>` : ''}
              </div>
              <span class="fw-700 ${e.isPaid ? 'text-danger' : ''}" style="color:${e.isPaid ? 'var(--danger)' : 'var(--warning)'}">${DateHelper.formatCurrency(e.amount)}</span>
            </div>
            <div class="mt-8 flex gap-8">
              ${UI.tag(e.isPaid ? '已付' : '未付', e.isPaid ? '#7DCEA0' : '#F7DC6F')}
              ${e.note ? `<span class="fs-12 text-secondary">${e.note}</span>` : ''}
            </div>
          </div>
        `).join('')}
      </div>
      ${UI.fab(() => Forms.editExpense(), '+')}
    `;
  },

  // ====== 商家资源 ======
  vendor(state = {}) {
    const vendors = DB.getVendors();
    const search = state.search || '';
    const typeIdx = state.typeIdx || 0;

    let filtered = vendors;
    if (search) {
      const s = search.toLowerCase();
      filtered = filtered.filter(v => v.name.toLowerCase().includes(s) || (v.notes || '').toLowerCase().includes(s));
    }
    if (typeIdx > 0) {
      const type = Enums.VendorServiceType[typeIdx - 1];
      filtered = filtered.filter(v => v.serviceType === type);
    }

    const types = ['全部', ...Enums.VendorServiceType];

    return `
      ${UI.searchBar('搜索商家...', search, v => App.render('vendor', { search: v, typeIdx }))}
      ${UI.chipRow(types, typeIdx, i => App.render('vendor', { search, typeIdx: i }))}

      <div class="section mt-12">
        ${filtered.length === 0 ? UI.emptyState('🏪', '暂无商家') : filtered.map(v => {
          const status = Enums.VendorStatus.find(s => s.value === v.status) || Enums.VendorStatus[1];
          return `
            <div class="vendor-card" onclick="Forms.editVendor('${v.id}')">
              <div class="vendor-name">${v.name}</div>
              <div class="vendor-meta">
                ${UI.tag(v.serviceType)}
                ${UI.tag(v.status, status.color)}
                ${v.price ? `<span class="fs-13 fw-600">${DateHelper.formatCurrency(v.price)}</span>` : ''}
              </div>
              ${v.notes ? `<div class="mt-8 fs-12 text-secondary">${v.notes}</div>` : ''}
            </div>`;
        }).join('')}
      </div>
      ${UI.fab(() => Forms.editVendor(), '+')}
    `;
  },

  // ====== 物资清单 ======
  material(state = {}) {
    const materials = DB.getMaterials();
    const listType = state.listType || '采购物资清单';
    const search = state.search || '';
    const catIdx = state.catIdx || 0;

    let filtered = materials.filter(m => m.listType === listType);
    if (search) {
      const s = search.toLowerCase();
      filtered = filtered.filter(m => m.name.toLowerCase().includes(s));
    }
    if (catIdx > 0) {
      const cat = Enums.MaterialCategory[catIdx - 1];
      filtered = filtered.filter(m => m.category === cat);
    }

    const purchased = filtered.filter(m => m.status === '已采购').length;
    const totalCost = filtered.filter(m => m.status === '已采购').reduce((s, m) => s + m.price * m.quantity, 0);
    const pendingCost = filtered.filter(m => m.status !== '已采购').reduce((s, m) => s + m.price * m.quantity, 0);

    const cats = ['全部', ...Enums.MaterialCategory];

    return `
      <!-- Tab Switch -->
      <div class="chip-row mb-12">
        <button class="chip ${listType === '采购物资清单' ? 'active' : ''}" onclick="App.render('material',{listType:'采购物资清单'})">采购物资清单</button>
        <button class="chip ${listType === '当日随身物品' ? 'active' : ''}" onclick="App.render('material',{listType:'当日随身物品'})">当日随身物品</button>
      </div>

      <!-- Progress -->
      <div class="card">
        <div class="flex" style="justify-content:space-between;margin-bottom:8px">
          <span class="fs-14">共 ${filtered.length} 项 · 待完成 ${filtered.length - purchased} 项</span>
          <span class="fs-14 text-secondary">${DateHelper.formatCurrency(totalCost + pendingCost)}</span>
        </div>
        ${UI.progressBar(filtered.length > 0 ? (purchased / filtered.length * 100) : 0, 'var(--success)')}
        <div class="text-center mt-8 fs-12 text-secondary">已采购 ${DateHelper.formatCurrency(totalCost)} · 待采购 ${DateHelper.formatCurrency(pendingCost)}</div>
      </div>

      ${UI.searchBar('搜索物资...', search, v => App.render('material', { listType, search: v, catIdx }))}
      ${UI.chipRow(cats, catIdx, i => App.render('material', { listType, search, catIdx: i }))}

      <div class="section mt-12">
        ${filtered.length === 0 ? UI.emptyState('📋', '暂无物资') : filtered.map(m => {
          const status = Enums.MaterialStatus.find(s => s.value === m.status) || Enums.MaterialStatus[0];
          return `
            <div class="material-row" onclick="Forms.editMaterial('${m.id}')">
              <div class="checkbox ${m.status === '已采购' ? 'checked' : ''}" onclick="event.stopPropagation(); App.toggleMaterial('${m.id}')">${m.status === '已采购' ? '✓' : ''}</div>
              <div style="flex:1;min-width:0">
                <div class="fw-600">${m.name}</div>
                <div class="task-meta">
                  ${UI.tag(m.category)}
                  ${UI.tag(m.channel)}
                  ${UI.tag(m.status, status.color)}
                </div>
              </div>
              <div class="text-right">
                <div class="fw-600">${DateHelper.formatCurrency(m.price * m.quantity)}</div>
                <div class="fs-12 text-secondary">${m.price} × ${m.quantity}</div>
              </div>
            </div>`;
        }).join('')}
      </div>
      ${UI.fab(() => Forms.editMaterial(), '+')}
    `;
  },

  // ====== 提醒中心 ======
  reminder() {
    const profile = DB.getProfile();
    const weddingDate = profile ? profile.weddingDate : null;
    const tasks = DB.getTasks().filter(t => !t.isCompleted);

    const pending = [];
    const overdue = [];
    tasks.forEach(t => {
      if (!weddingDate) return;
      const due = DateHelper.dueDate(weddingDate, t.daysBeforeWedding);
      const days = DateHelper.daysFromToday(due);
      if (days < 0) overdue.push({ ...t, due, days });
      else pending.push({ ...t, due, days });
    });

    pending.sort((a, b) => a.days - b.days);
    overdue.sort((a, b) => b.days - a.days);

    // Group pending
    const groups = { '本周内': [], '本月内': [], '更远': [] };
    pending.forEach(t => { groups[DateHelper.timeGroup(t.due)]?.push(t); });

    return `
      <!-- Stats -->
      <div class="stat-grid" style="grid-template-columns:repeat(3,1fr);margin-bottom:16px">
        <div class="stat-item"><div class="stat-num text-primary">${pending.length}</div><div class="stat-label">待提醒</div></div>
        <div class="stat-item"><div class="stat-num text-danger">${overdue.length}</div><div class="stat-label">已逾期</div></div>
        <div class="stat-item"><div class="stat-num text-secondary">${DB.getTasks().filter(t=>t.isCompleted).length}</div><div class="stat-label">已完成</div></div>
      </div>

      ${overdue.length > 0 ? `
      <div class="reminder-section">
        <div class="reminder-section-header" style="color:var(--danger)">已逾期</div>
        ${overdue.map(t => Pages._reminderRow(t)).join('')}
      </div>` : ''}

      ${Object.entries(groups).map(([name, items]) => items.length > 0 ? `
      <div class="reminder-section">
        <div class="reminder-section-header">${name}</div>
        ${items.map(t => Pages._reminderRow(t)).join('')}
      </div>` : '').join('')}

      ${pending.length === 0 && overdue.length === 0 ? UI.emptyState('🎉', '暂无待提醒事项') : ''}
    `;
  },

  _reminderRow(t) {
    const prio = Enums.Priority[t.priority] || Enums.Priority[1];
    return `
      <div class="card" onclick="Forms.editTask('${t.id}')">
        <div class="flex" style="justify-content:space-between;align-items:center">
          <span class="fw-600">${t.title}</span>
          <span style="display:inline-block;width:8px;height:8px;border-radius:50%;background:${prio.color}"></span>
        </div>
        <div class="task-meta mt-8">
          ${UI.tag(t.days < 0 ? `逾期${-t.days}天` : t.days === 0 ? '今天' : `${t.days}天后`, t.days < 0 ? '#E74C3C' : '#E8A0BF')}
          ${UI.tag(DateHelper.formatChineseDate(t.due))}
          ${t.reminderDaysBefore > 0 ? UI.tag(`提前${t.reminderDaysBefore}天`) : ''}
          ${UI.tag(t.category)}
        </div>
      </div>`;
  },
};
