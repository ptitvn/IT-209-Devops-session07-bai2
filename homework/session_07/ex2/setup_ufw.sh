#!/bin/bash
# ==============================================================================
# Script: setup_ufw.sh
# Bài 2: Quản trị Tường lửa UFW cho Cụm Dịch vụ Multi-port
# ==============================================================================

set -e

echo "=============================================="
echo " [0/5] Kiểm tra và cài đặt UFW (nếu chưa có)"
echo "=============================================="
if ! command -v ufw &> /dev/null; then
    echo "UFW chưa được cài đặt. Đang tiến hành cài đặt ufw..."
    sudo apt-get update -y
    sudo apt-get install -y ufw
    echo "Cài đặt UFW hoàn tất!"
fi

echo "=============================================="
echo " [1/5] Thiết lập chính sách mặc định (Default Policies)"
echo "=============================================="
# Chặn toàn bộ lưu lượng đi vào mặc định
sudo ufw default deny incoming
# Cho phép lưu lượng đi ra ngoài mặc định
sudo ufw default allow outgoing

echo "=============================================="
echo " [2/5] Cấu hình mở các cổng dịch vụ yêu cầu"
echo "=============================================="
# Cho phép SSH để quản trị từ xa
sudo ufw allow 22/tcp comment 'SSH Remote Management'

# Cho phép Web HTTP tiêu chuẩn
sudo ufw allow 80/tcp comment 'Nginx Web Server'

# Cho phép ứng dụng Spring Boot
sudo ufw allow 8082/tcp comment 'Spring Boot Application'

# Lưu ý: Cổng MySQL (3306/tcp) KHÔNG được thêm luật cho phép (bị chặn bởi default deny)
echo "Lưu ý: Cổng MySQL (3306/tcp) không được mở để đảm bảo cô lập CSDL từ Internet."

echo "=============================================="
echo " [3/5] Kích hoạt tường lửa UFW"
echo "=============================================="
# Kích hoạt UFW (dùng cờ --force để không hỏi xác nhận tương tác nếu chạy tự động)
sudo ufw --force enable

echo "=============================================="
echo " [4/5] Tải lại cấu hình UFW (Reload)"
echo "=============================================="
sudo ufw reload

echo "=============================================="
echo " [5/5] Kiểm tra trạng thái UFW chi tiết"
echo "=============================================="
echo ""
sudo ufw status verbose
echo ""
echo "=============================================="
echo " Hoàn tất thiết lập tường lửa UFW thành công!"
echo " Hãy sao chép kết quả trên vào file README.md."
echo "=============================================="
