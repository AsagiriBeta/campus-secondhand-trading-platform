-- 校园二手交易平台数据库结构
-- 数据库类型: SQLite
-- 创建日期: 2025-11-06

-- ==================== 用户表 ====================
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    student_id VARCHAR(20) UNIQUE NOT NULL,           -- 学号
    username VARCHAR(50) UNIQUE NOT NULL,             -- 用户名
    password_hash VARCHAR(200) NOT NULL,              -- 密码哈希
    real_name VARCHAR(50) NOT NULL,                   -- 真实姓名
    email VARCHAR(100) UNIQUE NOT NULL,               -- 邮箱
    phone VARCHAR(20),                                -- 联系电话
    campus VARCHAR(50),                               -- 所在校区
    dormitory VARCHAR(50),                            -- 宿舍地址
    avatar VARCHAR(200) DEFAULT 'default.jpg',        -- 头像路径
    balance REAL DEFAULT 0.0,                         -- 账户余额
    credit_score INTEGER DEFAULT 100,                 -- 信用分 (0-150)
    is_active BOOLEAN DEFAULT 1,                      -- 账户是否激活
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,    -- 注册时间
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP     -- 更新时间
);

-- 用户表索引
CREATE INDEX idx_users_student_id ON users(student_id);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);

-- ==================== 商品分类表 ====================
CREATE TABLE IF NOT EXISTS categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(50) UNIQUE NOT NULL,                 -- 分类名称
    description TEXT,                                 -- 分类描述
    icon VARCHAR(100),                                -- 分类图标
    sort_order INTEGER DEFAULT 0,                     -- 排序顺序
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ==================== 商品表 ====================
CREATE TABLE IF NOT EXISTS products (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title VARCHAR(200) NOT NULL,                      -- 商品标题
    description TEXT NOT NULL,                        -- 商品描述
    price REAL NOT NULL,                              -- 价格
    original_price REAL,                              -- 原价
    category_id INTEGER NOT NULL,                     -- 分类ID
    seller_id INTEGER NOT NULL,                       -- 卖家ID
    condition VARCHAR(20),                            -- 新旧程度
    status VARCHAR(20) DEFAULT 'available',           -- 状态: available/sold/reserved
    view_count INTEGER DEFAULT 0,                     -- 浏览次数
    favorite_count INTEGER DEFAULT 0,                 -- 收藏次数
    trade_location VARCHAR(100),                      -- 交易地点
    images TEXT,                                      -- 图片路径，多个用逗号分隔
    is_deleted BOOLEAN DEFAULT 0,                     -- 是否删除
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,    -- 发布时间
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,    -- 更新时间
    sold_at DATETIME,                                 -- 售出时间
    FOREIGN KEY (category_id) REFERENCES categories(id),
    FOREIGN KEY (seller_id) REFERENCES users(id)
);

-- 商品表索引
CREATE INDEX idx_products_seller_id ON products(seller_id);
CREATE INDEX idx_products_category_id ON products(category_id);
CREATE INDEX idx_products_status ON products(status);
CREATE INDEX idx_products_created_at ON products(created_at DESC);
CREATE INDEX idx_products_price ON products(price);
CREATE INDEX idx_products_status_created ON products(status, created_at DESC);

-- ==================== 订单表 ====================
CREATE TABLE IF NOT EXISTS orders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    order_no VARCHAR(50) UNIQUE NOT NULL,             -- 订单号
    product_id INTEGER NOT NULL,                      -- 商品ID
    buyer_id INTEGER NOT NULL,                        -- 买家ID
    seller_id INTEGER NOT NULL,                       -- 卖家ID
    price REAL NOT NULL,                              -- 成交价格
    status VARCHAR(20) DEFAULT 'pending',             -- 订单状态
    payment_method VARCHAR(20),                       -- 支付方式
    trade_location VARCHAR(100),                      -- 交易地点
    buyer_note TEXT,                                  -- 买家备注
    seller_note TEXT,                                 -- 卖家备注
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,    -- 创建时间
    paid_at DATETIME,                                 -- 支付时间
    completed_at DATETIME,                            -- 完成时间
    cancelled_at DATETIME,                            -- 取消时间
    FOREIGN KEY (product_id) REFERENCES products(id),
    FOREIGN KEY (buyer_id) REFERENCES users(id),
    FOREIGN KEY (seller_id) REFERENCES users(id)
);

-- 订单表索引
CREATE INDEX idx_orders_order_no ON orders(order_no);
CREATE INDEX idx_orders_buyer_id ON orders(buyer_id);
CREATE INDEX idx_orders_seller_id ON orders(seller_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);

-- ==================== 评价表 ====================
CREATE TABLE IF NOT EXISTS reviews (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id INTEGER UNIQUE NOT NULL,                 -- 订单ID
    reviewer_id INTEGER NOT NULL,                     -- 评价人ID
    reviewee_id INTEGER NOT NULL,                     -- 被评价人ID
    rating INTEGER NOT NULL,                          -- 评分 1-5
    content TEXT,                                     -- 评价内容
    is_anonymous BOOLEAN DEFAULT 0,                   -- 是否匿名
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id),
    FOREIGN KEY (reviewer_id) REFERENCES users(id),
    FOREIGN KEY (reviewee_id) REFERENCES users(id)
);

-- 评价表索引
CREATE INDEX idx_reviews_reviewer_id ON reviews(reviewer_id);
CREATE INDEX idx_reviews_reviewee_id ON reviews(reviewee_id);
CREATE INDEX idx_reviews_created_at ON reviews(created_at DESC);

-- ==================== 收藏表 ====================
CREATE TABLE IF NOT EXISTS favorites (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,                         -- 用户ID
    product_id INTEGER NOT NULL,                      -- 商品ID
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (product_id) REFERENCES products(id),
    UNIQUE(user_id, product_id)                       -- 联合唯一约束
);

-- 收藏表索引
CREATE INDEX idx_favorites_user_id ON favorites(user_id);
CREATE INDEX idx_favorites_product_id ON favorites(product_id);

-- ==================== 消息表 ====================
CREATE TABLE IF NOT EXISTS messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    sender_id INTEGER NOT NULL,                       -- 发送者ID
    receiver_id INTEGER NOT NULL,                     -- 接收者ID
    product_id INTEGER,                               -- 关联商品ID
    content TEXT NOT NULL,                            -- 消息内容
    is_read BOOLEAN DEFAULT 0,                        -- 是否已读
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sender_id) REFERENCES users(id),
    FOREIGN KEY (receiver_id) REFERENCES users(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
);

-- 消息表索引
CREATE INDEX idx_messages_sender_id ON messages(sender_id);
CREATE INDEX idx_messages_receiver_id ON messages(receiver_id);
CREATE INDEX idx_messages_created_at ON messages(created_at DESC);

-- ==================== 系统日志表 ====================
CREATE TABLE IF NOT EXISTS system_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,                                  -- 用户ID
    action VARCHAR(50) NOT NULL,                      -- 操作类型
    table_name VARCHAR(50),                           -- 操作表名
    record_id INTEGER,                                -- 记录ID
    description TEXT,                                 -- 操作描述
    ip_address VARCHAR(50),                           -- IP地址
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- 系统日志表索引
CREATE INDEX idx_system_logs_user_id ON system_logs(user_id);
CREATE INDEX idx_system_logs_action ON system_logs(action);
CREATE INDEX idx_system_logs_created_at ON system_logs(created_at DESC);

-- ==================== 视图定义 ====================

-- 视图1: 热门商品视图
CREATE VIEW IF NOT EXISTS v_hot_products AS
SELECT
    p.*,
    c.name as category_name,
    u.username as seller_name,
    u.credit_score as seller_credit
FROM products p
LEFT JOIN categories c ON p.category_id = c.id
LEFT JOIN users u ON p.seller_id = u.id
WHERE p.is_deleted = 0 AND p.status = 'available'
ORDER BY (p.view_count * 0.3 + p.favorite_count * 0.7) DESC;

-- 视图2: 用户统计视图
CREATE VIEW IF NOT EXISTS v_user_stats AS
SELECT
    u.id,
    u.username,
    u.real_name,
    u.credit_score,
    COUNT(DISTINCT p.id) as product_count,
    COUNT(DISTINCT CASE WHEN p.status = 'sold' THEN p.id END) as sold_count,
    COUNT(DISTINCT o1.id) as buy_count,
    COUNT(DISTINCT o2.id) as sell_count,
    AVG(CASE WHEN r.reviewee_id = u.id THEN r.rating END) as avg_rating
FROM users u
LEFT JOIN products p ON u.id = p.seller_id AND p.is_deleted = 0
LEFT JOIN orders o1 ON u.id = o1.buyer_id
LEFT JOIN orders o2 ON u.id = o2.seller_id
LEFT JOIN reviews r ON u.id = r.reviewee_id
GROUP BY u.id;

-- 视图3: 订单详情视图
CREATE VIEW IF NOT EXISTS v_order_details AS
SELECT
    o.*,
    p.title as product_title,
    p.images as product_images,
    buyer.username as buyer_name,
    buyer.phone as buyer_phone,
    seller.username as seller_name,
    seller.phone as seller_phone
FROM orders o
LEFT JOIN products p ON o.product_id = p.id
LEFT JOIN users buyer ON o.buyer_id = buyer.id
LEFT JOIN users seller ON o.seller_id = seller.id;

-- ==================== 触发器定义 ====================

-- 触发器1: 订单完成后更新用户信用分
CREATE TRIGGER IF NOT EXISTS update_credit_score_on_order_complete
AFTER UPDATE ON orders
WHEN NEW.status = 'completed' AND OLD.status != 'completed'
BEGIN
    -- 卖家信用分+5 (最高150分)
    UPDATE users SET credit_score = credit_score + 5
    WHERE id = NEW.seller_id AND credit_score < 150;

    -- 买家信用分+2 (最高150分)
    UPDATE users SET credit_score = credit_score + 2
    WHERE id = NEW.buyer_id AND credit_score < 150;
END;

-- 触发器2: 订单取消后恢复商品状态
CREATE TRIGGER IF NOT EXISTS restore_product_on_cancel
AFTER UPDATE ON orders
WHEN NEW.status = 'cancelled' AND OLD.status != 'cancelled'
BEGIN
    UPDATE products SET status = 'available'
    WHERE id = NEW.product_id;
END;

-- 触发器3: 商品售出后更新售出时间
CREATE TRIGGER IF NOT EXISTS update_sold_time
AFTER UPDATE ON products
WHEN NEW.status = 'sold' AND OLD.status != 'sold'
BEGIN
    UPDATE products SET sold_at = datetime('now')
    WHERE id = NEW.id;
END;

-- 触发器4: 插入评价后更新被评价人信用分
CREATE TRIGGER IF NOT EXISTS update_credit_on_review
AFTER INSERT ON reviews
BEGIN
    -- 根据评分调整信用分: 5星+4, 4星+2, 3星0, 2星-2, 1星-4
    -- 信用分范围: 0-150
    UPDATE users
    SET credit_score = credit_score + (NEW.rating - 3) * 2
    WHERE id = NEW.reviewee_id
    AND credit_score + (NEW.rating - 3) * 2 BETWEEN 0 AND 150;
END;

-- ==================== 初始数据 ====================

-- 插入商品分类
INSERT OR IGNORE INTO categories (name, description, icon, sort_order) VALUES
('数码产品', '手机、电脑、平板等', 'laptop', 1),
('图书教材', '各类教材、课外书籍', 'book', 2),
('生活用品', '日用品、家居用品', 'home', 3),
('体育用品', '运动器材、健身用品', 'basketball', 4),
('服装配饰', '衣服、鞋子、包包等', 'shopping-bag', 5),
('文具用品', '笔记本、笔、文件夹等', 'pen', 6),
('乐器音响', '吉他、音箱等', 'music', 7),
('其他', '其他类别商品', 'tag', 99);
# 校园二手交易平台

<p align="center">
  <img src="https://img.shields.io/badge/Python-3.8+-blue.svg" alt="Python">
  <img src="https://img.shields.io/badge/Flask-3.0.0-green.svg" alt="Flask">
  <img src="https://img.shields.io/badge/SQLite-3-orange.svg" alt="SQLite">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License">
</p>

基于 Flask + SQLite 开发的校园二手交易平台，用于《数据库原理与应用》课程设计。

## 功能特性

- 🔐 用户注册登录与权限管理
- 📦 商品发布、编辑、删除
- 🔍 商品搜索与分类浏览
- ❤️ 商品收藏功能
- 🛒 订单创建与管理
- ⭐ 交易评价系统
- 💰 信用分系统
- 📊 数据统计分析
- 🔔 系统日志记录

## 技术栈

### 后端
- **Web框架**: Flask 3.0.0
- **数据库**: SQLite 3
- **ORM**: Flask-SQLAlchemy 3.1.1
- **用户认证**: Flask-Login 0.6.3
- **密码加密**: Werkzeug

### 前端
- **UI框架**: Bootstrap 5.1.3
- **图标**: Bootstrap Icons
- **JavaScript**: 原生JS

## 项目结构

```
campus-secondhand-trading-platform/
├── app.py                 # Flask应用主文件
├── models.py              # 数据库模型定义
├── config.py              # 配置文件
├── init_db.py             # 数据库初始化脚本
├── requirements.txt       # Python依赖
├── .env                   # 环境变量配置
├── README.md              # 项目说明
├── 项目文档.md            # 详细设计文档
├── database_schema.sql    # 数据库结构SQL
├── templates/             # HTML模板
│   ├── base.html
│   ├── index.html
│   ├── login.html
│   ├── register.html
│   ├── product_detail.html
│   ├── publish_product.html
│   ├── user_profile.html
│   ├── user_products.html
│   ├── user_orders.html
│   ├── user_favorites.html
│   ├── order_detail.html
│   └── errors/
│       ├── 404.html
│       └── 500.html
├── static/                # 静态文件
│   ├── css/
│   │   └── style.css
│   ├── js/
│   │   └── main.js
│   ├── images/
│   └── uploads/          # 用户上传的图片
└── campus_trade.db       # SQLite数据库文件（运行后生成）
```

## 快速开始

### 1. 环境要求

- Python 3.8 或更高版本
- pip 包管理器

### 2. 安装依赖

```bash
# 克隆或下载项目
cd campus-secondhand-trading-platform

# 安装依赖
pip install -r requirements.txt
```

### 3. 初始化数据库

```bash
# 初始化数据库（创建表、索引、视图、触发器，并插入测试数据）
python init_db.py
```

### 4. 运行应用

```bash
# 启动Flask应用
python app.py
```

应用将在 http://127.0.0.1:5000 启动

### 5. 访问系统

打开浏览器访问: http://127.0.0.1:5000

## 测试账号

系统已预设以下测试账号：

| 用户名 | 密码 | 学号 | 姓名 |
|--------|------|------|------|
| zhangsan | 123456 | 2022001 | 张三 |
| lisi | 123456 | 2022002 | 李四 |
| wangwu | 123456 | 2022003 | 王五 |

## 主要功能说明

### 用户功能
- **注册登录**: 使用学号、用户名、邮箱注册，密码加密存储
- **个人中心**: 查看和管理个人信息
- **信用系统**: 根据交易行为自动计算信用分

### 商品功能
- **发布商品**: 支持多图上传、分类、定价
- **浏览商品**: 按分类浏览、关键词搜索
- **收藏商品**: 收藏感兴趣的商品

### 交易功能
- **创建订单**: 一键下单购买商品
- **订单管理**: 查看购买和销售订单
- **订单状态**: 待支付、已支付、已完成、已取消等

### 数据库特性
- **触发器**: 自动更新信用分、商品状态、售出时间
- **视图**: 热门商品、用户统计、订单详情等视图
- **索引**: 优化查询性能的多个索引
- **约束**: 外键约束保证数据完整性

## 数据库设计

### ER模型
系统包含8个主要实体：
- User (用户)
- Category (分类)
- Product (商品)
- Order (订单)
- Review (评价)
- Favorite (收藏)
- Message (消息)
- SystemLog (系统日志)

### 范式要求
所有关系模式均满足第三范式(3NF)，确保：
- 消除数据冗余
- 避免插入、删除、更新异常
- 提高数据一致性

详细的数据库设计请参考 `项目文档.md`

## 开发指南

### 添加新功能

1. 在 `models.py` 中定义数据模型
2. 在 `app.py` 中添加路由和业务逻辑
3. 在 `templates/` 中创建HTML模板
4. 在 `static/` 中添加CSS/JS

### 数据库迁移

```bash
# 如果修改了模型，需要删除旧数据库并重新初始化
rm campus_trade.db
python init_db.py
```

### 自定义配置

编辑 `.env` 文件修改配置：

```env
SECRET_KEY=your-secret-key
DATABASE_URL=sqlite:///campus_trade.db
FLASK_ENV=development
```

## API接口

### 收藏商品
```
POST /product/<product_id>/favorite
```

### 创建订单
```
POST /order/create/<product_id>
```

## 常见问题

### Q1: 导入模块失败
**A**: 请确保已安装所有依赖 `pip install -r requirements.txt`

### Q2: 数据库初始化失败
**A**: 删除 `campus_trade.db` 文件后重新运行 `python init_db.py`

### Q3: 图片上传失败
**A**: 确保 `static/uploads/` 目录存在且有写入权限

### Q4: 端口被占用
**A**: 修改 `app.py` 中的端口号：`app.run(port=5001)`

## 项目截图

（此处可添加项目运行截图）

## 课程要求对照

### 文档要求 ✅
- [x] 项目背景概述
- [x] 需求分析（数据字典、数据流）
- [x] 概念模型设计（E-R图）
- [x] 逻辑结构设计（关系模式、3NF）
- [x] 物理结构设计（索引设计）
- [x] 基本功能说明（SQL语句、触发器）
- [x] 小结（心得体会）

### 技术实现 ✅
- [x] 数据库应用系统原型
- [x] 完整的数据库设计
- [x] 触发器实现
- [x] 视图定义
- [x] 索引优化
- [x] 数据完整性约束

## 贡献者

- [你的姓名] - 项目负责人
- [成员2] - 数据库设计
- [成员3] - 前端开发
- [成员4] - 后端开发

## 许可证

MIT License

## 联系方式

如有问题，请联系：
- 邮箱: your-email@example.com
- GitHub: [your-github]

## 致谢

感谢老师的悉心指导和同学们的大力支持！

---

**说明**: 这是一个教学项目，仅用于数据库课程设计学习，不建议直接用于生产环境。

