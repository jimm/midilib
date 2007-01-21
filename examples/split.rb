#! /usr/bin/env ruby
#
# usage: split.rb [midi_file]
#
# This script splits a MIDI file into muliple files, one for each track. The
# output files are named with the track's names. Each file contains a copy of
# the 0'th track, which contains tempo information.

# Start looking for MIDI module classes in the directory above this one.
# This forces us to use the local copy, even if there is a previously
# installed version out there somewhere.
$LOAD_PATH[0, 0] = File.join(File.dirname(__FILE__), '..', 'lib')

require 'midilib/sequence'

DEFAULT_MIDI_TEST_FILE = 'NoFences.mid'

# Read from MIDI file
seq = MIDI::Sequence.new()

File.open(ARGV[0] || DEFAULT_MIDI_TEST_FILE, 'rb') { | file |
    # The block we pass in to Sequence.read is called at the end of every
    # track read. It is optional, but is useful for progress reports.
    seq.read(file) { | track, num_tracks, i |
	puts "read track #{track ? track.name : ''} (#{i} of #{num_tracks})"
    }
}

t0 = seq.tracks[0]
seq.each_with_index { | track, i |
    next unless i > 0
    s = MIDI::Sequence.new
    s.tracks << t0
    s.tracks << track
    File.open("#{track.name}.mid", 'wb') { | file | s.write(file) }
}
