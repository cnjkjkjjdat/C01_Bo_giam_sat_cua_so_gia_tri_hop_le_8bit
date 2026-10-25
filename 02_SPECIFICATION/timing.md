# C01 · Đặc tả thời gian (Timing)

---

## 1. Bản chất thời gian của khối này

C01 là mạch **Tổ hợp**.

Không có clock, không có setup/hold, không có chu kỳ. Đại lượng thời gian duy nhất
có nghĩa là **độ trễ lan truyền từ đầu vào đến khi đầu ra ổn định**.

| Khái niệm | Áp dụng? | Lý do |
|---|:-:|---|
| Chu kỳ clock | ❌ | Không có clock |
| Setup / hold | ❌ | Không có flip-flop trong khối |
| Clock skew, CTS | ❌ | Không có cây clock |
| WNS / TNS | ⚠️ | Chỉ có nghĩa **nếu** áp một clock ảo làm chuẩn phân tích |
| Độ trễ đường tổ hợp | ✅ | Đây là đại lượng cần đo |

## 2. Phương pháp ràng buộc đã dùng

Chế độ: **clock ảo (virtual clock)**.

File SDC: `04_IMPLEMENTATION/constraints/design.sdc`

```tcl
# Mach TO HOP: khong co clock that.
# vclk chi la MOC QUY CHIEU de STA tinh duoc slack tren duong to hop.
# KHONG dien giai period 10 ns thanh 'thiet ke chay o 100 MHz'.
create_clock -name vclk -period 10.0
set_input_delay  0.0 -clock vclk [all_inputs]
set_output_delay 0.0 -clock vclk [all_outputs]
```

## 3. Bốn giả định phải nêu kèm mọi con số

| # | Giả định | Giá trị dùng trong gói này |
|---|---|---|
| G-1 | Chu kỳ clock | `10,0 ns` — **mốc quy chiếu phân tích**, KHÔNG phải yêu cầu tần số của khối |
| G-2 | Input/output delay | 0,0 ns — giả định lý tưởng, không mô hình tầng ngoài |
| G-3 | Thư viện + PVT | `sky130_fd_sc_hd__tt_025C_1v80.lib` (typical · 25 °C · 1,80 V) |
| G-4 | Ký sinh dây (RC) | **Chưa có** — số liệu mới ở mức sau tổng hợp, chưa qua P&R |

> ❗ Không được diễn giải "period 10 ns" thành "C01 chạy được ở 100 MHz".
> Con số có ý nghĩa vật lý là **độ trễ tổ hợp** ở §4.

## 4. Số liệu thời gian đo được

| Đại lượng | Giá trị |
|---|---:|
| Startpoint | `sample_in[0]` |
| Endpoint | `above` |
| **Data arrival time** | **2,7 ns** |
| Slack | 7,3 ns |
| WNS | `wns max 0.00` |
| TNS | `tns max 0.00` |
| Số cell trên đường tới hạn | 9 |

Công cụ: **OpenSTA 3.1.0** · Bằng chứng: `06_GDSII/sta/timing_report_max.txt`

## 5. Nghĩa vụ của tầng ngoài

```
t_clk_he_thong  ≥  t_ckq(thanh ghi truoc)  +  t_C01_max  +  t_setup  +  t_skew
```

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Truy vết: REQ-C01-020, AC-12…AC-14.*
