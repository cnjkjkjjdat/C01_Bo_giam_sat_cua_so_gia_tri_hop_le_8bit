# C01 · Giản đồ thời gian (Timing Diagram)

C01 là mạch **tổ hợp**: không clock, không chu kỳ. Dùng **giản đồ lan truyền** với trục thời
gian liên tục, lấy số thật từ `06_GDSII/sta/timing_report_max.txt`.

---

## 1. Quy ước

```
  ──────  ổn định        ╳╳╳╳╳╳  đang chuyển / chưa ổn định
  ▲       đầu vào đổi    ◆       đầu ra ổn định cuối cùng
```

Mọi con số ns dưới đây lấy **đúng** từ báo cáo STA (góc `tt_025C_1v80`, **sau tổng hợp, chưa
có ký sinh dây**).

## 2. Ca **xấu nhất** — đường tới hạn `sample_in[0]` → `above` (2,70 ns)

Kích thích: `min_val`, `max_val` giữ nguyên; `sample_in` đổi sao cho bit 0 phải lan qua toàn
bộ chuỗi mượn 7 tầng (ví dụ `max_val = 8'h7F`, `sample_in` đổi `8'h7F` → `8'h80`).

```
   t(ns)  0      0,11   0,45   0,81   1,16   1,51   1,87   2,22   2,58   2,70
          ▲       │      │      │      │      │      │      │      │      ◆
 sample_in ┴──────────────────────────────────────────────────────────────────
          │
 _10_     ╳╳╳────────────────────────────────────────────────────────────────  _58_ isobuf
          │  ▲0,11
 _11_     ╳╳╳╳╳╳╳──────────────────────────────────────────────────────────── _59_ maj3
          │       ▲0,45
 _12_     ╳╳╳╳╳╳╳╳╳╳╳───────────────────────────────────────────────────────── _60_ maj3
          │              ▲0,81
 _13_     ╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳────────────────────────────────────────────────────  _61_ maj3
          │                     ▲1,16
 _14_     ╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳──────────────────────────────────────────────── _62_ maj3
          │                            ▲1,51
 _15_     ╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳──────────────────────────────────────────── _63_ maj3
          │                                   ▲1,87
 _16_     ╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳──────────────────────────────────────── _64_ maj3
          │                                          ▲2,22
 _17_     ╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳──────────────────────────────────── _65_ maj3
          │                                                 ▲2,58
 above    ╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳────────────────────────────────  _98_ isobuf
          │                                                        ◆2,70
          └──────────── 2,70 ns = data arrival time ────────────────┘
          └─────────── slack còn 7,30 ns tới mốc vclk 10 ns ──────────────────┘
```

### Đọc số từng tầng (trích `timing_report_max.txt`)

| Tầng | Cell | Delay tầng | Thời điểm ổn định | Nhận xét |
|---|---|---:|---:|---|
| 1 | `_58_` `lpflow_isobufsrc_1` | 0,11 ns | 0,11 | Tầng mượn đầu tiên |
| 2 | `_59_` `maj3_1` | 0,34 ns | 0,45 | |
| 3 | `_60_` `maj3_1` | 0,35 ns | 0,81 | |
| 4 | `_61_` `maj3_1` | 0,35 ns | 1,16 | |
| 5 | `_62_` `maj3_1` | 0,35 ns | 1,51 | |
| 6 | `_63_` `maj3_1` | 0,35 ns | 1,87 | |
| 7 | `_64_` `maj3_1` | 0,35 ns | 2,22 | |
| 8 | `_65_` `maj3_1` | 0,36 ns | 2,58 | Fanout 2 ⟹ chậm hơn 0,01 ns |
| 9 | `_98_` `lpflow_isobufsrc_1` | 0,12 ns | **2,70** | Cổng chặn theo `config_error` |

> 🔎 **Bảy tầng `maj3_1` gần như bằng nhau: 0,34–0,36 ns.** Đây là chữ ký rõ ràng của một
> **chuỗi nối tiếp đều** (uniform ripple chain). Nếu công cụ đã dựng cây, các tầng sẽ có độ
> trễ rất khác nhau và số tầng sẽ ít hơn. Nhìn độ trễ từng tầng là cách đọc kiến trúc từ báo
> cáo STA mà không cần mở netlist.
>
> **Ước lượng ngoại suy (chỉ để lập luận, KHÔNG phải số đo):** mỗi bit thêm vào độ rộng sẽ
> thêm khoảng 0,35 ns. Một bộ so sánh 16 bit cùng kiến trúc sẽ vào khoảng 2,70 + 8×0,35 ≈
> 5,5 ns. Muốn có số thật thì phải tổng hợp và chạy STA cho phiên bản 16 bit — **chưa làm**.

## 3. So bốn đầu ra trên cùng một trục thời gian

```
   t(ns)  0        0,5      1,0      1,5      2,0      2,5   2,58 2,65 2,70
          ▲                                                    │   │   │
 vào      ┴─────────────────────────────────────────────────────────────────

 config_error ╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳◆──────────  2,58
 inside       ╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳◆────────  2,65
 below        ╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳◆───────  2,66
 above        ╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳◆──────  2,70
                                                               └──┬──┘
                                                       chênh nhau chỉ 0,12 ns
```

| Đầu ra | Arrival | Slack | Đường đi |
|---|---:|---:|---|
| `config_error` | 2,58 ns | 7,42 ns | `min_val[0]` → chuỗi B (7 maj3) |
| `inside` | 2,65 ns | 7,35 ns | `sample_in[0]` → chuỗi A (7 maj3) → `_89_` nor2 |
| `below` | 2,66 ns | 7,34 ns | `min_val[0]` → chuỗi B → `config_error` → `_99_` |
| `above` | **2,70 ns** | **7,30 ns** | `sample_in[0]` → chuỗi A → `_98_` |

**Bốn đầu ra ổn định trong một cửa sổ 0,12 ns.** Đây là bằng chứng trực quan nhất cho việc
ba bộ so sánh chạy **song song** (Charter mục 9). Nếu chúng nối tiếp, bốn vạch `◆` sẽ nằm
cách nhau hàng ns chứ không phải 0,12 ns.

## 4. Ca **tốt nhất** — đường ngắn nhất

Báo cáo `timing_report_min.txt` tồn tại trong hồ sơ cho phân tích hold. Với một khối tổ hợp
không có flip-flop, phân tích min/hold **không có ý nghĩa vật lý** (không có phần tử nào để
vi phạm hold). Nó chỉ cho biết đường ngắn nhất từ vào tới ra.

Về mặt cấu trúc, đường ngắn nhất là đường từ các bit **cao** của toán hạng: `sample_in[7]`
vào thẳng `_65_` (tầng cuối của chuỗi A) rồi qua `_98_` ra `above` — chỉ **2 cell**.

```
 sample_in[7] ───▶ _65_ maj3 ───▶ _98_ isobuf ───▶ above
                   ≈0,36 ns        ≈0,12 ns
                   └────── tổng ≈ 0,48 ns ──────┘
```

> 🔎 **Chênh lệch 2,70 ns / ≈0,48 ns ≈ 5,6 lần giữa bit thấp nhất và bit cao nhất** chính là
> đặc trưng của kiến trúc ripple: bit càng thấp thì đường càng dài. Đây cũng là **vùng
> glitch lớn nhất** — xem §5.

## 5. Vùng glitch — cơ chế

Vì các bit của toán hạng đi những quãng đường **rất khác nhau** (2 cell so với 9 cell), kết
quả so sánh đi qua nhiều giá trị trung gian trước khi ổn định.

```
  Ví dụ: max_val = 8'h7F cố định, sample_in đổi 8'h7F → 8'h80
         (kết quả đúng: above chuyển 0 → 1)

  t ≈ 0,48 ns : bit 7 đã tới _65_ và ra above  →  above nhảy lên 1 SỚM
  t = 0,45…2,58 : chuỗi mượn từ bit 0 lan dần lên, LẦN LƯỢT ghi đè _11_.._17_
                  → above có thể ĐỔI GIÁ TRỊ NHIỀU LẦN trong khoảng này
  t = 2,70 ns : ổn định ở giá trị đúng

           0,48                                            2,70
            │                                                │
  above  ───┴─┐ ┌─┐ ┌───┐ ┌─────────────────────────────────┴──────
              └─┘ └─┘   └─┘
              └────── VÙNG GLITCH ≈ 2,2 ns ──────┘
```

| Hệ quả thiết kế | Lý do |
|---|---|
| Không dùng `below`/`inside`/`above` làm clock hay enable của latch | Mỗi sườn giả là một lần chốt sai |
| Không đếm sườn của cờ để "đếm số lần ra khỏi dải" | Một lần ra khỏi dải có thể sinh nhiều sườn |
| Muốn đếm sự kiện thì phải **chốt cờ bằng flip-flop có clock ở tầng ngoài**, sau khi đã qua 2,70 ns | Flip-flop chỉ lấy mẫu một thời điểm ⟹ miễn nhiễm glitch |
| Không suy ra `config_error` và `above` không bao giờ cùng bằng 1 | Ở trạng thái quá độ chúng **có thể** cùng bằng 1 — INV-3 là bất biến ở trạng thái ổn định |

> ⚠️ Vùng glitch ≈ 2,2 ns ở trên là **suy ra từ cấu trúc và từ hai con số STA** (0,48 và
> 2,70), không phải kết quả đo trực tiếp. Muốn đo thật phải mô phỏng gate-level có
> back-annotate SDF — **chưa chạy**.

## 6. Vì sao waveform từ mô phỏng **không** minh hoạ được những điều trên

| Hạng mục | Thực tế của C01 |
|---|---|
| Loại mô phỏng | **Hành vi (zero-delay)** — và ở C01 thì **còn chưa chạy được**: `COMPILE_FAIL` |
| Có waveform không? | **Không có** — thư mục `05_VERIFICATION/` không có `waveforms/`, không có `simulation.log` |
| Nếu chạy được thì có thấy glitch không? | **Không.** Zero-delay ⟹ mọi cổng có độ trễ 0 ⟹ không có vùng quá độ nào |
| Mốc `vclk period 10.0` trong SDC | **Mốc quy chiếu phân tích**, KHÔNG phải yêu cầu tần số. C01 không có clock |

> ❗ **Không được** phát biểu "C01 chạy được ở 100 MHz" từ con số `period 10.0`. Phát biểu
> đúng và duy nhất được phép: *"độ trễ lan truyền lớn nhất đo được sau tổng hợp là **2,70 ns**
> ở góc `tt_025C_1v80`, chưa tính ký sinh dây."*

## 7. Trạng thái số liệu thời gian

| Đại lượng | Giá trị | Nguồn |
|---|---|---|
| Độ trễ đường tới hạn | **2,70 ns** | `timing_report_max.txt` ✅ |
| Slack (so mốc 10 ns) | **7,30 ns** (MET) | như trên ✅ |
| WNS / TNS | `0.00` / `0.00` | `wns.txt`, `tns.txt` ✅ |
| Độ trễ sau routing | ⬜ chưa có | cần P&R + trích xuất RC |
| Độ trễ ở góc `ss` (chậm) | ⬜ chưa có | cần Liberty góc `ss` |
| Vùng glitch đo được | ⬜ chưa có | cần mô phỏng gate-level + SDF |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
