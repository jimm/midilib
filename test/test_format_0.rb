# Start looking for MIDI classes in the directory above this one.
# This forces us to use the local copy of MIDI, even if there is
# a previously installed version out there somewhere.
$LOAD_PATH[0, 0] = File.join(File.dirname(__FILE__), '..', 'lib')

require 'test/unit'
require 'midilib'

class Format0Tester < Test::Unit::TestCase

  def setup
    @seq = MIDI::Format0Sequence.new()
    @seq.track.events << MIDI::NoteOn.new(0, 64, 127, 0)
    @seq.track.events << MIDI::NoteOff.new(0, 64, 127, 1)
    @seq.track.recalc_times
    @path = '/tmp/midilib-test.mid'
    File.open(@path, 'wb') { |file|
      @seq.write(file)
    }
  end

  def test_can_read_format_0
    seq = MIDI::Sequence.new()
    File.open(@path, 'rb') {|file|
      seq.read(file)
    }
    assert_equal(1, seq.tracks.length)
    assert_equal(2, seq.tracks[0].events.length)
  end
end

