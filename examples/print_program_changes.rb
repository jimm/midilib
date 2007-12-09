#! /usr/bin/env ruby
#
# Shows use of print_decimal_numbers and print_channel_numbers_from_one.

$LOAD_PATH[0, 0] = File.join(File.dirname(__FILE__), '..', 'lib')

require 'midilib/sequence'

DEFAULT_MIDI_TEST_FILE = 'NoFences.mid'

# Read from MIDI file
seq = MIDI::Sequence.new()

File.open(ARGV[0] || DEFAULT_MIDI_TEST_FILE, 'rb') { | file |
    # The block we pass in to Sequence.read is called at the end of every
    # track read. It is optional, but is useful for progress reports.
    seq.read(file)
}

seq.each { | track |
  puts
  puts "*** track name \"#{track.name}\", \"#{track.instrument}\""
  track.each { | e |
    e.print_decimal_numbers = true
    e.print_channel_numbers_from_one = true
    puts e if e.program_change?
  }
}
