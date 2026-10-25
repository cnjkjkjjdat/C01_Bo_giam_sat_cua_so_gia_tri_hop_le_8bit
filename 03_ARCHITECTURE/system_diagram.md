# C01 · Sơ đồ hệ thống (System Diagram)

---

## 1. Bối cảnh ứng dụng (Charter mục 1)

> *"Khối kiểm tra mẫu ADC có nằm trong dải đo hợp lệ của cảm biến hay không, trước khi đưa
> vào tầng xử lý phía sau."*

C01 là một **cổng gác chất lượng dữ liệu** (data quality gate) đặt ngay sau ADC. Vai trò của
nó không phải là xử lý tín hiệu, mà là **trả lời một câu hỏi về độ tin cậy** của từng mẫu,
để tầng sau biết mẫu nào dùng được.

```
  ┌─────────┐   analog   ┌─────────┐  sample_in[7:0]
  │ CẢM BIẾN│═══════════▶│   ADC   │═════════════════╗
  └─────────┘            │  8 bit  │                 ║
                         └─────────┘                 ║
  ┌──────────────────────┐                           ║
  │ THANH GHI CẤU HÌNH   │  min_val[7:0]             ║
  │ (nạp lúc khởi động,  │═══════════════════════╗   ║
  │  từ CPU / eFuse /    │  max_val[7:0]         ║   ║
  │  bảng hiệu chuẩn)    │═══════════════════╗   ║   ║
  └──────────────────────┘                   ║   ║   ║
                                             ▼   ▼   ▼
          ╔══════════════════════════════════════════════════════╗
          ║            C01 — KHỐI ĐANG PHÂN TÍCH                 ║
          ║                                                      ║
          ║   so sánh 1:  sample < min   ──┐                     ║
          ║   so sánh 2:  sample > max   ──┤ ba cờ loại trừ nhau ║
          ║   so sánh 3:  min    > max   ──┘ + cờ lỗi cấu hình   ║
          ╚═══════╤═══════════╤═══════════╤═══════════╤══════════╝
                  │           │           │           │
              below       inside       above     config_error
                  │           │           │           │
                  ▼           ▼           ▼           ▼
   ┌──────────────────────┐ ┌──────────┐ ┌──────────────────────────┐
   │ XỬ LÝ NGOÀI DẢI      │ │ TẦNG XỬ  │ │ XỬ LÝ LỖI HỆ THỐNG       │
   │ (NGOÀI C01)          │ │ LÝ CHÍNH │ │ (NGOÀI C01)              │
   │ • loại mẫu           │ │ (NGOÀI   │ │ • chặn toàn bộ đường dữ  │
   │ • đếm sự kiện        │ │  C01)    │ │   liệu                   │
   │ • kẹp về biên (→C02!)│ │          │ │ • báo lỗi cho CPU        │
   │ • báo cảm biến hỏng  │ │          │ │ • nạp lại cấu hình       │
   └──────────────────────┘ └──────────┘ └──────────────────────────┘
```

> 🔎 **Liên hệ với C02 trong cùng học phần:** một trong các cách "xử lý mẫu ngoài dải" là
> **kẹp nó về biên gần nhất** — đó chính xác là đề C02 (`Bộ kẹp giá trị bão hoà`). C01 và
> C02 dùng **cùng một bộ ba cổng vào** (`sample_in`, `min_val`, `max_val`) và cùng chứa các
> bộ so sánh giống nhau; khác nhau ở chỗ C01 **báo cáo** còn C02 **can thiệp**. Ghép hai
> khối lại sẽ dùng chung được phần so sánh — xem `03_ARCHITECTURE/tradeoff.md` §6.

## 2. Ranh giới khối — cái gì thuộc C01, cái gì không

| Thành phần | Thuộc C01? | Ghi chú |
|---|:-:|---|
| Ba phép so sánh 8 bit | ✅ | Lõi của khối |
| Logic loại trừ ba trạng thái | ✅ | `inside = !below && !above` |
| Phát hiện `min > max` | ✅ | `config_error` |
| Chặn ba cờ khi cấu hình sai | ✅ | Trong RTL; ở netlist chỉ chặn 2 cờ — xem `datapath.md` §5 |
| **Thanh ghi giữ `min_val`, `max_val`** | ❌ | Nằm ở khối cấu hình bên ngoài. C01 chỉ *đọc* |
| **Quyết định làm gì khi mẫu ngoài dải** | ❌ | Tầng ngoài. C01 chỉ *báo* |
| **Kẹp / sửa giá trị mẫu** | ❌ | Đó là C02, một khối khác |
| **Lọc nhiễu, vùng trễ (hysteresis)** | ❌ | Charter mục 3: đó là C04, **ngoài phạm vi** |
| Đếm số mẫu lỗi, lập thống kê | ❌ | Tầng ngoài |
| Đồng bộ miền clock | ❌ | C01 không có clock |

## 3. Vì sao phát hiện `config_error` là việc của C01, không phải của CPU

Đây là một quyết định kiến trúc đáng bàn: tại sao khối phần cứng lại kiểm tra lỗi cấu hình,
trong khi phần mềm nạp cấu hình hoàn toàn có thể tự kiểm trước khi ghi?

| Lập luận | Nội dung |
|---|---|
| **Nguyên tắc "không tin đầu vào"** | Thanh ghi cấu hình có thể bị ghi sai do lỗi phần mềm, lỗi bus, hoặc lỗi bit do nhiễu/bức xạ sau khi đã ghi đúng. Kiểm ở nơi *dùng* bắt được cả ba, kiểm ở nơi *ghi* chỉ bắt được cái đầu |
| **Chi phí thấp, đã có sẵn hạ tầng** | Khối đã có sẵn bộ so sánh 8 bit và các cổng đảo cho `max_val`; thêm một phép so sánh nữa dùng lại được phần lớn hạ tầng đó (bằng chứng ở netlist — xem `block_diagram.md` §4) |
| **Thất bại an toàn (fail-safe)** | Không có `config_error`, cấu hình sai sẽ cho ra phân loại *trông hợp lệ*. Có `config_error`, hệ thống biết chắc là không biết |

## 4. Vòng đời RTL → GDSII — trạng thái THẬT của C01

Lấy đúng từ `brief/C01.md` và các file trong hồ sơ.

```
 ┌─────────────────┐
 │ 1. Đặc tả       │ ✅ 01_REQUIREMENT/, 02_SPECIFICATION/
 └────────┬────────┘
          ▼
 ┌─────────────────┐
 │ 2. RTL          │ ✅ c01_window_monitor.sv
 └────────┬────────┘
          ▼
 ┌─────────────────┐
 │ 3. Mô hình chuẩn│ ✅ PASS — reference_model.py
 └────────┬────────┘
          ▼
 ┌─────────────────┐
 │ 4. MÔ PHỎNG RTL │ ❌ ══► COMPILE_FAIL ◄══  iverilog: syntax error
 │    (Icarus)     │      tại 9 dòng — tất cả đều chứa tên `inside`
 └────────┬────────┘      → 05_VERIFICATION/known_issues.md
          ▼
 ┌─────────────────┐
 │ 5. Tổng hợp     │ ✅ PASS — 52 cell, 0 FF, 362,848 µm²
 │    (Yosys)      │    (Yosys chấp nhận tên `inside`, xem known_issues §5)
 └────────┬────────┘
          ▼
 ┌─────────────────┐
 │ 6. STA          │ ✅ PASS — sample_in[0] → above, 2,70 ns, slack 7,30 ns
 └────────┬────────┘
          ▼
 ┌─────────────────┐
 │ 7. Công suất    │ ✅ ước lượng — 1,21e-05 W, tổ hợp 100 %, tuần tự 0 %
 └────────┬────────┘
          ▼
 ┌─────────────────┐
 │ 8. Floorplan    │ ⬜ chưa chạy
 ├─────────────────┤
 │ 9. Placement    │ ⬜ chưa chạy
 ├─────────────────┤
 │ 10. CTS         │ ⬛ KHÔNG ÁP DỤNG — mạch tổ hợp, không có cây clock
 ├─────────────────┤
 │ 11. Routing     │ ⬜ chưa chạy
 ├─────────────────┤
 │ 12. DRC / LVS   │ ⬜ chưa chạy
 ├─────────────────┤
 │ 13. GDSII       │ ⬜ chưa chạy
 └─────────────────┘
```

| Ký hiệu | Nghĩa | Số bước |
|---|---|---:|
| ✅ | đã chạy, có bằng chứng | 6 |
| ❌ | đã chạy nhưng **thất bại** | 1 |
| ⬜ | chưa chạy | 5 |
| ⬛ | không áp dụng | 1 |

> ❗ **Vòng đời của C01 có hình dạng bất thường: bước 4 hỏng nhưng bước 5, 6, 7 vẫn chạy
> được.** Đây không phải chuyện bình thường và **phải** được giải thích, không được lờ đi.
> Nguyên nhân: hai công cụ xử lý khác nhau đối với một tên tín hiệu trùng từ khoá
> SystemVerilog. Toàn bộ phán xử: `05_VERIFICATION/known_issues.md`.
>
> **Hệ quả quan trọng:** hồ sơ C01 có đầy đủ số liệu **vật lý** (cell, diện tích, timing,
> công suất) nhưng lại **thiếu bằng chứng chức năng ở mức RTL**. Nói cách khác: ta biết rõ
> mạch này *to bao nhiêu và nhanh thế nào*, nhưng chưa tự tay chứng minh *nó chạy đúng*.
> Đó là thứ tự ngược so với thông lệ, và phải nói thẳng khi bảo vệ.

## 5. Phân loại analog / digital / mixed

| Tiêu chí | C01 |
|---|---|
| Miền tín hiệu tại ranh giới khối | Số thuần — đầu vào đã qua ADC |
| Có phần tử analog trong khối? | Không |
| Có phần tử mixed-signal trong khối? | Không |
| **Phân loại C01** | **Digital, mạch tổ hợp thuần** |
| Phân loại **hệ thống** chứa C01 | **Mixed-signal** — có cảm biến và ADC ở phía trước |

Phân biệt này quan trọng: **hệ thống** là mixed-signal, nhưng **khối C01** thì không. Ranh
giới của C01 bắt đầu **sau** đầu ra số của ADC. Thiết kế analog mức transistor nằm ngoài
phạm vi (Charter mục 3).

Bằng chứng khối là số thuần và tổ hợp: `06_GDSII/power/power_report.txt` — nhóm
`Combinational` chiếm **100,0 %**, nhóm `Sequential` và `Clock` đều **0,0 %**.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
