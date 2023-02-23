require_relative('lib/midilib')

# Create a new, empty sequence.
seq = MIDI::Sequence.new()

# Read the contents of a MIDI file into the sequence.
File.open('examples/ex2.mid', 'rb') { | file |
  seq.read(file) { | track, num_tracks, i |
    Array(track).each do |event|
      # if MIDI::Tempo === event
        # p event.data
      # end
      
    end
  
  }
  seq.avg_beats_per_minute
  # p MIDI::META_TRACK_END
}