# C01 · Ca biên và lý do chọn (Corner Cases)

Mỗi ca phải trả lời được: *"ca này bắt được lỗi nào mà ca khác không bắt được?"*

Nguồn đối chiếu: `05_VERIFICATION/testbench/c01_tb.sv` (đọc từng dòng) và
`05_VERIFICATION/golden_model/reference_model.py`.

> ⚠️ **Lưu ý đọc tài liệu này:** testbench đã được viết đầy đủ nhưng **chưa chạy được lần
> nào** — biên dịch thất bại. Cột "Có trong testbench?" nghĩa là *"đã được viết"*, **không**
> phải *"đã được chứng minh"*. Xem `05_VERIFICATION/known_issues.md`.

---

## 1. Ca bắt buộc của Charter mục 8 — và lý do kỹ thuật

| # | Ca Charter | Kích thích trong TB | Bắt lỗi gì | Dòng TB |
|---|---|---|---|---|
| 1 | Mẫu **dưới** min | `check(49, 50, 100)` | Nhánh `below` sai | 59 |
| 2 | Mẫu **bằng** min | `check(50, 50, 100)` | **Ca then chốt.** Dùng `<` hay `<=`? Sai một dấu là `sample=min` bị xếp nhầm vào `below` | 60 |
| 3 | **Giữa** cửa sổ | `check(75, 50, 100)` | Nhánh `inside` sai | 61 |
| 4 | Mẫu **bằng** max | `check(100, 50, 100)` | Ca then chốt đối xứng với #2: `>` hay `>=` | 62 |
| 5 | Mẫu **trên** max | `check(101, 50, 100)` | Nhánh `above` sai | 63 |
| 6 | **Cấu hình `min>max`** | `check(75, 100, 50)` | Quên hẳn `config_error`, hoặc quên chặn ba cờ | 64 |

> Charter mục 10 ghi: *"Chỗ hay tắc: Quên ca 'mẫu bằng đúng ngưỡng' — biên là chỗ lỗi hay
> nằm nhất."* Ca #2 và #4 chính là hai ca đó, và chúng là hai ca **duy nhất** phân biệt được
> `<` với `<=`. Bỏ chúng thì một RTL dùng sai dấu so sánh vẫn qua được mọi ca còn lại.

### Vì sao cần **cả hai** ca biên, không phải một

Một hiện thực sai có thể sai **không đối xứng**:

```
   RTL sai kiểu A:  below = (s <= min)   → hỏng ca #2, ĐÚNG ca #4
   RTL sai kiểu B:  above = (s >= max)   → ĐÚNG ca #2, hỏng ca #4
```

Chỉ kiểm một biên thì một trong hai kiểu sai lọt lưới hoàn toàn.

## 2. Ca tự xây dựng bổ sung (Charter mục 8 yêu cầu ≥ 2, có ca biên)

| # | Ca | Kích thích | Vì sao cần | Dòng TB |
|---|---|---|---|---|
| 7 | **Cửa sổ rộng đúng 1, ở đáy miền** | `check(0, 0, 0)` | `min=max` hợp lệ (không phải config_error); và `below` **không thể** bật vì không có `sample < 0` | 67 |
| 8 | **Cửa sổ rộng đúng 1, ở đỉnh miền** | `check(255, 255, 255)` | Đối xứng với #7: `above` không thể bật. Bắt lỗi tràn số khi tính `max+1` | 68 |
| 9 | **Cửa sổ phủ toàn miền, mẫu ở đáy** | `check(0, 0, 255)` | `inside` phải bật ở giá trị nhỏ nhất có thể | 69 |
| 10 | **Cửa sổ phủ toàn miền, mẫu ở đỉnh** | `check(255, 0, 255)` | `inside` phải bật ở giá trị lớn nhất có thể; bắt lỗi so sánh có dấu (với `signed`, `255` là `-1` ⟹ sẽ ra `below`) | 70 |
| 11 | **Quét vét cạn `sample` với nhiều cửa sổ đại diện** | ba vòng lồng: `lo` bước 17, `hi` bước 19, `s` toàn bộ 0…255 | Phủ toàn bộ dải mẫu cho mỗi cửa sổ; kiểm INV-9 (đơn điệu) một cách gián tiếp | 73–76 |

### Tính quy mô ca #11

Vòng `lo` chạy `0,17,34,…,255` → **16** giá trị. Với mỗi `lo`, vòng `hi` chạy từ `lo` bước 19.
Với mỗi cặp `(lo,hi)`, quét đủ **256** giá trị `sample`. Đây là mẫu quét thưa theo ngưỡng,
dày theo mẫu — đúng chiến lược: ngưỡng là tham số cấu hình (thay đổi hiếm), mẫu là dữ liệu
chảy qua liên tục (phải phủ kín).

> 🔎 **Điểm kỹ thuật của bước nhảy 17 và 19:** cả hai đều **nguyên tố cùng nhau với 256**
> (`gcd(17,256)=1`, `gcd(19,256)=1`). Nhờ đó chuỗi giá trị không bị "đồng bộ" với biên lũy
> thừa của 2, tránh trường hợp mọi ngưỡng thử đều có cùng dạng bit thấp. Một bước nhảy 16
> hay 32 sẽ tạo ra tập ngưỡng có 4–5 bit thấp luôn bằng 0 — lúc đó lỗi ở chuỗi mượn bit thấp
> sẽ không bao giờ bị kích hoạt.

## 3. Lỗ hổng phủ đã phát hiện khi đọc testbench

Testbench tốt, nhưng có ba lỗ hổng thật, cần ghi nhận:

| # | Lỗ hổng | Hậu quả | Đề nghị bổ sung |
|---|---|---|---|
| L-1 | **Vòng quét `hi` bắt đầu từ `lo`** (`for (int hi=lo; …)`, dòng 74) ⟹ phần quét vét cạn **không bao giờ** sinh cấu hình `min>max` | Ca `config_error` chỉ được kiểm bởi **một** vector duy nhất (`check(75,100,50)`, dòng 64) | Thêm một vòng quét `hi < lo` đối xứng, như mô hình chuẩn Python đã làm (`reference_model.py` dòng 38–41) |
| L-2 | Không có ca `min = max + 1` (config_error **sát biên**) | Không kiểm được ranh giới giữa "cửa sổ rộng 1" và "cấu hình sai" | `check(s, 100, 99)` — chỉ lệch 1 so với ca hợp lệ `check(s,100,100)` |
| L-3 | Không có ca `sample = min - 1` và `sample = max + 1` ở **cửa sổ rộng 1** | Cửa sổ hẹp nhất là chỗ ba vùng chạm nhau trong khoảng 3 giá trị liên tiếp | `check(99,100,100)`, `check(100,100,100)`, `check(101,100,100)` |

> Mô hình chuẩn Python **có** quét cấu hình sai (dòng 38–41: `lo` bước 13, `hi < lo` bước 11),
> nhưng testbench SystemVerilog thì **không**. Đây là chênh lệch phủ giữa hai lớp kiểm chứng
> — chính vì vậy chạy cả hai lớp mới có ý nghĩa.

## 4. Phân loại ca theo tiêu chí kỹ thuật riêng của C01

Tiêu chí tự nhiên của đề này là **quan hệ ba ngôi giữa `sample`, `min`, `max`**. Có đúng 13
lớp quan hệ có thể xảy ra:

| Lớp | Quan hệ | Kết quả mong đợi | Có trong TB? |
|---|---|---|:-:|
| 1 | `min < max`, `s < min` | `below` | ✅ |
| 2 | `min < max`, `s = min` | `inside` | ✅ |
| 3 | `min < max`, `min < s < max` | `inside` | ✅ |
| 4 | `min < max`, `s = max` | `inside` | ✅ |
| 5 | `min < max`, `s > max` | `above` | ✅ |
| 6 | `min = max`, `s < min` | `below` | 🟡 chỉ gián tiếp qua ca #8 |
| 7 | `min = max`, `s = min` | `inside` | ✅ (ca #7, #8) |
| 8 | `min = max`, `s > max` | `above` | 🟡 chỉ gián tiếp qua ca #7 |
| 9 | `min > max` | `config_error` | ✅ **chỉ một vector** |
| 10 | `min = 0` (không có `below` nào) | — | ✅ ca #7, #9 |
| 11 | `max = 255` (không có `above` nào) | — | ✅ ca #9, #10 |
| 12 | `min = 0, max = 255` (mọi mẫu `inside`) | — | ✅ ca #9, #10 |
| 13 | `min = max + 1` (config_error sát biên) | `config_error` | ❌ **thiếu — L-2** |

## 5. Ca **KHÔNG** áp dụng cho đề này — và vì sao

| Ca | Vì sao không áp dụng |
|---|---|
| Ca reset, giá trị sau reset | Mạch tổ hợp; giao diện không có `rst` |
| Ca theo chu kỳ clock, độ trễ N chu kỳ | Không có clock |
| Ca setup/hold, metastability | Không có phần tử tuần tự (0 FF trong `synth_stat.txt`) |
| **Ca vùng trễ (hysteresis):** mẫu dao động quanh ngưỡng làm cờ nhấp nháy | Charter mục 3 ghi rõ vùng trễ là **đề C04**, nằm **ngoài phạm vi** C01. C01 *cố ý* không có trạng thái, nên nó *phải* nhấp nháy khi mẫu dao động quanh biên — đó là hành vi đúng của C01 |
| Ca lọc nhiễu, trung bình trượt | Ngoài phạm vi (Charter mục 3) |
| Ca ngưỡng thay đổi theo thời gian | Ngoài phạm vi (Charter mục 3). C01 coi ngưỡng là hằng trong một lần đánh giá |
| Ca `sample` ngoài dải 0…255 | Không tồn tại: cổng rộng đúng 8 bit |
| Ca so sánh số có dấu | Đặc tả chốt **không dấu**; cổng khai báo `logic [7:0]` không `signed` |

> Mục này có giá trị dạy học riêng: **ranh giới giữa C01 và C04**. Sinh viên hay "cải tiến"
> C01 bằng cách thêm hysteresis cho cờ đỡ nhấp nháy. Làm vậy là **đổi đề**, và làm hỏng
> tính chất tổ hợp thuần (hysteresis cần nhớ trạng thái trước).

## 6. Ca cần bổ sung khi chuyển sang gate-level / post-layout

| Ca cần thêm | Bắt lỗi gì | Điều kiện để chạy |
|---|---|---|
| Mô phỏng gate-level trên `netlist.v`, chạy lại toàn bộ ca §1–§2 | Tổng hợp làm lệch chức năng; đặc biệt cần kiểm lại **kết luận của công cụ về `inside`** (xem §7) | Thư viện mô phỏng `sky130_fd_sc_hd` |
| `sample` đổi từ `min-1` sang `max+1` trong một bước | **Glitch**: chuỗi mượn 7 tầng ổn định dần ⟹ `inside` có thể nháy 1 trong lúc chuyển | Mô phỏng có SDF |
| `min_val` đổi làm `config_error` chuyển 0→1 | Glitch trên `below`/`above`: chúng bị chặn bởi `config_error` ở cell cuối, nên có cửa sổ thời gian mà `above=1` **và** `config_error=1` cùng lúc — **vi phạm INV-3 tức thời** | Mô phỏng có SDF |
| Đo `inside`, `above`, `below` ổn định sau 2,70 ns | Tầng ngoài lấy mẫu quá sớm | Đã có STA: `timing_report_max.txt` |
| Kiểm ở góc `ss` (chậm) và `ff` (nhanh) | Biên an toàn; ca `ff` bắt lỗi hold | Liberty các góc khác — **chưa có** |

> 🔎 **Ca glitch của `config_error` rất đáng dạy.** Trong netlist, `below` và `above` được
> chặn ở cell **cuối cùng** (`_99_` và `_98_`, chân `SLEEP` = `config_error`). Nghĩa là
> `above` được tính **trước**, rồi mới bị chặn. Ở mức tín hiệu thật có độ trễ, khi cấu hình
> chuyển sang sai, tồn tại một khoảng thời gian mà `above` chưa kịp về 0 trong khi
> `config_error` đã lên 1. INV-3 là bất biến **ở trạng thái ổn định**, không phải bất biến
> tức thời. Đây là phân biệt mà mô phỏng zero-delay **không bao giờ** dạy được.

## 7. Ca liên quan tới một kết luận bất ngờ của công cụ tổng hợp

Khi đọc `06_GDSII/synthesis/netlist.v`, có một điều đáng kiểm bằng ca riêng:

```verilog
sky130_fd_sc_hd__nor2_1 _89_ ( .A(_17_), .B(_40_), .Y(\inside ) );
```

`inside` được tính bằng `NOR(above_raw, below_raw)` — **không** có `config_error` trong biểu
thức, trong khi RTL viết rõ `if (!config_error)`. Công cụ đã chứng minh rằng phép chặn đó
**thừa** (chứng minh: `03_ARCHITECTURE/datapath.md` §5).

| Ca cần thêm để kiểm kết luận này | Kích thích |
|---|---|
| Mọi `sample` với cấu hình sai sát biên | `min = k+1, max = k` với `k = 0, 1, 127, 128, 254`, quét đủ 256 giá trị `sample`, kiểm `inside === 0` |
| Cấu hình sai cực đoan | `min=255, max=0`, quét đủ 256 `sample` |

Nếu công cụ sai, `inside` sẽ bật ở đâu đó trong các ca này. Nếu không ca nào bật, đó là
bằng chứng thực nghiệm ủng hộ chứng minh hình thức. **Chưa chạy được ca nào** vì mô phỏng
chưa biên dịch.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
