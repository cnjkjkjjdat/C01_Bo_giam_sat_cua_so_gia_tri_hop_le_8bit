# C01 · Đường dữ liệu (Datapath)

---

## 1. Đặc điểm datapath của C01: **rộng vào, hẹp ra**

C01 nhận 24 bit dữ liệu và trả về 4 bit. Không có bit dữ liệu nào **đi xuyên qua** khối —
mọi đầu ra đều là **kết luận** về đầu vào, không phải bản sao hay biến đổi của đầu vào.

```
  sample_in[7:0] ═══╗
                    ╠══▶ ┌──────────────────────────────────┐ ──▶ below         (kết luận)
  min_val[7:0]  ═══╬══▶ │  3 bộ so sánh 8 bit CHẠY SONG    │ ──▶ inside        (kết luận)
                    ║    │  SONG + logic loại trừ           │ ──▶ above         (kết luận)
  max_val[7:0]  ═══╝    └──────────────────────────────────┘ ──▶ config_error  (kết luận)

    24 bit vào                                                     4 bit ra
    ═══▶ dữ liệu nhiều bit        ──▶ tín hiệu 1 bit
```

Đây là điểm khác bản chất so với A01 (bộ cộng: 16 bit vào → 8 bit dữ liệu ra) và C02 (bộ
kẹp: 24 bit vào → 8 bit **dữ liệu** ra). C01 là khối **quyết định**, không phải khối **biến
đổi dữ liệu**. Hệ quả: fan-out ở đầu ra rất nhỏ, và không có đường dữ liệu rộng nào ở cuối
mạch cần ghép kênh.

## 2. Bảng các đường dữ liệu

| Đường | Độ rộng | Từ | Đến | Bản chất |
|---|---:|---|---|---|
| `sample_in[7:0]` | 8 | cổng vào | so sánh 1 (`<min`), so sánh 2 (`>max`) | Dữ liệu chảy, đổi liên tục theo nhịp ADC |
| `min_val[7:0]` | 8 | cổng vào | so sánh 1, so sánh 3 (`min>max`) | **Cấu hình** — đổi rất hiếm |
| `max_val[7:0]` | 8 | cổng vào | so sánh 2, so sánh 3 | **Cấu hình** — đổi rất hiếm |
| `~max_val[7:1]` | 7 | `_51_…_57_` (clkinv) | chuỗi `sample>max` **và** chuỗi `min>max` | **Nội bộ, DÙNG CHUNG cho 2 bộ so sánh** |
| `_10_…_17_` (chuỗi mượn 1) | 1×8 | `_58_` → `_65_` | `above`, `inside` | **Đường nối tiếp — nguồn gốc độ trễ #1** |
| `_41_…_47_`, `config_error` (chuỗi mượn 2) | 1×8 | `_90_` → `_97_` | `config_error`, chặn `below`/`above` | **Đường nối tiếp — nguồn gốc độ trễ #2** |
| `_18_…_40_` (cây so sánh) | ~23 nút | `_66_` → `_88_` | `below`, `inside` | Cây song song — **nhanh hơn hai chuỗi trên** |
| `below`, `inside`, `above` | 1 mỗi cái | cell cuối | cổng ra | Cờ phân loại |
| `config_error` | 1 | `_97_/X` | cổng ra **và** chân `SLEEP` của `_98_`, `_99_` | Cờ lỗi **kiêm tín hiệu điều khiển nội bộ** |

> 🔎 **`config_error` có hai vai trò.** Nó vừa là đầu ra báo cho hệ thống, vừa là tín hiệu
> chặn nội bộ cho `below` và `above`. Fan-out của nó trong netlist là **3** (ghi trong STA:
> `_97_/X` có `Fanout 3`). Đây là net có fan-out lớn nhất của C01 — và vẫn còn rất nhỏ,
> nên không cần buffer.

## 3. Đồ thị phụ thuộc và độ sâu logic

```
 mức 0    sample_in[7:0]     min_val[7:0]     max_val[7:0]
              │   │              │   │            │  │  │
              │   │              │   │            │  │  │
 mức 1        │   │              │   │      [10 × clkinv: ~max_val[1..7], ~min[3], ~min[5], ~s[0]]
              │   │              │   │            │        │
     ┌────────┘   └───┐      ┌───┘   └──────┐     │        │
     ▼                ▼      ▼              ▼     ▼        ▼
 ┌────────────┐  ┌──────────────────┐  ┌──────────────────────┐
 │ CHUỖI A    │  │ CÂY C            │  │ CHUỖI B              │
 │ sample>max │  │ sample<min       │  │ min>max              │
 │            │  │                  │  │                      │
 │ _58_       │  │ _66_ ─┐          │  │ _90_                 │
 │  ▼         │  │ _71_ ─┤ mức 2    │  │  ▼                   │
 │ _59_ mức 2 │  │ _73_ ─┤          │  │ _91_ mức 2           │
 │  ▼         │  │ _74_ ─┘          │  │  ▼                   │
 │ _60_ mức 3 │  │   ▼              │  │ _92_ mức 3           │
 │  ▼         │  │ _72_,_75_ mức 3  │  │  ▼                   │
 │ _61_ mức 4 │  │   ▼              │  │ _93_ mức 4           │
 │  ▼         │  │ _76_,_83_ mức 4  │  │  ▼                   │
 │ _62_ mức 5 │  │   ▼              │  │ _94_ mức 5           │
 │  ▼         │  │ _84_,_86_ mức 5  │  │  ▼                   │
 │ _63_ mức 6 │  │   ▼              │  │ _95_ mức 6           │
 │  ▼         │  │ _88_ mức 6       │  │  ▼                   │
 │ _64_ mức 7 │  │   ▼              │  │ _96_ mức 7           │
 │  ▼         │  │  _40_            │  │  ▼                   │
 │ _65_ mức 8 │  │ = (s<min)        │  │ _97_ mức 8           │
 │  ▼         │  │                  │  │  ▼                   │
 │ _17_       │  │                  │  │ config_error ────────┼──▶ config_error (ra)
 └─────┬──────┘  └────────┬─────────┘  └──────────┬───────────┘
       │                  │                        │
       ├──────────────────┼────────────────────────┤
       │                  │                        │
       ▼                  ▼                        │
  ┌─────────────────────────────┐                  │
  │ _89_ nor2(_17_, _40_)       │ mức 9            │
  └────────────┬────────────────┘                  │
               ▼                                   │
            inside (ra)                            │
       │                  │                        │
       ▼                  ▼                        │
  _98_ isobuf        _99_ isobuf  ◄────────────────┘ (SLEEP = config_error)
       ▼                  ▼          mức 9
     above              below
```

**Bảng độ sâu (số cell trên đường dài nhất tới mỗi đầu ra, đọc từ STA):**

| Đầu ra | Số cell | Arrival time | Đi qua |
|---|---:|---:|---|
| `config_error` | 8 | **2,58 ns** | Chuỗi B |
| `inside` | 9 | **2,65 ns** | Chuỗi A + 1 NOR |
| `below` | 9 | **2,66 ns** | Chuỗi **B** + 1 isobuf ← không phải cây C! |
| `above` | 9 | **2,70 ns** | Chuỗi A + 1 isobuf ← **đường tới hạn** |

> 🔎 **Bốn con số nằm trong khoảng 0,12 ns của nhau** (2,58…2,70). Sự đều nhau này **không
> phải ngẫu nhiên** — nó là bằng chứng trực tiếp rằng ba bộ so sánh chạy **song song**, và
> tất cả các đường đều bị chặn bởi cùng một thứ: một chuỗi mượn 8 tầng. Phần chênh lệch
> 0,12 ns chỉ là tầng cổng cuối cùng khác nhau.

## 4. Trả lời Charter mục 9 — hai bộ so sánh có cùng đường tới hạn không?

> **Charter mục 9:** *"Thiết kế này chứa hai bộ so sánh 8 bit. Kiểm trong báo cáo STA xem
> hai bộ này có nằm trên cùng một đường tới hạn không, và giải thích ý nghĩa của việc chúng
> chạy song song."*

### 4.1 Trả lời bằng số liệu

**KHÔNG. Hai bộ so sánh KHÔNG nằm trên cùng một đường tới hạn — chúng chạy song song.**

Bằng chứng từ `06_GDSII/sta/timing_report_max.txt`, đường tới hạn (path 1):

```
 sample_in[0] → _58_ → _59_ → _60_ → _61_ → _62_ → _63_ → _64_ → _65_ → _98_ → above
                 └─────────────── 7 × maj3_1 ───────────────┘
   Data arrival time = 2,70 ns · Slack = 7,30 ns (MET) · 9 cell
```

Toàn bộ 9 cell trên đường này thuộc về **một** bộ so sánh duy nhất (`sample > max`) cộng một
cổng chặn. **Không có cell nào** của bộ so sánh `sample < min` xuất hiện trên đường này.

### 4.2 Phép kiểm định lượng: nếu nối tiếp thì sẽ ra bao nhiêu?

| Giả thiết | Độ trễ dự kiến | Số đo thật |
|---|---:|---:|
| Hai bộ so sánh mắc **nối tiếp** (kết quả bộ này vào bộ kia) | ≈ 2 × 2,58 = **5,16 ns** | — |
| Hai bộ so sánh **song song**, chỉ cộng thêm tầng logic cuối | ≈ 2,58 + 0,12 = **2,70 ns** | **2,70 ns** ✅ |

Số đo khớp giả thiết song song và **lệch gần 2 lần** so với giả thiết nối tiếp. Đây là bằng
chứng định lượng, không phải suy đoán.

### 4.3 Nhưng có một chi tiết tinh tế — và nó là phát hiện đáng giá nhất của đề

Đường **thứ hai** trong báo cáo STA:

```
 min_val[0] → _90_ → _91_ … _97_ → config_error → _99_/SLEEP → below
              └────── 7 × maj3_1 ──────┘
   Data arrival time = 2,66 ns
```

Đường chậm nhất tới `below` **không** đi qua bộ so sánh `sample < min`. Nó đi qua bộ so sánh
**`min > max`**, rồi qua cổng chặn `_99_`.

**Ý nghĩa:** `below` phụ thuộc hai thứ — kết quả so sánh `sample<min` (cây C) và cờ chặn
`config_error` (chuỗi B). STA chọn đường dài hơn trong hai đường, và nó chọn **chuỗi B**.
Suy ra: **cây so sánh `sample < min` nhanh hơn chuỗi mượn `min > max`**, dù cả hai cùng là
so sánh 8 bit. Lý do: một bên là cây song song ~6 tầng, một bên là chuỗi nối tiếp 8 tầng
(xem `block_diagram.md` §4.1).

> Đây cũng là câu trả lời cho một câu hỏi mentor hay hỏi: *"nếu công cụ biết cách dựng cây
> nhanh hơn, sao nó không dùng cây cho cả ba?"* Trả lời: vì hai bộ so sánh dính tới
> `max_val` **dùng chung 7 cổng đảo**; chọn cùng kiến trúc cho chúng tiết kiệm được 7 cell.
> `abc` đã đánh đổi **tốc độ lấy diện tích** ở đúng chỗ mà slack còn dư 7,30 ns.

### 4.4 Vì sao "chạy song song" là điều quan trọng

| Hệ quả của việc song song | Giá trị |
|---|---|
| Độ trễ tổng ≈ độ trễ **một** bộ so sánh, không phải tổng ba bộ | 2,70 ns thay vì ~7,7 ns |
| Mở rộng lên 16 bit: độ trễ tăng **tuyến tính theo độ rộng**, không theo số bộ so sánh | Thêm bộ so sánh thứ tư gần như không tốn thêm thời gian |
| Ba cờ ra gần như **đồng thời** (chênh ≤ 0,12 ns) | Tầng ngoài có thể lấy mẫu cả ba tại một thời điểm, không cần cân bằng đường |
| Cái giá phải trả là **diện tích** | 52 cell cho một khối logic rất đơn giản — 44,2 % số cell nằm ở riêng cây so sánh `sample<min` |

## 5. Một phát hiện hình thức: công cụ đã **chứng minh** cổng chặn của `inside` là thừa

Đọc netlist, cell sinh `inside` là:

```verilog
sky130_fd_sc_hd__nor2_1 _89_ ( .A(_17_), .B(_40_), .Y(\inside ) );
```

Tức là `inside = !(sample>max) & !(sample<min)` — **không có `config_error` trong biểu thức**,
trong khi RTL viết rõ `if (!config_error) … inside = !below && !above;`.

**Công cụ có sai không? Không.** Chứng minh:

```
  Giả sử  inside_netlist = 1
     ⟹  !(sample > max)  và  !(sample < min)
     ⟹  sample ≤ max     và  sample ≥ min
     ⟹  min ≤ sample ≤ max
     ⟹  min ≤ max
     ⟹  config_error = 0          ∎

  Vậy: inside_netlist = 1  ⟹  config_error = 0
  Nghĩa là phép chặn "inside &= !config_error" KHÔNG BAO GIỜ đổi giá trị của inside.
```

Bản chất: khi `min > max`, cửa sổ **rỗng** — không tồn tại giá trị nào đồng thời `≥ min` và
`≤ max`. Nên `inside` tự động bằng 0, không cần chặn.

| Hệ quả | Giá trị |
|---|---|
| Tiết kiệm | **1 cell** (một cổng chặn không phải dựng) |
| Rủi ro | Kết luận đúng ở **trạng thái ổn định**; ở trạng thái quá độ (glitch) `_17_` và `_40_` chưa ổn định nên `inside` **có thể** nháy 1 ngay cả khi cấu hình sai |
| Bài học | Công cụ tổng hợp làm được **suy luận logic hình thức**, không chỉ ánh xạ cú pháp. Netlist có thể **khác cấu trúc** RTL mà vẫn tương đương hàm số |
| Việc cần làm | Mô phỏng gate-level để xác nhận bằng thực nghiệm — ca kiểm cụ thể đã liệt ở `corner_cases.md` §7. **Chưa chạy** |

## 6. Vì sao datapath này không có thanh ghi

| Câu hỏi | Trả lời |
|---|---|
| Dữ liệu có cần giữ qua chu kỳ không? | Không — mỗi mẫu được phân loại độc lập |
| Ngưỡng `min`/`max` có cần thanh ghi không? | **Có, nhưng ở ngoài C01.** Thanh ghi cấu hình thuộc khối cấu hình (xem `system_diagram.md` §2) |
| Có vùng trễ (hysteresis) không? | Không — cần nhớ trạng thái trước, mà đó là đề C04, **ngoài phạm vi** |
| Nếu thêm ô nhớ thì sao? | Vi phạm REQ-C01-003 và Charter mục 10 |
| Đã chứng minh chưa? | ✅ **Rồi** — `synth_stat.txt`: 0 cell tuần tự; `power_report.txt`: Sequential 0,0 % |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Truy vết: REQ-C01-020, Charter mục 9.*
