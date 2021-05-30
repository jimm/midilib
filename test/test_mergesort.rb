# Start looking for MIDI classes in the directory above this one.
# This forces us to use the local copy of MIDI, even if there is
# a previously installed version out there somewhere.
$LOAD_PATH[0, 0] = File.join(File.dirname(__FILE__), '..', 'lib')

require 'test/unit'
require 'midilib/mergesort'

class MergesortTester < Test::Unit::TestCase
  def test_mergesort
    track = MIDI::Track.new(nil)
    track.events = []

    # Two events with later start times but earlier in the event list
    e2 = MIDI::NoteOff.new(0, 64, 64, 100)
    e2.time_from_start = 100
    track.events << e2

    e3 = MIDI::NoteOn.new(0, 64, 64, 100)
    e3.time_from_start = 100
    track.events << e3

    # Earliest start time, latest in the list of events
    e1 = MIDI::NoteOn.new(0, 64, 64, 100)
    e1.time_from_start = 0
    track.events << e1

    # Recalc sorts. Make sure note off/note on pair at t 100 are in the
    # correct order.
    track.recalc_delta_from_times

    # These tests would fail before we moved to mergesort.
    assert_equal(e1, track.events[0])
    assert_equal(e2, track.events[1])
    assert_equal(e3, track.events[2])
  end
end
