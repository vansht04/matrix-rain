#!/usr/bin/env ruby
# frozen_string_literal: true

# matrix_rain.rb
#
# A "digital rain" terminal animation, Matrix-movie style.
# Pure Ruby standard library — no gems required.
#
# Run:
#   ruby matrix_rain.rb
#   ruby matrix_rain.rb --speed 0.03 --density 0.06
#
# Stop with Ctrl+C.

require 'io/console'
require 'optparse'

# --- Options -----------------------------------------------------------

options = {
  speed: 0.05,      # seconds between frames (lower = faster)
  density: 0.04,     # chance per column per frame that a new drop spawns
  trail_length: 14   # how many characters long each drop's fading tail is
}

OptionParser.new do |opts|
  opts.banner = 'Usage: ruby matrix_rain.rb [options]'
  opts.on('--speed SECONDS', Float, 'Delay between frames (default 0.05)') { |v| options[:speed] = v }
  opts.on('--density FLOAT', Float, 'Spawn probability per column per frame (default 0.04)') { |v| options[:density] = v }
  opts.on('--trail LENGTH', Integer, 'Length of each drop\'s fading tail (default 14)') { |v| options[:trail_length] = v }
  opts.on('-h', '--help', 'Show this help') do
    puts opts
    exit
  end
end.parse!

# --- Character set ------------------------------------------------------
# Mix of katakana, digits, and symbols — the classic Matrix look.
CHARSET = (0x30A0..0x30FF).map { |c| [c].pack('U') } + # katakana
          ('0'..'9').to_a +
          %w[* + - < > / \\ | : . = ! ? # % & @]

# A single falling "drop" in one column.
class Drop
  attr_accessor :row

  def initialize(col, height, trail_length)
    @col = col
    @row = 0
    @height = height
    @trail_length = trail_length
    @chars = Array.new(trail_length) { CHARSET.sample }
  end

  def col = @col

  def advance
    @row += 1
    # occasionally mutate a character in the trail for a flicker effect
    @chars[rand(@chars.length)] = CHARSET.sample if rand < 0.3
  end

  def dead?
    @row - @trail_length > @height
  end

  # Yields [row, char, brightness] for each visible cell of this drop,
  # brightness 0.0 (dim tail) .. 1.0 (bright head)
  def each_cell
    @trail_length.times do |i|
      r = @row - i
      next if r < 0 || r >= @height

      brightness = i.zero? ? 1.0 : 1.0 - (i.to_f / @trail_length)
      yield r, @chars[i], brightness
    end
  end
end

# --- Rendering -----------------------------------------------------------

def color_for(brightness)
  if brightness >= 0.99
    "\e[1;97m" # bright white head
  elsif brightness > 0.6
    "\e[1;92m" # bright green
  elsif brightness > 0.25
    "\e[32m"   # medium green
  else
    "\e[2;32m" # dim green
  end
end

def render(grid, width, height)
  buf = +"\e[H" # cursor home (screen cleared once up front, then we overwrite)
  height.times do |r|
    line = +''
    width.times do |c|
      cell = grid[r][c]
      line << (cell ? "#{color_for(cell[1])}#{cell[0]}\e[0m" : ' ')
    end
    buf << line << "\n"
  end
  print buf
end

# --- Main loop -------------------------------------------------------------

def run(options)
  width, height = IO.console.winsize.reverse
  # Fall back to a sane default if the terminal doesn't report a size
  # (e.g. some pipes, minimal pseudo-terminals, or CI environments).
  width = 80 if width.nil? || width <= 0
  height = 24 if height.nil? || height <= 0
  height -= 1 # leave a line so the terminal doesn't scroll

  drops = []
  print "\e[?25l" # hide cursor
  print "\e[2J"   # clear screen once

  trap('INT') do
    print "\e[0m\e[?25h\e[2J\e[H"
    puts 'Bye!'
    exit
  end

  loop do
    # spawn new drops
    width.times do |c|
      drops << Drop.new(c, height, options[:trail_length]) if rand < options[:density]
    end

    # build a grid of [char, brightness] per cell (nil = blank)
    grid = Array.new(height) { Array.new(width) }
    drops.each do |d|
      d.each_cell { |r, ch, b| grid[r][d.col] = [ch, b] }
    end

    render(grid, width, height)

    drops.each(&:advance)
    drops.reject!(&:dead?)

    sleep options[:speed]
  end
end

run(options)
