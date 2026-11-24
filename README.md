# Chrome Profile Dock

One Dock icon per Google Chrome profile, on macOS.

Click an icon and that profile's window comes to the front. If the profile has no window open, Chrome opens it and restores its tabs. Each icon is the Chrome logo with the profile's picture (or its initial) in the corner.

Without this, `open -a "Google Chrome" --args --profile-directory=...` opens a **new window** every time, even when the profile already has one.

[Tiếng Việt bên dưới](#tiếng-việt)

## Install

```bash
git clone https://github.com/<you>/chrome-profile-dock.git
cd chrome-profile-dock
./install.sh          # lists your profiles, asks, then builds the apps in ~/Applications
```

Then:

1. Drag the `Chrome - <profile>` apps from `~/Applications` to your Dock.
2. **System Settings → Privacy & Security → Accessibility**: press **+**, pick `Chrome Profile Dock` in `~/Applications`, and turn it on.
3. Click a Dock icon. When macOS asks whether `Chrome Profile Dock` may control **System Events** and **Google Chrome**, choose **Allow**.

You grant these permissions once. Re-running `./install.sh` (for example after adding a profile) keeps them.

Options: `--list` (show profiles only), `--yes` (no prompt), `--dest DIR`, `--rebuild-helper`.

Uninstall: `./uninstall.sh`, then remove the icons from the Dock.

**Needs:** macOS with Google Chrome in `/Applications`. Nothing else: no Xcode, Python or Homebrew. Tested on macOS 26.

## How it works

```
Dock icon "Chrome - Work"  --open chromeprofile://profile-1-->  Chrome Profile Dock (helper)
                                                                  |
                                    runs ~/Library/Application Support/ChromeProfileDock/switch.scpt
                                                                  |
                    finds the profile's window -> raises it   |   none -> opens the profile, then raises its window
```

- **Dock icons** are tiny AppleScript apps that only open a `chromeprofile://` URL. They need no permissions.
- **The helper** (`Chrome Profile Dock.app`, no Dock icon) handles those URLs. It is the only app that needs Accessibility and Automation permission. It never changes, so macOS keeps its permission.
- **The switch logic** lives outside the helper in `~/Library/Application Support/ChromeProfileDock/switch.applescript`. After editing it, run `osacompile -o switch.scpt switch.applescript` in that folder. You never have to re-sign the helper or grant permissions again.
- **Finding a profile's window:** Chrome's scripting does not say which profile a window belongs to, but the window title macOS sees ends with the profile name (`Inbox - Google Chrome - Work`). The logic briefly gives each unnamed window a name (`cpd-<id>`). The title then ties Chrome's window id to its profile. It raises the window with Chrome's own `set index`, then clears the names. Windows you named yourself keep their names.

## Limits

- The Dock icons show no "running" dot. Every profile's window belongs to the one Google Chrome process, so the dot stays under Chrome's own icon.
- A click takes about 0.7–1 s: macOS starts the icon's app, which starts the helper.
- A window on another Space or in full screen may not be found. The profile then opens a new window.
- Chrome only. Other Chromium browsers would need other paths and window titles.

## Troubleshooting

- **Nothing happens on click:** look at `~/Library/Logs/ChromeProfileDock.log`.
- **"… is not allowed assistive access" (-25211):** turn on `Chrome Profile Dock` under Accessibility. If you rebuilt the helper, remove its old entry with **−** and add it again.
- **The icon still shows a script scroll:** remove it from the Dock and drag it back. You can also run `killall Dock`.

## Lessons learned (macOS pitfalls)

These pitfalls cost hours. Avoid them if you build something similar:

1. **Script apps ignore `applet.icns`** when `Assets.car` and `CFBundleIconName` are present. Delete both.
2. **Permissions are tied to the code signature.** Re-signing an ad-hoc app silently voids its Accessibility grant. Hidden "denied" entries keyed by bundle id can also shadow the entries you add with **+**. That is why the permissions live on one helper app that never changes.
3. **Testing from Terminal lies:** a script started from a terminal runs with the terminal's permissions, not the app's.
4. **`key` is a reserved word in AppleScript.** `set key to …` fails inside an `open location` handler, and the error is silent.
5. **Raising through Accessibility (`AXRaise`) races with app activation.** Chrome then pulls its previous window back on top. Use Chrome's own `set index of window … to 1`.

## License

MIT

---

## Tiếng Việt

Mỗi profile Google Chrome có một icon riêng trên Dock của macOS.

- Bấm icon: cửa sổ của profile đó được đưa lên trước.
- Profile chưa mở: Chrome mở profile đó và khôi phục các tab cũ.

Icon là logo Chrome, có ảnh đại diện (hoặc chữ cái đầu) của profile ở góc.

**Cài đặt:**

```bash
git clone https://github.com/<you>/chrome-profile-dock.git
cd chrome-profile-dock
./install.sh
```

Sau đó:

1. Kéo các app `Chrome - <profile>` trong `~/Applications` xuống Dock.
2. Vào **Cài đặt hệ thống → Quyền riêng tư & Bảo mật → Trợ năng**. Bấm **+**, chọn `Chrome Profile Dock`, rồi bật công tắc.
3. Bấm một icon trên Dock. Khi macOS hỏi quyền điều khiển **System Events** và **Google Chrome**, chọn **Cho phép**.

Chỉ cấp quyền một lần. Chạy lại `./install.sh`, ví dụ khi thêm profile, vẫn giữ quyền.

Gỡ cài đặt: `./uninstall.sh`.

**Giới hạn:**
- Icon không có dấu chấm "đang chạy", vì mọi cửa sổ đều thuộc một tiến trình Chrome.
- Mỗi lần bấm mất khoảng 0,7–1 giây.
