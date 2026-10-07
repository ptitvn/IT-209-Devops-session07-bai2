# Báo Cáo Thực Hành: Quản Trị Tường Lửa UFW cho Cụm Dịch Vụ Multi-port


## 1. Mục Tiêu

- Thiết lập tường lửa UFW (Uncomplicated Firewall) để bảo vệ máy chủ Linux chạy đồng thời nhiều cổng dịch vụ mạng.
- Cấu hình mở cổng cho các dịch vụ công khai (Web, Spring Boot, SSH) và cô lập hoàn toàn các cổng cơ sở dữ liệu nội bộ (MySQL) khỏi truy cập Internet bên ngoài.
- Rèn luyện kỹ năng thiết lập chính sách bảo mật tối thiểu (Principle of Least Privilege) trên hệ thống tường lửa.

---

## 2. Bối Cảnh & Phân Tích Cổng Dịch Vụ

Máy chủ dự kiến triển khai các dịch vụ:
1. **SSH (Port 22/tcp):** Truy cập và quản trị máy chủ từ xa.
2. **Nginx Web Server (Port 80/tcp):** Phục vụ giao thức HTTP cho người dùng cuối.
3. **Spring Boot Application (Port 8082/tcp):** Ứng dụng Backend API kiểm tra từ xa.
4. **MySQL Database (Port 3306/tcp):** Hệ quản trị CSDL, chỉ phục vụ nội bộ máy chủ hoặc mạng private, **tuyệt đối không mở ra Internet** để tránh tấn công brute-force và rò rỉ dữ liệu.

### Bảng Phân Tích & Chính Sách Tường Lửa

| Cổng Dịch Vụ | Giao thức | Dịch vụ | Mục đích | Chính sách UFW |
| :--- | :--- | :--- | :--- | :--- |
| **Default Incoming** | Any | Mọi dịch vụ vào | Bảo vệ mặc định | **DENY** |
| **Default Outgoing** | Any | Mọi kết nối ra ngoài | Cập nhật hệ thống, tải package | **ALLOW** |
| **22** | TCP | SSH | Quản trị từ xa | **ALLOW IN** (Anywhere) |
| **80** | TCP | Nginx Web | Phục vụ Web HTTP | **ALLOW IN** (Anywhere) |
| **8082** | TCP | Spring Boot App | Kiểm thử ứng dụng Backend | **ALLOW IN** (Anywhere) |
| **3306** | TCP | MySQL Server | Lưu trữ cơ sở dữ liệu | **KHÔNG MỞ** (Bị chặn bởi Default Deny) |

---

## 3. Các Bước Cấu Hình Chi Tiết

### Cách 1: Chạy file script tự động hóa

Chúng tôi đã chuẩn bị sẵn script thực thi tự động [setup_ufw.sh](setup_ufw.sh):

```bash
# Cấp quyền thực thi và chạy script
chmod +x setup_ufw.sh
./setup_ufw.sh
```

---

### Cách 2: Thực thi từng câu lệnh thủ công

#### Bước 1: Thiết lập chính sách mặc định
Chặn toàn bộ lưu lượng đi vào và cho phép toàn bộ lưu lượng đi ra:
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

#### Bước 2: Cho phép các cổng dịch vụ quy định
Mở cổng quản trị SSH (22/tcp):
```bash
sudo ufw allow 22/tcp comment 'SSH Remote Management'
```

Mở cổng dịch vụ Web HTTP (80/tcp):
```bash
sudo ufw allow 80/tcp comment 'Nginx Web Server'
```

Mở cổng ứng dụng Spring Boot (8082/tcp):
```bash
sudo ufw allow 8082/tcp comment 'Spring Boot Application'
```

> **Lưu ý:** Cổng **3306/tcp (MySQL)** không thêm luật `allow`. Dựa theo chính sách `default deny incoming`, cổng này sẽ tự động bị từ chối mọi kết nối từ bên ngoài Internet.

#### Bước 3: Kích hoạt tường lửa UFW
```bash
sudo ufw --force enable
sudo ufw reload
```

---

## 4. Kết Quả Đầu Ra Thực Tế (Output)

Lệnh kiểm tra trạng thái tường lửa chi tiết:
```bash
sudo ufw status verbose
```

### Kết quả đầu ra ghi nhận:

```text
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)
New profiles: skip

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW IN    Anywhere                   # SSH Remote Management
80/tcp                     ALLOW IN    Anywhere                   # Nginx Web Server
8082/tcp                   ALLOW IN    Anywhere                   # Spring Boot Application
22/tcp (v6)                ALLOW IN    Anywhere (v6)              # SSH Remote Management
80/tcp (v6)                ALLOW IN    Anywhere (v6)              # Nginx Web Server
8082/tcp (v6)              ALLOW IN    Anywhere (v6)              # Spring Boot Application
```

---

## 5. Đánh Giá & Xác Minh Kết Quả

1. **Trạng thái tường lửa:**
   - `Status: active`: Tường lửa đang hoạt động và áp dụng các luật lọc gói tin.
2. **Chính sách gốc (Default Policy):**
   - `deny (incoming)`: Toàn bộ lưu lượng đến cổng chưa được khai báo đều bị loại bỏ tự động.
   - `allow (outgoing)`: Máy chủ vẫn có thể tải gói tin, gọi API ra ngoài bình thường.
3. **Các cổng công khai:**
   - Các cổng `22/tcp`, `80/tcp`, `8082/tcp` đều có trạng thái `ALLOW IN` từ `Anywhere` cho cả IPv4 và IPv6.
4. **Cô lập Cơ sở Dữ liệu MySQL:**
   - Cổng `3306/tcp` hoàn toàn không có trong danh sách `ALLOW IN`.
   - Kết hợp với chính sách `deny (incoming)`, các cuộc tấn công quét cổng từ Internet vào cổng 3306 sẽ bị tường lửa chặn đứng.
