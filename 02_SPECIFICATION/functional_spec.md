# C01 · Đặc tả chức năng (Functional Specification)

Tài liệu mô tả **hành vi đúng**, độc lập với cách hiện thực. RTL trong
`04_IMPLEMENTATION/rtl/c01_window_monitor.sv` là **một** cách hiện thực đặc tả này.

---

## 1. Chức năng ở một câu

C01 phân loại một mẫu 8 bit vào **đúng một trong ba vùng** so với cửa sổ `[min_val, max_val]`,
và báo riêng trường hợp **cửa sổ được cấu hình sai**.

```
      0                min_val              max_val                255
      ├──────────────────┼────────────────────┼─────────────────────┤
      │      below       │       inside       │        above        │
      │   (dưới cửa sổ)  │   (trong cửa sổ)   │    (trên cửa sổ)    │
                         ▲                    ▲
                    BAO GỒM min_val      BAO GỒM max_val
```

## 2. Bảng hành vi

### 2.1 Cấu hình hợp lệ (`min_val ≤ max_val`)

| Điều kiện trên `sample_in` | `below` | `inside` | `above` | `config_error` |
|---|:-:|:-:|:-:|:-:|
| `sample_in < min_val` | **1** | 0 | 0 | 0 |
| `min_val ≤ sample_in ≤ max_val` | 0 | **1** | 0 | 0 |
| `sample_in > max_val` | 0 | 0 | **1** | 0 |

### 2.2 Cấu hình sai (`min_val > max_val`)

| `sample_in` | `below` | `inside` | `above` | `config_error` |
|---|:-:|:-:|:-:|:-:|
| bất kỳ | 0 | 0 | 0 | **1** |

Phương trình đầy đủ:

```
config_error =  (min_val > max_val)
below        = !config_error && (sample_in <  min_val)
above        = !config_error && (sample_in >  max_val)
inside       = !config_error && !below_raw && !above_raw
               trong đó below_raw = (sample_in < min_val), above_raw = (sample_in > max_val)
```

## 3. Ngữ nghĩa quan trọng phải chốt bằng chữ

| Quyết định đặc tả | Giá trị chốt | Vì sao phải nói rõ |
|---|---|---|
| Cửa sổ **bao gồm** hai biên (closed interval `[min,max]`) | ✅ Bao gồm | `sample = min` cho `inside=1`, không phải `below=1`. Golden model ghi thẳng: *"Inclusive [min,max] semantics"* (`c01_reference.sv` dòng 2) |
| Cửa sổ **rộng 1** khi `min == max` | Hợp lệ | `min=max=100` ⟹ chỉ `sample=100` là `inside` |
| Cửa sổ **rỗng** | Không tồn tại | Khi `min > max` thì đó là `config_error`, không phải "cửa sổ rỗng có 0 phần tử" |
| Khi `config_error=1`, ba cờ phân loại | **Đều bằng 0** | Không được đoán bừa. `config_error` là "tôi không phân loại được", khác hẳn "mẫu nằm ngoài" |
| Phép so sánh | **Không dấu** (unsigned) | Cả ba cổng vào khai báo `logic [7:0]`, không có `signed`. Với ADC 8 bit không dấu, đây là ngữ nghĩa đúng |

> 🔎 **Vì sao `config_error` phải chặn cả ba cờ.** Nếu để nguyên `below`/`above` khi
> `min > max`, tầng sau sẽ nhận được một phân loại *trông có vẻ hợp lệ* từ một cấu hình
> *hoàn toàn vô nghĩa* — đó là kiểu lỗi tệ nhất: sai mà không ai biết. Chặn về `000` biến
> trạng thái đó thành **không thể nhầm**: không cờ nào bật, chỉ có cờ lỗi.

## 4. Ràng buộc cấu trúc bắt buộc

| # | Ràng buộc | Nguồn | Trạng thái |
|---|---|---|---|
| S-1 | Mạch **tổ hợp thuần** — 0 ô nhớ | Charter mục 10, REQ-C01-003 | ✅ đã chứng minh: 0 FF trong `synth_stat.txt`, công suất nhóm Sequential = 0,0 % |
| S-2 | Không clock, không reset | Charter mục 4 | ✅ giao diện không có |
| S-3 | Ngưỡng **cố định trong một lần đánh giá** — không có ngưỡng thay đổi theo thời gian, không lọc nhiễu, không vùng trễ (hysteresis) | Charter mục 3 (đó là đề C04) | ✅ RTL không có trạng thái |
| S-4 | Phải có cờ phát hiện cấu hình sai | Charter mục 2 câu 2, mục 8 | ✅ `config_error` |

> Tên đề **không** chỉ định kiến trúc nội bộ. Người thiết kế tự do chọn cách so sánh (chuỗi
> mượn nối tiếp, cây so sánh, hay để công cụ tự chọn). Điều này có hệ quả thú vị ở netlist
> thật — xem `03_ARCHITECTURE/block_diagram.md` §4.

## 5. Tính chất bất biến (invariants)

| ID | Phát biểu | Dạng assertion |
|---|---|---|
| **INV-1** | Khi `config_error=0`: **đúng một** trong ba cờ bằng 1 | `assert (!config_error \|-> (below+inside+above)==1)` |
| **INV-2** | Ba cờ **loại trừ nhau từng đôi** ở mọi lúc | `assert (!(below&&inside) && !(inside&&above) && !(below&&above))` |
| **INV-3** | Khi `config_error=1`: cả ba cờ bằng 0 | `assert (config_error \|-> {below,inside,above}==3'b000)` |
| **INV-4** | `config_error` **chỉ** phụ thuộc `min_val`, `max_val` — độc lập hoàn toàn với `sample_in` | Đổi `sample_in` tuỳ ý, `config_error` không đổi |
| **INV-5** | `below=1` ⟹ `sample_in < min_val` (và ngược lại khi `!config_error`) | quan hệ hai chiều |
| **INV-6** | `above=1` ⟹ `sample_in > max_val` (và ngược lại khi `!config_error`) | quan hệ hai chiều |
| **INV-7** | `sample_in == min_val` ⟹ `inside=1` (biên dưới **thuộc** cửa sổ) | ca biên bắt buộc |
| **INV-8** | `sample_in == max_val` ⟹ `inside=1` (biên trên **thuộc** cửa sổ) | ca biên bắt buộc |
| **INV-9** | Đơn điệu: với `min`, `max` cố định, khi `sample` tăng thì trạng thái chỉ đi theo thứ tự `below → inside → above`, **không bao giờ quay lui** | quét toàn dải `sample` |
| **INV-10** | 0 ô nhớ: đầu ra chỉ phụ thuộc đầu vào hiện tại | đếm cell tuần tự trong netlist |

**INV-1 và INV-2 là trọng tâm của Charter mục 2 câu 1** ("ba trạng thái loại trừ nhau —
bằng chứng nào chứng minh?"). Bằng chứng ở ba mức, xem `05_VERIFICATION/known_issues.md` §7.

> 🔎 **INV-9 đáng chú ý:** tính đơn điệu không phải hệ quả hiển nhiên của INV-1. Một hiện
> thực sai (ví dụ so sánh có dấu trong khi dữ liệu không dấu) vẫn có thể giữ được INV-1 mà
> **vi phạm** INV-9 — trạng thái nhảy `below → above → inside` khi `sample` vượt 127. Vì vậy
> INV-9 là assertion **bắt được lỗi mà INV-1 không bắt được**.

## 6. Điều kiện biên và hành vi không xác định

| Ca | Hành vi theo đặc tả | Vì sao là ca biên |
|---|---|---|
| `sample = min` | `inside=1` | Ranh giới `below`/`inside` — Charter mục 10 gọi thẳng đây là chỗ hay sai |
| `sample = max` | `inside=1` | Ranh giới `inside`/`above` |
| `sample = min-1` | `below=1` | Ô ngay sát biên dưới |
| `sample = max+1` | `above=1` | Ô ngay sát biên trên |
| `min = max` | Cửa sổ rộng đúng 1 giá trị | Hợp lệ, **không** phải config_error |
| `min = max = 0` | Chỉ `sample=0` là `inside`; mọi `sample>0` là `above`; **không có** `below` nào | Biên dưới của miền giá trị: không tồn tại `sample < 0` |
| `min = max = 255` | Chỉ `sample=255` là `inside`; mọi `sample<255` là `below`; **không có** `above` nào | Biên trên của miền giá trị |
| `min=0, max=255` | **Mọi** mẫu đều `inside` | Cửa sổ phủ toàn miền — `below` và `above` không bao giờ bật |
| `min=255, max=0` | `config_error=1` | Cấu hình sai cực đoan nhất |
| Đầu vào chứa `X`/`Z` | **Không xác định** | Tầng ngoài bảo đảm — xem `interface.md` §4 |

> 🔎 **Ba ca `min=max=0`, `min=max=255`, `min=0,max=255` rất đáng dạy:** chúng chứng minh
> rằng "đúng một trong ba cờ" **không** có nghĩa là "cả ba cờ đều có lúc bật được". Với cấu
> hình biên, có cờ **không bao giờ** bật được — và đó vẫn là hành vi đúng.

## 7. Trạng thái chứng minh của đặc tả này

| Mệnh đề | Bằng chứng | Trạng thái |
|---|---|---|
| Hành vi §2 đúng theo mô hình chuẩn Python độc lập | `python_reference_run.log` — PASS | ✅ |
| Hành vi §2 đúng trên RTL | mô phỏng RTL | ❌ **COMPILE_FAIL** — chưa chạy được dòng nào |
| S-1 (0 ô nhớ) | `synth_stat.txt`: 52 cell, 0 cell tuần tự; `power_report.txt`: Sequential 0,0 % | ✅ **hai bằng chứng độc lập** |
| Tổng hợp được ra standard cell sky130 | 52 cell, 362,848 µm² | ✅ |
| Độ trễ đường tới hạn | `sample_in[0]` → `above`, **2,70 ns**, slack 7,30 ns | ✅ ở mức sau tổng hợp |
| Tương đương RTL ↔ netlist | mô phỏng gate-level | ⬜ chưa chạy |

> ⚠️ **Tình huống hiếm gặp và cần nói rõ:** C01 **tổng hợp được** nhưng **không mô phỏng
> được**. Đây là ngược lại hoàn toàn với B09 trong cùng học phần. Nguyên nhân là một xung
> đột **tên tín hiệu với từ khoá SystemVerilog**, và hai công cụ xử lý khác nhau. Phán xử
> đầy đủ: **`05_VERIFICATION/known_issues.md`**.
>
> Hệ quả với đặc tả này: mọi mệnh đề về **hàm số** của C01 hiện mới được chứng minh bởi mô
> hình chuẩn Python, **chưa** được chứng minh trên chính RTL.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
