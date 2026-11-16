# Báo cáo sửa lỗi 1.0.8

Đã sửa các key menu chính sau để tránh lỗi hiển thị `&amp;` trong Cursor:

- `vs/platform/menubar/electron-main/menubar` / `mFile`: `&&Tệp` → `Tệp`
- `vs/platform/menubar/electron-main/menubar` / `mEdit`: `&&Chỉnh sửa` → `Chỉnh sửa`
- `vs/platform/menubar/electron-main/menubar` / `mSelection`: `Lựa &&chọn` → `Lựa chọn`
- `vs/platform/menubar/electron-main/menubar` / `mView`: `&&Xem` → `Xem`
- `vs/platform/menubar/electron-main/menubar` / `mGoto`: `&&Đi tới` → `Đi tới`
- `vs/platform/menubar/electron-main/menubar` / `mRun`: `&&Chạy` → `Chạy`
- `vs/platform/menubar/electron-main/menubar` / `mTerminal`: `&&Dòng lệnh` → `Dòng lệnh`
- `vs/platform/menubar/electron-main/menubar` / `mHelp`: `&&Trợ giúp` → `Trợ giúp`
- `vs/workbench/browser/parts/titlebar/menubarControl` / `mFile`: `&&Tệp` → `Tệp`
- `vs/workbench/browser/parts/titlebar/menubarControl` / `mEdit`: `&&Chỉnh sửa` → `Chỉnh sửa`
- `vs/workbench/browser/parts/titlebar/menubarControl` / `mSelection`: `Lựa &&chọn` → `Lựa chọn`
- `vs/workbench/browser/parts/titlebar/menubarControl` / `mView`: `&&Xem` → `Xem`
- `vs/workbench/browser/parts/titlebar/menubarControl` / `mGoto`: `&&Đi tới` → `Đi tới`
- `vs/workbench/browser/parts/titlebar/menubarControl` / `mTerminal`: `&&Dòng lệnh` → `Dòng lệnh`
- `vs/workbench/browser/parts/titlebar/menubarControl` / `mHelp`: `&&Trợ giúp` → `Trợ giúp`
- `vs/workbench/browser/parts/titlebar/menubarControl` / `mPreferences`: `Cài đặt` → `Cài đặt`
- `vs/workbench/contrib/debug/browser/debug.contribution` / `mRun`: `&&Chạy` → `Chạy`

Nếu UI vẫn hiện `Hiển &amp; thị`, cần xoá cache ngôn ngữ của Cursor vì file VSIX hiện không còn chuỗi đó trong bản dịch chính.
