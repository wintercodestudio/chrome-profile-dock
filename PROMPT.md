# Prompt: rebuild this with an AI coding agent

You can paste the prompt below into Claude Code, Codex or a similar agent on a Mac. It describes the goal and the traps, so the agent does not rediscover them the hard way. If you just want the tool, run `./install.sh` instead.

---

Make macOS Dock shortcuts, one per Google Chrome profile on this Mac.

**Goal**
- Read `~/Library/Application Support/Google/Chrome/Local State` (`profile.info_cache`) to list the profiles: each profile's folder (`Default`, `Profile 1`, …) and name. Show me the list and the app names (`Chrome - <name>.app`, email domain stripped) and wait for my OK.
- Clicking an icon must **bring that profile's existing window to the front**. Only when the profile has no window should it open the profile (`open -n -a "Google Chrome" --args --profile-directory=<folder>`), then raise the new window. That window may open behind others.
- Each icon: the Chrome icon with the profile's `Google Profile Picture.png` (or its initial) as a round badge in the bottom-right corner.
- Put the apps in `~/Applications`, then open that folder.

**Design that works**
- The Dock icons are AppleScript apps that only run `open chromeprofile://<key>`. They need no permissions.
- One helper app handles the `chromeprofile` URL scheme (`CFBundleURLTypes`, `LSUIElement`). It is the only app that gets Accessibility + Automation permission. Its `on open location` handler just runs an external compiled script in `~/Library/Application Support/...`, so the logic can change without re-signing the helper.
- To map a window to its profile: the system window title ends with `Google Chrome - <profile name>` or `(<profile name>)`. Chrome's AppleScript has no profile property. So briefly set each unnamed window's `given name` to a unique marker, read the titles with System Events, and map the marker to Chrome's window id. Clear the markers afterwards. Raise the window with Chrome's own `set index of window to 1` + `activate`.

**Pitfalls to avoid**
1. Script apps show the default script icon from `Assets.car`/`CFBundleIconName`. Delete both so `applet.icns` is used.
2. Re-signing an ad-hoc-signed app voids its Accessibility grant. Give every app a stable `CFBundleIdentifier` and never re-sign the helper once permission is granted.
3. A script run from Terminal uses the terminal's permissions. Test by clicking the Dock icon. System Events can click it: `click UI element "<name>" of list 1` of process "Dock".
4. `key` is reserved in AppleScript; errors inside `on open location` are silent. Log to a file.
5. `AXRaise` followed by app activation is unreliable: Chrome pulls its previous window back. Use Chrome's `set index`.
6. Rename the helper's executable from `applet` so the Privacy settings list shows a real name.
7. When Chrome is not running, opening a profile restores its session on its own. When Chrome is running, a profile opened again also restores its last tabs.
