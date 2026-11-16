# Changelog

## 1.1.0 — 2026-11-16

- Tạo định danh cá nhân `hungthinh.hungthinhpack` và nhắm tới VS Code 1.146.0 trở lên.
- Đồng bộ catalog lõi lên 32.108 khóa hiện có; bổ sung bản dịch còn thiếu và kiểm tra placeholder.
- Đồng bộ các chuỗi package của extension tích hợp, gồm Copilot Chat và ba extension VS Code mới.
- Làm rõ trong README rằng các khóa mới được dịch tự động và cần hiệu đính khi chạy thử.


## 1.0.9

- Giữ bản sửa lỗi menu `View` thành `Xem`, tránh lỗi `Hiển &amp; thị`.
- Làm rõ phần `Cursor Settings` là UI riêng của Cursor, không luôn đi qua cơ chế Language Pack.
- Tách hướng vá UI riêng của Cursor thành gói phụ trợ riêng, tránh làm gói Marketplace bị hiểu sai phạm vi.
- Cập nhật README để người dùng VS Code và Cursor hiểu đúng cách cài đặt.

## 1.0.8

- Sửa cứng nhãn menu chính `View` thành `Xem` ở cả hai lớp menu của VS Code/Cursor.
- Bỏ ký hiệu phím tắt dạng `&&` khỏi các menu chính để tránh Cursor hiển thị lỗi HTML như `&amp;`.
- Giữ bản 1.0.8 là bản nên dùng khi cài thủ công vào Cursor bằng VSIX.

## 1.0.7

- Sửa thuật ngữ menu chính: View thành Xem, Run thành Chạy, Terminal thành Dòng lệnh.
- Sửa lỗi hiển thị menu có nguy cơ hiện `Hiển &amp; thị` trên giao diện.
- Dọn phần đầu README cho Marketplace, giảm phụ thuộc vào một phiên bản Cursor cụ thể.
- Chuyển các lệnh patch dành cho source xuống mục Dành cho nhà phát triển.

## 1.0.6

- Mở rộng dữ liệu dịch cho bản VSIX trước khi rà soát Marketplace.
- Kiểm tra lại cấu trúc `contributes.localizations` và các file dịch khai báo.

## 1.0.5

- Tăng mức Việt hóa Settings qua NLS runtime và extension `package.nls.json`.
- Thêm `vscode.ocaml` để bao phủ đầy đủ extension có `package.nls.json` trong Cursor 3.1.17.
- Thêm `npm run report:settings` và mở rộng audit để báo Settings NLS, extension settings thiếu dịch, và Cursor Settings hard-code ngoài phạm vi VSIX-only.
- Chuẩn hóa thêm thuật ngữ Settings, Agent, MCP, Layout, Notification, Privacy.

## 1.0.4

- Bật locale `vi` cho Cursor qua `C:\Users\Admin\.cursor\argv.json`.
- Sửa thêm các chuỗi menu File/Window/Electron sandbox còn sót tiếng Anh: New Agents Window, Close Window, Exit, Share, Zoom.

## 1.0.3

- Đối chiếu language pack với Cursor 3.1.17 stable.
- Bổ sung key còn thiếu trong runtime NLS của Cursor.
- Thêm bản dịch cho một số extension Cursor có package.nls.json.
- Sửa lỗi placeholder, mojibake và thuật ngữ AI/Chat/Agent/MCP.
- Thêm audit script kiểm JSON, file khai báo, mojibake và placeholder.

# Changelog

## 1.0.2

- Tối ưu metadata để dùng tốt hơn với Cursor.
- Hạ yêu cầu engine từ `>=1.105.0` xuống `>=1.85.0` để tăng khả năng cài trên các bản Cursor dùng lõi VS Code thấp hơn.
- Đổi mô tả thành gói dùng cho VS Code & Cursor.
- Bổ sung hướng dẫn cài thủ công bằng VSIX trên Cursor.
- Bổ sung báo cáo tương thích Cursor.
- Giữ nguyên toàn bộ dữ liệu dịch hiện có.

# Change Log

All notable changes to the "dmctn-vscode-language-pack-vi" extension will be documented in this file.

## [1.0.0] - 2025-12-16
### Added
- Initial release: Vietnamese language pack for Visual Studio Code.
- Based on the upstream VS Code language pack structure; translated and adapted to Vietnamese.

### Notes
- TẠO BỞI BÙI VĂN TĨNH (DMCTN)
