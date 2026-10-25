# C01 · Sự cố đã biết và phán xử (Known Issues)

## ✅ Trạng thái: **ĐÃ ÁP DỤNG**

**Ngày áp dụng:** 2026-09-24 · **Người duyệt:** giảng viên đã duyệt áp dụng toàn bộ bản vá

Bản vá ở **§5.1 và §5.2** đã được áp dụng — đổi tên `inside` → `in_window`:

| # | File | Số chỗ sửa |
|---|---|---|
| P-1 | `04_IMPLEMENTATION/rtl/c01_window_monitor.sv` | **3** — dòng 9, 17, 23 |
| P-2 | `05_VERIFICATION/testbench/c01_tb.sv` | **9** — dòng 6, 34, 41, 43, 49, 52 (mã) + dòng 35, 42, 44 (chuỗi thông báo `$fatal`) |

`c01_reference.sv` và `reference_model.py` **không sửa** (§5.3). Nhật ký đầy đủ:
[`08_ORIGINAL_SOURCE/PATCHLOG.md`](../08_ORIGINAL_SOURCE/PATCHLOG.md).

> **Chênh lệch so với bản vá đã soạn:** §5.2 liệt kê **6** chỗ trong testbench; thực tế sửa
> **9**. Ba chỗ thêm là **chuỗi thông báo `$fatal`** (`"inside mismatch…"`,
> `"below/inside overlap"`, `"inside/above overlap"`). Để nguyên sẽ khiến log mô phỏng nói về
> một tín hiệu **không còn tồn tại**. Đây là thay đổi thuần tuý văn bản trong chuỗi, không
> đụng biểu thức nào và không ảnh hưởng hành vi.

| Bước xác minh | Trước khi vá | **Sau khi vá** |
|---|---|---|
| Mô hình chuẩn Python | PASS, mã thoát 0 | ✅ PASS, mã thoát 0 |
| Biên dịch (`iverilog -g2012`) | ❌ **COMPILE_FAIL** — mã thoát **23**, 20 dòng lỗi, **không sinh được `sim.vvp`** | ✅ **PASS** — mã thoát 0, log **rỗng hoàn toàn**: không lỗi, không cảnh báo, không `sorry:` |
| Mô phỏng (`vvp`) | ❌ **KHÔNG CHẠY ĐƯỢC LẦN NÀO** | ✅ **PASS** — `C01 functional verification PASS`, `$finish` tại `Time: 29450`, 0 dòng ERROR/FATAL/mismatch |
| Tổng hợp (Yosys 0.33 + sky130hd) | ✅ 52 cell / 0 FF / 362,848 µm² | ✅ **52 cell / 0 FF / 362,8480 µm²** — **trùng khít tới từng chữ số** |

> ★ **Phép kiểm chéo ở §5.5 bước 3 đã đạt.** §5.5 đặt ra phép thử: *"đổi tên là phép biến đổi
> không đổi ngữ nghĩa, nên mọi số liệu tổng hợp phải giữ nguyên chính xác. Nếu số liệu thay
> đổi, nghĩa là bản vá đã vô tình đổi thứ gì khác."* Kết quả đo: **52 cell, 362,848 µm²,
> 0 FF — trùng khít**, đúng từng dòng trong bảng cell. Bản vá được xác nhận là đổi tên thuần tuý.

### ⚠️ Bản vá này **ĐỔI GIAO DIỆN MODULE**

Cổng ra `inside` của `c01_window_monitor` nay tên là `in_window`. Độ rộng, chiều và thứ tự
cổng **không đổi**. Mọi tài liệu tầng 02 (`interface.md`, `functional_spec.md`,
`parameters.md`), sơ đồ tầng 03, netlist và SDC phải **sinh lại** theo tên mới. Netlist cũ
mang cổng `\inside ` (định danh thoát) nay không còn cần thoát nữa.

### Lớp bằng chứng chức năng — §7 nay đã đổi trạng thái

| Khẳng định | Trước | Sau khi vá |
|---|---|---|
| RTL khớp mô hình chuẩn | ❌ Chưa chạy được lần nào | ✅ **Đã kiểm** |
| Ba cờ loại trừ nhau (INV-1, INV-2) | 🟡 Chưa kiểm trên RTL | ✅ **Đã kiểm trên RTL** |
| Đúng một cờ tích cực khi không có lỗi cấu hình | 🟡 Chưa kiểm trên RTL | ✅ **Đã kiểm** |
| `config_error` chặn đúng ba cờ | 🟡 Chưa kiểm trên RTL | ✅ **Đã kiểm** |
| Ca biên `sample = min`, `sample = max` | 🟡 Chưa kiểm trên RTL | ✅ **Đã kiểm** |
| Kết luận `inside` không cần chặn (`datapath.md` §5) | 🟡 Chưa có xác nhận thực nghiệm | ✅ **Đã có xác nhận thực nghiệm** |

> **Câu giờ ĐÃ ĐƯỢC PHÉP nói khi bảo vệ:** *"C01 đã được kiểm chứng chức năng ở mức RTL, đối
> chiếu với mô hình chuẩn độc lập, và toàn bộ số liệu vật lý giữ nguyên sau bản vá."*
> Điều này thay thế lời cảnh báo ở cuối §7.

---

*Toàn bộ nội dung từ đây trở xuống là bản chẩn đoán gốc, giữ nguyên để làm tài liệu dạy học.
Trạng thái "CHƯA ÁP DỤNG" ghi ở §8 nay đã lỗi thời — xem khối trạng thái ở trên.*

---

> **Tóm tắt một dòng (tại thời điểm chẩn đoán, trước khi vá):** mô phỏng RTL **COMPILE_FAIL**. Nguyên nhân: tên tín hiệu `inside`
> trùng với **từ khoá dành riêng của SystemVerilog**. Lỗi nằm ở **DUT** (và lan sang
> testbench vì testbench dùng cùng tên), là lỗi **tuân thủ chuẩn ngôn ngữ** — Icarus Verilog
> **đúng** khi từ chối. Không phải lỗi logic, không phải lỗi mô hình chuẩn, không phải giới
> hạn công cụ. Tổng hợp vẫn PASS vì frontend SystemVerilog của Yosys dễ tính hơn.

---

## 1. Thông báo lỗi — trích chính xác

Nguồn: `05_VERIFICATION/iverilog_compile.log` (toàn bộ, đã rút đường dẫn cho gọn):

```
c01_window_monitor.sv:9 : syntax error
c01_window_monitor.sv:1 : Errors in port declarations.
c01_window_monitor.sv:17: syntax error
c01_window_monitor.sv:17: Syntax in assignment statement l-value.
c01_window_monitor.sv:23: syntax error
c01_window_monitor.sv:23: Syntax in assignment statement l-value.
c01_tb.sv:6 : syntax error
c01_tb.sv:1 : error: Syntax error in variable list.
c01_tb.sv:34: syntax error
c01_tb.sv:34: error: Malformed conditional expression.
c01_tb.sv:41: syntax error
c01_tb.sv:41: error: Operand of unary ! is not a primary expression.
c01_tb.sv:42: error: Malformed statement
c01_tb.sv:43: syntax error
c01_tb.sv:43: error: Operand of unary ! is not a primary expression.
c01_tb.sv:44: error: Malformed statement
c01_tb.sv:49: syntax error
c01_tb.sv:50: error: Malformed statement
c01_tb.sv:52: syntax error
c01_tb.sv:52: error: Malformed conditional expression.
```

Hệ quả: không sinh được `sim.vvp`, nên **không có** `05_VERIFICATION/simulation.log` và
**không có** thư mục `waveforms/`. Liên kết tới `simulation.log` trong
`verification_report.md` §3 là liên kết **hỏng** — đúng như trạng thái thật.

## 2. Truy nguyên: mọi dòng lỗi đều chứa đúng một từ

Đây là bước phán xử quan trọng nhất. Đối chiếu **từng dòng lỗi** với **từng dòng mã**:

### 2.1 `c01_window_monitor.sv`

| Dòng lỗi | Nội dung dòng mã | Chứa `inside`? |
|---:|---|:-:|
| 9 | `    output logic       inside,` | ✅ |
| 17 | `        inside = 1'b0;` | ✅ |
| 23 | `            inside = !below && !above;` | ✅ |
| *(1)* | *`module c01_window_monitor (`* — lỗi phụ "Errors in port declarations", hệ quả của dòng 9 | — |

**Các dòng 8, 10, 11** (`output logic below,`, `output logic above,`,
`output logic config_error`) **không** bị báo lỗi, dù cấu trúc cú pháp **giống hệt** dòng 9.

### 2.2 `c01_tb.sv`

| Dòng lỗi | Nội dung dòng mã | Chứa `inside`? |
|---:|---|:-:|
| 6 | `    logic below, inside, above, config_error;` | ✅ |
| 34 | `            assert(inside === inside_ref)` | ✅ |
| 41 | `            assert(!(below && inside))` | ✅ |
| 43 | `            assert(!(inside && above))` | ✅ |
| 49 | `                assert((below + inside + above) == 1)` | ✅ |
| 52 | `                assert({below,inside,above} === 3'b000)` | ✅ |

**Dòng 7** (`logic below_ref, inside_ref, above_ref, config_error_ref;`) **không** bị báo lỗi
— dù cũng chứa chuỗi ký tự "inside", nhưng là một phần của định danh `inside_ref`.

### 2.3 `c01_reference.sv` — **không có lỗi nào**

Golden model dùng các tên `below_ref`, `inside_ref`, `above_ref`, `config_error_ref`. Không
tên nào là `inside` đơn lẻ ⟹ **không dòng nào bị báo lỗi**.

### 2.4 Kết luận truy nguyên

| Quan sát | Kết luận |
|---|---|
| **9/9** dòng bị báo `syntax error` đều chứa định danh `inside` đứng một mình | Tương quan hoàn hảo |
| **0** dòng không chứa `inside` bị báo `syntax error` | Không có ngoại lệ |
| Định danh `inside_ref` **không** gây lỗi | Lỗi ở **toàn bộ từ**, không phải chuỗi con — đúng đặc trưng của **tách token từ khoá** |
| File duy nhất không dùng tên `inside` là file duy nhất không có lỗi | Xác nhận |

**Nguyên nhân: `inside` là từ khoá dành riêng của SystemVerilog** (toán tử kiểm tra thuộc
tập hợp, dùng như `if (x inside {1, 2, [5:9]})`). Nó có trong danh sách từ khoá của IEEE
1800 và **không được dùng làm định danh**. Icarus Verilog chạy với cờ `-g2012`
(`04_IMPLEMENTATION/scripts/01_run_sim.sh` dòng 17) nên bật đúng bộ từ khoá SystemVerilog.

Điều này giải thích **chính xác** từng thông báo phụ:

| Thông báo | Vì sao trình phân tích nói vậy |
|---|---|
| `Syntax in assignment statement l-value` (dòng 17, 23) | Vế trái của phép gán là một **từ khoá**, không phải định danh ⟹ không phải l-value hợp lệ |
| `Syntax error in variable list` (TB dòng 6) | Đang liệt kê biến thì gặp từ khoá giữa danh sách |
| `Operand of unary ! is not a primary expression` (TB dòng 41, 43) | Sau `&&` phải là biểu thức; gặp từ khoá `inside` ⟹ trình phân tích thấy toán tử `inside` thiếu vế trái |
| `Malformed conditional expression` (TB dòng 34, 52) | Biểu thức trong `assert(...)` hỏng vì lý do trên |
| `Errors in port declarations` (RTL dòng 1) | Lỗi tổng kết cho cả danh sách cổng, báo tại dòng mở module |

## 3. Phán xử: lỗi nằm ở đâu?

| Ứng viên | Phán xử | Lập luận |
|---|:-:|---|
| **DUT** (`c01_window_monitor.sv`) | ✅ **CÓ LỖI** — và đây là gốc | Đặt tên cổng ra là `inside`, một từ khoá dành riêng. Lỗi ở **giao diện**, nên nó lan ra mọi file dùng giao diện đó |
| **Testbench** (`c01_tb.sv`) | 🟡 **Bị kéo theo**, không phải gốc | TB **buộc** phải dùng tên `inside` vì nó nối với DUT bằng `.*` (dòng 9) — kết nối ngầm đòi tên hai bên trùng khớp. Sửa TB mà không sửa DUT thì `.*` sẽ hỏng |
| **Mô hình chuẩn** (`c01_reference.sv`, `reference_model.py`) | ❌ **Không lỗi** | Dùng hậu tố `_ref` nên tránh được từ khoá; không file nào bị báo lỗi; Python model PASS |
| **Giới hạn công cụ** (Icarus) | ❌ **Không phải** | Icarus **đúng theo chuẩn**. Bất kỳ trình biên dịch SystemVerilog tuân thủ IEEE 1800 nào cũng phải từ chối. Đây **không** phải chuyện "Icarus yếu" |

**Mức độ:** chặn tiến độ ở nhánh kiểm chứng chức năng (mô phỏng), **không** chặn nhánh vật
lý (tổng hợp/STA/công suất đều PASS).

## 4. Vì sao Yosys chấp nhận mà Icarus từ chối?

Đây là phần có giá trị dạy học cao nhất của đề này: **hai công cụ đọc cùng một file, cho hai
kết luận trái ngược.**

| Công cụ | Kết quả | Vì sao |
|---|---|---|
| **Icarus Verilog** (`-g2012`) | ❌ Từ chối | Bộ phân tích SystemVerilog đầy đủ, có cài đặt toán tử `inside` ⟹ `inside` là token từ khoá |
| **Yosys** (`read_verilog -sv`) | ✅ Chấp nhận | Frontend SystemVerilog của Yosys chỉ hỗ trợ **một tập con** của IEEE 1800. Toán tử `inside` không nằm trong tập con đó, nên Yosys **không** giữ `inside` làm từ khoá và coi nó là định danh bình thường |

### Bằng chứng Yosys "biết" tên này có vấn đề

Mở `06_GDSII/synthesis/netlist.v`, dòng 3 và 58:

```verilog
module c01_window_monitor(sample_in, min_val, max_val, below, \inside , above, config_error);
  ...
  output \inside ;
```

Yosys viết tên đó dưới dạng **định danh thoát** (escaped identifier): dấu `\` ở đầu, khoảng
trắng bắt buộc ở cuối. Đây là cơ chế của Verilog để dùng tên "không hợp lệ" một cách hợp lệ.
**Chính công cụ đã đánh dấu rằng tên này cần xử lý đặc biệt khi xuất ra Verilog.**

> 🎓 **Bài học:** *"tổng hợp được"* **không** đồng nghĩa với *"đúng chuẩn ngôn ngữ"*, và
> *"một công cụ chấp nhận"* **không** đồng nghĩa với *"mọi công cụ sẽ chấp nhận"*. Một
> thiết kế thật phải đi qua nhiều công cụ (mô phỏng, lint, tổng hợp, formal, P&R). Tên nào
> chỉ qua được một nửa số công cụ thì phải đổi, không phải tranh cãi xem công cụ nào đúng.

## 5. Bản vá tối thiểu

### 5.1 Diff cho RTL

```diff
--- a/04_IMPLEMENTATION/rtl/c01_window_monitor.sv
+++ b/04_IMPLEMENTATION/rtl/c01_window_monitor.sv
@@ -6,7 +6,7 @@
     input  logic [7:0] max_val,
     output logic       below,
-    output logic       inside,
+    output logic       in_window,
     output logic       above,
     output logic       config_error
 );
@@ -14,12 +14,12 @@
         config_error = (min_val > max_val);
 
         below  = 1'b0;
-        inside = 1'b0;
+        in_window = 1'b0;
         above  = 1'b0;
 
         if (!config_error) begin
             below  = (sample_in < min_val);
             above  = (sample_in > max_val);
-            inside = !below && !above;
+            in_window = !below && !above;
         end
```

**Ba chỗ trong RTL: dòng 9, 17, 23.**

### 5.2 Diff cho testbench

Vì `c01_tb.sv` nối DUT bằng `.*` (dòng 9), **bắt buộc** phải đổi tên đồng bộ:

```diff
--- a/05_VERIFICATION/testbench/c01_tb.sv
+++ b/05_VERIFICATION/testbench/c01_tb.sv
@@ -6 +6 @@
-    logic below, inside, above, config_error;
+    logic below, in_window, above, config_error;
@@ -34 +34 @@
-            assert(inside === inside_ref)
+            assert(in_window === inside_ref)
@@ -41,2 +41,2 @@
-            assert(!(below && inside))
+            assert(!(below && in_window))
@@ -43,2 +43,2 @@
-            assert(!(inside && above))
+            assert(!(in_window && above))
@@ -49,2 +49,2 @@
-                assert((below + inside + above) == 1)
+                assert((below + in_window + above) == 1)
@@ -52,2 +52,2 @@
-                assert({below,inside,above} === 3'b000)
+                assert({below,in_window,above} === 3'b000)
```

**Sáu chỗ trong testbench: dòng 6, 34, 41, 43, 49, 52.**

### 5.3 Golden model: **không sửa gì**

`c01_reference.sv` dùng `inside_ref` — hợp lệ, giữ nguyên. Testbench đối chiếu
`in_window === inside_ref`, hai tên khác nhau là bình thường (một bên DUT, một bên mô hình
chuẩn).

### 5.4 Chọn tên thay thế

| Tên đề nghị | Đánh giá |
|---|---|
| **`in_window`** | ✅ **Khuyến nghị** — mô tả đúng nghĩa ("trong cửa sổ"), không trùng từ khoá nào, giữ được phong cách đặt tên của các cổng khác |
| `within` | 🟡 Được, nhưng mơ hồ hơn |
| `inside_win` | 🟡 Được |
| `\inside ` (định danh thoát) | ❌ **Không nên** — hợp lệ về cú pháp nhưng gây rắc rối ở mọi bước sau (script, SDC, báo cáo, tên net trong P&R) |
| `inside_r`, `is_inside` | 🟡 Được, nhưng `in_window` rõ nghĩa hơn |

### 5.5 Sau khi vá — quy trình kiểm chứng lại

```bash
# 1. Mô phỏng: giờ phải biên dịch được và PASS
bash 04_IMPLEMENTATION/scripts/01_run_sim.sh

# 2. Tổng hợp LẠI (bắt buộc — tên cổng trong netlist đã đổi)
bash 04_IMPLEMENTATION/scripts/02_run_synth.sh

# 3. Xác nhận số liệu KHÔNG đổi: phải vẫn là 52 cell, 362,848 µm², 0 FF
#    (đổi tên cổng không đổi logic; nếu số liệu đổi thì có gì đó sai)

# 4. Chạy lại STA — đường tới hạn phải vẫn là sample_in[0] → above, 2,70 ns
```

> **Bước 3 là một phép kiểm chéo rất có giá trị:** đổi tên là phép biến đổi **không đổi ngữ
> nghĩa**, nên mọi số liệu tổng hợp phải giữ nguyên chính xác. Nếu số liệu thay đổi, nghĩa
> là bản vá đã vô tình đổi thứ gì khác.

## 6. Giá trị dạy học

Lỗi này đáng dạy vì bốn lý do:

**① Nó dạy cách truy nguyên lỗi cú pháp một cách có hệ thống.** Hai mươi dòng lỗi trông rất
đáng sợ, nhưng chỉ cần một thao tác — đối chiếu **số dòng lỗi** với **nội dung dòng mã** — là
lộ ngay quy luật: mọi dòng lỗi đều chứa đúng một từ. Đây là kỹ năng chuyển giao được cho mọi
lỗi cú pháp, không riêng gì lỗi này.

**② Nó dạy rằng "tên biến" là một quyết định kỹ thuật, không phải chuyện thẩm mỹ.** Các tên
cần tránh trong SystemVerilog vì trùng từ khoá: `inside`, `ref`, `bind`, `cell`, `config`,
`table`, `time`, `type`, `event`, `final`, `matches`, `randomize`, `before`, `expect`,
`priority`, `unique`, `wait`, `cover`, `assert`, `assume`, `local`, `new`, `null`, `this`.
Nhiều trong số đó nghe **rất tự nhiên** cho tên tín hiệu phần cứng.

**③ Nó xuất hiện hai lần trong cùng bộ hồ sơ.** `brief/C01.md` ghi mục *"Sửa nguồn tối thiểu
đã áp dụng"*: instance của golden model trong testbench vốn tên là `ref` — cũng là **từ khoá
SystemVerilog** (đối số truyền tham chiếu) — và đã phải đổi thành `ref_i` để Icarus chấp nhận.
Cùng một loại lỗi, hai chỗ khác nhau, trong một file. Đó không phải trùng hợp: đây là **lớp
lỗi phổ biến**, không phải tai nạn hiếm.

**④ Nó cho thấy giá trị thật của việc chạy nhiều công cụ độc lập.** Nếu quy trình chỉ chạy
Yosys, lỗi này sẽ **không bao giờ lộ ra** — cho tới khi ai đó thử mô phỏng, hoặc thử một
công cụ khác, hoặc nộp bài cho hệ thống của Tiny Tapeout. Chạy cả Icarus lẫn Yosys đã bắt
được lỗi ở giai đoạn rẻ nhất.

### Đề nghị bổ sung quy trình (chưa áp dụng, cần thầy duyệt)

Thêm một bước **lint** trước khi mô phỏng, dùng công cụ có bộ từ khoá đầy đủ
(Verilator `--lint-only`, hoặc Verible). Lint sẽ bắt lớp lỗi này ngay ở bước rẻ nhất, và
cũng bắt được lớp lỗi latch của đề **B09** trong cùng học phần.

## 7. Hậu quả: những gì C01 **chưa** chứng minh được vì lỗi này

Mục này quan trọng vì hồ sơ C01 nhìn thoáng qua rất "đầy đủ" (có số cell, diện tích, timing,
công suất) nhưng lại **thiếu đúng lớp bằng chứng nền tảng nhất**.

| Khẳng định | Bằng chứng hiện có | Trạng thái |
|---|---|---|
| Hàm số của C01 đúng theo đặc tả | **Chỉ** mô hình chuẩn Python (`python_reference_run.log` PASS) | 🟡 **Một nguồn duy nhất** |
| RTL khớp mô hình chuẩn | — | ❌ **Chưa chạy được lần nào** |
| Ba cờ loại trừ nhau (INV-1, INV-2) | Mô hình chuẩn Python có assert; testbench có assert nhưng **chưa chạy** | 🟡 Chưa kiểm trên RTL |
| Ca biên `sample = min`, `sample = max` đúng | Mô hình chuẩn Python; testbench đã viết nhưng chưa chạy | 🟡 Chưa kiểm trên RTL |
| `config_error` chặn đúng ba cờ | như trên | 🟡 Chưa kiểm trên RTL |
| Kết luận của công cụ rằng `inside` không cần chặn là đúng (xem `datapath.md` §5) | Chứng minh hình thức bằng tay | 🟡 **Chưa có xác nhận thực nghiệm** |
| C01 là mạch tổ hợp, 0 ô nhớ | `synth_stat.txt` (0 cell tuần tự) + `power_report.txt` (Sequential 0,0 %) | ✅ **Hai bằng chứng độc lập** |
| Tổng hợp ra 52 cell, 362,848 µm² | `synth_stat.txt` | ✅ |
| Độ trễ tới hạn 2,70 ns, slack 7,30 ns | `timing_report_max.txt` | ✅ |

> ❗ **Câu phải nói khi bảo vệ:** *"Số liệu vật lý của C01 đầy đủ và đáng tin. Nhưng bằng
> chứng chức năng ở mức RTL hiện đang thiếu — testbench đã viết xong nhưng chưa chạy được
> lần nào vì lỗi tên tín hiệu. Sau khi áp bản vá, toàn bộ lớp bằng chứng đó sẽ có."*
>
> **Câu KHÔNG được nói:** *"C01 đã được kiểm chứng chức năng"*. Chưa.

## 8. Trạng thái áp dụng bản vá — ~~CHƯA ÁP DỤNG~~ → **ĐÃ ÁP DỤNG (2026-09-24)**

> ✅ **Cập nhật 2026-09-24:** giảng viên đã duyệt; bản vá §5.1 + §5.2 **đã được áp dụng**.
> Quy trình §5.5 bước 1–3 **đã xong**: biên dịch và mô phỏng PASS, tổng hợp PASS với số liệu
> **trùng khít** (52 cell / 0 FF / 362,848 µm²) — đúng như phép kiểm chéo ở bước 3 đòi hỏi.
> Bước 4 (STA) **còn lại**. Xem khối trạng thái ở đầu tài liệu và
> `08_ORIGINAL_SOURCE/PATCHLOG.md`.
>
> Lý do 2 ("bản gốc là bằng chứng dạy học") vẫn được tôn trọng: bản gốc nguyên vẹn nằm trong
> `08_ORIGINAL_SOURCE/rtl/` và `08_ORIGINAL_SOURCE/testbench/`, và toàn bộ phần chẩn đoán
> trong tài liệu này được giữ nguyên.
>
> *Văn bản gốc của mục này, giữ nguyên để đối chiếu:*

> ⚠️ **BẢN VÁ CHƯA ĐƯỢC ÁP DỤNG.** Các file `04_IMPLEMENTATION/rtl/c01_window_monitor.sv` và
> `05_VERIFICATION/testbench/c01_tb.sv` trong hồ sơ này **giữ nguyên bản gốc của thầy**.
>
> Lý do giữ nguyên:
> 1. RTL và testbench là tài sản của giảng viên; hồ sơ phân tích không tự ý sửa mã được giao.
> 2. Bản gốc chính là **bằng chứng dạy học** cho lớp lỗi "tên trùng từ khoá".
> 3. Mọi số liệu trong hồ sơ phải khớp với **đúng mã đã chạy**. Netlist hiện tại có cổng tên
>    `\inside ` — sửa RTL mà không chạy lại tổng hợp sẽ làm hồ sơ mâu thuẫn với netlist.
>
> **Cần thầy duyệt trước khi sửa.** Sau khi duyệt, làm theo §5.5 và cập nhật:
> `05_VERIFICATION/verification_report.md` §2–§4, `05_VERIFICATION/test_matrix.csv`
> (TC-001, TC-002, L2-SIM), `07_TRACEABILITY/limitations.md`, và mục §7 ở trên.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Nguồn bằng chứng: `05_VERIFICATION/iverilog_compile.log`, `04_IMPLEMENTATION/rtl/c01_window_monitor.sv`, `05_VERIFICATION/testbench/c01_tb.sv`, `05_VERIFICATION/golden_model/c01_reference.sv`, `06_GDSII/synthesis/netlist.v` (dòng 3, 58), `brief/C01.md`.*
