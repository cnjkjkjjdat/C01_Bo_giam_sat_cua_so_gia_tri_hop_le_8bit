# C01 · Phần điều khiển (Control)

---

## 1. Kết luận: C01 **không có phần điều khiển** — nhưng có một tín hiệu *tự sinh* đóng vai điều khiển

| Khái niệm | C01 có không? | Bằng chứng |
|---|:-:|---|
| **Khối điều khiển** (FSM, bộ đếm, máy trạng thái theo thời gian) | ❌ Không | RTL chỉ có một `always_comb`; không clock, không reset; netlist 0 cell tuần tự |
| **Tín hiệu điều khiển đến từ bên ngoài** (enable, mode, start) | ❌ Không | Giao diện chỉ có 3 cổng vào, cả ba đều là dữ liệu 8 bit |
| **Tín hiệu điều khiển sinh ra bên trong** | ✅ **Có** — `config_error` | `config_error` vừa là đầu ra, vừa chặn `below` và `above` |

C01 vì thế là một trường hợp thú vị: nó **không nhận lệnh từ ai**, nhưng nó **tự sinh ra một
tín hiệu chặn** từ chính dữ liệu cấu hình của mình.

## 2. Bằng chứng không có phần điều khiển

| # | Bằng chứng | Trạng thái | Nguồn |
|---|---|:-:|---|
| B-1 | RTL không có `always_ff`, không có `posedge` | ✅ | `c01_window_monitor.sv` — chỉ một `always_comb` (dòng 13) |
| B-2 | Giao diện không có `clk`, không có `rst` | ✅ | `02_SPECIFICATION/interface.md` |
| B-3 | **Netlist có 0 cell tuần tự** | ✅ | `synth_stat.txt` — 52 cell, không cell nào là `__df*` hay `__dlatch*` |
| B-4 | **Công suất nhóm Sequential = 0,0 %** | ✅ | `power_report.txt` — Combinational 100,0 % |
| B-5 | **Clock trong STA là clock ảo** (`vclk`), không phải clock thật | ✅ | `design.sdc`: `create_clock -name vclk -period 10.0`, không gắn vào cổng nào |

> Bốn bằng chứng B-1…B-4 **độc lập** với nhau (mã nguồn, giao diện, cấu trúc netlist, báo
> cáo công suất). Đây là mức chắc chắn cao nhất mà hồ sơ này đạt được cho bất kỳ khẳng định
> nào — và nó tương phản rõ với đề B09 trong cùng học phần, nơi khẳng định tương tự **không**
> chứng minh được.

## 3. `config_error` — tín hiệu điều khiển nội bộ

### 3.1 Bảng tác dụng

| `config_error` | Tác dụng lên datapath | Hiện thực trong netlist |
|:-:|---|---|
| `0` | Ba cờ phân loại hoạt động bình thường | `_98_/X = _17_ & 1`, `_99_/X = _40_ & 1` |
| `1` | **Chặn** `below` và `above` về 0; `inside` tự bằng 0 theo cấu trúc | `_98_/X = _17_ & 0 = 0`, `_99_/X = _40_ & 0 = 0` |

### 3.2 Nó điều khiển cái gì và **không** điều khiển cái gì

```
                     config_error
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
      _98_ SLEEP     _99_ SLEEP     cổng ra config_error
          │               │
          ▼               ▼
        above           below

     ✗ KHÔNG đi vào cell _89_ (sinh `inside`)
     ✗ KHÔNG chặn ba bộ so sánh — chúng vẫn tính bình thường
```

**Hai nhận xét kiến trúc quan trọng:**

1. **`config_error` chặn ở cuối, không chặn ở đầu.** Ba bộ so sánh vẫn chạy và vẫn tiêu tốn
   công suất chuyển mạch kể cả khi cấu hình sai. Nếu muốn tiết kiệm công suất thì phải chặn
   đầu vào (operand isolation) — nhưng khi đó `config_error` lại nằm **trước** các chuỗi so
   sánh, làm đường tới hạn **dài thêm một chuỗi nữa**. Đây là đánh đổi công suất ↔ tốc độ,
   và với C01 (slack còn 7,30 ns, công suất 1,21e-05 W) thì **không đáng đổi**.

2. **`inside` không bị chặn — và đó là kết luận đúng của công cụ.** Chứng minh hình thức ở
   `03_ARCHITECTURE/datapath.md` §5: khi `min > max` thì cửa sổ rỗng, nên `inside` tự bằng 0.

## 4. Nghĩa vụ hợp đồng của tầng ngoài

| # | Nghĩa vụ | Hậu quả nếu bỏ qua |
|---|---|---|
| N-1 | Giữ `min_val`, `max_val` **ổn định** trong suốt cửa sổ lấy mẫu | Ngưỡng đổi giữa chừng ⟹ ba cờ không nhất quán với nhau |
| N-2 | Chỉ lấy mẫu đầu ra sau **≥ 2,70 ns** kể từ lần đầu vào đổi cuối cùng (số sau tổng hợp, **chưa** tính dây) | Lấy phải giá trị trung gian |
| N-3 | **Đọc `config_error` trước khi tin ba cờ kia** | Cấu hình sai bị hiểu nhầm thành "mẫu bình thường, không vùng nào" |
| N-4 | Nạp cấu hình thoả `min_val ≤ max_val`, và **kiểm lại bằng `config_error`** sau khi nạp | Cửa sổ vô nghĩa chạy âm thầm |
| N-5 | Nếu ADC và tầng xử lý khác miền clock: đặt bộ đồng bộ **ngoài** C01 | C01 không có bất kỳ phần tử đồng bộ nào |
| N-6 | Không dùng ba cờ làm clock hay enable của latch | Glitch trong vùng quá độ |
| N-7 | Chấp nhận rằng cờ **sẽ nhấp nháy** khi mẫu dao động quanh biên | C01 **cố ý** không có hysteresis (đó là C04). Muốn cờ ổn định thì lọc ở tầng ngoài |

> N-7 hay bị hiểu nhầm thành lỗi. Với `min=50`, mẫu dao động `49,50,49,50…` sẽ làm
> `below`/`inside` nhấp nháy theo. **Đó là hành vi đúng** của một khối không trạng thái.
> Mọi cơ chế làm nó "êm" hơn đều cần bộ nhớ, và bộ nhớ nằm ngoài phạm vi C01.

## 5. So sánh với `threshold_alarm` — trả lời Charter mục 2 câu 3

> *"Khối này khác case threshold_alarm của học phần ở đúng chỗ nào?"*

| Tiêu chí | `threshold_alarm` (một ngưỡng) | **C01** (cửa sổ hai ngưỡng) |
|---|---|---|
| Số ngưỡng | 1 | **2** |
| Số bộ so sánh trong RTL | 1 | **3** (hai cho mẫu, một cho cấu hình) |
| Số trạng thái phân loại | 2 (`dưới` / `từ ngưỡng trở lên`) | **3** (`below` / `inside` / `above`) |
| Cần logic loại trừ không? | Không — 2 trạng thái là phủ định của nhau, chỉ cần 1 bit | **Có** — 3 trạng thái cần bằng chứng riêng rằng chúng loại trừ nhau (INV-1, INV-2) |
| Cấu hình có thể sai không? | **Không** — một ngưỡng đơn lẻ luôn hợp lệ | **Có** — `min > max` là cấu hình vô nghĩa ⟹ **phải có `config_error`** |
| Số cờ ra | 1 | 4 |
| Số cell đo được | ⬜ chưa đo trong học phần này | **52** |

**Khác biệt cốt lõi, nói bằng một câu:** thêm ngưỡng thứ hai không chỉ nhân đôi số bộ so
sánh — nó sinh ra **hai loại nghĩa vụ hoàn toàn mới** mà một ngưỡng không có:
1. Nghĩa vụ **chứng minh ba trạng thái loại trừ nhau** (với 2 trạng thái thì hiển nhiên).
2. Nghĩa vụ **kiểm tra tính hợp lệ của chính cấu hình** (với 1 ngưỡng thì không có khái niệm
   cấu hình sai).

Nghĩa vụ thứ hai tốn **8 cell chuỗi so sánh + 2 cell chặn = 10/52 cell ≈ 19,2 %** tổng số
cell của C01 (đếm từ netlist, `block_diagram.md` §6) — một phần đáng kể, cho một chức năng
mà phiên bản một-ngưỡng hoàn toàn không cần.

## 6. Khi nào C01 sẽ cần khối điều khiển thật

| Kịch bản | Điều khiển cần có | Trạng thái |
|---|---|---|
| Nạp ngưỡng làm 2 nhịp qua cùng một bộ chân (Charter mục 4 có nhắc "nạp 2 lần bằng chân chọn") | Thanh ghi giữ nửa đầu + 1 tín hiệu chọn nhịp | Lõi RTL hiện tại **cố ý** không làm — nó nhận thẳng 3 cổng 8 bit, nhường phần vỏ chân cho tầng ngoài |
| Thêm vùng trễ (hysteresis) | Thanh ghi 1 bit giữ trạng thái trước + logic chọn ngưỡng theo trạng thái | **Ngoài phạm vi** — đó là đề C04 |
| Lọc nhiễu (yêu cầu N mẫu liên tiếp mới đổi cờ) | Bộ đếm + FSM | **Ngoài phạm vi** (Charter mục 3) |
| Nhiều cửa sổ, quét lần lượt | FSM + bộ đếm chỉ số cửa sổ | Không có trong Charter |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Truy vết: Charter mục 2 câu 3.*
