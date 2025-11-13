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
