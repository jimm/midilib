# Start looking for MIDI classes in the directory above this one.
# This forces us to use the local copy of MIDI, even if there is
# a previously installed version out there somewhere.
$LOAD_PATH[0, 0] = File.join(File.dirname(__FILE__), '..', 'lib')

require 'test/unit'
require 'midilib'

class Format0SequenceTester < Test::Unit::TestCase

  def setup
    @seq = MIDI::Format0Sequence.new()
    3.times { @seq.track.events << MIDI::NoteOn.new(0, 64, 64, 100) }
    @seq.track.recalc_times
  end

  def test_basics
    assert_equal(0, @seq.seq.format)
    assert_equal(120, @seq.seq.beats_per_minute)
    assert_equal(MIDI::Track::UNNAMED, @seq.seq.name)
    assert_equal(MIDI::Sequence::DEFAULT_TEMPO, @seq.seq.bpm)
  end
end
