Matrix Rain

A "digital rain" terminal animation, Matrix-movie style — falling green katakana, digits, and symbols with a bright leading edge and a fading tail. Pure Ruby standard library, zero gems.

Requirements
Ruby 3.0+ (uses io/console, which ships with Ruby)
A terminal that supports ANSI color and UTF-8
Run
bash
ruby matrix_rain.rb

Stop it with Ctrl+C — it restores your cursor and clears the screen on exit.

Options
--speed SECONDS   Delay between frames (default 0.05, lower = faster)
--density FLOAT   Spawn probability per column per frame (default 0.04)
--trail LENGTH    Length of each drop's fading tail (default 14)

Examples:

bash
# Slower, sparser rain
ruby matrix_rain.rb --speed 0.08 --density 0.02

# Dense, fast, long trails
ruby matrix_rain.rb --speed 0.02 --density 0.08 --trail 25
How it works

Each terminal column can spawn a Drop, which falls one row per frame carrying a short buffer of random characters. The head renders bright white; the rest fade through shades of green based on distance from the head. Characters occasionally mutate mid-fall for a flickering, glitchy look. Everything is drawn with raw ANSI escape codes — no curses library needed.

Ideas to extend it
Add a --color flag to swap the palette (blue "Tron" mode, amber "old terminal" mode)
Make drops occasionally pause mid-fall for a stuttering effect
Render actual words falling instead of random characters
Add a --message "TEXT" flag that occasionally reveals a hidden phrase in the rain
