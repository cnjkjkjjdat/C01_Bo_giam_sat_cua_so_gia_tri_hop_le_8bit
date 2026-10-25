# C01 · Sơ đồ khối bên trong (Block Diagram)

Tài liệu này vẽ **hai** sơ đồ: một theo **RTL thật**, một theo **netlist thật**. Chúng khác
nhau ở những chỗ rất đáng học.

---

## 1. Sơ đồ theo RTL (`c01_window_monitor.sv`)

```
 ┌──────────────────────────────────────────────────────────────────────────┐
 │                          c01_window_monitor                              │
 │                                                                          │
 │  min_val[7:0] ──┬───────────────────────┐                                │
 │                 │                       │                                │
 │  max_val[7:0] ──┼──┬────────────────────┼──┐                             │
 │                 │  │                    │  │                             │
 │                 ▼  ▼                    │  │                             │
 │        ┌────────────────────┐           │  │                             │
 │        │ SO SÁNH 3          │           │  │                             │
 │        │ min_val > max_val  │ (dòng 14) │  │                             │
 │        └─────────┬──────────┘           │  │                             │
 │                  │ config_error ────────┼──┼───────────────▶ config_error│
 │                  │                      │  │                             │
 │                  │        ┌─────────────┘  │                             │
 │  sample_in[7:0]──┼────┬───┼────────────────┼──┐                          │
 │                  │    ▼   ▼                │  │                          │
 │                  │ ┌──────────────────┐    │  │                          │
 │                  │ │ SO SÁNH 1        │    │  │                          │
 │                  │ │ sample < min     │    │  │                          │
 │                  │ │ (dòng 21)        │    │  │                          │
 │                  │ └────────┬─────────┘    │  │                          │
 │                  │          │ below_raw    ▼  ▼                          │
 │                  │          │       ┌──────────────────┐                 │
 │                  │          │       │ SO SÁNH 2        │                 │
 │                  │          │       │ sample > max     │                 │
 │                  │          │       │ (dòng 22)        │                 │
 │                  │          │       └────────┬─────────┘                 │
 │                  │          │                │ above_raw                 │
 │                  │          │   ┌────────────┤                           │
 │                  │          ▼   ▼            │                           │
 │                  │      ┌──────────────┐     │                           │
 │                  │      │ NOR (dòng 23)│     │                           │
 │                  │      │ !raw & !raw  │     │                           │
 │                  │      └──────┬───────┘     │                           │
 │                  │             │ inside_raw  │                           │
 │                  ▼             ▼             ▼                           │
 │            ┌─────────────────────────────────────────┐                   │
 │            │ CỔNG CHẶN THEO config_error (dòng 20)   │                   │
 │            │  if (!config_error) … else giữ 3'b000   │                   │
 │            └────┬──────────────┬──────────────┬──────┘                   │
 │                 │              │              │                          │
 └─────────────────┼──────────────┼──────────────┼──────────────────────────┘
                   ▼              ▼              ▼
                 below         inside          above
```

## 2. Bảng ánh xạ cấu trúc RTL → phần cứng sinh ra

| Dòng RTL | Mã | Phần cứng thật trong netlist | Số cell |
|---:|---|---|---:|
| 14 | `config_error = (min_val > max_val)` | Chuỗi mượn: `_90_` (isobufsrc) + `_91_…_97_` (7 × `maj3_1`) | **8** |
| 16–18 | `below=0; inside=0; above=0;` | Gán mặc định → **0 cell**, nhưng **chặn suy ra latch** | 0 |
| 20 | `if (!config_error)` | `_98_`, `_99_` (2 × `isobufsrc`, chân `SLEEP` = `config_error`) | **2** |
| 21 | `below = (sample_in < min_val)` | Cây so sánh: `_66_…_88_` (xnor2, nand, nor, aoi/oai) | **~23** |
| 22 | `above = (sample_in > max_val)` | Chuỗi mượn: `_58_` (isobufsrc) + `_59_…_65_` (7 × `maj3_1`) | **8** |
| 23 | `inside = !below && !above` | `_89_` (1 × `nor2_1`) | **1** |
| — | các cổng đảo dùng chung | `_48_…_57_` (10 × `clkinv_1`) | **10** |
| | | **Tổng** | **52** ✅ khớp `synth_stat.txt` |

## 3. Sơ đồ theo NETLIST thật (`06_GDSII/synthesis/netlist.v`)

```
  max_val[7:1] ──▶ [_51_.._57_: 7×clkinv] ──▶ ~max_val[7:1] ═══╗ (DÙNG CHUNG
                                                               ║  cho 2 chuỗi)
                                                               ║
 sample_in[0] ─▶ _58_ isobuf ─▶ _59_ ─▶ _60_ ─▶ … ─▶ _65_ ─────╫──▶ _17_ = (sample>max)
      ▲                        └──── 7 × maj3_1 ────┘          ║      │
      └── sample_in[1..7] vào từng tầng maj3                    ║      ├──▶ _98_ isobuf
                                                                ║      │    (SLEEP=cfg_err)
   min_val[0] ─▶ _90_ isobuf ─▶ _91_ ─▶ _92_ ─▶ … ─▶ _97_ ──────╝      │         └─▶ above
      ▲                        └──── 7 × maj3_1 ────┘                  │
      └── min_val[1..7] vào từng tầng maj3            │                │
                                                     ▼                │
                                              config_error ───────────┘
                                                     │
 sample_in ──┐                                       │
 min_val  ───┼──▶ ┌────────────────────────────┐     │
                  │ CÂY SO SÁNH (sample < min) │     │
                  │ _66_ … _88_ : xnor2 ×5,    │     │
                  │ nand2b, nand3b, o21ai,     │     │
                  │ a21oi, xor2, nor2, nand3,  │     │
                  │ o21bai, nor3b, a2111oi,    │     │
                  │ a31oi  → ~23 cell          │     │
                  └─────────────┬──────────────┘     │
                                │ _40_ = (sample<min)│
                                ├────────────────────┼──▶ _99_ isobuf ──▶ below
                                │                    │    (SLEEP=cfg_err)
                                ▼                    │
                          _89_ nor2(_17_, _40_) ─────┼──▶ inside
                                                     │      ▲
                                                     │      └── KHÔNG có config_error!
                                                     └──────────▶ config_error
```

## 4. Ba phát hiện khi đọc netlist — phần đáng học nhất

### 4.1 Ba phép so sánh, **hai** kiến trúc khác nhau

| Phép so sánh | Kiến trúc công cụ chọn | Số tầng | Bằng chứng |
|---|---|---:|---|
| `sample > max` | **Chuỗi mượn nối tiếp** (ripple) | 8 | `_58_` + `_59_…_65_` |
| `min > max` | **Chuỗi mượn nối tiếp** (ripple) | 8 | `_90_` + `_91_…_97_` |
| `sample < min` | **Cây so sánh song song** | ~6 | `_66_…_88_`, không có `maj3_1` nào |

Cùng một bài toán (so sánh 8 bit không dấu), cùng một công cụ, cùng một lần chạy — mà ra
**hai kiến trúc khác nhau**. Lý do có thể đọc được từ netlist:

> **Hai phép so sánh đầu dùng chung toán hạng `~max_val`.** Cả `_59_` và `_91_` đều lấy
> `_03_ = ~max_val[1]`; cả `_60_` và `_92_` đều lấy `_04_ = ~max_val[2]`; và cứ thế hết 7
> cổng đảo `_51_…_57_`. Chọn cùng một kiến trúc cho hai phép so sánh này cho phép **dùng
> chung 7 cổng đảo**. Phép so sánh thứ ba (`sample < min`) không dính tới `max_val`, không
> có gì để chia sẻ, nên `abc` tự do chọn cấu trúc rẻ nhất cho riêng nó.

**Bài học:** *"một phép `>` trong RTL = một bộ so sánh trong phần cứng"* là cách nghĩ sai.
Công cụ chọn kiến trúc theo **ngữ cảnh chia sẻ tài nguyên**, không theo từng dòng RTL.

### 4.2 `maj3_1` chính là bộ sinh mượn (borrow generator)

`maj3` = cổng đa số 3 ngõ: `X = (A&B) | (B&C) | (A&C)`. Đây **đúng** là công thức carry-out
của một bộ cộng đầy đủ. Một phép so sánh `a > b` không dấu thực chất là lấy **carry-out của
`a + ~b + 1`** — nên chuỗi `maj3` mắc nối tiếp chính là **chuỗi carry**, đúng bản chất như
bộ cộng ripple của đề A01.

```
   a > b   ⟺   carry_out( a + ~b + 1 ) = 1

   tầng i:  carry[i+1] = maj3( a[i], ~b[i], carry[i] )
                                             ▲
                                             └── PHỤ THUỘC NỐI TIẾP
```

Đây là lý do độ trễ so sánh 8 bit tỉ lệ `O(N)`, và là lý do đường tới hạn của C01 dài đúng
7 tầng `maj3`.

### 4.3 `lpflow_isobufsrc_1` **không** dùng để cách ly nguồn

Cell này trong thư viện `sky130_fd_sc_hd` vốn dành cho cách ly miền nguồn (power isolation).
Ở đây `abc` chọn nó vì **hàm boolean** của nó là `X = A & !SLEEP` — tức là một cổng AND với
một ngõ đảo — và diện tích của nó nhỏ. Netlist dùng nó ở 4 chỗ, cho 3 mục đích khác nhau:

| Instance | Vai trò thật | Hàm |
|---|---|---|
| `_58_` | Tầng đầu chuỗi `sample>max` | `sample_in[0] & ~max_val[0]` = mượn ban đầu |
| `_90_` | Tầng đầu chuỗi `min>max` | `min_val[0] & ~max_val[0]` |
| `_98_` | **Cổng chặn** `above` theo `config_error` | `_17_ & ~config_error` |
| `_99_` | **Cổng chặn** `below` theo `config_error` | `_40_ & ~config_error` |

> ⚠️ **Đừng đọc tên cell để đoán ý đồ thiết kế.** `abc` ánh xạ theo hàm logic và chi phí,
> không theo tên. Muốn biết một cell làm gì, phải đọc **kết nối** của nó trong netlist.
> (`06_GDSII/synthesis/README.md` cũng nhắc: flow LibreLane thật thường đưa `lpflow_*` vào
> `dont_use`, nên số cell sau P&R có thể lệch chút ít.)

## 5. Khối con nào nằm trên đường tới hạn?

Đối chiếu với `06_GDSII/sta/timing_report_max.txt`:

| Khối con | Trên đường tới hạn? | Arrival time | Bằng chứng |
|---|:-:|---:|---|
| **So sánh `sample > max` (chuỗi 7 maj3)** | ✅ **CÓ** | **2,70 ns** → `above` | Path 1 của STA: `_58_ → _59_…_65_ → _98_` |
| **So sánh `min > max` (chuỗi 7 maj3)** | ✅ CÓ (đường thứ hai) | 2,66 ns → `below`; 2,58 ns → `config_error` | Path 2 và 4 |
| So sánh `sample < min` (cây) | ❌ **KHÔNG** | không xuất hiện trong báo cáo max | Cây nông hơn chuỗi ripple |
| Cổng NOR sinh `inside` | phần đuôi | 2,65 ns → `inside` | Path 3, chỉ +0,07 ns sau `_65_` |

### Bảng bốn đường được STA báo cáo

| # | Startpoint → Endpoint | Arrival | Slack | Số cell | Đi qua bộ so sánh nào |
|---|---|---:|---:|---:|---|
| 1 | `sample_in[0]` → `above` | **2,70 ns** | 7,30 | 9 | `sample > max` |
| 2 | `min_val[0]` → `below` | 2,66 ns | 7,34 | 9 | `min > max` (!) |
| 3 | `sample_in[0]` → `inside` | 2,65 ns | 7,35 | 9 | `sample > max` |
| 4 | `min_val[0]` → `config_error` | 2,58 ns | 7,42 | 8 | `min > max` |

> 🔎 **Kết quả bất ngờ ở đường #2:** đường chậm nhất tới `below` **không** đi qua bộ so sánh
> `sample < min` — nó đi qua bộ so sánh **`min > max`** rồi mới tới cổng chặn `_99_`. Nghĩa
> là *cái chặn* chậm hơn *cái bị chặn*. Đây là bằng chứng định lượng cho thấy cây so sánh
> (`sample < min`) thật sự nhanh hơn chuỗi ripple, và là dữ kiện trung tâm để trả lời Charter
> mục 9 — xem `03_ARCHITECTURE/datapath.md` §4.

## 6. Bảng phân bổ 52 cell theo chức năng

| Nhóm chức năng | Instance | Số cell | Tỷ lệ |
|---|---|---:|---:|
| Chuỗi so sánh `sample > max` | `_58_` + `_59_…_65_` | 8 | 15,4 % |
| Chuỗi so sánh `min > max` (config_error) | `_90_` + `_91_…_97_` | 8 | 15,4 % |
| Cây so sánh `sample < min` | `_66_…_88_` | 23 | 44,2 % |
| Cổng chặn theo `config_error` | `_98_`, `_99_` | 2 | 3,8 % |
| Cổng NOR sinh `inside` | `_89_` | 1 | 1,9 % |
| Cổng đảo dùng chung (`~min_val[3]`, `~min_val[5]`, `~sample_in[0]`, `~max_val[1..7]`) | `_48_…_57_` | 10 | 19,2 % |
| | **Tổng** | **52** | **100 %** |

> Bảng này đếm **instance trong netlist**, không phải diện tích. Cell không bằng nhau về
> diện tích (một `maj3_1` lớn hơn một `clkinv_1`), nên **không được** suy ra tỷ lệ diện tích
> từ tỷ lệ số cell. Muốn tỷ lệ diện tích chính xác cần tổng hợp riêng từng phần rồi trừ —
> **chưa làm**. Tổng diện tích đo được: **362,848 µm²**.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
