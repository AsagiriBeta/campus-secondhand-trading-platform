# 校园二手交易平台 🎓

<p align="center">
  <img src="https://img.shields.io/badge/Python-3.8+-blue.svg">
  <img src="https://img.shields.io/badge/Flask-3.0.0-green.svg">
  <img src="https://img.shields.io/badge/SQLite-3-orange.svg">
  <img src="https://img.shields.io/badge/Bootstrap-5-purple.svg">
</p>

> 基于 Flask + SQLite 的校园二手交易平台 - 数据库原理与应用课程设计

---

## 📖 目录

- [功能特性](#-功能特性)
- [快速开始](#-快速开始)
- [项目结构](#-项目结构)
- [数据库设计](#️-数据库设计)
- [课程文档](#-课程设计文档)
- [演示指南](#-演示指南)
- [常见问题](#-常见问题)

---

## ✨ 功能特性

- 🔐 **用户系统**: 注册登录、个人中心、信用分管理（0-150分）
- 📦 **商品管理**: 发布/编辑/删除商品、8大分类、多图上传
- 🔍 **搜索浏览**: 关键词搜索、分类筛选、分页显示
- ❤️ **收藏功能**: 收藏商品、收藏列表管理
- 🛒 **交易系统**: 订单创建、状态跟踪、买卖双向查询
- ⭐ **评价系统**: 交易评价、信用分自动调整
- 📊 **数据统计**: 热门商品、用户统计、交易分析
- 🔧 **数据库特性**: 4个触发器、3个视图、16个索引

---

## 🚀 快速开始

### 环境要求
- Python 3.8+
- pip 包管理器

### 一键启动

```bash
# 1. 进入项目目录
cd campus-secondhand-trading-platform

# 2. 安装依赖
pip install -r requirements.txt

# 3. 初始化数据库（包含测试数据）
python init_db.py

# 4. 启动应用
python app.py

# 5. 浏览器访问
http://127.0.0.1:5001
```

### 测试账号

| 用户名 | 密码 | 角色 |
|--------|------|------|
| zhangsan | 123456 | 已发布2个商品 |
| lisi | 123456 | 已发布2个商品 |
| wangwu | 123456 | 已发布1个商品 |

---

## 📁 项目结构

```
campus-secondhand-trading-platform/
├── app.py                    # Flask主应用（406行）
├── models.py                 # 数据库模型（8个表）
├── config.py                 # 配置管理
├── init_db.py                # 数据库初始化
├── database_schema.sql       # SQL建表脚本
├── requirements.txt          # Python依赖
├── .env                      # 环境变量
├── templates/                # HTML模板（13个页面）
│   ├── base.html            # 基础模板
│   ├── index.html           # 首页
│   ├── login.html           # 登录页
│   ├── register.html        # 注册页
│   ├── product_detail.html  # 商品详情
│   ├── publish_product.html # 发布商品
│   ├── user_*.html          # 用户中心页面
│   └── errors/              # 错误页面
├── static/                   # 静态资源
│   ├── css/style.css        # 自定义样式
│   ├── js/main.js           # JavaScript
│   ├── images/              # 图片资源
│   └── uploads/             # 用户上传
└── instance/                 # Flask实例文件夹
    └── campus_trade.db      # SQLite数据库
```

---

## 🗄️ 数据库设计

### 表结构（8个表）

| 表名 | 说明 | 字段数 | 主要字段 |
|------|------|--------|----------|
| **users** | 用户表 | 15 | 学号、用户名、信用分、余额 |
| **categories** | 分类表 | 5 | 分类名、图标、排序 |
| **products** | 商品表 | 17 | 标题、价格、状态、图片 |
| **orders** | 订单表 | 14 | 订单号、价格、状态 |
| **reviews** | 评价表 | 7 | 订单ID、评分、内容 |
| **favorites** | 收藏表 | 3 | 用户ID、商品ID |
| **messages** | 消息表 | 6 | 发送者、接收者、内容 |
| **system_logs** | 日志表 | 7 | 用户、操作、时间 |

### ER模型关系

```
┌─────────┐       发布1:N      ┌─────────┐     属于N:1     ┌──────────┐
│  User   │ ─────────────────→ │ Product │ ─────────────→ │ Category │
│ (用户)  │                    │ (商品)  │                │  (分类)  │
└─────────┘                    └─────────┘                └──────────┘
     │                              │
     │ 收藏(N:M)                    │ 关联1:N
     │                              │
     ↓                              ↓
┌──────────┐                   ┌─────────┐
│ Favorite │                   │  Order  │
│  (收藏)  │                   │ (订单)  │
└──────────┘                   └─────────┘
                                    │ 1:1
                                    ↓
                               ┌─────────┐
                               │ Review  │
                               │ (评价)  │
                               └─────────┘
```

### 数据库特性

#### 🔧 触发器（4个）

```sql
-- 1. 订单完成后自动增加信用分
CREATE TRIGGER update_credit_score_on_order_complete
AFTER UPDATE ON orders
WHEN NEW.status = 'completed'
BEGIN
    UPDATE users SET credit_score = credit_score + 5 
    WHERE id = NEW.seller_id AND credit_score < 150;
END;

-- 2. 订单取消后恢复商品状态
-- 3. 商品售出后记录时间
-- 4. 评价后调整信用分
```

#### 📊 视图（3个）

- **v_hot_products** - 热门商品视图（浏览+收藏加权）
- **v_user_stats** - 用户统计视图（商品数、订单数、评分）
- **v_order_details** - 订单详情视图（商品+用户信息）

#### ⚡ 索引（16个）

- 用户表: student_id, username, email
- 商品表: seller_id, category_id, status, created_at, price, (status+created_at)
- 订单表: order_no, buyer_id, seller_id, status, created_at
- 收藏表: user_id, product_id, (user_id+product_id)联合唯一
- 评价表: reviewer_id, reviewee_id, created_at
- 消息表: sender_id, receiver_id, created_at

#### ✅ 3NF范式

所有表满足第三范式：
- ✓ 第一范式：所有字段原子性
- ✓ 第二范式：非主属性完全依赖主键
- ✓ 第三范式：非主属性不传递依赖主键

---

## 📚 课程设计文档

### 一、项目背景概述

**项目背景**: 校园二手交易需求增长，传统线下交易存在信息不对称、缺乏信用保障等问题。

**拟实现功能**:
- 用户注册登录与信息管理
- 商品发布、浏览、搜索
- 订单创建与交易管理
- 评价系统与信用分机制

**开发环境**:
- 操作系统: macOS/Windows/Linux
- 编程语言: Python 3.8+
- Web框架: Flask 3.0.0
- 数据库: SQLite 3
- 前端: Bootstrap 5.1.3

### 二、需求分析

**数据字典**: 8个表，详细字段定义见 `database_schema.sql`

**数据流图**:
```
用户 → 注册/登录 → 系统
用户 → 发布商品 → 系统 → 存储商品信息
用户 → 浏览商品 → 系统 → 返回商品列表
用户 → 创建订单 → 系统 → 生成订单 → 更新商品状态
用户 → 完成交易 → 系统 → 触发器更新信用分 → 评价
```

### 三、概念模型设计（ER图）

见上方ER模型关系图

### 四、逻辑结构设计

**关系模式**:
- R1: User(id, student_id, username, ...) - 主键: id
- R2: Product(id, title, price, seller_id, ...) - 主键: id, 外键: seller_id→User
- R3: Order(id, order_no, product_id, buyer_id, seller_id, ...) - 主键: id
- R4-R8: 其他表...

**范式分析**: 所有表满足3NF

### 五、物理结构设计

**索引设计**: 16个索引优化查询性能

**存储估算** (1000用户规模):
- users: 500KB
- products: 4MB
- orders: 1.2MB
- 其他表: 约15MB
- **总计**: 约21MB

### 六、基本功能说明

**核心SQL语句**:
```sql
-- 搜索商品
SELECT * FROM products 
WHERE (title LIKE '%keyword%' OR description LIKE '%keyword%')
AND is_deleted = 0 AND status = 'available';

-- 用户统计
SELECT * FROM v_user_stats WHERE id = ?;

-- 热门商品
SELECT * FROM v_hot_products LIMIT 10;
```

**触发器**: 4个触发器实现信用分自动更新、状态管理

### 七、项目小结

**完成情况**: 
- ✅ 数据库设计完整规范
- ✅ 系统功能完整可用
- ✅ 触发器视图索引完善
- ✅ 文档详细清晰

**技术亮点**:
1. 符合3NF的规范设计
2. 触发器实现业务自动化
3. 视图简化复杂查询
4. 索引优化查询性能
5. 完整的安全机制

**心得体会**:
通过本次课程设计，深入理解了数据库设计原理，掌握了ER模型、范式理论、SQL高级特性等知识，提升了全栈开发能力和系统设计思维。

---

## 🎯 演示指南

### 演示流程（15分钟）

#### 1. 数据库设计（5分钟）
- 展示ER图和表结构
- 说明3NF设计思路
- 演示外键约束

#### 2. 功能演示（5分钟）
```
登录(zhangsan) → 发布商品 → 浏览搜索 → 
切换用户(lisi) → 收藏商品 → 创建订单 → 
查看我的订单 → 个人中心
```

#### 3. 数据库特性（5分钟）

**触发器演示**:
```sql
-- 创建订单并完成
UPDATE orders SET status = 'completed' WHERE id = 1;

-- 查看信用分变化
SELECT username, credit_score FROM users WHERE id IN (1, 2);
```

**视图查询**:
```sql
-- 热门商品
SELECT * FROM v_hot_products LIMIT 5;

-- 用户统计
SELECT * FROM v_user_stats WHERE id = 1;
```

**统计分析**:
```sql
-- 分类统计
SELECT c.name, COUNT(p.id) as count
FROM categories c
LEFT JOIN products p ON c.id = p.category_id
GROUP BY c.id;
```

### 演示准备检查清单

- [ ] 应用已启动（http://127.0.0.1:5001）
- [ ] 测试账号可用
- [ ] 测试数据完整
- [ ] SQLite客户端准备好
- [ ] ER图和文档准备好

---

## ❓ 常见问题

### Q1: 如何启动项目？
```bash
pip install -r requirements.txt
python init_db.py
python app.py
```

### Q2: 端口5001被占用？
修改 `app.py` 最后一行：
```python
app.run(debug=True, port=5002)  # 改为其他端口
```

### Q3: 数据库初始化失败？
```bash
rm instance/campus_trade.db
python init_db.py
```

### Q4: 如何查看数据库？
```bash
sqlite3 instance/campus_trade.db
.tables          # 查看所有表
.schema users    # 查看表结构
SELECT * FROM users;  # 查询数据
```

### Q5: 如何重置数据？
```bash
rm instance/campus_trade.db
python init_db.py  # 重新初始化
```

---

## 📊 项目统计

| 指标 | 数量 |
|------|------|
| 代码总行数 | ~3300行 |
| Python代码 | ~1500行 |
| HTML模板 | ~1000行 |
| 数据表 | 8个 |
| 视图 | 3个 |
| 触发器 | 4个 |
| 索引 | 16个 |
| 路由 | 15个 |
| 测试数据 | 3用户+5商品+8分类 |

---

## 🛠️ 技术栈详情

**后端**:
- Flask 3.0.0 - Web框架
- SQLAlchemy 3.1.1 - ORM
- Flask-Login 0.6.3 - 用户认证
- Werkzeug - 密码加密

**前端**:
- Bootstrap 5.1.3 - UI框架
- Bootstrap Icons - 图标库
- JavaScript ES6 - 交互逻辑

**数据库**:
- SQLite 3 - 轻量级数据库
- 3NF设计 - 范式规范
- 触发器 - 业务自动化
- 视图 - 查询简化
- 索引 - 性能优化

---

## 📝 开发与维护

### 添加新功能
1. 在 `models.py` 定义模型
2. 在 `app.py` 添加路由
3. 在 `templates/` 创建模板
4. 在 `static/` 添加样式

### 修改数据库
```bash
# 备份数据
sqlite3 instance/campus_trade.db .dump > backup.sql

# 修改模型后重建
rm instance/campus_trade.db
python init_db.py

# 恢复数据（如需要）
sqlite3 instance/campus_trade.db < backup.sql
```

### 部署上线
1. 修改 `.env` 配置
2. 设置 `FLASK_ENV=production`
3. 使用 Gunicorn/uWSGI
4. 配置 Nginx 反向代理
5. 迁移到 MySQL/PostgreSQL（生产环境推荐）

---

## 🎓 学习资源

- [Flask 官方文档](https://flask.palletsprojects.com/)
- [SQLAlchemy 文档](https://www.sqlalchemy.org/)
- [SQLite 教程](https://www.sqlite.org/docs.html)
- [Bootstrap 文档](https://getbootstrap.com/)

---

## 📄 许可证

MIT License - 仅用于教学和学习目的

---

## 👥 贡献者

- 项目开发: [填写小组成员姓名]
- 指导教师: [填写老师姓名]
- 完成日期: 2025年11月

---

<p align="center">
  <strong>🎉 祝答辩顺利！</strong><br>
  <sub>这是一个完整的数据库课程设计项目，包含规范的设计、完整的实现和详细的文档。</sub>
</p>

---

> 💡 **提示**: 
> - 所有代码和数据库已准备就绪，可直接运行和演示
> - 数据库设计满足3NF，包含触发器、视图、索引等高级特性
> - 项目文档完整，满足《数据库原理与应用》课程要求
> - 建议演示前先熟悉测试账号和数据，准备好演示流程

