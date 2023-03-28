#!/usr/bin/env ruby
#
# usage: measure_mbt.rb midi_file
#
# This program loads a sequences and prints out all start-of-notes
# in a "sequencer-style" manner:
#    Measure:Beat:Tick   Channel: Note-name

require_relative '../lib/midilib/sequence'

seq = MIDI::Sequence.new
File.open(ARGV[0], 'rb') { |file| seq.read(file) }

# Get all measures, so events can be mapped to measures:
measures = seq.get_measures

seq.each do |track|
  track.each do |e|
    next unless e.is_a?(MIDI::NoteOn)

    # Print out start of notes
    e.print_note_names = true
    puts measures.to_mbt(e) + "  ch #{e.channel}:  #{e.note_to_s}"
  end
end
