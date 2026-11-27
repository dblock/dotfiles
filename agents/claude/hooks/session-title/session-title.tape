# Records the session-title demo: types three prompts into the Claude Code agent view and shows the new
# sessions named "🏠 dotfiles", "📧 gmail-toggle", and "🧪 testlanes". Render from this directory with
# "vhs session-title.tape". Trust the dotfiles folder in Claude Code first, since the trust prompt would
# otherwise appear. Plan mode keeps the demo sessions from changing files; stop and remove them afterwards
# with "claude stop <id>" and "claude rm <id>".
Output session-title.mp4
Output session-title.gif
Set Shell "bash"
Set FontSize 18
Set Width 1400
Set Height 700
Set Padding 24
Set Framerate 24
Set TypingSpeed 55ms
Hide
Type "cd ~/source/dotfiles && clear && claude agents --cwd ~/source/dotfiles --permission-mode plan"
Enter
Sleep 5s
Show
Sleep 1.5s
Type "let's add some emojis to our dotfiles"
Sleep 0.5s
Enter
Sleep 3s
Type "fix the label sync in gmail-toggle"
Sleep 0.5s
Enter
Sleep 3s
Type "speed up the testlanes CI"
Sleep 0.5s
Enter
Sleep 2.8s
Hide
Ctrl+C
Ctrl+C
Sleep 1s
