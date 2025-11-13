"""
Flask应用主文件
校园二手交易平台
"""
import os
from flask import Flask, render_template, request, redirect, url_for, flash, jsonify
from flask_login import LoginManager, login_user, logout_user, login_required, current_user
from werkzeug.utils import secure_filename
from config import Config
from models import db, User, Product, Category, Order, Favorite, SystemLog
from datetime import datetime
import uuid

# 创建Flask应用
app = Flask(__name__)
app.config.from_object(Config)

# 初始化数据库
db.init_app(app)

# 初始化登录管理器
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'login'
login_manager.login_message = '请先登录'


@login_manager.user_loader
def load_user(user_id):
    """加载用户"""
    return User.query.get(int(user_id))


def allowed_file(filename):
    """检查文件扩展名"""
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in app.config['ALLOWED_EXTENSIONS']


# ==================== 路由定义 ====================

@app.route('/')
def index():
    """首页 - 展示最新商品"""
    page = request.args.get('page', 1, type=int)
    category_id = request.args.get('category', type=int)
    keyword = request.args.get('keyword', '')

    query = Product.query.filter_by(is_deleted=False, status='available')

    if category_id:
        query = query.filter_by(category_id=category_id)

    if keyword:
        query = query.filter(Product.title.contains(keyword) |
                           Product.description.contains(keyword))

    products = query.order_by(Product.created_at.desc()).paginate(
        page=page, per_page=app.config['ITEMS_PER_PAGE'], error_out=False
    )

    categories = Category.query.order_by(Category.sort_order).all()

    return render_template('index.html', products=products, categories=categories,
                         current_category=category_id, keyword=keyword)


@app.route('/register', methods=['GET', 'POST'])
def register():
    """用户注册"""
    if current_user.is_authenticated:
        return redirect(url_for('index'))

    if request.method == 'POST':
        student_id = request.form.get('student_id')
        username = request.form.get('username')
        password = request.form.get('password')
        real_name = request.form.get('real_name')
        email = request.form.get('email')
        phone = request.form.get('phone')
        campus = request.form.get('campus')

        # 验证数据
        if User.query.filter_by(student_id=student_id).first():
            flash('学号已存在', 'danger')
            return redirect(url_for('register'))

        if User.query.filter_by(username=username).first():
            flash('用户名已存在', 'danger')
            return redirect(url_for('register'))

        if User.query.filter_by(email=email).first():
            flash('邮箱已被注册', 'danger')
            return redirect(url_for('register'))

        # 创建用户
        user = User(
            student_id=student_id,
            username=username,
            real_name=real_name,
            email=email,
            phone=phone,
            campus=campus
        )
        user.set_password(password)

        db.session.add(user)
        db.session.commit()

        # 记录日志
        log = SystemLog(user_id=user.id, action='register', description='用户注册')
        db.session.add(log)
        db.session.commit()

        flash('注册成功，请登录', 'success')
        return redirect(url_for('login'))

    return render_template('register.html')


@app.route('/login', methods=['GET', 'POST'])
def login():
    """用户登录"""
    if current_user.is_authenticated:
        return redirect(url_for('index'))

    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        remember = request.form.get('remember', False)

        user = User.query.filter_by(username=username).first()

        if user is None or not user.check_password(password):
            flash('用户名或密码错误', 'danger')
            return redirect(url_for('login'))

        if not user.is_active:
            flash('账户已被禁用，请联系管理员', 'danger')
            return redirect(url_for('login'))

        login_user(user, remember=remember)

        # 记录日志
        log = SystemLog(user_id=user.id, action='login', description='用户登录')
        db.session.add(log)
        db.session.commit()

        next_page = request.args.get('next')
        if next_page:
            return redirect(next_page)
        return redirect(url_for('index'))

    return render_template('login.html')


@app.route('/logout')
@login_required
def logout():
    """用户登出"""
    logout_user()
    flash('已成功登出', 'info')
    return redirect(url_for('index'))


@app.route('/product/<int:product_id>')
def product_detail(product_id):
    """商品详情"""
    product = Product.query.get_or_404(product_id)

    if product.is_deleted:
        flash('该商品不存在', 'warning')
        return redirect(url_for('index'))

    # 增加浏览次数
    product.view_count += 1
    db.session.commit()

    # 检查是否已收藏
    is_favorited = False
    if current_user.is_authenticated:
        is_favorited = Favorite.query.filter_by(
            user_id=current_user.id, product_id=product_id
        ).first() is not None

    # 获取卖家其他商品
    other_products = Product.query.filter(
        Product.seller_id == product.seller_id,
        Product.id != product_id,
        Product.is_deleted == False,
        Product.status == 'available'
    ).limit(4).all()

    return render_template('product_detail.html', product=product,
                         is_favorited=is_favorited, other_products=other_products)


@app.route('/product/publish', methods=['GET', 'POST'])
@login_required
def publish_product():
    """发布商品"""
    if request.method == 'POST':
        title = request.form.get('title')
        description = request.form.get('description')
        price = float(request.form.get('price'))
        original_price = request.form.get('original_price')
        category_id = int(request.form.get('category_id'))
        condition = request.form.get('condition')
        trade_location = request.form.get('trade_location')

        # 处理图片上传
        images = []
        files = request.files.getlist('images')
        for file in files:
            if file and allowed_file(file.filename):
                filename = secure_filename(file.filename)
                filename = f"{uuid.uuid4().hex}_{filename}"
                filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
                os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
                file.save(filepath)
                images.append(filename)

        product = Product(
            title=title,
            description=description,
            price=price,
            original_price=float(original_price) if original_price else None,
            category_id=category_id,
            seller_id=current_user.id,
            condition=condition,
            trade_location=trade_location,
            images=','.join(images) if images else None
        )

        db.session.add(product)
        db.session.commit()

        # 记录日志
        log = SystemLog(user_id=current_user.id, action='publish_product',
                       table_name='products', record_id=product.id,
                       description=f'发布商品：{title}')
        db.session.add(log)
        db.session.commit()

        flash('商品发布成功', 'success')
        return redirect(url_for('product_detail', product_id=product.id))

    categories = Category.query.order_by(Category.sort_order).all()
    return render_template('publish_product.html', categories=categories)


@app.route('/product/<int:product_id>/favorite', methods=['POST'])
@login_required
def toggle_favorite(product_id):
    """收藏/取消收藏商品"""
    product = Product.query.get_or_404(product_id)

    favorite = Favorite.query.filter_by(
        user_id=current_user.id, product_id=product_id
    ).first()

    if favorite:
        db.session.delete(favorite)
        product.favorite_count -= 1
        is_favorited = False
        message = '已取消收藏'
    else:
        favorite = Favorite(user_id=current_user.id, product_id=product_id)
        db.session.add(favorite)
        product.favorite_count += 1
        is_favorited = True
        message = '收藏成功'

    db.session.commit()

    return jsonify({'success': True, 'is_favorited': is_favorited,
                   'message': message, 'favorite_count': product.favorite_count})


@app.route('/order/create/<int:product_id>', methods=['POST'])
@login_required
def create_order(product_id):
    """创建订单"""
    product = Product.query.get_or_404(product_id)

    if product.status != 'available':
        flash('商品已售出或下架', 'warning')
        return redirect(url_for('product_detail', product_id=product_id))

    if product.seller_id == current_user.id:
        flash('不能购买自己的商品', 'warning')
        return redirect(url_for('product_detail', product_id=product_id))

    # 生成订单号
    order_no = f"ORD{datetime.now().strftime('%Y%m%d%H%M%S')}{uuid.uuid4().hex[:6].upper()}"

    order = Order(
        order_no=order_no,
        product_id=product_id,
        buyer_id=current_user.id,
        seller_id=product.seller_id,
        price=product.price,
        trade_location=request.form.get('trade_location', product.trade_location),
        buyer_note=request.form.get('buyer_note')
    )

    # 更新商品状态
    product.status = 'reserved'

    db.session.add(order)
    db.session.commit()

    flash('订单创建成功，请尽快支付', 'success')
    return redirect(url_for('order_detail', order_id=order.id))


@app.route('/order/<int:order_id>')
@login_required
def order_detail(order_id):
    """订单详情"""
    order = Order.query.get_or_404(order_id)

    # 只有买家和卖家可以查看
    if order.buyer_id != current_user.id and order.seller_id != current_user.id:
        flash('无权查看该订单', 'danger')
        return redirect(url_for('index'))

    return render_template('order_detail.html', order=order)




@app.route('/order/<int:order_id>/cancel', methods=['POST'])
@login_required
def cancel_order(order_id):
    """取消订单"""
    order = Order.query.get_or_404(order_id)

    #只有买家可以取消
    if order.buyer_id != current_user.id:
        flash('您无权取消该订单', 'danger')
        return redirect(url_for('order_detail', order_id=order.id))

    # 只有 'pending' (待处理) 状态的订单可以取消
    if order.status != 'pending':
        flash(f'该订单状态（{order.status}）无法取消', 'warning')
        return redirect(url_for('order_detail', order_id=order.id))

    # 更新订单状态
    order.status = 'cancelled'
    order.cancelled_at = datetime.now()  #

    # 会在此时自动将 product.status 恢复为 'available'。
    db.session.commit()
    # 记录日志
    log = SystemLog(user_id=current_user.id, action='cancel_order',
                    table_name='orders', record_id=order.id,
                    description=f'取消订单：{order.order_no}')  #
    db.session.add(log)
    db.session.commit()

    flash('订单已成功取消', 'success')
    return redirect(url_for('order_detail', order_id=order.id))


# ... (在 app.py 的 cancel_order 函数之后) ...

@app.route('/order/<int:order_id>/complete', methods=['POST'])
@login_required
def complete_order(order_id):
    """(卖家) 确认订单完成"""

    order = Order.query.get_or_404(order_id)
    if order.seller_id != current_user.id:
        flash('您无权操作该订单', 'danger')
        return redirect(url_for('order_detail', order_id=order.id))
     # 状态检查：只有 'pending' (或 'paid') 状态的订单可以被标记为完成

    if order.status != 'pending':
        flash(f'该订单状态（{order.status}）无法被标记为完成', 'warning')
        return redirect(url_for('order_detail', order_id=order.id))


    order.status = 'completed'
    order.completed_at = datetime.now()  #

    # 2. 更新商品状态
    if order.product:
        order.product.status = 'sold'
        # 数据库触发器 'update_sold_time' 会自动更新 sold_at

    # 3. 提交数据库
    db.session.commit()
    # 4. 记录日志
    log = SystemLog(user_id=current_user.id, action='complete_order',
                    table_name='orders', record_id=order.id,
                    description=f'确认订单完成：{order.order_no}')
    db.session.add(log)
    db.session.commit()

    flash('交易已成功确认完成！双方信用分已更新。', 'success')
    return redirect(url_for('order_detail', order_id=order.id))


@app.route('/user/profile')
@login_required
def user_profile():
    """用户个人中心"""
    return render_template('user_profile.html', user=current_user)


@app.route('/user/products')
@login_required
def user_products():
    """我的商品"""
    page = request.args.get('page', 1, type=int)
    products = Product.query.filter_by(
        seller_id=current_user.id, is_deleted=False
    ).order_by(Product.created_at.desc()).paginate(
        page=page, per_page=app.config['ITEMS_PER_PAGE'], error_out=False
    )
    return render_template('user_products.html', products=products)


@app.route('/user/orders')
@login_required
def user_orders():
    """我的订单"""
    order_type = request.args.get('type', 'buy')  # buy or sell
    page = request.args.get('page', 1, type=int)

    if order_type == 'buy':
        orders = Order.query.filter_by(buyer_id=current_user.id)
    else:
        orders = Order.query.filter_by(seller_id=current_user.id)

    orders = orders.order_by(Order.created_at.desc()).paginate(
        page=page, per_page=app.config['ITEMS_PER_PAGE'], error_out=False
    )

    return render_template('user_orders.html', orders=orders, order_type=order_type)


@app.route('/user/favorites')
@login_required
def user_favorites():
    """我的收藏"""
    page = request.args.get('page', 1, type=int)
    favorites = Favorite.query.filter_by(user_id=current_user.id).order_by(
        Favorite.created_at.desc()
    ).paginate(page=page, per_page=app.config['ITEMS_PER_PAGE'], error_out=False)

    return render_template('user_favorites.html', favorites=favorites)


# ==================== 错误处理 ====================

@app.errorhandler(404)
def not_found_error(error):
    return render_template('errors/404.html'), 404


@app.errorhandler(500)
def internal_error(error):
    db.session.rollback()
    return render_template('errors/500.html'), 500


# ==================== 上下文处理器 ====================

@app.context_processor
def utility_processor():
    """模板上下文处理器"""
    return {
        'now': datetime.now,
        'enumerate': enumerate
    }


if __name__ == '__main__':
    with app.app_context():
        db.create_all()
        print("数据库表创建成功！")

    app.run(debug=True, host='0.0.0.0', port=5001)

