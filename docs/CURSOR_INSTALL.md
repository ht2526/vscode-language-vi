# Cài gói tiếng Việt DMCTN vào Cursor

## Cách cài chắc nhất

1. Mở Cursor.
2. Nhấn `Ctrl + Shift + P`.
3. Gõ `Extensions: Install from VSIX...`.
4. Chọn file `.vsix`.
5. Đợi cài xong.
6. Nhấn `Ctrl + Shift + P`.
7. Gõ `Configure Display Language`.
8. Chọn `Tiếng Việt (DMCTN)` hoặc `vi`.
9. Restart Cursor.

## Nếu không thấy Tiếng Việt

Kiểm tra:

- Extension đã Enabled chưa.
- Có đang chọn đúng Display Language không.
- Cursor đã restart chưa.
- Nếu vẫn không đổi, thử tắt rồi mở lại Cursor hoàn toàn.

## Phần có thể chưa Việt hoá

Các màn hình riêng của Cursor như AI Chat, Agent, Plan Mode, Model Picker, Account, Billing và một phần `Cursor Settings` custom có thể vẫn còn tiếng Anh nếu chuỗi bị hard-code ngoài NLS.

## Nếu đã chọn `vi` nhưng menu vẫn tiếng Anh

Cursor 3.1.17 có thể không tự sinh cache NLS trong `%APPDATA%\Cursor\clp`, dù VSIX đã cài đúng.

Chạy trong thư mục dự án:

```powershell
npm run repair:cursor-cache
```

Sau đó thoát hẳn Cursor và mở lại. Không cần sửa file trong `E:\cursor\resources\app`.
