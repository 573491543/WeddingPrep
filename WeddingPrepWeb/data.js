// ==================== data.js ====================
// 数据层：localStorage 存储 + 模型 + 种子数据 + 日期工具

const DB = {
  // ====== Storage Keys ======
  KEYS: {
    profile: 'wp_profile',
    tasks: 'wp_tasks',
    categories: 'wp_categories',
    expenses: 'wp_expenses',
    vendors: 'wp_vendors',
    materials: 'wp_materials',
  },

  // ====== Generic CRUD ======
  _get(key) {
    try { return JSON.parse(localStorage.getItem(key)) || []; } catch { return []; }
  },
  _set(key, val) { localStorage.setItem(key, JSON.stringify(val)); },

  // ====== Wedding Profile ======
  getProfile() {
    const list = this._get(this.KEYS.profile);
    return list[0] || null;
  },
  saveProfile(p) {
    p.id = p.id || this._uuid();
    p.updatedAt = new Date().toISOString();
    this._set(this.KEYS.profile, [p]);
    return p;
  },

  // ====== Tasks ======
  getTasks() { return this._get(this.KEYS.tasks); },
  getTask(id) { return this.getTasks().find(t => t.id === id); },
  saveTask(t) {
    const tasks = this.getTasks();
    t.id = t.id || this._uuid();
    t.createdAt = t.createdAt || new Date().toISOString();
    t.updatedAt = new Date().toISOString();
    const idx = tasks.findIndex(x => x.id === t.id);
    if (idx >= 0) tasks[idx] = t; else tasks.push(t);
    this._set(this.KEYS.tasks, tasks);
    return t;
  },
  deleteTask(id) {
    this._set(this.KEYS.tasks, this.getTasks().filter(t => t.id !== id));
  },

  // ====== Budget Categories ======
  getCategories() { return this._get(this.KEYS.categories); },
  saveCategory(c) {
    const cats = this.getCategories();
    c.id = c.id || this._uuid();
    const idx = cats.findIndex(x => x.id === c.id);
    if (idx >= 0) cats[idx] = c; else cats.push(c);
    this._set(this.KEYS.categories, cats);
    return c;
  },
  deleteCategory(id) {
    this._set(this.KEYS.categories, this.getCategories().filter(c => c.id !== id));
  },

  // ====== Expenses ======
  getExpenses() { return this._get(this.KEYS.expenses); },
  saveExpense(e) {
    const list = this.getExpenses();
    e.id = e.id || this._uuid();
    const idx = list.findIndex(x => x.id === e.id);
    if (idx >= 0) list[idx] = e; else list.push(e);
    this._set(this.KEYS.expenses, list);
    return e;
  },
  deleteExpense(id) {
    this._set(this.KEYS.expenses, this.getExpenses().filter(e => e.id !== id));
  },

  // ====== Vendors ======
  getVendors() { return this._get(this.KEYS.vendors); },
  saveVendor(v) {
    const list = this.getVendors();
    v.id = v.id || this._uuid();
    const idx = list.findIndex(x => x.id === v.id);
    if (idx >= 0) list[idx] = v; else list.push(v);
    this._set(this.KEYS.vendors, list);
    return v;
  },
  deleteVendor(id) {
    this._set(this.KEYS.vendors, this.getVendors().filter(v => v.id !== id));
  },

  // ====== Materials ======
  getMaterials() { return this._get(this.KEYS.materials); },
  saveMaterial(m) {
    const list = this.getMaterials();
    m.id = m.id || this._uuid();
    const idx = list.findIndex(x => x.id === m.id);
    if (idx >= 0) list[idx] = m; else list.push(m);
    this._set(this.KEYS.materials, list);
    return m;
  },
  deleteMaterial(id) {
    this._set(this.KEYS.materials, this.getMaterials().filter(m => m.id !== id));
  },

  // ====== Export/Import ======
  exportAll() {
    return {
      version: 1,
      exportDate: new Date().toISOString(),
      profile: [this.getProfile()].filter(Boolean),
      tasks: this.getTasks(),
      categories: this.getCategories(),
      expenses: this.getExpenses(),
      vendors: this.getVendors(),
      materials: this.getMaterials(),
    };
  },
  importAll(data) {
    if (!data || typeof data !== 'object') throw new Error('文件格式不正确');
    const existingIds = new Set([
      ...this.getTasks().map(t => t.id),
      ...this.getCategories().map(c => c.id),
      ...this.getExpenses().map(e => e.id),
      ...this.getVendors().map(v => v.id),
      ...this.getMaterials().map(m => m.id),
    ]);
    if (data.profile && data.profile[0]) this._set(this.KEYS.profile, data.profile);
    const importList = (arr, key) => {
      if (!Array.isArray(arr)) return;
      const filtered = arr.filter(x => x.id && !existingIds.has(x.id));
      if (filtered.length) {
        const existing = this._get(key);
        this._set(key, [...existing, ...filtered]);
      }
    };
    importList(data.tasks, this.KEYS.tasks);
    importList(data.categories, this.KEYS.categories);
    importList(data.expenses, this.KEYS.expenses);
    importList(data.vendors, this.KEYS.vendors);
    importList(data.materials, this.KEYS.materials);
  },
  resetAll() {
    Object.values(this.KEYS).forEach(k => localStorage.removeItem(k));
    SeedData.init();
  },

  // ====== Utils ======
  _uuid() { return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, c => { const r = Math.random()*16|0; const v = c==='x'?r:(r&0x3|0x8); return v.toString(16); }); },
};

// ==================== Enum Definitions ====================
const Enums = {
  TaskStage: [
    { value: '婚前6个月', days: 180 },
    { value: '婚前3个月', days: 90 },
    { value: '婚前1个月', days: 30 },
    { value: '婚前1周', days: 7 },
    { value: '婚礼当天', days: 0 },
    { value: '自定义', days: 60 },
  ],
  TaskCategory: ['摄影摄像','婚纱礼服','婚宴筹备','婚庆布置','亲友沟通','证件办理','跟妆造型','蜜月旅行','其他'],
  TaskType: ['任务','备忘'],
  Priority: [
    { value: 0, label: '高', color: '#E74C3C' },
    { value: 1, label: '中', color: '#F7DC6F' },
    { value: 2, label: '低', color: '#7DCEA0' },
  ],
  VendorStatus: [
    { value: '已签约', color: '#7DCEA0', icon: '✅' },
    { value: '意向中', color: '#F7DC6F', icon: '👍' },
    { value: '已洽谈', color: '#85C1E2', icon: '🤝' },
    { value: '已淘汰', color: '#888888', icon: '❌' },
  ],
  VendorServiceType: ['婚纱礼服','摄影摄像','婚宴酒店','婚庆布置','跟妆造型','婚礼司仪','婚车租赁','花艺布置','其他'],
  MaterialCategory: ['婚房布置','喜糖喜品','新娘用品','宾客用品','仪式道具','其他'],
  MaterialChannel: ['淘宝','京东','拼多多','线下商场','自制/DIY','其他'],
  MaterialStatus: [
    { value: '未采购', color: '#E8A0BF' },
    { value: '已采购', color: '#7DCEA0' },
  ],
  MaterialListType: ['采购物资清单','当日随身物品'],
  BudgetPresets: [
    { name: '婚宴酒席', budgetLimit: 80000, colorHex: '#E8A0BF' },
    { name: '婚纱礼服', budgetLimit: 5000, colorHex: '#7DCEA0' },
    { name: '摄影摄像', budgetLimit: 8000, colorHex: '#C8B6E2' },
    { name: '跟妆造型', budgetLimit: 3000, colorHex: '#F7DC6F' },
    { name: '婚庆布置', budgetLimit: 10000, colorHex: '#85C1E2' },
    { name: '婚戒首饰', budgetLimit: 15000, colorHex: '#F1948A' },
    { name: '蜜月旅行', budgetLimit: 20000, colorHex: '#82E0AA' },
    { name: '亲友住宿', budgetLimit: 5000, colorHex: '#AED6F1' },
    { name: '其他支出', budgetLimit: 5000, colorHex: '#D5DBDB' },
  ],
};

// ==================== Date Helper ====================
const DateHelper = {
  daysUntilWedding(weddingDate) {
    const today = new Date(); today.setHours(0,0,0,0);
    const wedding = new Date(weddingDate); wedding.setHours(0,0,0,0);
    return Math.round((wedding - today) / 86400000);
  },
  dueDate(weddingDate, daysBefore) {
    const d = new Date(weddingDate);
    d.setDate(d.getDate() - daysBefore);
    return d;
  },
  daysFromToday(dueDate) {
    const today = new Date(); today.setHours(0,0,0,0);
    const due = new Date(dueDate); due.setHours(0,0,0,0);
    return Math.round((due - today) / 86400000);
  },
  formatChineseDate(date) {
    const d = new Date(date);
    const weekdays = ['周日','周一','周二','周三','周四','周五','周六'];
    return `${d.getMonth()+1}月${d.getDate()}日 ${weekdays[d.getDay()]}`;
  },
  formatFullDate(date) {
    const d = new Date(date);
    return `${d.getFullYear()}年${d.getMonth()+1}月${d.getDate()}日`;
  },
  formatCurrency(amount) {
    return '¥' + (amount || 0).toLocaleString('zh-CN', { maximumFractionDigits: 0 });
  },
  formatPercent(num, den) {
    if (!den) return '0%';
    return ((num / den) * 100).toFixed(1) + '%';
  },
  timeGroup(date) {
    const today = new Date(); today.setHours(0,0,0,0);
    const target = new Date(date); target.setHours(0,0,0,0);
    const weekday = today.getDay();
    const daysToSaturday = (7 - weekday) % 7;
    const endOfWeek = new Date(today); endOfWeek.setDate(today.getDate() + daysToSaturday);
    const endOfMonth = new Date(today.getFullYear(), today.getMonth() + 1, 0);
    if (target <= endOfWeek) return '本周内';
    if (target <= endOfMonth) return '本月内';
    return '更远';
  },
  toInputDate(date) {
    const d = new Date(date);
    const tz = d.getTimezoneOffset() * 60000;
    return new Date(d - tz).toISOString().slice(0, 10);
  },
};

// ==================== Seed Data ====================
const SeedData = {
  init() {
    if (DB.getProfile()) return; // Already seeded

    // Profile
    const weddingDate = new Date();
    weddingDate.setMonth(weddingDate.getMonth() + 9);
    DB.saveProfile({
      weddingDate: weddingDate.toISOString(),
      brideName: '',
      groomName: '',
      totalBudget: 100000,
    });

    // Budget Categories
    Enums.BudgetPresets.forEach((p, i) => {
      DB.saveCategory({ ...p, id: DB._uuid(), order: i });
    });

    // Task Templates
    const templates = [
      ['双方家长见面商定婚期','婚前6个月','亲友沟通',180,0,'确定大致婚礼日期范围',7],
      ['确定婚礼预算总金额','婚前6个月','其他',180,0,'与双方家庭商议预算分配',7],
      ['挑选并预定婚宴酒店','婚前6个月','婚宴筹备',175,0,'热门档期需提前半年预定',7],
      ['开始考察婚纱摄影机构','婚前6个月','摄影摄像',170,1,'对比3家以上',5],
      ['预定婚庆策划公司','婚前6个月','婚庆布置',165,1,'',5],
      ['拍摄婚纱照','婚前3个月','摄影摄像',90,0,'提前预约外景场地',7],
      ['挑选婚纱礼服','婚前3个月','婚纱礼服',85,0,'出门纱、主婚纱、敬酒服',5],
      ['确定跟妆师并试妆','婚前3个月','跟妆造型',80,0,'带参考图沟通风格',5],
      ['预定婚车','婚前3个月','其他',75,2,'',3],
      ['确定伴郎伴娘人选','婚前3个月','亲友沟通',70,1,'',5],
      ['制作宾客名单','婚前3个月','亲友沟通',65,1,'双方各自统计人数',3],
      ['选购婚戒首饰','婚前3个月','其他',60,0,'预留定制时间',7],
      ['发送请柬','婚前1个月','亲友沟通',30,0,'电子请柬+纸质请柬',7],
      ['确定最终宾客人数','婚前1个月','亲友沟通',25,0,'通知酒店调整桌数',3],
      ['与婚庆确认最终方案','婚前1个月','婚庆布置',25,0,'场地布置、流程确认',3],
      ['试穿最终婚纱礼服','婚前1个月','婚纱礼服',20,0,'确认尺寸是否需要调整',3],
      ['确定婚礼当天流程表','婚前1个月','其他',20,0,'',3],
      ['采购婚房布置用品','婚前1个月','婚庆布置',18,1,'喜字贴纸、气球、床品',3],
      ['采购喜糖喜品','婚前1个月','其他',15,1,'确定数量和款式',3],
      ['与司仪沟通婚礼流程','婚前1个月','其他',15,1,'',3],
      ['安排伴郎伴娘服装','婚前1个月','婚纱礼服',12,2,'',3],
      ['最终试纱确认','婚前1周','婚纱礼服',7,0,'',2],
      ['确认所有商家到场时间','婚前1周','其他',5,0,'化妆师、摄影、婚庆',1],
      ['准备婚礼当天随身物品','婚前1周','其他',5,0,'敬酒服、备用丝袜、针线包',1],
      ['打印座位图和流程表','婚前1周','其他',3,1,'',1],
      ['婚房最后布置','婚前1周','婚庆布置',2,1,'',1],
      ['早起化妆造型','婚礼当天','跟妆造型',0,0,'比约定时间提前30分钟',0],
      ['迎宾接待','婚礼当天','亲友沟通',0,0,'',0],
      ['婚礼仪式','婚礼当天','其他',0,0,'',0],
      ['婚宴敬酒','婚礼当天','婚宴筹备',0,0,'',0],
      ['送客收拾','婚礼当天','其他',0,2,'',0],
    ];

    templates.forEach(t => {
      DB.saveTask({
        title: t[0], stage: t[1], category: t[2], type: '任务',
        daysBeforeWedding: t[3], priority: t[4], isCompleted: false,
        notes: t[5], reminderDaysBefore: t[6],
      });
    });
  },
};
