// 主JS文件

// 收藏功能
function toggleFavorite(productId) {
    fetch(`/product/${productId}/favorite`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            // 更新商品列表页的收藏按钮
            const btn = document.querySelector(`#favorite-btn-${productId}`);
            if (btn) {
                if (data.is_favorited) {
                    btn.classList.add('favorited');
                    btn.innerHTML = '<i class="bi bi-heart-fill"></i> 已收藏';
                } else {
                    btn.classList.remove('favorited');
                    btn.innerHTML = '<i class="bi bi-heart"></i> 收藏';
                }
            }

            // 更新商品详情页的收藏按钮
            const icon = document.getElementById('favorite-icon');
            const text = document.getElementById('favorite-text');
            if (icon && text) {
                if (data.is_favorited) {
                    icon.classList.add('bi-heart-fill');
                    icon.classList.remove('bi-heart');
                    text.textContent = '取消收藏';
                } else {
                    icon.classList.add('bi-heart');
                    icon.classList.remove('bi-heart-fill');
                    text.textContent = '收藏';
                }
            }

            // 更新收藏数量
            const countElement = document.querySelector(`#favorite-count-${productId}`);
            if (countElement) {
                countElement.textContent = data.favorite_count;
            }

            // 显示提示消息
            showToast(data.message, 'success');
        }
    })
    .catch(error => {
        console.error('Error:', error);
        showToast('操作失败，请重试', 'danger');
    });
}

// 图片预览功能
function previewImages(input) {
    const preview = document.getElementById('image-preview');
    if (!preview) return;

    preview.innerHTML = '';

    if (input.files) {
        Array.from(input.files).forEach(file => {
            const reader = new FileReader();
            reader.onload = function(e) {
                const img = document.createElement('img');
                img.src = e.target.result;
                img.className = 'image-preview';
                preview.appendChild(img);
            }
            reader.readAsDataURL(file);
        });
    }
}

// 表单验证
function validateForm(formId) {
    const form = document.getElementById(formId);
    if (!form) return true;

    const inputs = form.querySelectorAll('input[required], textarea[required], select[required]');
    let isValid = true;

    inputs.forEach(input => {
        if (!input.value.trim()) {
            input.classList.add('is-invalid');
            isValid = false;
        } else {
            input.classList.remove('is-invalid');
        }
    });

    return isValid;
}

// 提示消息
function showToast(message, type = 'info') {
    // 创建提示元素
    const toast = document.createElement('div');
    toast.className = `alert alert-${type} alert-dismissible fade show position-fixed`;
    toast.style.cssText = 'top: 20px; right: 20px; z-index: 9999; min-width: 250px;';
    toast.innerHTML = `
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;

    document.body.appendChild(toast);

    // 3秒后自动消失
    setTimeout(() => {
        toast.remove();
    }, 3000);
}

// 确认对话框
function confirmAction(message, callback) {
    if (confirm(message)) {
        callback();
    }
}

// 格式化价格
function formatPrice(price) {
    return '¥' + parseFloat(price).toFixed(2);
}

// 格式化时间
function formatDate(dateString) {
    const date = new Date(dateString);
    const now = new Date();
    const diff = now - date;

    // 小于1分钟
    if (diff < 60000) {
        return '刚刚';
    }
    // 小于1小时
    if (diff < 3600000) {
        return Math.floor(diff / 60000) + '分钟前';
    }
    // 小于1天
    if (diff < 86400000) {
        return Math.floor(diff / 3600000) + '小时前';
    }
    // 小于7天
    if (diff < 604800000) {
        return Math.floor(diff / 86400000) + '天前';
    }

    // 格式化为日期
    return date.toLocaleDateString('zh-CN');
}

// 图片懒加载
function lazyLoadImages() {
    const images = document.querySelectorAll('img[data-src]');

    const imageObserver = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const img = entry.target;
                img.src = img.dataset.src;
                img.removeAttribute('data-src');
                observer.unobserve(img);
            }
        });
    });

    images.forEach(img => imageObserver.observe(img));
}

// 页面加载完成后执行
document.addEventListener('DOMContentLoaded', function() {
    // 初始化工具提示
    const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    tooltipTriggerList.map(function (tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl);
    });

    // 初始化图片懒加载
    lazyLoadImages();

    // 自动隐藏提示消息
    setTimeout(() => {
        const alerts = document.querySelectorAll('.alert');
        alerts.forEach(alert => {
            const bsAlert = new bootstrap.Alert(alert);
            bsAlert.close();
        });
    }, 5000);
});

// 搜索建议（可选功能）
function searchSuggestion(keyword) {
    if (keyword.length < 2) return;

    fetch(`/api/search/suggestion?q=${encodeURIComponent(keyword)}`)
        .then(response => response.json())
        .then(data => {
            // 显示搜索建议
            console.log(data);
        })
        .catch(error => console.error('Error:', error));
}

