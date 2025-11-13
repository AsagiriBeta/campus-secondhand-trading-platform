"""
数据库初始化脚本
创建数据库表、索引、触发器、视图等
"""
from app import app, db
from models import User, Product, Category


def init_database():
    """初始化数据库"""
    with app.app_context():
        # 删除所有表
        db.drop_all()
        print("已删除所有表")

        # 创建所有表
        db.create_all()
        print("已创建所有表")

        # 创建索引
        create_indexes()

        # 创建视图
        create_views()

        # 插入初始数据
        insert_initial_data()

        print("数据库初始化完成！")


def create_indexes():
    """创建额外的索引（提高查询性能）"""
    with app.app_context():
        # 执行原始SQL创建索引
        db.session.execute(db.text("""
            CREATE INDEX IF NOT EXISTS idx_products_price ON products(price);
        """))

        db.session.execute(db.text("""
            CREATE INDEX IF NOT EXISTS idx_products_status_created ON products(status, created_at DESC);
        """))

        db.session.execute(db.text("""
            CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
        """))

        db.session.commit()
        print("索引创建成功")


def create_views():
    """创建视图"""
    with app.app_context():
        # 创建热门商品视图
        db.session.execute(db.text("""
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
        """))

        # 创建用户统计视图
        db.session.execute(db.text("""
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
        """))

        # 创建订单详情视图
        db.session.execute(db.text("""
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
        """))

        db.session.commit()
        print("视图创建成功")


def insert_initial_data():
    """插入初始数据"""
    with app.app_context():
        # 创建商品分类
        categories = [
            Category(name='数码产品', description='手机、电脑、平板等', icon='laptop', sort_order=1),
            Category(name='图书教材', description='各类教材、课外书籍', icon='book', sort_order=2),
            Category(name='生活用品', description='日用品、家居用品', icon='home', sort_order=3),
            Category(name='体育用品', description='运动器材、健身用品', icon='basketball', sort_order=4),
            Category(name='服装配饰', description='衣服、鞋子、包包等', icon='shopping-bag', sort_order=5),
            Category(name='文具用品', description='笔记本、笔、文件夹等', icon='pen', sort_order=6),
            Category(name='乐器音响', description='吉他、音箱等', icon='music', sort_order=7),
            Category(name='其他', description='其他类别商品', icon='tag', sort_order=99),
        ]

        for category in categories:
            db.session.add(category)

        db.session.commit()
        print(f"已创建 {len(categories)} 个商品分类")

        # 创建测试用户
        test_users = [
            {
                'student_id': '2022001',
                'username': 'zhangsan',
                'real_name': '张三',
                'email': 'zhangsan@example.com',
                'phone': '13800138001',
                'campus': '本部',
                'dormitory': '1号楼101',
                'password': '123456'
            },
            {
                'student_id': '2022002',
                'username': 'lisi',
                'real_name': '李四',
                'email': 'lisi@example.com',
                'phone': '13800138002',
                'campus': '本部',
                'dormitory': '2号楼201',
                'password': '123456'
            },
            {
                'student_id': '2022003',
                'username': 'wangwu',
                'real_name': '王五',
                'email': 'wangwu@example.com',
                'phone': '13800138003',
                'campus': '东区',
                'dormitory': '3号楼301',
                'password': '123456'
            }
        ]

        for user_data in test_users:
            password = user_data.pop('password')
            user = User(**user_data)
            user.set_password(password)
            user.balance = 1000.0  # 初始余额
            db.session.add(user)

        db.session.commit()
        print(f"已创建 {len(test_users)} 个测试用户")

        # 创建测试商品
        test_products = [
            {
                'title': 'iPhone 13 Pro 256G',
                'description': '9成新，无磕碰，功能完好，配件齐全。因换新机出售。',
                'price': 4500.0,
                'original_price': 7999.0,
                'category_id': 1,
                'seller_id': 1,
                'condition': '几乎全新',
                'trade_location': '图书馆门口',
            },
            {
                'title': '高等数学教材（第七版）',
                'description': '同济大学版本，9成新，无笔记无划线。',
                'price': 25.0,
                'original_price': 48.0,
                'category_id': 2,
                'seller_id': 1,
                'condition': '几乎全新',
                'trade_location': '教学楼A座',
            },
            {
                'title': '自行车 美利达',
                'description': '骑行2个月，车况良好，因毕业离校出售。',
                'price': 350.0,
                'original_price': 800.0,
                'category_id': 4,
                'seller_id': 2,
                'condition': '轻微使用痕迹',
                'trade_location': '宿舍楼下',
            },
            {
                'title': 'ThinkPad T480 笔记本',
                'description': 'i5-8250U，8G内存，256G固态，14寸屏幕，适合办公学习。',
                'price': 2200.0,
                'original_price': 5000.0,
                'category_id': 1,
                'seller_id': 2,
                'condition': '明显使用痕迹',
                'trade_location': '咖啡厅',
            },
            {
                'title': '电热水壶',
                'description': '美的品牌，使用半年，功能正常。',
                'price': 30.0,
                'original_price': 89.0,
                'category_id': 3,
                'seller_id': 3,
                'condition': '轻微使用痕迹',
                'trade_location': '食堂门口',
            }
        ]

        for product_data in test_products:
            product = Product(**product_data)
            db.session.add(product)

        db.session.commit()
        print(f"已创建 {len(test_products)} 个测试商品")


def create_triggers():
    """创建触发器（SQLite支持的触发器）"""
    with app.app_context():
        # 触发器1: 订单完成后更新用户信用分
        db.session.execute(db.text("""
            CREATE TRIGGER IF NOT EXISTS update_credit_score_on_order_complete
            AFTER UPDATE ON orders
            WHEN NEW.status = 'completed' AND OLD.status != 'completed'
            BEGIN
                UPDATE users SET credit_score = credit_score + 5 
                WHERE id = NEW.seller_id AND credit_score < 150;
                
                UPDATE users SET credit_score = credit_score + 2 
                WHERE id = NEW.buyer_id AND credit_score < 150;
            END;
        """))

        # 触发器2: 订单取消后恢复商品状态
        db.session.execute(db.text("""
            CREATE TRIGGER IF NOT EXISTS restore_product_on_cancel
            AFTER UPDATE ON orders
            WHEN NEW.status = 'cancelled' AND OLD.status != 'cancelled'
            BEGIN
                UPDATE products SET status = 'available' 
                WHERE id = NEW.product_id;
            END;
        """))

        # 触发器3: 商品售出后更新售出时间
        db.session.execute(db.text("""
            CREATE TRIGGER IF NOT EXISTS update_sold_time
            AFTER UPDATE ON products
            WHEN NEW.status = 'sold' AND OLD.status != 'sold'
            BEGIN
                UPDATE products SET sold_at = datetime('now') 
                WHERE id = NEW.id;
            END;
        """))

        # 触发器4: 插入评价后更新被评价人信用分
        db.session.execute(db.text("""
            CREATE TRIGGER IF NOT EXISTS update_credit_on_review
            AFTER INSERT ON reviews
            BEGIN
                UPDATE users 
                SET credit_score = credit_score + (NEW.rating - 3) * 2
                WHERE id = NEW.reviewee_id 
                AND credit_score + (NEW.rating - 3) * 2 BETWEEN 0 AND 150;
            END;
        """))

        db.session.commit()
        print("触发器创建成功")


if __name__ == '__main__':
    init_database()
    create_triggers()
    print("\n数据库初始化完成！")
    print("测试账号：")
    print("  用户名: zhangsan, 密码: 123456")
    print("  用户名: lisi, 密码: 123456")
    print("  用户名: wangwu, 密码: 123456")
