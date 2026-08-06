// ==================== forms.js ====================
// 编辑表单：婚礼信息 / 任务 / 支出 / 商家 / 物资 / 备份

const Forms = {

  // ====== 编辑婚礼信息 ======
  editWedding() {
    const p = DB.getProfile() || { weddingDate: new Date(Date.now() + 9*30*86400000).toISOString(), brideName: '', groomName: '', totalBudget: 100000 };
    const dateVal = DateHelper.toInputDate(p.weddingDate);
    UI.showSheet('编辑婚礼信息', `
      <div class="form-group">
        <label class="form-label">婚礼日期</label>
        <input class="form-input" type="date" id="f-weddingDate" value="${dateVal}">
      </div>
      <div class="form-row">
        <div class="form-group">
          <label class="form-label">新娘姓名</label>
          <input class="form-input" type="text" id="f-brideName" value="${p.brideName || ''}" placeholder="新娘">
        </div>
        <div class="form-group">
          <label class="form-label">新郎姓名</label>
          <input class="form-input" type="text" id="f-groomName" value="${p.groomName || ''}" placeholder="新郎">
        </div>
      </div>
      <div class="form-group">
        <label class="form-label">总预算（元）</label>
        <input class="form-input" type="number" id="f-totalBudget" value="${p.totalBudget || 0}" min="0" step="1000">
      </div>
      <button class="btn btn-primary btn-block" onclick="Forms._saveWedding()">保存</button>
    `);
  },
  _saveWedding() {
    const dateStr = document.getElementById('f-weddingDate').value;
    if (!dateStr) { UI.toast('请选择婚礼日期'); return; }
    DB.saveProfile({
      id: DB.getProfile()?.id,
      weddingDate: new Date(dateStr + 'T12:00:00').toISOString(),
      brideName: document.getElementById('f-brideName').value,
      groomName: document.getElementById('f-groomName').value,
      totalBudget: parseFloat(document.getElementById('f-totalBudget').value) || 0,
    });
    UI.closeSheet(); UI.toast('保存成功'); App.refresh();
  },

  // ====== 编辑任务 ======
  editTask(id) {
    const t = id ? DB.getTask(id) : { title: '', stage: '婚前1个月', category: '其他', type: '任务', daysBeforeWedding: 30, priority: 1, isCompleted: false, notes: '', reminderDaysBefore: 3 };
    const stages = Enums.TaskStage.map(s => s.value);
    const cats = Enums.TaskCategory;
    const prios = Enums.Priority;
    UI.showSheet(id ? '编辑任务' : '新增任务', `
      <div class="form-group">
        <label class="form-label">任务标题</label>
        <input class="form-input" type="text" id="f-title" value="${t.title || ''}" placeholder="输入任务标题">
      </div>
      <div class="form-row">
        <div class="form-group">
          <label class="form-label">时间节点</label>
          <select class="form-select" id="f-stage">${stages.map(s => `<option ${s === t.stage ? 'selected' : ''}>${s}</option>`).join('')}</select>
        </div>
        <div class="form-group">
          <label class="form-label">距婚礼天数</label>
          <input class="form-input" type="number" id="f-days" value="${t.daysBeforeWedding}" min="0">
        </div>
      </div>
      <div class="form-row">
        <div class="form-group">
          <label class="form-label">类别</label>
          <select class="form-select" id="f-category">${cats.map(c => `<option ${c === t.category ? 'selected' : ''}>${c}</option>`).join('')}</select>
        </div>
        <div class="form-group">
          <label class="form-label">优先级</label>
          <select class="form-select" id="f-priority">${prios.map(p => `<option value="${p.value}" ${p.value === t.priority ? 'selected' : ''}>${p.label}</option>`).join('')}</select>
        </div>
      </div>
      <div class="form-group">
        <label class="form-label">提前提醒天数</label>
        <input class="form-input" type="number" id="f-reminder" value="${t.reminderDaysBefore}" min="0">
      </div>
      <div class="form-group">
        <label class="form-label">备注</label>
        <textarea class="form-textarea" id="f-notes" placeholder="备注信息">${t.notes || ''}</textarea>
      </div>
      <button class="btn btn-primary btn-block" onclick="Forms._saveTask('${id || ''}')">保存</button>
      ${id ? `<div style="height:12px"></div><button class="btn btn-danger btn-block" onclick="Forms._deleteTask('${id}')">删除任务</button>` : ''}
    `);
    // Auto-fill days when stage changes
    document.getElementById('f-stage').onchange = e => {
      const stage = Enums.TaskStage.find(s => s.value === e.target.value);
      if (stage) document.getElementById('f-days').value = stage.days;
    };
  },
  _saveTask(id) {
    const title = document.getElementById('f-title').value.trim();
    if (!title) { UI.toast('请输入任务标题'); return; }
    DB.saveTask({
      id: id || undefined,
      title,
      stage: document.getElementById('f-stage').value,
      category: document.getElementById('f-category').value,
      type: '任务',
      daysBeforeWedding: parseInt(document.getElementById('f-days').value) || 0,
      priority: parseInt(document.getElementById('f-priority').value),
      isCompleted: id ? DB.getTask(id).isCompleted : false,
      notes: document.getElementById('f-notes').value,
      reminderDaysBefore: parseInt(document.getElementById('f-reminder').value) || 0,
    });
    UI.closeSheet(); UI.toast('保存成功'); App.refresh();
  },
  _deleteTask(id) {
    UI.confirm('确定删除这个任务吗？', () => {
      DB.deleteTask(id); UI.closeSheet(); UI.toast('已删除'); App.refresh();
    });
  },

  // ====== 编辑支出 ======
  editExpense(id) {
    const e = id ? DB.getExpenses().find(x => x.id === id) : { amount: 0, categoryName: '', date: new Date().toISOString(), isPaid: false, note: '', vendorName: '' };
    const cats = DB.getCategories().sort((a,b) => a.order - b.order);
    const dateVal = DateHelper.toInputDate(e.date);
    UI.showSheet(id ? '编辑支出' : '新增支出', `
      <div class="form-group">
        <label class="form-label">金额（元）</label>
        <input class="form-input" type="number" id="f-amount" value="${e.amount}" min="0" step="0.01">
      </div>
      <div class="form-group">
        <label class="form-label">分类</label>
        <select class="form-select" id="f-catName">${cats.map(c => `<option ${c.name === e.categoryName ? 'selected' : ''}>${c.name}</option>`).join('')}</select>
      </div>
      <div class="form-row">
        <div class="form-group">
          <label class="form-label">日期</label>
          <input class="form-input" type="date" id="f-date" value="${dateVal}">
        </div>
        <div class="form-group">
          <label class="form-label">付款状态</label>
          <select class="form-select" id="f-isPaid">
            <option value="true" ${e.isPaid ? 'selected' : ''}>已付</option>
            <option value="false" ${!e.isPaid ? 'selected' : ''}>未付</option>
          </select>
        </div>
      </div>
      <div class="form-group">
        <label class="form-label">关联商家（可选）</label>
        <input class="form-input" type="text" id="f-vendorName" value="${e.vendorName || ''}" placeholder="商家名称">
      </div>
      <div class="form-group">
        <label class="form-label">备注</label>
        <textarea class="form-textarea" id="f-note" placeholder="备注">${e.note || ''}</textarea>
      </div>
      <button class="btn btn-primary btn-block" onclick="Forms._saveExpense('${id || ''}')">保存</button>
      ${id ? `<div style="height:12px"></div><button class="btn btn-danger btn-block" onclick="Forms._deleteExpense('${id}')">删除</button>` : ''}
    `);
  },
  _saveExpense(id) {
    const amount = parseFloat(document.getElementById('f-amount').value) || 0;
    if (amount <= 0) { UI.toast('请输入金额'); return; }
    const dateStr = document.getElementById('f-date').value;
    DB.saveExpense({
      id: id || undefined,
      amount,
      categoryName: document.getElementById('f-catName').value,
      date: new Date(dateStr + 'T12:00:00').toISOString(),
      isPaid: document.getElementById('f-isPaid').value === 'true',
      note: document.getElementById('f-note').value,
      vendorName: document.getElementById('f-vendorName').value || null,
    });
    UI.closeSheet(); UI.toast('保存成功'); App.refresh();
  },
  _deleteExpense(id) {
    UI.confirm('确定删除这条支出记录吗？', () => {
      DB.deleteExpense(id); UI.closeSheet(); UI.toast('已删除'); App.refresh();
    });
  },

  // ====== 编辑分类预算 ======
  editCategory(id) {
    const c = DB.getCategories().find(x => x.id === id);
    if (!c) return;
    UI.showSheet(`设置 ${c.name} 预算`, `
      <div class="form-group">
        <label class="form-label">预算上限（元）</label>
        <input class="form-input" type="number" id="f-limit" value="${c.budgetLimit}" min="0" step="100">
      </div>
      <button class="btn btn-primary btn-block" onclick="Forms._saveCategory('${id}')">保存</button>
    `);
  },
  _saveCategory(id) {
    const c = DB.getCategories().find(x => x.id === id);
    c.budgetLimit = parseFloat(document.getElementById('f-limit').value) || 0;
    DB.saveCategory(c); UI.closeSheet(); UI.toast('保存成功'); App.refresh();
  },

  // ====== 编辑商家 ======
  editVendor(id) {
    const v = id ? DB.getVendors().find(x => x.id === id) : { name: '', serviceType: '婚纱礼服', price: 0, status: '意向中', contactDate: null, phone: '', notes: '' };
    const types = Enums.VendorServiceType;
    const statuses = Enums.VendorStatus;
    const dateVal = v.contactDate ? DateHelper.toInputDate(v.contactDate) : '';
    UI.showSheet(id ? '编辑商家' : '新增商家', `
      <div class="form-group">
        <label class="form-label">商家名称</label>
        <input class="form-input" type="text" id="f-name" value="${v.name || ''}" placeholder="商家名称">
      </div>
      <div class="form-row">
        <div class="form-group">
          <label class="form-label">服务类型</label>
          <select class="form-select" id="f-serviceType">${types.map(t => `<option ${t === v.serviceType ? 'selected' : ''}>${t}</option>`).join('')}</select>
        </div>
        <div class="form-group">
          <label class="form-label">状态</label>
          <select class="form-select" id="f-status">${statuses.map(s => `<option ${s.value === v.status ? 'selected' : ''}>${s.value}</option>`).join('')}</select>
        </div>
      </div>
      <div class="form-row">
        <div class="form-group">
          <label class="form-label">报价（元）</label>
          <input class="form-input" type="number" id="f-price" value="${v.price || 0}" min="0">
        </div>
        <div class="form-group">
          <label class="form-label">联系日期</label>
          <input class="form-input" type="date" id="f-contactDate" value="${dateVal}">
        </div>
      </div>
      <div class="form-group">
        <label class="form-label">联系电话</label>
        <input class="form-input" type="tel" id="f-phone" value="${v.phone || ''}" placeholder="手机号">
      </div>
      <div class="form-group">
        <label class="form-label">备注</label>
        <textarea class="form-textarea" id="f-notes" placeholder="备注">${v.notes || ''}</textarea>
      </div>
      <button class="btn btn-primary btn-block" onclick="Forms._saveVendor('${id || ''}')">保存</button>
      ${id ? `<div style="height:12px"></div><button class="btn btn-danger btn-block" onclick="Forms._deleteVendor('${id}')">删除</button>` : ''}
    `);
  },
  _saveVendor(id) {
    const name = document.getElementById('f-name').value.trim();
    if (!name) { UI.toast('请输入商家名称'); return; }
    const dateStr = document.getElementById('f-contactDate').value;
    DB.saveVendor({
      id: id || undefined,
      name,
      serviceType: document.getElementById('f-serviceType').value,
      status: document.getElementById('f-status').value,
      price: parseFloat(document.getElementById('f-price').value) || 0,
      contactDate: dateStr ? new Date(dateStr + 'T12:00:00').toISOString() : null,
      phone: document.getElementById('f-phone').value,
      notes: document.getElementById('f-notes').value,
    });
    UI.closeSheet(); UI.toast('保存成功'); App.refresh();
  },
  _deleteVendor(id) {
    UI.confirm('确定删除这个商家吗？', () => {
      DB.deleteVendor(id); UI.closeSheet(); UI.toast('已删除'); App.refresh();
    });
  },

  // ====== 编辑物资 ======
  editMaterial(id) {
    const m = id ? DB.getMaterials().find(x => x.id === id) : { name: '', price: 0, quantity: 1, category: '婚房布置', channel: '淘宝', status: '未采购', notes: '', listType: '采购物资清单' };
    const cats = Enums.MaterialCategory;
    const channels = Enums.MaterialChannel;
    const statuses = Enums.MaterialStatus;
    const listTypes = Enums.MaterialListType;
    UI.showSheet(id ? '编辑物资' : '新增物资', `
      <div class="form-group">
        <label class="form-label">物品名称</label>
        <input class="form-input" type="text" id="f-name" value="${m.name || ''}" placeholder="物品名称">
      </div>
      <div class="form-row">
        <div class="form-group">
          <label class="form-label">单价（元）</label>
          <input class="form-input" type="number" id="f-price" value="${m.price || 0}" min="0" step="0.01">
        </div>
        <div class="form-group">
          <label class="form-label">数量</label>
          <input class="form-input" type="number" id="f-quantity" value="${m.quantity || 1}" min="1">
        </div>
      </div>
      <div class="form-row">
        <div class="form-group">
          <label class="form-label">分类</label>
          <select class="form-select" id="f-category">${cats.map(c => `<option ${c === m.category ? 'selected' : ''}>${c}</option>`).join('')}</select>
        </div>
        <div class="form-group">
          <label class="form-label">渠道</label>
          <select class="form-select" id="f-channel">${channels.map(c => `<option ${c === m.channel ? 'selected' : ''}>${c}</option>`).join('')}</select>
        </div>
      </div>
      <div class="form-row">
        <div class="form-group">
          <label class="form-label">状态</label>
          <select class="form-select" id="f-status">${statuses.map(s => `<option ${s.value === m.status ? 'selected' : ''}>${s.value}</option>`).join('')}</select>
        </div>
        <div class="form-group">
          <label class="form-label">清单</label>
          <select class="form-select" id="f-listType">${listTypes.map(l => `<option ${l === m.listType ? 'selected' : ''}>${l}</option>`).join('')}</select>
        </div>
      </div>
      <div class="form-group">
        <label class="form-label">备注</label>
        <textarea class="form-textarea" id="f-notes" placeholder="备注">${m.notes || ''}</textarea>
      </div>
      <button class="btn btn-primary btn-block" onclick="Forms._saveMaterial('${id || ''}')">保存</button>
      ${id ? `<div style="height:12px"></div><button class="btn btn-danger btn-block" onclick="Forms._deleteMaterial('${id}')">删除</button>` : ''}
    `);
  },
  _saveMaterial(id) {
    const name = document.getElementById('f-name').value.trim();
    if (!name) { UI.toast('请输入物品名称'); return; }
    DB.saveMaterial({
      id: id || undefined,
      name,
      price: parseFloat(document.getElementById('f-price').value) || 0,
      quantity: parseInt(document.getElementById('f-quantity').value) || 1,
      category: document.getElementById('f-category').value,
      channel: document.getElementById('f-channel').value,
      status: document.getElementById('f-status').value,
      listType: document.getElementById('f-listType').value,
      notes: document.getElementById('f-notes').value,
    });
    UI.closeSheet(); UI.toast('保存成功'); App.refresh();
  },
  _deleteMaterial(id) {
    UI.confirm('确定删除这个物品吗？', () => {
      DB.deleteMaterial(id); UI.closeSheet(); UI.toast('已删除'); App.refresh();
    });
  },

  // ====== 备份导出 ======
  backup() {
    const data = DB.exportAll();
    const json = JSON.stringify(data, null, 2);
    const blob = new Blob([json], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `WeddingPrep_Backup_${new Date().toISOString().slice(0,10)}.json`;
    a.click();
    URL.revokeObjectURL(url);
    UI.toast('备份文件已下载');
  },

  // ====== 备份导入 ======
  importBackup() {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = '.json,.wpbackup,application/json';
    input.onchange = e => {
      const file = e.target.files[0];
      if (!file) return;
      const reader = new FileReader();
      reader.onload = ev => {
        try {
          const data = JSON.parse(ev.target.result);
          DB.importAll(data);
          UI.toast('导入成功'); App.refresh();
        } catch (err) {
          UI.toast('导入失败：' + err.message);
        }
      };
      reader.readAsText(file);
    };
    input.click();
  },
};
