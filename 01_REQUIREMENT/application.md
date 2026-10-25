# C01 · Bối cảnh ứng dụng

> 🔧 **ĐỀ NÀY ĐÃ ĐƯỢC VÁ LỖI**
>
> Mô phỏng ban đầu không đạt. Lỗi đã được chẩn đoán, vá và **xác minh lại bằng
> công cụ thật**. Mọi số liệu trong hồ sơ là số liệu **sau khi vá**.
>
> * Mã nguồn gốc: [`08_ORIGINAL_SOURCE/`](08_ORIGINAL_SOURCE/) — giữ nguyên, quay lui được
> * Nhật ký vá: [`08_ORIGINAL_SOURCE/PATCHLOG.md`](08_ORIGINAL_SOURCE/PATCHLOG.md)
> * Chẩn đoán đầy đủ: [`05_VERIFICATION/known_issues.md`](05_VERIFICATION/known_issues.md)



| | |
|---|---|
| Mã đề | **C01** |
| Tên đề | Bộ giám sát cửa sổ giá trị hợp lệ 8-bit |
| Nhóm đề | C · Ngưỡng, cảnh báo và giám sát |
| Độ khó | Trung bình (nhẹ) |
| Loại mạch | **Tổ hợp** |
| Quy mô ước lượng (Charter) | ~130–190 cell · 1×1 tile |
| Nguồn gốc | Project Charter — C01, mục 1 |

---

## 1. Mục tiêu và bối cảnh ứng dụng

Trích nguyên văn Charter mục 1:

> Phân tích khối số “Bộ giám sát cửa sổ giá trị hợp lệ 8-bit” ở mức khối. Bối cảnh ứng dụng: Khối kiểm tra mẫu ADC có nằm trong dải đo hợp lệ của cảm biến hay không, trước khi đưa vào tầng xử lý phía sau.

## 2. Vị trí khối C01 trong hệ thống

```
   ┌──────────────┐      ┌──────────────────────────────┐      ┌──────────────┐
   │  Nguồn tín   │─────▶│      ►►► KHỐI C01 ◄◄◄        │─────▶│  Tầng tiêu   │
   │  hiệu / dữ   │      │  Bộ giám sát cửa sổ giá trị h │      │  thụ kết quả │
   │  liệu vào    │      │  Loại mạch: Tổ hợp           │      │              │
   └──────────────┘      └──────────────────────────────┘      └──────────────┘
```

> Sơ đồ chi tiết có chú thích: `03_ARCHITECTURE/system_diagram.md`.

## 3. Phân loại analog / digital / mixed

| Khối | Phân loại | Ghi chú |
|---|---|---|
| Cảm biến / nguồn tín hiệu vật lý (nếu có) | Analog | Đại lượng liên tục |
| Chuyển đổi ADC/DAC (nếu có) | Mixed-signal | Ranh giới analog–số |
| **C01 — Bộ giám sát cửa sổ giá trị hợp lệ 8-bit** | **Digital, tổ hợp** | Đầu ra chỉ phụ thuộc đầu vào hiện tại; không clock, không ô nhớ |
| Tầng xử lý phía sau | Digital | Tiêu thụ kết quả của C01 |

Bằng chứng cho dòng phân loại của C01: tổng hợp thật cho **0 flip-flop**
(`06_GDSII/synthesis/synth_stat.txt`).

---

**Truy vết:** yêu cầu sinh từ tài liệu này được đánh số `REQ-C01-0xx` trong
`01_REQUIREMENT/requirements.md`, và truy vết đến bằng chứng trong `07_TRACEABILITY/RTM.csv`.

*Phiên bản: v1.0 · Ngày: 2026-09-24*
