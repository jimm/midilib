# Start looking for MIDI classes in the directory above this one.
# This forces us to use the local copy of MIDI, even if there is
# a previously installed version out there somewhere.
$LOAD_PATH[0, 0] = File.join(File.dirname(__FILE__), '..', 'lib')

require 'test/unit'
require 'midilib'

class TrackTester < Test::Unit::TestCase
  def setup
    @seq = MIDI::Sequence.new
    @track = MIDI::Track.new(@seq)
    @seq.tracks << @track
    3.times { @track.events << MIDI::NoteOn.new(0, 64, 64, 100) }
    @track.recalc_times
  end

  def test_basics
    assert_equal(3, @track.events.length)
    3.times do |i|
      assert_equal(100, @track.events[i].delta_time)
      assert_equal((i + 1) * 100, @track.events[i].time_from_start)
    end
    assert_equal(MIDI::Track::UNNAMED, @track.name)
  end

  def test_append_event
    @track.events << MIDI::NoteOn.new(0, 64, 64, 100)
    @track.recalc_times
    assert_equal(4, @track.events.length)
    4.times do |i|
      assert_equal((i + 1) * 100, @track.events[i].time_from_start)
    end
  end

  def test_append_list
    @track.events +=
      (1..12).collect { |i| MIDI::NoteOn.new(0, 64, 64, 3) }
    @track.recalc_times

    3.times do |i|
      assert_equal(100, @track.events[i].delta_time)
      assert_equal((i + 1) * 100, @track.events[i].time_from_start)
    end
    12.times do |i|
      assert_equal(3, @track.events[3 + i].delta_time)
      assert_equal(300 + ((i + 1) * 3),
                   @track.events[3 + i].time_from_start)
    end
  end

  def test_insert
    @track.events[1, 0] = MIDI::NoteOn.new(0, 64, 64, 3)
    @track.recalc_times
    assert_equal(100, @track.events[0].time_from_start)
    assert_equal(103, @track.events[1].time_from_start)
    assert_equal(203, @track.events[2].time_from_start)
    assert_equal(303, @track.events[3].time_from_start)
  end

  def test_merge
    list = (1..12).collect { |i| MIDI::NoteOn.new(0, 64, 64, 10) }
    @track.merge(list)
    # We merged 15 events, but an end of track meta event was added by merge
    assert_equal(16, @track.events.length)
    assert_equal(10, @track.events[0].time_from_start)
    assert_equal(10, @track.events[0].delta_time)
    assert_equal(20, @track.events[1].time_from_start)
    assert_equal(10, @track.events[1].delta_time)
    assert_equal(30, @track.events[2].time_from_start)
    assert_equal(40, @track.events[3].time_from_start)
    assert_equal(50, @track.events[4].time_from_start)
    assert_equal(60, @track.events[5].time_from_start)
    assert_equal(70, @track.events[6].time_from_start)
    assert_equal(80, @track.events[7].time_from_start)
    assert_equal(90, @track.events[8].time_from_start)
    assert_equal(100, @track.events[9].time_from_start)
    assert_equal(100, @track.events[10].time_from_start)
    assert_equal(110, @track.events[11].time_from_start)
    assert_equal(120, @track.events[12].time_from_start)
    assert_equal(200, @track.events[13].time_from_start)
    assert_equal(300, @track.events[14].time_from_start)
    assert_equal(300, @track.events[15].time_from_start) # end of track meta event
  end

  def test_recalc_delta_from_times
    @track.each { |event| event.delta_time = 0 }
    @track.recalc_delta_from_times
    @track.each { |event| assert_equal(100, event.delta_time) }
  end

  def test_recalc_delta_from_times_unsorted
    @track.events[0].time_from_start = 100
    @track.events[1].time_from_start = 50
    @track.events[2].time_from_start = 150
    @track.recalc_delta_from_times
    prev_start_time = 0
    @track.each do |event|
      assert(prev_start_time <= event.time_from_start)
      assert(event.delta_time > 0)
      prev_start_time = event.time_from_start
    end
  end

  def test_sort
    e = @track.events[0]
    e.time_from_start = 300
    e = @track.events[1]
    e.time_from_start = 100
    e = @track.events[2]
    e.time_from_start = 200

    @track.sort

    assert_equal(100, @track.events[0].time_from_start)
    assert_equal(100, @track.events[0].delta_time)

    assert_equal(200, @track.events[1].time_from_start)
    assert_equal(100, @track.events[1].delta_time)

    assert_equal(300, @track.events[2].time_from_start)
    assert_equal(100, @track.events[2].delta_time)
  end

  def test_quantize
    @seq.ppqn = 80

    @track.quantize(1) # Quantize to a quarter note
    assert_equal(80, @track.events[0].time_from_start)  # was 100
    assert_equal(240, @track.events[1].time_from_start) # was 200
    assert_equal(320, @track.events[2].time_from_start) # was 300
  end

  def test_instrument
    @track.instrument = 'foo'
    assert_equal('foo', @track.instrument)
  end

  def test_old_note_class_names
    x = MIDI::NoteOn.new(0, 64, 64, 10)
    assert(x.is_a?(MIDI::NoteOnEvent))  # old name
    x = MIDI::NoteOff.new(0, 64, 64, 10)
    assert(x.is_a?(MIDI::NoteOffEvent)) # old name
  end

  def test_delete_event
    # Event is not in the track; nothing happens
    @track.delete_event(MIDI::Controller.new(0, 64, 64, 200))
    assert_equal(3, @track.events.length)

    # Make sure we update delta times and that start times are preserved
    e = @track.events[1]
    @track.delete_event(e)
    assert_equal(2, @track.events.length)
    assert(@track.events.index(e).nil?)
    assert_equal([100, 200], @track.events.map(&:delta_time))
    assert_equal([100, 300], @track.events.map(&:time_from_start))
  end

  def test_ensure_track_end_meta_event
    @track.ensure_track_end_meta_event
    assert_equal(4, @track.events.length)
    e = @track.events.last
    assert(e.is_a?(MIDI::MetaEvent))
    assert_equal(MIDI::META_TRACK_END, e.meta_type)
    assert_equal(0, e.delta_time)
    assert_equal(@track.events[-2].time_from_start, e.time_from_start)
  end

  def test_ensure_track_end_meta_event_removes_duplicates
    mte = MIDI::MetaEvent.new(MIDI::META_TRACK_END, nil, 0)
    @track.events << mte
    @track.events.unshift(mte.dup)
    @track.events.unshift(mte.dup)

    @track.ensure_track_end_meta_event
    mtes = @track.events.select { |e| e.is_a?(MIDI::MetaEvent) && e.meta_type == MIDI::META_TRACK_END }
    assert_equal(1, mtes.length)
    assert(@track.events.last.is_a?(MIDI::MetaEvent) && @track.events.last.meta_type == MIDI::META_TRACK_END)
  end

  def test_ensure_track_end_with_dupes_does_not_shrink_track
    mte = MIDI::MetaEvent.new(MIDI::META_TRACK_END, nil, 123)
    @track.events.unshift(mte.dup)
    @track.events << mte
    @track.recalc_times
    start_time = @track.events.last.time_from_start

    @track.ensure_track_end_meta_event
    mtes = @track.events.select { |e| e.is_a?(MIDI::MetaEvent) && e.meta_type == MIDI::META_TRACK_END }
    assert_equal(1, mtes.length)
    assert_equal(mte, mtes[0])

    # As a side effect, ensure_track_end_meta_event calls recalc_times which
    # in this case will modify the start time of mte.
    assert_equal(start_time, mte.time_from_start)
  end

  def test_ensure_track_end_adds_to_empty_track
    t = MIDI::Track.new(@seq)
    t.ensure_track_end_meta_event

    assert_equal(1, t.events.length)
    mte = t.events.first
    assert(mte.is_a?(MIDI::MetaEvent) && mte.meta_type == MIDI::META_TRACK_END)
  end
end
