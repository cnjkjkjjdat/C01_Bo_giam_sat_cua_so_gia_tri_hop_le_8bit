# C01 — Bộ giám sát cửa sổ giá trị hợp lệ 8-bit · Ghi chú thực hiện

---

## 1. Bài toán này thực chất là gì

C01 trông như bài "so sánh hai lần": kiểm mẫu có `≥ min` và `≤ max` không. Nhưng bản chất
của nó là một bài toán về **phân hoạch không gian** và về **độ tin cậy của chính cấu hình**.

Đầu ra của C01 không phải dữ liệu — nó là **một kết luận về dữ liệu**. Khối nhận 24 bit và
trả về 4 bit, và 4 bit đó phải thoả một tính chất mạnh hơn "đúng từng cái": chúng phải tạo
thành một **phân hoạch** — đúng một cờ bật, không hơn không kém. Charter mục 2 câu 1 hỏi
thẳng vào đó ("ba trạng thái loại trừ nhau — bằng chứng nào chứng minh?").

Lớp thứ hai của bài toán, và là lớp dễ bị bỏ sót: **cấu hình cũng có thể sai**. Một ngưỡng
đơn lẻ thì không bao giờ sai được — mọi giá trị 8 bit đều là ngưỡng hợp lệ. Nhưng một **cặp**
ngưỡng thì có thể mâu thuẫn: `min > max` mô tả một cửa sổ rỗng, không có ý nghĩa nào. Khi đó
C01 **không được đoán bừa**; nó phải nói "tôi không phân loại được". Đó là lý do tồn tại của
`config_error`, và đó cũng là điều phân biệt C01 với `threshold_alarm` một ngưỡng (Charter
mục 2 câu 3).

## 2. Bản chất kỹ thuật — cơ chế hoạt động

**Cơ chế so sánh không dấu.** Một phép `a > b` trên 8 bit không dấu thực chất là lấy
**carry-out của `a + ~b + 1`**. Netlist thật của C01 xác nhận điều này: chuỗi so sánh được
dựng bằng 7 cổng `maj3_1` (cổng đa số 3 ngõ, `X = AB|BC|AC` — đúng công thức carry-out của
bộ cộng đầy đủ) mắc nối tiếp:

```
  tầng i:   carry[i+1] = maj3( a[i], ~b[i], carry[i] )
                                              ▲
                                              └── carry[i+1] CẦN carry[i] đã ổn định
```

Đây mới là nút thắt thật: **phụ thuộc nối tiếp 8 tầng**, giống hệt bản chất chuỗi carry của
đề A01. Độ trễ đo được xác nhận: 7 tầng `maj3_1` với độ trễ đều nhau 0,34–0,36 ns, tổng
2,70 ns. Không phải phép "so sánh" là chậm — phép **lan truyền mượn từ bit thấp lên bit cao**
mới là chậm.

**Cơ chế loại trừ ba trạng thái.** Điểm tinh tế: `inside` **không** được tính bằng một phép
so sánh riêng. Nó được tính bằng phủ định của hai phép kia: `inside = !below && !above`. Cách
này bảo đảm tính loại trừ **theo cấu trúc**, không theo may mắn:

```
   below_raw = (s < min)          above_raw = (s > max)

   inside = !below_raw & !above_raw
            └──────────┬─────────┘
       KHÔNG THỂ đồng thời với below_raw hay above_raw — đó là phủ định của chúng
```

Nếu thay bằng `inside = (s >= min) && (s <= max)` — một phép tính độc lập — thì tính loại trừ
trở thành **hệ quả tình cờ** của ba biểu thức riêng biệt, và một lỗi dấu `<`/`<=` ở một chỗ
sẽ phá vỡ nó. Cách hiện tại làm cho INV-1 và INV-2 đúng **theo xây dựng**.

**Cơ chế chặn khi cấu hình sai.** Ba cờ bị ép về `000` khi `config_error=1`. Trong netlist,
phép chặn được hiện thực ở **cell cuối cùng** của đường (`_98_`, `_99_` — chân `SLEEP`), nghĩa
là ba bộ so sánh **vẫn chạy**, chỉ kết quả bị chặn ở cửa ra. Đây là đánh đổi: chặn ở cuối thì
không kéo dài đường tới hạn (`config_error` ổn định ở 2,58 ns, sớm hơn `above` ở 2,70 ns);
chặn ở đầu thì tiết kiệm công suất chuyển mạch nhưng nối thêm một chuỗi vào đường tới hạn.

## 3. Đọc mã nguồn: RTL làm gì, từng dòng quan trọng

**Đoạn 1 — ba dòng chặn latch (dòng 14–18):**

```systemverilog
always_comb begin
    config_error = (min_val > max_val);

    below  = 1'b0;
    inside = 1'b0;
    above  = 1'b0;
```

Ba dòng gán mặc định chạy **trước** mọi nhánh. Chúng làm hai việc cùng lúc: (a) hiện thực
yêu cầu chức năng "cả ba cờ về 0 khi lỗi cấu hình", và (b) chặn hoàn toàn nguy cơ suy ra
latch. Nếu xoá chúng, Yosys sẽ suy ra **ba latch** và tổng hợp sẽ hỏng đúng như đề B09.
So hai đề cạnh nhau là bài học trực quan nhất về mẫu "gán mặc định đầu khối".

**Đoạn 2 — loại trừ theo xây dựng (dòng 20–24):**

```systemverilog
if (!config_error) begin
    below  = (sample_in < min_val);
    above  = (sample_in > max_val);
    inside = !below && !above;
end
```

Dòng `inside = !below && !above` đọc **giá trị vừa gán** của `below` và `above` trong cùng
một khối thủ tục — đây là ngữ nghĩa gán chặn (blocking) và nó đúng. Về phần cứng, nó không
tạo ra vòng lặp: công cụ thay `below`/`above` bằng biểu thức của chúng và ra một cổng NOR.

**Đoạn 3 — nơi hồ sơ vấp (dòng 9):**

```systemverilog
output logic       inside,
```

`inside` là **từ khoá dành riêng của SystemVerilog** (toán tử kiểm tra thuộc tập hợp). Icarus
Verilog với `-g2012` từ chối, mô phỏng **COMPILE_FAIL**. Yosys chấp nhận vì frontend của nó
chỉ cài đặt một tập con của IEEE 1800 và không giữ `inside` làm từ khoá — bằng chứng: netlist
viết tên này dưới dạng định danh thoát `\inside `. Phán xử đầy đủ:
`05_VERIFICATION/known_issues.md`.

## 4. Vì sao chọn kiến trúc này

Tên đề **không** chỉ định kiến trúc nội bộ, nên RTL viết ở mức hành vi (`<`, `>`) và để công
cụ chọn. Kết quả là một phát hiện đáng giá khi đọc netlist: **`abc` chọn hai kiến trúc khác
nhau cho ba phép so sánh cùng loại.**

| Phép so sánh | Kiến trúc | Số cell | Trên đường tới hạn? |
|---|---|---:|:-:|
| `sample > max` | chuỗi mượn ripple (7 × `maj3_1`) | 8 | ✅ |
| `min > max` | chuỗi mượn ripple (7 × `maj3_1`) | 8 | ✅ (đường thứ 2) |
| `sample < min` | **cây so sánh song song** | 23 | ❌ |

Lý do đọc được từ netlist: hai phép đầu **dùng chung toán hạng `~max_val`** — cả `_59_` và
`_91_` cùng lấy `_03_ = ~max_val[1]`, và cứ thế qua 7 cổng đảo `_51_…_57_`. Chọn cùng kiến
trúc cho chúng tiết kiệm được 7 cell. Phép thứ ba không dính `max_val`, không chia sẻ được
gì, nên được tối ưu riêng — và ra một cấu trúc cây nhanh hơn.

**Bài học:** *"một phép `>` trong RTL = một bộ so sánh trong phần cứng"* là cách nghĩ sai.
Công cụ chọn kiến trúc theo **ngữ cảnh chia sẻ tài nguyên**, không theo từng dòng RTL.

## 5. Cách thực hiện — lộ trình 8 bước từ đặc tả tới GDSII

| Bước | Việc | Trạng thái C01 | Bằng chứng |
|---|---|:-:|---|
| 1 | Chốt bảng hành vi + ngữ nghĩa biên (đóng hay mở) | ✅ | `02_SPECIFICATION/functional_spec.md` §2–§3 |
| 2 | Viết mô hình chuẩn Python **độc lập** | ✅ PASS | `python_reference_run.log` |
| 3 | Đọc RTL, lập bảng ánh xạ RTL → phần cứng | ✅ | `03_ARCHITECTURE/block_diagram.md` §2 |
| 4 | Viết testbench tự kiểm, quét đại diện | 🟡 đã viết, **chưa chạy được** | `iverilog_compile.log` |
| 5 | **Lint RTL** | ⬜ chưa có bước này | *Có bước này thì lỗi từ khoá đã bị bắt ở đây* |
| 6 | Tổng hợp + **đếm cell tuần tự** | ✅ 52 cell, **0 FF** | `synth_stat.txt` |
| 7 | STA với clock ảo, đọc đường tới hạn | ✅ 2,70 ns, slack 7,30 ns | `timing_report_max.txt` |
| 8 | P&R → DRC/LVS → GDSII | ⬜ chưa chạy | — |

> Vòng đời của C01 có hình dạng bất thường: **bước 4 hỏng nhưng bước 6–7 chạy được**. Nguyên
> nhân là hai công cụ xử lý khác nhau một tên tín hiệu trùng từ khoá. Phải nói thẳng điều
> này khi bảo vệ, không được lờ đi.

## 6. Số liệu thật đã đo được và cách đọc chúng

| Chỉ số | Giá trị | Nguồn |
|---|---|---|
| Mô hình chuẩn Python | **PASS** | `python_reference_run.log` |
| Mô phỏng RTL | **COMPILE_FAIL** | `iverilog_compile.log` |
| Tổng hợp | **PASS** — 52 cell, **0 FF**, **362,848 µm²** | `synth_stat.txt` |
| STA | **PASS** — `sample_in[0]` → `above`, **2,70 ns**, slack **7,30 ns** | `timing_report_max.txt` |
| WNS / TNS | `0.00` / `0.00` | `wns.txt`, `tns.txt` |
| Công suất | **1,21e-05 W** — tổ hợp **100,0 %**, tuần tự **0,0 %** | `power_report.txt` |
| Cell trên đường tới hạn | 9: `_58_` isobuf + 7 × `maj3_1` + `_98_` isobuf | `timing_report_max.txt` |

**Những số này CHỨNG MINH được:**
- C01 là **mạch tổ hợp thuần**: 0 cell tuần tự trong netlist **và** nhóm công suất Sequential
  = 0,0 %. Hai bằng chứng **độc lập** cho cùng một khẳng định — mức chắc chắn cao nhất trong
  hồ sơ này, và là "dấu hiệu làm đúng" mà Charter mục 10 nêu.
- Ba bộ so sánh **chạy song song**: bốn đầu ra ổn định trong cửa sổ 0,12 ns (2,58…2,70 ns).
- Kiến trúc thật của hai bộ so sánh là **chuỗi mượn nối tiếp**: 7 tầng `maj3_1` độ trễ đều
  0,34–0,36 ns — chữ ký không thể nhầm của ripple.
- Quy mô thật (52 cell) **nhỏ hơn 2,5–3,7 lần** ước lượng Charter (130–190 cell), và lý do
  giải thích được (chia sẻ cổng đảo, gộp cell phức hợp, xoá một cổng chặn thừa).

**Những số này KHÔNG chứng minh được:**
- **Không** chứng minh C01 đúng chức năng ở mức RTL — mô phỏng chưa chạy được lần nào. Bằng
  chứng chức năng hiện **chỉ có một nguồn**: mô hình chuẩn Python.
- **Không** chứng minh netlist tương đương RTL (chưa mô phỏng gate-level).
- **Không** nói gì về độ trễ sau routing: 2,70 ns là số **sau tổng hợp, chưa có ký sinh dây**;
  số thật sau P&R sẽ **lớn hơn**.
- **Không** có biên an toàn qua góc PVT: mới chạy `tt_025C_1v80`, góc `ss` sẽ chậm hơn đáng kể.
- Công suất là **ước lượng** với hoạt động mặc định, không từ VCD thật.
- `period 10.0` trong SDC là **mốc quy chiếu**, **không** được đọc thành "C01 chạy ở 100 MHz".

## 7. Trả lời các câu hỏi kỹ thuật của Charter (mục 2)

**Câu 1 — Ba trạng thái loại trừ nhau, bằng chứng nào chứng minh?**
Ba mức bằng chứng, mạnh dần:
1. **Theo xây dựng (mạnh nhất):** `inside = !below && !above` là **phủ định** của hai cờ kia,
   nên không thể đồng thời với chúng. `below` và `above` loại trừ nhau vì `s < min` và
   `s > max` không thể cùng đúng khi `min ≤ max`.
2. **Theo netlist:** `inside` được sinh bởi **một** cổng `nor2_1` (`_89_`) lấy đúng hai ngõ
   là `_17_` (above_raw) và `_40_` (below_raw). Quan hệ phủ định hiện rõ ở mức cổng.
3. **Theo mô phỏng:** mô hình chuẩn Python kiểm `b+i+a == 1` trên mọi vector (PASS).
   Testbench SystemVerilog có assert tương đương ở dòng 41–53 — nhưng **chưa chạy được**.

**Câu 2 — Lỗi cấu hình `min>max` phát hiện bằng logic gì, tốn bao nhiêu cell?**
Bằng một phép so sánh 8 bit không dấu `min_val > max_val`, hiện thực **cùng kiến trúc** và
**dùng chung 7 cổng đảo** với bộ so sánh `sample > max`. Chi phí đếm từ netlist:
**8 cell** (chuỗi `_90_`+`_91_…_97_`) + **2 cell** chặn (`_98_`, `_99_`) = **10/52 cell =
19,2 % số cell**. Chi phí thời gian ≈ **0 ns**: `config_error` ổn định ở 2,58 ns, **sớm hơn**
đường tới hạn 2,70 ns. Lưu ý: 19,2 % là tỷ lệ **số cell**, không phải tỷ lệ **diện tích** —
muốn số diện tích chính xác phải tổng hợp một bản không có `config_error` rồi lấy hiệu
(**chưa chạy**).

**Câu 3 — C01 khác `threshold_alarm` ở đúng chỗ nào?**
Không phải chỉ ở chỗ "nhân đôi số bộ so sánh". Thêm ngưỡng thứ hai sinh ra **hai nghĩa vụ mới
về chất**: (a) phải **chứng minh ba trạng thái loại trừ nhau** — với 2 trạng thái thì tính
loại trừ là hiển nhiên; (b) phải **kiểm tra tính hợp lệ của chính cấu hình** — với một ngưỡng
thì không tồn tại khái niệm "cấu hình sai". Nghĩa vụ (b) tốn 19,2 % số cell. Bảng so sánh
đầy đủ: `03_ARCHITECTURE/control.md` §5.

## 8. Trả lời câu phân tích riêng (Charter mục 9)

> *"Kiểm trong báo cáo STA xem hai bộ so sánh có nằm trên cùng một đường tới hạn không, và
> giải thích ý nghĩa của việc chúng chạy song song."*

**Trả lời: KHÔNG — chúng chạy song song. Bằng chứng số:**

| Bằng chứng | Số liệu |
|---|---|
| Đường tới hạn có **9 cell**, tất cả thuộc **một** bộ so sánh + 1 cổng chặn | `_58_` + `_59_…_65_` + `_98_` |
| Bốn đầu ra ổn định trong cửa sổ **0,12 ns** | 2,58 / 2,65 / 2,66 / 2,70 ns |
| Nếu nối tiếp, dự kiến ≈ 2 × 2,58 = **5,16 ns**; số đo thật **2,70 ns** | lệch gần 2 lần |

**Phát hiện phụ, và là phần thú vị nhất:** đường chậm nhất tới `below` **không** đi qua bộ so
sánh `sample < min` — nó đi qua bộ so sánh **`min > max`** (chuỗi `_90_…_97_`) rồi mới tới
cổng chặn `_99_`. Nghĩa là **cái chặn chậm hơn cái bị chặn**. Suy ra: cây so sánh
`sample < min` thật sự **nhanh hơn** chuỗi ripple, dù cả hai cùng là so sánh 8 bit.

**Ý nghĩa của việc song song:** độ trễ tổng bằng độ trễ **một** bộ so sánh cộng một tầng
(2,70 ns), thay vì tổng ba bộ (~7,7 ns). Hệ quả thực tiễn: thêm phép so sánh thứ ba
(`config_error`) gần như **miễn phí về thời gian** — nó ổn định sớm hơn cả đường tới hạn.
Cái giá nằm ở **diện tích**, không nằm ở tốc độ. Muốn nhanh hơn nữa thì phải đổi kiến trúc
**bên trong một** bộ so sánh (ripple → cây), chứ không phải giảm số bộ so sánh.

**Phát hiện thứ ba — công cụ đã chứng minh một cổng chặn là thừa.** Netlist sinh `inside`
bằng `nor2(_17_, _40_)`, **không có `config_error`**, trong khi RTL có `if (!config_error)`.
Công cụ đúng: nếu `inside = 1` thì `min ≤ sample ≤ max` ⟹ `min ≤ max` ⟹ `config_error = 0`.
Khi cửa sổ rỗng, `inside` tự bằng 0. Tiết kiệm 1 cell. Chứng minh đầy đủ:
`03_ARCHITECTURE/datapath.md` §5.

## 9. Những chỗ sinh viên hay sai và cách phát hiện

| # | Sai lầm | Hậu quả | Phát hiện bằng bằng chứng nào |
|---|---|---|---|
| 1 | Dùng `<` thay `<=` ở biên (hoặc ngược lại) | `sample = min` bị xếp nhầm vào `below` | Chạy ca `check(50,50,100)` — ca #2 của Charter mục 8 |
| 2 | Quên hẳn `config_error` | Cấu hình `min>max` cho ra phân loại *trông hợp lệ* | Chạy ca `check(75,100,50)`; hoặc đọc netlist tìm chuỗi so sánh thứ ba |
| 3 | Có `config_error` nhưng **quên chặn** ba cờ | Vi phạm INV-3: cờ lỗi bật mà vẫn có cờ phân loại bật | Assert `config_error \|-> {below,inside,above}==3'b000` (TB dòng 52) |
| 4 | Xoá ba dòng gán mặc định vì "đằng nào cũng gán trong `if`" | Sinh **3 latch**, mất tính tổ hợp | `grep -i latch` trong `synth_stat.txt`; đối chiếu đề B09 |
| 5 | Đặt tên tín hiệu trùng **từ khoá** (`inside`, `ref`, `config`, `time`, `type`…) | Mô phỏng không biên dịch được, dù tổng hợp vẫn chạy | Đối chiếu **số dòng lỗi** với **nội dung dòng mã**. Xem `known_issues.md` §2 |
| 6 | Dùng `signed` cho toán hạng | `255` thành `-1` ⟹ ca `check(255,0,255)` ra `below` thay vì `inside` | Ca biên #10 trong `corner_cases.md` §2 |
| 7 | Tin rằng "tổng hợp PASS = thiết kế đúng" | Bỏ qua việc chưa kiểm chứng chức năng | So `synth_stat.txt` (PASS) với `iverilog_compile.log` (FAIL) |
| 8 | Suy tỷ lệ **diện tích** từ tỷ lệ **số cell** | Số sai trong báo cáo | Cell không bằng nhau về diện tích; chỉ tổng diện tích 362,848 µm² là số đo |
| 9 | Đọc `period 10.0` thành "chạy ở 100 MHz" | Phát biểu vượt mức | `design.sdc` ghi rõ `vclk` là mốc quy chiếu; C01 không có clock |
| 10 | "Cải tiến" C01 bằng cách thêm hysteresis cho cờ đỡ nhấp nháy | **Đổi đề** (thành C04) và phá tính tổ hợp thuần | Charter mục 3 liệt hysteresis vào ngoài phạm vi |
| 11 | Nghĩ INV-3 đúng cả ở trạng thái quá độ | Suy luận sai về glitch | Trong netlist, `above` bị chặn ở **cell cuối** ⟹ có cửa sổ thời gian `above=1` và `config_error=1` cùng lúc |

## 10. Câu hỏi mentor nên đặt khi bảo vệ

| # | Câu hỏi | Đáp án mong đợi |
|---|---|---|
| 1 | Tổng hợp PASS mà mô phỏng không biên dịch được — giải thích? | `inside` là từ khoá SystemVerilog. Icarus (`-g2012`) đúng khi từ chối; Yosys chấp nhận vì frontend chỉ cài tập con của IEEE 1800. Bằng chứng: netlist viết `\inside ` dạng định danh thoát |
| 2 | Làm sao chứng minh lỗi đúng do tên `inside`? | Đối chiếu 9 dòng lỗi với nội dung mã: **tất cả** đều chứa `inside` đơn lẻ; không dòng nào khác bị báo lỗi; `inside_ref` không gây lỗi; golden model sạch lỗi |
| 3 | Hai bộ so sánh có cùng đường tới hạn không? Số nào chứng minh? | Không. Đường tới hạn 9 cell đều thuộc **một** bộ. Bốn đầu ra ổn định trong 0,12 ns. Nếu nối tiếp thì phải ≈ 5,16 ns chứ không phải 2,70 ns |
| 4 | `maj3_1` làm gì trong một bộ so sánh? | Bộ sinh carry/mượn: `a > b` = carry-out của `a + ~b + 1`, mà carry-out mỗi tầng chính là hàm đa số 3 ngõ |
| 5 | Vì sao ba bộ so sánh cùng loại mà ra hai kiến trúc khác nhau? | Hai bộ dính `max_val` **dùng chung 7 cổng đảo** ⟹ giữ cùng kiến trúc để chia sẻ. Bộ thứ ba không chia sẻ được gì ⟹ tối ưu riêng, ra cây nhanh hơn |
| 6 | Đường chậm nhất tới `below` đi qua bộ so sánh nào? | Qua `min > max`, **không** phải `sample < min`. Bất ngờ: cái chặn chậm hơn cái bị chặn ⟹ cây nhanh hơn ripple |
| 7 | Trong netlist, `inside` có bị chặn bởi `config_error` không? | Không — công cụ chứng minh được là thừa: `inside=1` ⟹ `min ≤ s ≤ max` ⟹ `min ≤ max` ⟹ `config_error=0`. Cửa sổ rỗng thì `inside` tự bằng 0 |
| 8 | `lpflow_isobufsrc_1` xuất hiện 4 lần — để cách ly nguồn? | Không. `abc` chọn vì hàm `X = A & !SLEEP` và diện tích nhỏ. Hai cái làm tầng mượn đầu chuỗi, hai cái làm cổng chặn |
| 9 | Ba dòng `below=0; inside=0; above=0;` có xoá được không? | Không — sinh **ba latch** (đúng lỗi đề B09) và mất luôn hành vi "cả ba cờ về 0 khi lỗi cấu hình" |
| 10 | C01 đã được kiểm chứng chức năng chưa? | **Chưa.** Mô phỏng RTL chưa chạy được lần nào; bằng chứng chức năng chỉ có một nguồn là mô hình chuẩn Python |
| 11 | `config_error=1` và `above=1` có bao giờ cùng xảy ra? | Ở trạng thái ổn định: không. Ở quá độ: có — `above` bị chặn ở cell cuối. INV-3 là bất biến ở trạng thái ổn định |
| 12 | Vì sao 52 cell trong khi Charter ước lượng 130–190? | Chia sẻ 7 cổng đảo; `abc` gộp cổng vào cell phức hợp; xoá một cổng chặn thừa. Ước lượng Charter là con số dự trù |

## 11. Giới hạn: đã chứng minh được gì, chưa chứng minh được gì

**Đã chứng minh được:**
- **C01 là mạch tổ hợp thuần, 0 ô nhớ** — hai bằng chứng độc lập (netlist 0 cell tuần tự;
  công suất Sequential 0,0 %). "Dấu hiệu làm đúng" của Charter mục 10.
- Quy mô thật **52 cell, 362,848 µm²**, đối chiếu được từng instance với từng dòng RTL.
- Độ trễ lớn nhất **sau tổng hợp** **2,70 ns**, slack 7,30 ns.
- **Ba bộ so sánh chạy song song** — Charter mục 9, trả lời bằng số liệu không suy đoán.
- Kiến trúc thật: hai chuỗi ripple 7 tầng `maj3_1` + một cây so sánh, đọc từ netlist.

**Chưa chứng minh được:**
- **RTL khớp mô hình chuẩn** — mô phỏng `COMPILE_FAIL`, chưa chạy được lần nào. Đây là lỗ
  hổng nghiêm trọng nhất của hồ sơ, dù bề ngoài hồ sơ có vẻ đầy đủ số liệu. Kéo theo: ba
  bất biến INV-1…INV-3 chưa được kiểm trên chính RTL.
- Kết luận của công cụ rằng cổng chặn `inside` là thừa — mới có **chứng minh hình thức bằng
  tay**, chưa có xác nhận thực nghiệm; và tương đương RTL ↔ netlist chưa kiểm.
- Độ trễ **thật sau routing** (2,70 ns chưa tính ký sinh dây); biên an toàn qua các góc PVT;
  công suất thật của ứng dụng (mới là ước lượng).
- Mọi kết luận mức layout: DRC, LVS, GDSII — chưa chạy bước nào.

**Không được phát biểu:** "đã sign-off", "đã tape-out", "chạy được ở 100 MHz", "C01 đã được
kiểm chứng chức năng", "config_error tốn 19,2 % **diện tích**".

**Phát biểu đúng:** *"C01 tổng hợp được ra 52 cell không có ô nhớ nào, diện tích 362,848 µm²,
độ trễ tổ hợp lớn nhất sau tổng hợp 2,70 ns ở góc typical. Ba bộ so sánh 8 bit chạy song song
— chứng minh bằng việc bốn đầu ra ổn định trong cửa sổ 0,12 ns. Kiểm chứng chức năng ở mức
RTL hiện chưa thực hiện được vì tên cổng `inside` trùng từ khoá SystemVerilog; bản vá đã có,
chưa áp dụng, cần giảng viên duyệt."*

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
