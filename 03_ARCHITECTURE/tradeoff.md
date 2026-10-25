# C01 · Đánh đổi kiến trúc (Trade-off Analysis)

---

## 1. Câu hỏi trung tâm của đề

> **Charter mục 9:** *"Thiết kế này chứa hai bộ so sánh 8 bit. Kiểm trong báo cáo STA xem hai
> bộ này có nằm trên cùng một đường tới hạn không, và giải thích ý nghĩa của việc chúng chạy
> song song."*
>
> **Charter mục 10:** *"Dấu hiệu làm đúng: 0 ô nhớ. Là threshold_alarm nhân đôi + logic loại trừ."*

Toàn bộ tài liệu này phục vụ hai câu đó, bằng số liệu thật.

## 2. Số liệu nền — tất cả đều đo được

| Chỉ số | Giá trị đo được | Nguồn |
|---|---:|---|
| Tổng số cell | **52** | `06_GDSII/synthesis/synth_stat.txt` |
| Cell tuần tự (FF / latch) | **0** | như trên |
| Diện tích | **362,848 µm²** | như trên |
| Độ trễ đường tới hạn | **2,70 ns** (`sample_in[0]` → `above`) | `06_GDSII/sta/timing_report_max.txt` |
| Slack | **7,30 ns** (MET) | như trên |
| WNS / TNS | `0.00` / `0.00` | `wns.txt`, `tns.txt` |
| Công suất tổng | **1,21e-05 W** (tổ hợp 100,0 %, tuần tự 0,0 %) | `06_GDSII/power/power_report.txt` |
| Ước lượng Charter | ~130–190 cell · 1×1 tile | metadata Charter |

**52 cell thật, so với ước lượng 130–190 cell của Charter: nhỏ hơn 2,5–3,7 lần.** Điều này
hợp lý và giải thích được: ước lượng Charter mang tính dự phòng và giả định mỗi phép so sánh
dựng riêng một bộ so sánh đầy đủ; thực tế `abc` đã (a) dùng chung 7 cổng đảo cho hai chuỗi
so sánh, (b) gộp nhiều cổng cơ bản vào các cell phức hợp (`a2111oi`, `o21bai`, `a31oi`,
`nand3b`…), và (c) **chứng minh được** cổng chặn của `inside` là thừa (xem `datapath.md` §5).

Điều kiện tạo ra bằng chứng: Yosys 0.33 + OpenSTA 3.1.0, thư viện `sky130_fd_sc_hd`,
Liberty `sky130_fd_sc_hd__tt_025C_1v80.lib`, góc typical · 25 °C · 1,80 V, **sau tổng hợp,
chưa có ký sinh dây**.

## 3. Trả lời Charter mục 9 bằng số

**Hai bộ so sánh KHÔNG nằm trên cùng một đường tới hạn.**

| Kiểm chứng | Số liệu |
|---|---|
| Đường tới hạn có 9 cell: `_58_` + 7×`maj3_1` + `_98_` | Toàn bộ thuộc **một** bộ so sánh (`sample > max`) |
| Bốn đầu ra ổn định trong cửa sổ **0,12 ns** (2,58 → 2,70) | Dấu hiệu song song |
| Nếu nối tiếp, độ trễ dự kiến ≈ 2 × 2,58 = **5,16 ns** | Số đo thật **2,70 ns** — lệch gần 2 lần |

Phân tích chi tiết và phát hiện phụ (đường tới `below` đi qua bộ so sánh `min>max` chứ không
phải `sample<min`): `03_ARCHITECTURE/datapath.md` §4.

### Ý nghĩa của việc chạy song song

| Hệ quả | Giá trị định lượng |
|---|---|
| Độ trễ = độ trễ **một** bộ so sánh + 1 tầng, không phải tổng ba bộ | **2,70 ns** thay vì ~7,7 ns |
| Thêm phép so sánh thứ ba (`config_error`) gần như **miễn phí về thời gian** | `config_error` ổn định ở 2,58 ns — **sớm hơn** cả `above` |
| Cái giá nằm ở **diện tích**, không nằm ở tốc độ | 52 cell cho logic rất đơn giản; 44,2 % số cell dành riêng cho cây so sánh `sample<min` |
| Mở rộng độ rộng làm độ trễ tăng, mở rộng số bộ so sánh thì không | Độ trễ ~ `O(N)` theo độ rộng, `O(1)` theo số bộ so sánh |

## 4. So ba cách hiện thực bộ so sánh 8 bit

C01 là ví dụ hiếm có: **cùng một lần chạy tổng hợp, công cụ chọn hai kiến trúc khác nhau cho
cùng một phép toán.** Bảng dưới đây so cả ba, trong đó hai dòng đầu là **kiến trúc thật đo
được trong netlist của chính C01**.

| Kiến trúc | Có trong C01? | Độ trễ | Diện tích | Độ phức tạp | Dùng khi |
|---|:-:|---|---|---|---|
| **Chuỗi mượn nối tiếp (ripple)** | ✅ dùng cho `sample>max` và `min>max` | `O(N)` — 7 tầng `maj3_1`, ~0,35 ns/tầng | 8 cell/bộ, **dùng chung được cổng đảo toán hạng** | Rất đơn giản | Khi hai bộ so sánh **chia sẻ toán hạng** và slack còn dư |
| **Cây so sánh song song** | ✅ dùng cho `sample<min` | ~6 tầng, **không xuất hiện trên đường max** | 23 cell — **to nhất** | Trung bình | Khi bộ so sánh nằm trên đường tới hạn và không chia sẻ được gì |
| Bộ trừ đầy đủ rồi xét dấu | ❌ | `O(N)` như ripple | Lớn hơn — phải dựng cả 8 bit hiệu mà chỉ dùng 1 bit | Trung bình | Khi **cũng cần** giá trị hiệu (ví dụ C02 cần giá trị để kẹp) |

> 🔎 **Bài học quan trọng nhất của bảng này:** không có "kiến trúc tốt nhất" cho phép so sánh
> 8 bit. `abc` chọn **ripple** cho hai phép dùng chung `~max_val` (tiết kiệm 7 cổng đảo) và
> chọn **cây** cho phép còn lại (không chia sẻ được gì, nên tối ưu riêng). Cùng công cụ, cùng
> lần chạy, hai quyết định trái ngược — vì **ngữ cảnh** khác nhau.

## 5. Đánh đổi của `config_error` — trả lời Charter mục 2 câu 2

> *"Lỗi cấu hình min>max được phát hiện bằng logic gì, và nó tốn bao nhiêu cell?"*

**Logic:** một phép so sánh 8 bit không dấu `min_val > max_val`, hiện thực bằng chuỗi mượn
7 tầng `maj3_1` — **cùng kiến trúc và dùng chung 7 cổng đảo `~max_val[1:7]`** với bộ so sánh
`sample > max`.

**Chi phí, đếm trực tiếp từ netlist:**

| Thành phần | Instance | Số cell |
|---|---|---:|
| Chuỗi so sánh `min > max` | `_90_` + `_91_…_97_` | 8 |
| Cổng chặn `above` | `_98_` | 1 |
| Cổng chặn `below` | `_99_` | 1 |
| Cổng chặn `inside` | **0** — công cụ chứng minh là thừa | **0** |
| Cổng đảo `~max_val[1:7]` | **0 cell tính thêm** — dùng chung với bộ so sánh `sample>max` | 0 |
| | **Tổng quy cho `config_error`** | **10 / 52 = 19,2 %** |

**Chi phí về thời gian: ≈ 0 ns.** `config_error` ổn định ở **2,58 ns**, sớm hơn đường tới
hạn (2,70 ns). Hai cổng chặn `_98_`/`_99_` thêm 0,12 ns vào đường của `above`/`below` —
nhưng chúng nằm **sau** chuỗi so sánh nên không kéo dài chuỗi.

> ⚠️ **Giới hạn của con số 19,2 %:** đây là tỷ lệ **số cell**, đếm từ netlist. Nó **không**
> bằng tỷ lệ **diện tích**, vì các cell khác nhau về kích thước. Muốn biết phần diện tích
> chính xác phải tổng hợp một phiên bản **không có `config_error`** rồi lấy hiệu — tương tự
> cách Charter yêu cầu ở đề B09. **Chưa chạy.** Diện tích tổng hiện có: 362,848 µm².

**Đánh giá đánh đổi:** trả 19,2 % số cell và ~0 ns để phát hiện một lớp lỗi mà phiên bản
một-ngưỡng không hề có. Với một khối *giám sát chất lượng dữ liệu*, đây là đánh đổi **rất
đáng**: chức năng cốt lõi của C01 là nói cho hệ thống biết khi nào **không nên tin** dữ liệu
— mà cấu hình sai chính là một trong hai lý do lớn nhất để không tin.

## 6. So C01 với C02 — hai khối "anh em" trong cùng học phần

Cả hai chạy trong **cùng một môi trường công cụ** (Yosys 0.33, OpenSTA 3.1.0,
`sky130_fd_sc_hd__tt_025C_1v80.lib`, góc typical · 25 °C · 1,80 V — xem `parameters.md` của
từng đề), nên so sánh này hợp lệ.

| Chỉ số | **C01** (giám sát) | **C02** (kẹp) | Chênh lệch |
|---|---:|---:|---|
| Cổng vào | 3 × 8 bit = 24 bit | 3 × 8 bit = 24 bit | Giống hệt |
| Cổng ra | 4 × 1 bit | 1 × 8 bit | C01 hẹp, C02 rộng |
| Số cell | **52** | **68** | C02 **+31 %** |
| Diện tích | **362,848 µm²** | **515,4944 µm²** | C02 **+42,1 %** |
| Cell tuần tự | 0 | 0 | Cả hai đều tổ hợp thuần ✅ |
| Độ trễ tới hạn | **2,70 ns** | **3,30 ns** | C02 **+0,60 ns (+22 %)** |
| Công suất | 1,21e-05 W | 1,94e-05 W | C02 **+60 %** |
| `maj3_1` (tầng chuỗi so sánh) | 14 | 16 | Gần bằng nhau |
| Cell ghép kênh (`mux2*`) | **0** | **14** | ← **nguồn gốc khác biệt** |

**Diễn giải:** phần *so sánh* của hai khối gần như bằng nhau (14 so với 16 `maj3_1`). Toàn
bộ 42,1 % diện tích chênh lệch và +0,60 ns độ trễ của C02 đến từ **tầng ghép kênh 8 bit ở
đầu ra** mà C01 không có — vì C01 chỉ trả về *kết luận 1 bit*, còn C02 phải *chọn và đưa ra
một giá trị 8 bit*.

> 🎓 **Bài học kiến trúc:** trong một khối kiểu "so sánh rồi hành động", phần **so sánh**
> quyết định **độ trễ**, còn phần **ghép kênh đường dữ liệu ra** quyết định **diện tích**.
> Muốn nhỏ thì thu hẹp đường ra; muốn nhanh thì đổi kiến trúc so sánh. Hai việc hoàn toàn
> khác nhau.

## 7. Ràng buộc phạm vi — cái gì **không** được đổi

| Cám dỗ | Vì sao không được |
|---|---|
| Thêm **vùng trễ (hysteresis)** cho cờ đỡ nhấp nháy | Charter mục 3: hysteresis là **đề C04**, ngoài phạm vi. Và nó cần bộ nhớ ⟹ phá tính tổ hợp thuần |
| Thêm **lọc nhiễu** (N mẫu liên tiếp mới đổi cờ) | Ngoài phạm vi (Charter mục 3); cần bộ đếm ⟹ thêm ô nhớ |
| Cho phép **ngưỡng thay đổi theo thời gian** | Ngoài phạm vi (Charter mục 3) |
| Ép cả ba bộ so sánh dùng cùng một kiến trúc "cho đồng bộ" | Sẽ **tăng** diện tích hoặc độ trễ — `abc` đã chọn đúng theo ngữ cảnh. Và sửa netlist bằng tay nằm ngoài phạm vi |
| Bỏ `config_error` để tiết kiệm 19,2 % cell | Vi phạm Charter mục 8 (ca `min>max` là ca bắt buộc) và mục 2 câu 2 |
| Kẹp mẫu về biên thay vì chỉ báo | Đó là **C02**, một đề khác. C01 báo cáo, không can thiệp |

## 8. Những đánh đổi **không** được phép trong đề này

| Cám dỗ | Vì sao không được |
|---|---|
| Đổi `<` thành `<=` "cho đối xứng" | Đổi ngữ nghĩa cửa sổ từ đóng sang nửa mở — vi phạm đặc tả *"Inclusive [min,max]"* và làm sai ca biên của Charter mục 8 |
| Để `below`/`above` giữ nguyên khi `config_error=1` | Hệ thống nhận phân loại *trông hợp lệ* từ cấu hình vô nghĩa — lỗi im lặng, kiểu lỗi tệ nhất cho khối giám sát |
| Xoá ba dòng gán mặc định (16–18) vì "đằng nào cũng gán trong `if`" | Sinh **ba latch**, phá tính tổ hợp. Xem `fsm.md` §4 |
| Dùng `signed` cho toán hạng | Với ADC không dấu, `255` sẽ thành `-1` ⟹ ca `check(255,0,255)` sẽ ra `below` thay vì `inside` |
| Đọc `period 10.0` thành "C01 chạy ở 100 MHz" | Đó là mốc quy chiếu STA. C01 không có clock |
| Suy tỷ lệ **diện tích** từ tỷ lệ **số cell** | Cell không bằng nhau về diện tích. Chỉ được nói "19,2 % **số cell**" |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Truy vết: REQ-C01-020, REQ-C01-021, Charter mục 2 câu 2, mục 9, mục 10.*
