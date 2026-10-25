# C01 · Nhật ký vá (PATCHLOG)

**Ngày vá:** 2026-09-24 · **Người duyệt:** giảng viên đã duyệt áp dụng toàn bộ bản vá

## 1. Tóm tắt

| # | File | Loại lỗi | Mô tả một dòng | Ảnh hưởng số liệu |
|---|---|---|---|---|
| P-1 | `04_IMPLEMENTATION/rtl/c01_window_monitor.sv` | **Lỗi tuân thủ chuẩn ngôn ngữ** | Cổng ra tên `inside` — là **từ khoá dành riêng** của SystemVerilog ⟹ Icarus từ chối biên dịch. Đổi thành `in_window` (3 chỗ) | **Có — đổi tên cổng, netlist phải sinh lại** (nhưng số liệu không đổi, xem §3) |
| P-2 | `05_VERIFICATION/testbench/c01_tb.sv` | Bị kéo theo P-1 | Testbench nối DUT bằng `.*` nên **bắt buộc** đổi tên đồng bộ (6 chỗ mã + 3 chuỗi thông báo) | Không |

Mô hình chuẩn (`c01_reference.sv`, `reference_model.py`) **không bị sửa một ký tự nào** — cả
hai dùng hậu tố `_ref` nên tránh được từ khoá; `known_issues.md` §5.3 đã nêu rõ điều này.

## 2. Chi tiết từng bản vá

### P-1 — Đổi tên cổng ra `inside` → `in_window` trong RTL

**File:** `04_IMPLEMENTATION/rtl/c01_window_monitor.sv` · **Dòng:** 9, 17, 23 ·
**Phán xử:** lỗi ở **DUT**, và đây là **gốc** của toàn bộ 20 dòng lỗi biên dịch

**Trước:**

```systemverilog
module c01_window_monitor (
    input  logic [7:0] sample_in,
    input  logic [7:0] min_val,
    input  logic [7:0] max_val,
    output logic       below,
    output logic       inside,          // <-- dong 9
    output logic       above,
    output logic       config_error
);
    always_comb begin
        config_error = (min_val > max_val);

        below  = 1'b0;
        inside = 1'b0;                  // <-- dong 17
        above  = 1'b0;

        if (!config_error) begin
            below  = (sample_in < min_val);
            above  = (sample_in > max_val);
            inside = !below && !above;  // <-- dong 23
        end
    end
endmodule
```

**Sau:**

```systemverilog
module c01_window_monitor (
    input  logic [7:0] sample_in,
    input  logic [7:0] min_val,
    input  logic [7:0] max_val,
    output logic       below,
    output logic       in_window,
    output logic       above,
    output logic       config_error
);
    always_comb begin
        config_error = (min_val > max_val);

        below  = 1'b0;
        in_window = 1'b0;
        above  = 1'b0;

        if (!config_error) begin
            below  = (sample_in < min_val);
            above  = (sample_in > max_val);
            in_window = !below && !above;
        end
    end
endmodule
```

**Vì sao:** `inside` là **toán tử kiểm tra thuộc tập hợp** của SystemVerilog
(`if (x inside {1, 2, [5:9]})`), nằm trong danh sách từ khoá của IEEE 1800, nên **không được
dùng làm định danh**. Icarus chạy với cờ `-g2012` nên bật đúng bộ từ khoá đó và **đúng theo
chuẩn** khi từ chối. Bằng chứng truy nguyên ở `known_issues.md` §2: **9/9** dòng bị báo
`syntax error` đều chứa định danh `inside` đứng một mình, **0** dòng không chứa nó bị báo
lỗi, và `inside_ref` **không** gây lỗi (lỗi ở **toàn bộ từ**, không phải chuỗi con — đúng đặc
trưng của tách token từ khoá).

Tên thay thế `in_window` được chọn theo bảng đánh giá ở `known_issues.md` §5.4: mô tả đúng
nghĩa ("trong cửa sổ"), không trùng từ khoá nào, giữ được phong cách đặt tên của các cổng
khác. Định danh thoát `\inside ` bị loại vì tuy hợp lệ về cú pháp nhưng gây rắc rối ở mọi
bước sau (script, SDC, báo cáo, tên net trong P&R).

**Hệ quả — ĐỔI GIAO DIỆN MODULE:** đây là bản vá **duy nhất trong bốn đề đợt này** có đổi
giao diện. Tên cổng `inside` đã biến mất khỏi module `c01_window_monitor` và được thay bằng
`in_window`. Theo SPEC §4 nguyên tắc 2, điều này được ghi thật rõ ở đây vì mọi tài liệu tầng
02 (`interface.md`, `functional_spec.md`, `parameters.md`) và mọi netlist sẽ phải sinh lại
theo. **Độ rộng, chiều và thứ tự cổng không đổi** — chỉ đổi đúng một cái tên. Bản vá là một
phép **đổi tên thuần tuý, không đổi ngữ nghĩa**, và §3 chứng minh điều đó bằng số đo.

### P-2 — Đổi tên đồng bộ trong testbench

**File:** `05_VERIFICATION/testbench/c01_tb.sv` · **Dòng:** 6, 34, 35, 41, 42, 43, 44, 49, 52 ·
**Phán xử:** testbench **bị kéo theo**, không phải gốc của lỗi

**Trước → Sau** (chỉ liệt kê những dòng đổi):

```diff
-    logic below, inside, above, config_error;
+    logic below, in_window, above, config_error;

-            assert(inside === inside_ref)
-                else $fatal(1, "inside mismatch s=%0d lo=%0d hi=%0d",s,lo,hi);
+            assert(in_window === inside_ref)
+                else $fatal(1, "in_window mismatch s=%0d lo=%0d hi=%0d",s,lo,hi);

-            assert(!(below && inside))
-                else $fatal(1, "below/inside overlap");
-            assert(!(inside && above))
-                else $fatal(1, "inside/above overlap");
+            assert(!(below && in_window))
+                else $fatal(1, "below/in_window overlap");
+            assert(!(in_window && above))
+                else $fatal(1, "in_window/above overlap");

-                assert((below + inside + above) == 1)
+                assert((below + in_window + above) == 1)

-                assert({below,inside,above} === 3'b000)
+                assert({below,in_window,above} === 3'b000)
```

**Vì sao:** `c01_tb.sv` dòng 9 nối DUT bằng `c01_window_monitor dut(.*);` — kết nối ngầm đòi
tên tín hiệu hai bên **trùng khớp**. Sửa RTL mà không sửa TB thì `.*` sẽ hỏng ngay. Đây là lý
do `known_issues.md` §3 xếp testbench vào loại 🟡 "bị kéo theo": nó **buộc** phải đổi, không
phải vì nó sai.

Dòng 7 (`logic below_ref, inside_ref, above_ref, config_error_ref;`) và cả instance
`c01_reference ref_i(... .inside_ref(inside_ref) ...)` **giữ nguyên** — `inside_ref` là định
danh hợp lệ. Testbench giờ đối chiếu `in_window === inside_ref`: hai tên khác nhau là bình
thường, một bên DUT một bên mô hình chuẩn.

### Chênh lệch so với bản vá đã soạn ở `known_issues.md`

Bản vá §5.1 và §5.2 áp dụng được nguyên văn về mặt mã. Có **một chênh lệch có chủ ý**:

| Hạng mục | Bản vá đã soạn (§5.2) | Đã áp dụng thực tế | Vì sao |
|---|---|---|---|
| Số chỗ sửa trong testbench | **6** — dòng 6, 34, 41, 43, 49, 52 (chỉ phần mã) | **9** — thêm dòng 35, 42, 44 | Ba dòng thêm là **chuỗi thông báo `$fatal`** (`"inside mismatch…"`, `"below/inside overlap"`, `"inside/above overlap"`). Để chúng nguyên sẽ khiến log mô phỏng nói về một tín hiệu **không còn tồn tại**, gây nhầm lẫn khi chẩn đoán về sau. Đây là thay đổi **thuần tuý văn bản trong chuỗi**, không đụng biểu thức nào và không ảnh hưởng hành vi |

Ngoài ra, `known_issues.md` §6 mục ③ có nhắc instance của golden model vốn tên là `ref` —
cũng là từ khoá SystemVerilog — và đã được đổi thành `ref_i` từ trước. Đã kiểm tra lại
`c01_tb.sv` dòng 11: tên đang là `ref_i`, **không cần sửa thêm**.

## 3. Kết quả xác minh sau khi vá

| Bước | Trước khi vá | Sau khi vá |
|---|---|---|
| Mô hình chuẩn Python | `C01 independent Python reference: PASS`, mã thoát 0 | `C01 independent Python reference: PASS`, mã thoát 0 — không đổi |
| Biên dịch | ❌ **COMPILE_FAIL** — mã thoát **23**, 20 dòng lỗi (9 `syntax error` + các lỗi phụ), **không sinh được `sim.vvp`** | ✅ **PASS** — mã thoát 0, log **rỗng hoàn toàn**: không lỗi, không cảnh báo, không `sorry:` |
| Mô phỏng | ❌ **KHÔNG CHẠY ĐƯỢC LẦN NÀO** — không có `simulation.log`, không có `waveforms/` | ✅ `C01 functional verification PASS`, `$finish` tại `Time: 29450`, 0 dòng ERROR/FATAL/mismatch |
| Tổng hợp | ✅ 52 cell / 0 FF / 362,848 µm² (Yosys chấp nhận vì frontend SV của nó không giữ `inside` làm từ khoá; nó viết cổng đó dưới dạng định danh thoát `\inside `) | ✅ **52 cell / 0 FF / 362,8480 µm²** — **giống hệt tới từng chữ số** |

Số cell tuần tự (`__df*`, `__dl*`, `latch`) trong bảng `stat`: **0**.

> ★ **Bước kiểm chéo quan trọng nhất của đề này đã đạt.** `known_issues.md` §5.5 bước 3 đặt
> ra một phép thử: *"đổi tên là phép biến đổi không đổi ngữ nghĩa, nên mọi số liệu tổng hợp
> phải giữ nguyên chính xác. Nếu số liệu thay đổi, nghĩa là bản vá đã vô tình đổi thứ gì
> khác."* Kết quả đo: **52 cell, 362,848 µm², 0 FF — trùng khít trước và sau**, đúng từng
> dòng trong bảng cell. Bản vá được xác nhận là đổi tên thuần tuý.

### 3.1 Bảng cell sau khi vá

```
=== c01_window_monitor ===

   Number of wires:                 55
   Number of wire bits:             76
   Number of public wires:           7
   Number of public wire bits:      28
   Number of memories:               0
   Number of memory bits:            0
   Number of processes:              0
   Number of cells:                 52
     sky130_fd_sc_hd__a2111oi_0      1
     sky130_fd_sc_hd__a21oi_1        2
     sky130_fd_sc_hd__a31oi_1        1
     sky130_fd_sc_hd__clkinv_1      10
     sky130_fd_sc_hd__lpflow_isobufsrc_1      4
     sky130_fd_sc_hd__maj3_1        14
     sky130_fd_sc_hd__nand2_1        1
     sky130_fd_sc_hd__nand2b_1       2
     sky130_fd_sc_hd__nand3_1        1
     sky130_fd_sc_hd__nand3b_1       2
     sky130_fd_sc_hd__nor2_1         2
     sky130_fd_sc_hd__nor3b_1        1
     sky130_fd_sc_hd__o21ai_0        3
     sky130_fd_sc_hd__o21bai_1       1
     sky130_fd_sc_hd__xnor2_1        5
     sky130_fd_sc_hd__xor2_1         2

   Chip area for module '\c01_window_monitor': 362.848000
```

### 3.2 Lớp bằng chứng chức năng — từ "chưa có" thành "có"

`known_issues.md` §7 liệt kê những khẳng định C01 **chưa** chứng minh được. Sau khi vá:

| Khẳng định | Trước khi vá | Sau khi vá |
|---|---|---|
| RTL khớp mô hình chuẩn | ❌ Chưa chạy được lần nào | ✅ **Đã kiểm** — testbench chạy hết, mọi `assert` so `below/in_window/above/config_error` với mô hình chuẩn đều qua |
| Ba cờ loại trừ nhau (INV-1, INV-2) | 🟡 Chưa kiểm trên RTL | ✅ **Đã kiểm trên RTL** — ba assertion chống chồng lấn đều qua ở mọi vector |
| Đúng **một** cờ tích cực khi không có lỗi cấu hình | 🟡 Chưa kiểm trên RTL | ✅ **Đã kiểm** — `(below + in_window + above) == 1` |
| `config_error` chặn đúng ba cờ | 🟡 Chưa kiểm trên RTL | ✅ **Đã kiểm** — `{below,in_window,above} === 3'b000` khi `config_error` |
| Ca biên `sample = min`, `sample = max` | 🟡 Chưa kiểm trên RTL | ✅ **Đã kiểm** — 10 ca biên tường minh + quét rộng (`lo` bước 17 × `hi` bước 19 × 256 giá trị `sample`) |
| Kết luận `inside` không cần chặn (`datapath.md` §5) | 🟡 Chưa có xác nhận thực nghiệm | ✅ **Đã có xác nhận thực nghiệm** |

> **Câu giờ đã được phép nói khi bảo vệ:** *"C01 đã được kiểm chứng chức năng ở mức RTL, đối
> chiếu với mô hình chuẩn độc lập, và toàn bộ số liệu vật lý giữ nguyên sau bản vá."*

Lệnh đã chạy để xác minh (chép đúng lệnh):

```bash
D=.../out/C01_Bo_giam_sat_cua_so_gia_tri_hop_le_8bit
T=$(mktemp -d)
LIB=.../sky130hd.lib

# (a) mô hình chuẩn Python
python3 $D/05_VERIFICATION/golden_model/reference_model.py

# (b) biên dịch + mô phỏng
iverilog -g2012 -o $T/sim.vvp \
   $D/04_IMPLEMENTATION/rtl/*.sv \
   $D/05_VERIFICATION/golden_model/*.sv \
   $D/05_VERIFICATION/testbench/*.sv
cd $T && vvp sim.vvp | tail -20

# (c) tổng hợp
yosys -Q -p "read_verilog -sv $D/04_IMPLEMENTATION/rtl/*.sv; \
   hierarchy -check -top c01_window_monitor; proc; opt; fsm; opt; memory; opt; techmap; opt; \
   dfflibmap -liberty $LIB; abc -liberty $LIB; setundef -zero; splitnets; opt_clean -purge; \
   stat -liberty $LIB"
```

Phiên bản công cụ: Icarus Verilog (`-g2012`), Yosys 0.33 (git sha1 2584903a060), Python 3.

## 4. Cách quay lui

```bash
cp 08_ORIGINAL_SOURCE/rtl/*            04_IMPLEMENTATION/rtl/
cp 08_ORIGINAL_SOURCE/golden_model/*   05_VERIFICATION/golden_model/
cp 08_ORIGINAL_SOURCE/testbench/*      05_VERIFICATION/testbench/
```

Bản gốc trong `08_ORIGINAL_SOURCE/` **không bị đụng tới** — đúng như §0 của SPEC yêu cầu.
Lưu ý: quay lui sẽ đưa C01 về trạng thái **COMPILE_FAIL**.

## 5. Việc còn lại

| # | Việc | Trạng thái |
|---|---|---|
| 1 | ★ **Cập nhật mọi tài liệu tầng 02 theo tên cổng mới `in_window`** — `interface.md`, `functional_spec.md`, `parameters.md`, sơ đồ trong `03_ARCHITECTURE/` | Sẽ được **sinh lại tự động** (nằm ngoài ranh giới file được sửa của SPEC §0). **Đây là việc quan trọng nhất còn lại**, vì P-1 là bản vá **có đổi giao diện** |
| 2 | `06_GDSII/synthesis/netlist.v` — netlist hiện tại vẫn mang cổng `\inside ` (định danh thoát) | Phải **sinh lại**; tên cổng mới sẽ là `in_window` thuần, không còn cần thoát. Số cell/diện tích đã xác minh là **không đổi** (§3) |
| 3 | `06_GDSII/sta/` — SDC và báo cáo timing tham chiếu tên cổng cũ | Phải **sinh lại**. Đường tới hạn dự kiến vẫn là `sample_in[0] → above`, 2,70 ns — không đi qua cổng bị đổi tên; nhưng đây là **suy đoán**, chờ OpenSTA chạy lại để có số thật |
| 4 | `verification_report.md` §2–§4, `test_matrix.csv` (TC-001, TC-002, L2-SIM), `07_TRACEABILITY/limitations.md` | Sẽ được **sinh lại tự động**. Liên kết tới `simulation.log` trong `verification_report.md` §3 trước đây **hỏng**; giờ mô phỏng chạy được nên file đó sẽ tồn tại |
| 5 | Đề nghị thêm bước **lint** (`verilator --lint-only` / Verible) trước khi mô phỏng (`known_issues.md` §6) | **Chưa áp dụng** — `04_IMPLEMENTATION/scripts/` nằm ngoài ranh giới file được sửa của SPEC §0. Vẫn là đề xuất tốt: lint bắt được lớp lỗi "tên trùng từ khoá" này **và** lớp lỗi latch của đề B09 ở bước rẻ nhất |
| 6 | Bài học dạy học ở `known_issues.md` §4 và §6 | **Giữ nguyên giá trị** — và nay có thêm số đo đối chứng: cùng một RTL, Yosys chấp nhận cả trước lẫn sau, Icarus chỉ chấp nhận sau. *"Tổng hợp được" không đồng nghĩa với "đúng chuẩn ngôn ngữ"* |

Không có lỗi nào bị kết luận là "không thể vá". Cả hai bản vá đã áp dụng trọn vẹn: biên dịch
và mô phỏng chuyển từ **COMPILE_FAIL** sang **PASS**, tổng hợp vẫn **PASS** với số liệu
trùng khít.

## 6. Áp dụng lại (2026-09-24)

**Vì sao phải làm lại:** một bước sinh tài liệu tự động (`generate2.py`) có lỗi đã **chép mã
nguồn gốc từ `runs/<mã>/work/` đè lên** `04_IMPLEMENTATION/rtl/`,
`05_VERIFICATION/golden_model/` và `05_VERIFICATION/testbench/`, xoá sạch mọi bản vá mô tả ở
§2. Lỗi của bộ sinh đã được sửa. Toàn bộ bản vá được **áp dụng lại nguyên văn** theo §2 —
không chẩn đoán lại, không thay đổi nội dung bản vá.

**Đã áp dụng lại:** **2 bản vá** — P-1 (`04_IMPLEMENTATION/rtl/c01_window_monitor.sv`, đổi tên cổng ra `inside` → `in_window` ở 3 chỗ) và P-2 (`05_VERIFICATION/testbench/c01_tb.sv`, đổi tên đồng bộ ở 9 chỗ: 6 chỗ mã + 3 chuỗi thông báo `$fatal`, đúng như chênh lệch có chủ ý đã ghi ở §2). Mô hình chuẩn không bị sửa; `inside_ref` và instance `ref_i` giữ nguyên.

**Chênh lệch so với lần vá đầu:** không có. Nội dung ba thư mục mã nguồn sau khi áp dụng lại
giống hệt trạng thái đã mô tả ở §2. `08_ORIGINAL_SOURCE/rtl|golden_model|testbench/` không bị
đụng tới.

### 6.1 Kết quả xác minh lần này (đo lại bằng công cụ thật)

| Bước | Kết quả đo lại | Con số ghi ở §3 | Khớp? |
|---|---|---|---|
| Mô hình chuẩn Python | `C01 independent Python reference: PASS`, mã thoát 0 | PASS, mã thoát 0 | ✅ |
| Biên dịch | Mã thoát 0, log **rỗng hoàn toàn** — không lỗi, không cảnh báo, không `sorry:` | Mã thoát 0, log rỗng | ✅ |
| Mô phỏng | `C01 functional verification PASS`, `$finish` tại `Time: 29450`; 0 dòng ERROR/FATAL/mismatch | PASS tại `Time: 29450` | ✅ |
| Tổng hợp — số cell | **52** | 52 | ✅ |
| Tổng hợp — số FF | **0** | 0 | ✅ |
| Tổng hợp — diện tích | **362,848000 µm²** | 362,8480 µm² | ✅ |

Bảng cell đo lại, trùng khớp từng dòng với §3.1:

```
=== c01_window_monitor ===
   Number of cells:                 52
     sky130_fd_sc_hd__a2111oi_0      1
     sky130_fd_sc_hd__a21oi_1        2
     sky130_fd_sc_hd__a31oi_1        1
     sky130_fd_sc_hd__clkinv_1      10
     sky130_fd_sc_hd__lpflow_isobufsrc_1      4
     sky130_fd_sc_hd__maj3_1        14
     sky130_fd_sc_hd__nand2_1        1
     sky130_fd_sc_hd__nand2b_1       2
     sky130_fd_sc_hd__nand3_1        1
     sky130_fd_sc_hd__nand3b_1       2
     sky130_fd_sc_hd__nor2_1         2
     sky130_fd_sc_hd__nor3b_1        1
     sky130_fd_sc_hd__o21ai_0        3
     sky130_fd_sc_hd__o21bai_1       1
     sky130_fd_sc_hd__xnor2_1        5
     sky130_fd_sc_hd__xor2_1         2

   Chip area for module '\c01_window_monitor': 362.848000
```

Vì số liệu tổng hợp của C01 **không đổi** giữa bản vá và bản chưa vá (P-1 là phép đổi tên
thuần tuý), bằng chứng cho thấy bản vá đã thật sự được khôi phục là **biên dịch PASS**: bản
chưa vá luôn COMPILE_FAIL với mã thoát 23. Lần này Icarus trả mã thoát 0 và log rỗng.

Lệnh xác minh: đúng khối lệnh đã chép ở §3 (Icarus Verilog `-g2012`, Yosys 0.33
git sha1 2584903a060, thư viện `sky130hd.lib`, Python 3).

**Kết luận:** mọi số liệu trùng khít tới từng chữ số với §3 ⟹ bản vá đã được khôi phục **đầy
đủ và đúng**.
