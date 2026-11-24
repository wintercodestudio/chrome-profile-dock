-- Chrome Profile Dock helper. Receives chromeprofile://<key> URLs from the Dock launchers.
-- It only forwards to the switch logic, so it never changes and keeps its permissions.
on open location u
	set f to (POSIX path of (path to application support folder from user domain)) & "ChromeProfileDock/switch.scpt"
	run script (POSIX file f) with parameters {u}
end open location
