# C01 · Máy trạng thái (FSM)

---

## 1. Kết luận: C01 **không có FSM** — và ở đây có một bẫy khái niệm rất đáng dạy

C01 có **ba trạng thái** `below` / `inside` / `above`, loại trừ nhau, có cả "trạng thái lỗi"
`config_error`. Nghe đúng như một FSM. **Nhưng nó không phải FSM**, và hiểu vì sao không
phải là nội dung chính của tài liệu này.

## 2. Bẫy khái niệm: "ba trạng thái" ≠ "máy trạng thái"

```
   MÁY TRẠNG THÁI (FSM)                 PHÂN LOẠI TỔ HỢP (C01)
   ─────────────────────                ──────────────────────────
   trạng thái tiếp theo                 "trạng thái" hiện tại
     = f(trạng thái HIỆN TẠI, vào)        = f(đầu vào HIỆN TẠI)
                ▲                                    ▲
                └── PHỤ THUỘC QUÁ KHỨ                └── KHÔNG phụ thuộc quá khứ

   cần phần tử nhớ + clock              không cần nhớ, không cần clock
   có đồ thị chuyển trạng thái          KHÔNG có đồ thị chuyển trạng thái
```

**Phép thử quyết định:** đặt cùng một bộ `(sample, min, max)` vào C01 **hai lần khác nhau**,
sau hai lịch sử hoàn toàn khác nhau. Kết quả có giống nhau không?

| Với FSM thật | Với C01 |
|---|---|
| **Có thể khác nhau** — vì trạng thái trước khác nhau | **Luôn giống nhau** — đầu ra là hàm thuần tuý của đầu vào |

C01 thuộc vế phải. Ba cờ của nó là **nhãn phân loại**, không phải trạng thái của một máy.

> 🎓 **Cách diễn đạt đúng khi viết báo cáo:** không viết *"C01 có ba trạng thái"*, mà viết
> *"C01 phân loại đầu vào vào một trong ba vùng"*. Chữ "trạng thái" hàm ý bộ nhớ; chữ
> "vùng"/"nhãn" thì không.

## 3. Bằng chứng: không có FSM, không có phần tử nhớ nào

| # | Bằng chứng | Trạng thái | Nguồn |
|---|---|:-:|---|
| B-1 | RTL không có `always_ff`, không có `posedge`, không có biến trạng thái, không có `enum` trạng thái | ✅ | `c01_window_monitor.sv` — đọc toàn bộ 26 dòng |
| B-2 | Giao diện không có `clk` — **FSM không thể tồn tại nếu không có nguồn định nhịp** | ✅ | `02_SPECIFICATION/interface.md` |
| B-3 | Giao diện không có `rst` — không có trạng thái nào cần đặt lại | ✅ | như trên |
| B-4 | **Netlist: 0 cell tuần tự** trong 52 cell | ✅ | `synth_stat.txt` — toàn bộ là cổng logic tổ hợp (`maj3_1`, `clkinv_1`, `xnor2_1`, `nand*`, `nor*`, `a*oi*`, `o*ai*`, `lpflow_isobufsrc_1`) |
| B-5 | **Công suất nhóm Sequential = 0,0 %** và nhóm Clock = 0,0 % | ✅ | `power_report.txt` |
| B-6 | Không có `always_comb` nào gán thiếu nhánh ⟹ không có latch ngoài ý muốn | ✅ | RTL dòng 16–18 gán mặc định cho cả ba cờ trước nhánh `if` |

> B-6 đáng nhấn mạnh vì đây chính là chỗ đề **B09** trong cùng học phần đã thất bại. C01 làm
> **đúng** mẫu "gán mặc định đầu khối": `below = 1'b0; inside = 1'b0; above = 1'b0;` (dòng
> 16–18) chạy trước `if (!config_error)`. Nhờ vậy Yosys không phải suy ra latch nào, và tổng
> hợp PASS. So hai đề cạnh nhau là bài học trực quan nhất về mẫu này.

## 4. Nếu thiếu dòng 16–18 thì sao? (thí nghiệm tư duy)

```systemverilog
always_comb begin
    config_error = (min_val > max_val);
    // GIẢ SỬ XOÁ ba dòng gán mặc định ở đây
    if (!config_error) begin
        below  = (sample_in < min_val);
        above  = (sample_in > max_val);
        inside = !below && !above;
    end
    // không có else  →  ba cờ không được gán khi config_error = 1
end
```

Khi `config_error = 1`, cả ba cờ giữ giá trị cũ ⟹ Yosys suy ra **ba latch**. Hậu quả:
`below`/`inside`/`above` sẽ **đóng băng ở kết quả phân loại cuối cùng trước khi cấu hình
hỏng** — tức là khối báo một phân loại *trông hợp lệ* trong khi cấu hình đã sai. Đây là kiểu
lỗi tệ nhất có thể có với một khối giám sát chất lượng dữ liệu.

Ba dòng gán mặc định vì vậy không phải "cho đẹp" — chúng là **yêu cầu chức năng** (cả ba cờ
phải về 0 khi lỗi cấu hình) *đồng thời* là **biện pháp phòng latch**.

## 5. Khi nào C01 sẽ thật sự cần FSM

| Kịch bản | FSM cần có | Vì sao |
|---|---|---|
| Thêm **vùng trễ (hysteresis)** | FSM 2 trạng thái: `ĐANG TRONG DẢI` / `ĐANG NGOÀI DẢI`, mỗi trạng thái dùng một ngưỡng khác nhau | Phải nhớ trạng thái trước để biết dùng ngưỡng nào. **Charter mục 3: đây là đề C04, ngoài phạm vi C01** |
| **Lọc nhiễu**: chỉ đổi cờ khi có N mẫu liên tiếp cùng kết luận | FSM + bộ đếm N | Phải nhớ chuỗi kết luận gần nhất. **Ngoài phạm vi** |
| Nạp ngưỡng làm **2 nhịp** qua cùng bộ chân | FSM 2 trạng thái `NẠP_MIN` → `NẠP_MAX` | Phải nhớ đã nạp tới đâu. Charter mục 4 có nhắc cơ chế này ở lớp vỏ chân, nhưng lõi RTL cố ý không làm |
| Báo **sườn** (mẫu vừa rời khỏi cửa sổ) thay vì báo **mức** | 1 flip-flop giữ cờ của chu kỳ trước + XOR | Sườn là khái niệm cần hai thời điểm ⟹ cần bộ nhớ |

Trong cả bốn kịch bản, FSM nằm **bao quanh** lõi tổ hợp hiện tại; ba bộ so sánh vẫn giữ
nguyên vai trò. Đó là dấu hiệu lõi C01 được tách khối đúng: nó là một **hàm thuần tuý**, dễ
tái sử dụng trong mọi kịch bản có trạng thái.

## 6. Liên hệ: vì sao bảng "chuyển trạng thái" của C01 lại là một **bảng chân lý**

Nếu có ai yêu cầu "vẽ bảng chuyển trạng thái của C01", câu trả lời đúng là: C01 không có
bảng chuyển trạng thái, nó có **bảng chân lý** — và bảng đó đã nằm ở
`02_SPECIFICATION/functional_spec.md` §2. Khác biệt:

| | Bảng chuyển trạng thái | Bảng chân lý |
|---|---|---|
| Cột vào | trạng thái hiện tại **+** đầu vào | chỉ đầu vào |
| Cột ra | trạng thái kế tiếp **+** đầu ra | chỉ đầu ra |
| Số dòng của C01 nếu lập đầy đủ | — | `2²⁴` tổ hợp (24 bit vào) — nên phải mô tả bằng **quan hệ so sánh**, không liệt kê |

Vì không thể liệt kê `2²⁴ = 16 777 216` dòng, đặc tả buộc phải viết dưới dạng **điều kiện
so sánh** (`sample < min` …). Đây cũng là lý do testbench phải **quét đại diện** thay vì vét
cạn — xem `02_SPECIFICATION/corner_cases.md` §2.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
