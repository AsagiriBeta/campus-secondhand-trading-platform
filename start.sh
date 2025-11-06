#!/bin/bash
# 校园二手交易平台 - 一键启动脚本

echo "=========================================="
echo "  校园二手交易平台"
echo "  数据库原理与应用课程设计"
echo "=========================================="
echo ""

# 检查Python版本
echo "✓ 检查Python环境..."
python --version

# 检查数据库
if [ ! -f "campus_trade.db" ]; then
    echo "✓ 数据库不存在，正在初始化..."
    python init_db.py
else
    echo "✓ 数据库已存在"
fi

# 启动应用
echo ""
echo "✓ 启动Flask应用..."
echo "✓ 访问地址: http://127.0.0.1:5001"
echo ""
echo "测试账号："
echo "  - 用户名: zhangsan, 密码: 123456"
echo "  - 用户名: lisi, 密码: 123456"
echo "  - 用户名: wangwu, 密码: 123456"
echo ""
echo "按 Ctrl+C 停止服务"
echo "=========================================="
echo ""

python app.py

