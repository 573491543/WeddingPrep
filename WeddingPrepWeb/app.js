// ==================== app.js ====================
// 主入口：初始化、导航、事件处理

const App = {
  currentTab: 'home',
  pageState: {},

  // ====== 初始化 ======
  init() {
    // 首次启动预填数据
    SeedData.init();
    // 绑定 Tab 点击
    document.querySelectorAll('.tab-item').forEach(btn => {
      btn.onclick = () => this.navigate(btn.dataset.tab);
    });
    // 渲染首页
    this.navigate('home');
  },

  // ====== 导航 ======
  navigate(tab) {
    this.currentTab = tab;
    this.pageState = {};
    // 更新 Tab 高亮
    document.querySelectorAll('.tab-item').forEach(btn => {
      btn.classList.toggle('active', btn.dataset.tab === tab);
    });
    this.render(tab);
  },

  // ====== 渲染页面 ======
  render(tab, state) {
    if (state) this.pageState = { ...this.pageState, ...state };
    const container = document.getElementById('page-container');
    let html = '';
    switch (tab || this.currentTab) {
      case 'home': html = Pages.home(); break;
      case 'timeplan': html = Pages.timeplan(this.pageState); break;
      case 'budget': html = Pages.budget(); break;
      case 'vendor': html = Pages.vendor(this.pageState); break;
      case 'material': html = Pages.material(this.pageState); break;
      case 'reminder': html = Pages.reminder(); break;
    }
    container.innerHTML = html;
    // 执行内联 <script> 标签（Canvas 绘制等）
    container.querySelectorAll('script').forEach(s => {
      const ns = document.createElement('script');
      ns.textContent = s.textContent;
      s.replaceWith(ns);
    });
  },

  // ====== 刷新当前页 ======
  refresh() {
    this.render(this.currentTab);
  },

  // ====== 快捷操作 ======
  quickAction(type) {
    switch (type) {
      case 'task':
        this.navigate('timeplan');
        setTimeout(() => Forms.editTask(), 300);
        break;
      case 'expense':
        this.navigate('budget');
        setTimeout(() => Forms.editExpense(), 300);
        break;
      case 'vendor':
        this.navigate('vendor');
        setTimeout(() => Forms.editVendor(), 300);
        break;
      case 'material':
        this.navigate('material');
        setTimeout(() => Forms.editMaterial(), 300);
        break;
    }
  },

  // ====== 切换任务完成状态 ======
  toggleTask(id) {
    const task = DB.getTask(id);
    if (!task) return;
    task.isCompleted = !task.isCompleted;
    DB.saveTask(task);
    this.refresh();
  },

  // ====== 切换物资采购状态 ======
  toggleMaterial(id) {
    const m = DB.getMaterials().find(x => x.id === id);
    if (!m) return;
    m.status = m.status === '已采购' ? '未采购' : '已采购';
    DB.saveMaterial(m);
    this.refresh();
  },
};

// ====== 启动 ======
document.addEventListener('DOMContentLoaded', () => App.init());
