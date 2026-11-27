# Record real Copilot CLI sessions named by the session-title hook and rename_session.
# Render here with "./record.sh" to isolate demo sessions from real sessions.
# The recorder links the real hooks and instructions and removes its temporary state.
# Plan mode and a demo-only instruction prevent implementation.
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
Type "cd ~/source/dotfiles && clear && copilot --plan --sync-session=off --disable-mcp-server github-mcp-server --secret-env-vars GH_TOKEN"
Enter
Sleep 7s
Enter
Sleep 5s
Left
Right
Show
Sleep 1.5s
Type "let's add some emojis to our dotfiles"
Sleep 0.5s
Enter
Wait+Screen@90s /🏠 dotfiles/
Wait+Screen@90s /Ready\./
Sleep 2s
Type "/new"
Enter
Sleep 2s
Type "fix the label sync in gmail-toggle"
Sleep 0.5s
Enter
Wait+Screen@90s /📧 gmail-toggle/
Wait+Screen@90s /Ready\./
Sleep 2s
Type "/new"
Enter
Sleep 2s
Type "speed up the testlanes CI"
Sleep 0.5s
Enter
Wait+Screen@90s /🧪 testlanes/
Wait+Screen@90s /Ready\./
Sleep 2s
Left
Sleep 3s
Screenshot session-title.png
Hide
Type "/exit print"
Enter
Sleep 2s
