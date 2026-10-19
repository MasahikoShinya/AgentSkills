# Sound

Report `[AgentSkills][PROMPT][START] ::sound` after reading this file.

`::sound` manages the user's global Codex notification sound on macOS or Windows. When this pseudo-command is invoked, operate only on the user's global Codex notification files; never modify the repository, Git state, branches, commits, or pull requests.

Accepted forms:

    ::sound
    ::sound --list
    ::sound --play <name>
    ::sound <name>
    ::sound --set <name>

Detect the host operating system before acting. On macOS, use the .aiff files in /System/Library/Sounds and /usr/bin/afplay. On Windows, use the .wav files in C:\Windows\Media and System.Media.SoundPlayer. On other systems, report that this command has no sound backend and make no changes. Do not use a Windows executable or path on macOS.

The recommended macOS default is Funk.aiff played twice (about four seconds total). When the user asks to enable sound without naming one, select Funk.aiff with two plays. An unqualified ::sound invocation still previews all sounds and changes no configuration.

- ::sound displays each available filename and plays the sounds in filename order, waiting for each to finish. It changes no configuration. Tell the user that Ctrl+C stops playback.
- ::sound --list displays the available filenames without playback or configuration changes.
- ::sound --play <name> displays the matched filename and plays only that sound once, waiting for it to finish. It changes no configuration. Match and validate the name by the same rules as selection below.
- ::sound <name> selects the matching system sound. Accept a basename with or without the platform's extension, case-insensitively. ::sound --set <name> remains accepted for backward compatibility. Reject path separators, .., empty names, unknown options, and extra arguments. Verify that the selected file exists directly in the platform's system sound directory before changing any configuration.

For selection, update only ~/.codex/notify-sound.sh and ~/.codex/config.toml, preserving all unrelated config settings. Use absolute paths in the generated script. The script must ignore or forward Codex's optional JSON payload safely, without evaluating it as shell code. Set the top-level notify array to invoke the script through bash with its absolute path. Set [tui] notifications = ["agent-turn-complete", "approval-requested"] and notification_condition = "always", adding or updating only these keys. The TUI notification method may be set to "bel" on macOS when the user wants terminal bell audio; terminal sound behavior depends on the terminal's own settings.

On macOS, the generated script plays the selected absolute .aiff file with /usr/bin/afplay. If a top-level notify command already exists and is not this sound script, preserve that command: embed its argument vector as a safely quoted Bash array named original_notify in notify-sound.sh and invoke it with the JSON payload before playing the sound. Keep this array empty if no prior command exists. Store the selected sound path in a variable named selected_sound and the number of plays in repeat_count. Use repeat_count=2 for the recommended Funk default and 1 for other selections unless the user requests a longer sound. Run afplay even if the original command fails; return a useful failure status if playback fails. Do not replace an existing notification integration silently. On later sound changes, retain original_notify and update only selected_sound and repeat_count instead of wrapping the sound script again. If the existing notify points to this script but the script cannot be read or its preserved command cannot be identified, stop and explain the problem rather than creating a recursive invocation.

On Windows, the generated script plays the selected absolute .wav file through powershell.exe using System.Media.SoundPlayer, waiting for playback to finish. Preserve an unrelated existing notify command using the same Bash-array forwarding rule. Never execute a macOS path on Windows.

The external notify command currently receives turn-completion events only. approval-requested is a TUI notification; other kinds of input waiting, including questions in the desktop app, depend on the app's own notification settings and cannot be guaranteed by this command. Explain this limit in the result. Report the selected filename and state that Codex must be restarted after a selection change. For list and playback operations, including --play, report that configuration was unchanged. Report PROMPT END with the operation result.
