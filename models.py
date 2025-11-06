"""
数据库模型定义
包含用户、商品、订单、评价、收藏等表
所有关系均满足3NF（第三范式）
"""
from datetime import datetime
from flask_sqlalchemy import SQLAlchemy
from flask_login import UserMixin
from werkzeug.security import generate_password_hash, check_password_hash

db = SQLAlchemy()


class User(UserMixin, db.Model):
    """用户表 - 存储用户基本信息"""
    __tablename__ = 'users'

    id = db.Column(db.Integer, primary_key=True)
    student_id = db.Column(db.String(20), unique=True, nullable=False, index=True, comment='学号')
    username = db.Column(db.String(50), unique=True, nullable=False, index=True, comment='用户名')
    password_hash = db.Column(db.String(200), nullable=False, comment='密码哈希')
    real_name = db.Column(db.String(50), nullable=False, comment='真实姓名')
    email = db.Column(db.String(100), unique=True, nullable=False, comment='邮箱')
    phone = db.Column(db.String(20), comment='联系电话')
    campus = db.Column(db.String(50), comment='所在校区')
    dormitory = db.Column(db.String(50), comment='宿舍地址')
    avatar = db.Column(db.String(200), default='default.jpg', comment='头像路径')
    balance = db.Column(db.Float, default=0.0, comment='账户余额')
    credit_score = db.Column(db.Integer, default=100, comment='信用分')
    is_active = db.Column(db.Boolean, default=True, comment='账户是否激活')
    created_at = db.Column(db.DateTime, default=datetime.now, comment='注册时间')
    updated_at = db.Column(db.DateTime, default=datetime.now, onupdate=datetime.now, comment='更新时间')

    # 关系
    products = db.relationship('Product', backref='seller', lazy='dynamic',
                              foreign_keys='Product.seller_id')
    orders_as_buyer = db.relationship('Order', backref='buyer', lazy='dynamic',
                                     foreign_keys='Order.buyer_id')
    orders_as_seller = db.relationship('Order', backref='seller', lazy='dynamic',
                                      foreign_keys='Order.seller_id')
    favorites = db.relationship('Favorite', backref='user', lazy='dynamic', cascade='all, delete-orphan')
    reviews_given = db.relationship('Review', backref='reviewer', lazy='dynamic',
                                   foreign_keys='Review.reviewer_id')
    messages_sent = db.relationship('Message', backref='sender', lazy='dynamic',
                                   foreign_keys='Message.sender_id')
    messages_received = db.relationship('Message', backref='receiver', lazy='dynamic',
                                       foreign_keys='Message.receiver_id')

    def set_password(self, password):
        """设置密码"""
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        """验证密码"""
        return check_password_hash(self.password_hash, password)

    def __repr__(self):
        return f'<User {self.username}>'


class Category(db.Model):
    """商品分类表"""
    __tablename__ = 'categories'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(50), unique=True, nullable=False, comment='分类名称')
    description = db.Column(db.Text, comment='分类描述')
    icon = db.Column(db.String(100), comment='分类图标')
    sort_order = db.Column(db.Integer, default=0, comment='排序顺序')
    created_at = db.Column(db.DateTime, default=datetime.now)

    # 关系
    products = db.relationship('Product', backref='category', lazy='dynamic')

    def __repr__(self):
        return f'<Category {self.name}>'


class Product(db.Model):
    """商品表 - 存储商品信息"""
    __tablename__ = 'products'

    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False, index=True, comment='商品标题')
    description = db.Column(db.Text, nullable=False, comment='商品描述')
    price = db.Column(db.Float, nullable=False, comment='价格')
    original_price = db.Column(db.Float, comment='原价')
    category_id = db.Column(db.Integer, db.ForeignKey('categories.id'), nullable=False, comment='分类ID')
    seller_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True, comment='卖家ID')
    condition = db.Column(db.String(20), comment='新旧程度')  # 全新/几乎全新/轻微使用痕迹/明显使用痕迹
    status = db.Column(db.String(20), default='available', comment='状态')  # available/sold/reserved
    view_count = db.Column(db.Integer, default=0, comment='浏览次数')
    favorite_count = db.Column(db.Integer, default=0, comment='收藏次数')
    trade_location = db.Column(db.String(100), comment='交易地点')
    images = db.Column(db.Text, comment='图片路径，多个用逗号分隔')
    is_deleted = db.Column(db.Boolean, default=False, comment='是否删除')
    created_at = db.Column(db.DateTime, default=datetime.now, index=True, comment='发布时间')
    updated_at = db.Column(db.DateTime, default=datetime.now, onupdate=datetime.now)
    sold_at = db.Column(db.DateTime, comment='售出时间')

    # 关系
    favorites = db.relationship('Favorite', backref='product', lazy='dynamic', cascade='all, delete-orphan')
    orders = db.relationship('Order', backref='product', lazy='dynamic')

    def get_images_list(self):
        """获取图片列表"""
        if self.images:
            return self.images.split(',')
        return []

    def __repr__(self):
        return f'<Product {self.title}>'


class Order(db.Model):
    """订单表 - 存储交易订单信息"""
    __tablename__ = 'orders'

    id = db.Column(db.Integer, primary_key=True)
    order_no = db.Column(db.String(50), unique=True, nullable=False, index=True, comment='订单号')
    product_id = db.Column(db.Integer, db.ForeignKey('products.id'), nullable=False, comment='商品ID')
    buyer_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True, comment='买家ID')
    seller_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True, comment='卖家ID')
    price = db.Column(db.Float, nullable=False, comment='成交价格')
    status = db.Column(db.String(20), default='pending', comment='订单状态')
    # pending/paid/delivering/completed/cancelled/refunding/refunded
    payment_method = db.Column(db.String(20), comment='支付方式')  # balance/alipay/wechat
    trade_location = db.Column(db.String(100), comment='交易地点')
    buyer_note = db.Column(db.Text, comment='买家备注')
    seller_note = db.Column(db.Text, comment='卖家备注')
    created_at = db.Column(db.DateTime, default=datetime.now, index=True, comment='创建时间')
    paid_at = db.Column(db.DateTime, comment='支付时间')
    completed_at = db.Column(db.DateTime, comment='完成时间')
    cancelled_at = db.Column(db.DateTime, comment='取消时间')

    # 关系
    review = db.relationship('Review', backref='order', uselist=False, cascade='all, delete-orphan')

    def __repr__(self):
        return f'<Order {self.order_no}>'


class Review(db.Model):
    """评价表 - 存储交易评价"""
    __tablename__ = 'reviews'

    id = db.Column(db.Integer, primary_key=True)
    order_id = db.Column(db.Integer, db.ForeignKey('orders.id'), unique=True, nullable=False, comment='订单ID')
    reviewer_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True, comment='评价人ID')
    reviewee_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True, comment='被评价人ID')
    rating = db.Column(db.Integer, nullable=False, comment='评分 1-5')
    content = db.Column(db.Text, comment='评价内容')
    is_anonymous = db.Column(db.Boolean, default=False, comment='是否匿名')
    created_at = db.Column(db.DateTime, default=datetime.now, index=True)

    reviewee = db.relationship('User', foreign_keys=[reviewee_id], backref='reviews_received')

    def __repr__(self):
        return f'<Review {self.id}>'


class Favorite(db.Model):
    """收藏表 - 存储用户收藏的商品"""
    __tablename__ = 'favorites'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True, comment='用户ID')
    product_id = db.Column(db.Integer, db.ForeignKey('products.id'), nullable=False, index=True, comment='商品ID')
    created_at = db.Column(db.DateTime, default=datetime.now)

    # 联合唯一索引
    __table_args__ = (
        db.UniqueConstraint('user_id', 'product_id', name='unique_user_product'),
    )

    def __repr__(self):
        return f'<Favorite user:{self.user_id} product:{self.product_id}>'


class Message(db.Model):
    """消息表 - 存储用户间的私信"""
    __tablename__ = 'messages'

    id = db.Column(db.Integer, primary_key=True)
    sender_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True, comment='发送者ID')
    receiver_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True, comment='接收者ID')
    product_id = db.Column(db.Integer, db.ForeignKey('products.id'), comment='关联商品ID')
    content = db.Column(db.Text, nullable=False, comment='消息内容')
    is_read = db.Column(db.Boolean, default=False, comment='是否已读')
    created_at = db.Column(db.DateTime, default=datetime.now, index=True)

    related_product = db.relationship('Product', backref='messages')

    def __repr__(self):
        return f'<Message {self.id}>'


class SystemLog(db.Model):
    """系统日志表 - 记录重要操作"""
    __tablename__ = 'system_logs'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), comment='用户ID')
    action = db.Column(db.String(50), nullable=False, comment='操作类型')
    table_name = db.Column(db.String(50), comment='操作表名')
    record_id = db.Column(db.Integer, comment='记录ID')
    description = db.Column(db.Text, comment='操作描述')
    ip_address = db.Column(db.String(50), comment='IP地址')
    created_at = db.Column(db.DateTime, default=datetime.now, index=True)

    user = db.relationship('User', backref='logs')

    def __repr__(self):
        return f'<SystemLog {self.action}>'

