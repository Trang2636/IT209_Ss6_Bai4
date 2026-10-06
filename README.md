# Bài 4: Quản lý tiến trình nền với nohup và tín hiệu Kill

## 1. Mục tiêu

- Khởi chạy tiến trình chạy nền độc lập với phiên Terminal bằng `nohup` và `&`.
- Giám sát tiến trình bằng `ps`, `pgrep`, `top`/`htop`.
- Sử dụng lệnh `kill` với các tín hiệu (Signals) để quản lý tiến trình.

---

## 2. Mã nguồn script `loop-monitor.sh`

```bash
#!/bin/bash
# ============================================================
# loop-monitor.sh - Script giám sát hệ thống chạy nền
# Mô tả: Ghi thời gian hiện tại vào /tmp/monitor.log mỗi 5s
# Sử dụng: nohup ./loop-monitor.sh > /dev/null 2>&1 &
# ============================================================

LOG_FILE="/tmp/monitor.log"

echo "==== Monitor script started at $(date) ====" >> "$LOG_FILE"

while true; do
    echo "System time: $(date)" >> "$LOG_FILE"
    sleep 5
done
```

---

## 3. Các bước thực hiện

### Bước 1: Gán quyền thực thi cho script

```bash
chmod +x loop-monitor.sh
```

### Bước 2: Khởi chạy script ở chế độ nền với `nohup`

```bash
nohup ./loop-monitor.sh > /dev/null 2>&1 &
```

> **Giải thích lệnh:**
>
> | Thành phần | Ý nghĩa |
> |---|---|
> | `nohup` | Đảm bảo tiến trình không bị hủy khi đóng terminal (immune to HUP signal) |
> | `./loop-monitor.sh` | Script cần chạy |
> | `> /dev/null` | Redirect stdout sang /dev/null (không ghi ra terminal) |
> | `2>&1` | Redirect stderr vào cùng stdout |
> | `&` | Chạy tiến trình ở chế độ nền (background) |

**Kết quả:**

```
[1] 28451
```

Số `28451` chính là **PID** (Process ID) của tiến trình vừa được khởi tạo.

---

### Bước 3: Tìm PID của tiến trình

**Cách 1 - Sử dụng `pgrep`:**

```bash
pgrep -f loop-monitor.sh
```

**Kết quả:**

```
28451
```

**Cách 2 - Sử dụng `ps aux`:**

```bash
ps aux | grep loop-monitor.sh
```

**Kết quả:**

```
user     28451  0.0  0.0   8312  3120 ?        S    14:30   0:00 /bin/bash ./loop-monitor.sh
user     28520  0.0  0.0   6420   720 pts/0    S+   14:31   0:00 grep --color=auto loop-monitor.sh
```

> Dòng chứa `grep` là tiến trình tìm kiếm, **không phải** tiến trình monitor. PID thực tế là `28451`.

---

### Bước 4: Kiểm tra file log đang được ghi liên tục

```bash
tail -n 10 /tmp/monitor.log
```

**Kết quả:**

```
==== Monitor script started at Tue Oct  6 14:30:00 UTC 2026 ====
System time: Tue Oct  6 14:30:00 UTC 2026
System time: Tue Oct  6 14:30:05 UTC 2026
System time: Tue Oct  6 14:30:10 UTC 2026
System time: Tue Oct  6 14:30:15 UTC 2026
System time: Tue Oct  6 14:30:20 UTC 2026
System time: Tue Oct  6 14:30:25 UTC 2026
System time: Tue Oct  6 14:30:30 UTC 2026
System time: Tue Oct  6 14:30:35 UTC 2026
System time: Tue Oct  6 14:30:40 UTC 2026
```

> Log ghi đều đặn mỗi 5 giây, xác nhận script hoạt động chính xác.

---

### Bước 5: Kiểm tra tiến trình vẫn chạy sau khi đóng & mở lại terminal

Đóng terminal hiện tại, mở terminal mới và kiểm tra:

```bash
pgrep -f loop-monitor.sh
```

**Kết quả:** Tiến trình vẫn hiển thị PID → xác nhận `nohup` hoạt động đúng, tiến trình **không bị hủy** khi tắt session terminal.

---

### Bước 6: Tắt tiến trình bằng tín hiệu Kill

**Bước 6a — Sử dụng SIGTERM (tín hiệu 15) trước:**

```bash
kill -15 28451
```

> `SIGTERM` (Signal 15) là tín hiệu "graceful shutdown" — yêu cầu tiến trình tự dọn dẹp và thoát.

Kiểm tra tiến trình đã tắt:

```bash
ps aux | grep loop-monitor.sh
```

**Kết quả:**

```
user     28600  0.0  0.0   6420   720 pts/0    S+   14:35   0:00 grep --color=auto loop-monitor.sh
```

> Chỉ còn tiến trình `grep`, tiến trình monitor đã bị tắt thành công bằng `SIGTERM`.

**Bước 6b — Trường hợp SIGTERM không hiệu quả, sử dụng SIGKILL (tín hiệu 9):**

```bash
kill -9 28451
```

> `SIGKILL` (Signal 9) là tín hiệu **bắt buộc tắt ngay lập tức** — tiến trình không thể chặn hay bỏ qua tín hiệu này. Chỉ nên dùng khi `SIGTERM` thất bại.

---

## 4. So sánh SIGTERM vs SIGKILL

| Tín hiệu | Số hiệu | Hành vi | Có thể bắt/chặn? | Khi nào dùng |
|---|---|---|---|---|
| `SIGTERM` | 15 | Yêu cầu tắt graceful | ✅ Có | Ưu tiên dùng trước |
| `SIGKILL` | 9 | Buộc tắt ngay lập tức | ❌ Không | Chỉ khi SIGTERM thất bại |

---

## 5. Tổng kết

| Hạng mục | Kết quả |
|---|---|
| Script `loop-monitor.sh` ghi log mỗi 5s | ✅ Hoạt động chính xác |
| Chạy nền bằng `nohup ... &` | ✅ Thành công |
| Tiến trình tồn tại sau khi tắt terminal | ✅ Đúng kỳ vọng |
| Tìm PID bằng `pgrep` / `ps aux` | ✅ Thành công |
| Tắt bằng `kill -15` (SIGTERM) | ✅ Tiến trình dừng thành công |
| File `/tmp/monitor.log` ghi liên tục | ✅ Xác nhận qua `tail` |
