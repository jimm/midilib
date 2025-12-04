require 'test/unit'
require_relative '../lib/midilib'
require_relative '../lib/midilib/consts'
require_relative 'event_equality'

class IOTester < Test::Unit::TestCase
  SEQ_TEST_FILE = File.join(File.dirname(__FILE__), 'test.mid')
  OUTPUT_FILE = 'testout.mid'
  TEMPFILE = '/tmp/midilib_test.mid'

  def compare_tracks(t0, t1)
    assert_equal(t0.name, t1.name, 'track names differ')
    assert_equal(t0.events.length, t1.events.length,
                 'number of track events differ')
    t0.each_with_index { |ev0, i| assert_equal(ev0, t1.events[i], 'events differ') }
    assert_equal(t0.instrument, t1.instrument)
  end

  def compare_sequences(s0, s1)
    assert_equal(s0.name, s1.name, 'sequence names differ')
    assert_equal(s0.tracks.length, s1.tracks.length,
                 'number of tracks differ')
    s0.each_with_index { |track0, i| compare_tracks(track0, s1.tracks[i]) }
  end

  def compare_sequences_format_0(multitrack_seq, format0_seq)
    assert_equal(multitrack_seq.name, format0_seq.name, 'sequence names differ')
    assert_equal(1, format0_seq.tracks.length, 'number of tracks differ')
    format_1_count = multitrack_seq.tracks.map { |t| t.events.count }.reduce(:+)
    format_0_count = format0_seq.tracks.map { |t| t.events.count }.reduce(:+)

    # The format 1 file will have one more event because there is an end of
    # track meta event at the end of each track (the track 0 metadata track
    # and track 1 with the notes), whereas the format 0 file only has one
    # track, thus one end of track meta event.
    assert_equal(format_1_count, format_0_count + 1, 'different number of total events')
  end

  def test_read_and_write
    seq0 = MIDI::Sequence.new
    File.open(SEQ_TEST_FILE, 'rb') { |f| seq0.read(f) }
    File.open(OUTPUT_FILE, 'wb') { |f| seq0.write(f) }
    seq1 = MIDI::Sequence.new
    File.open(OUTPUT_FILE, 'rb') { |f| seq1.read(f) }
    compare_sequences(seq0, seq1)
  ensure
    File.delete(OUTPUT_FILE) if File.exist?(OUTPUT_FILE)
  end

  def test_read_and_write_format_0
    seq0 = MIDI::Sequence.new
    File.open(SEQ_TEST_FILE, 'rb') { |f| seq0.read(f) }
    File.open(OUTPUT_FILE, 'wb') { |f| seq0.write(f, 0) }
    seq1 = MIDI::Sequence.new
    File.open(OUTPUT_FILE, 'rb') { |f| seq1.read(f) }
    compare_sequences_format_0(seq0, seq1)
  ensure
    File.delete(OUTPUT_FILE) if File.exist?(OUTPUT_FILE)
  end

  def test_read_callback
    seq = MIDI::Sequence.new
    names = []
    num_tracks = -1
    File.open(SEQ_TEST_FILE, 'rb') do |f|
      seq.read(f) do |track, ntracks, i|
        names << (track ? track.name : nil)
        num_tracks = ntracks
      end
    end
    assert_equal(names, [nil, 'Sequence Name', 'My New Track'])
    assert_equal(num_tracks, 2)
  ensure
    File.delete(OUTPUT_FILE) if File.exist?(OUTPUT_FILE)
  end

  def test_write_callback
    seq = MIDI::Sequence.new
    File.open(SEQ_TEST_FILE, 'rb') { |f| seq.read(f) }

    names = []
    num_tracks = -1
    File.open(OUTPUT_FILE, 'wb') do |f|
      seq.write(f) do |track, ntracks, i|
        names << (track ? track.name : nil)
        num_tracks = ntracks
      end
    end
    assert_equal(names, [nil, 'Sequence Name', 'My New Track'])
    assert_equal(num_tracks, 2)
  ensure
    File.delete(OUTPUT_FILE) if File.exist?(OUTPUT_FILE)
  end

  def test_read_strings
    seq = MIDI::Sequence.new
    File.open(SEQ_TEST_FILE, 'rb') { |f| seq.read(f) }
    assert_equal('Sequence Name', seq.tracks[0].name)
    assert_equal(MIDI::GM_PATCH_NAMES[0], seq.tracks[1].instrument)
  end

  # This is a regression test.
  def test_read_eot_preserves_delta
    seq = MIDI::Sequence.new
    File.open(SEQ_TEST_FILE, 'rb') { |f| seq.read(f) }
    track = seq.tracks.last
    mte = MIDI::MetaEvent.new(MIDI::META_TRACK_END, nil, 123)
    track.events << mte
    track.recalc_times
    File.open(OUTPUT_FILE, 'wb') { |f| seq.write(f) }
    File.open(OUTPUT_FILE, 'rb') { |f| seq.read(f) }

    assert_equal(mte, seq.tracks.last.events.last)
  ensure
    File.delete(OUTPUT_FILE) if File.exist?(OUTPUT_FILE)
  end

  def test_preserve_deltas_in_some_situations
    out_seq = MIDI::Sequence.new
    out_track = MIDI::Track.new(out_seq)
    out_seq.tracks << out_track
    out_track.events << MIDI::Tempo.new(MIDI::Tempo.bpm_to_mpq(120))

    # 1) The meta events with non-zero delta time
    # Normally copyright and sequence name events are at time 0, but non-zero
    # start times are allowed.
    begin
      out_track.events << MIDI::MetaEvent.new(MIDI::META_COPYRIGHT, '(C) 1950 Donald Duck', 100)
      out_track.events << MIDI::MetaEvent.new(MIDI::META_SEQ_NAME, 'Quack, Track 1', 200)
      out_track.events << MIDI::NoteOn.new(0, 64, 127, 0)
      out_track.events << MIDI::NoteOff.new(0, 64, 127, 100)
    end

    # 2) The unusual note off event with non-zero delta time
    begin
      out_track.events << MIDI::NoteOff.new(0, 65, 127, 120)
      out_track.events << MIDI::NoteOn.new(0, 65, 127, 0)
      # Add note off (which will be complemented at #end_track if missing) for later comparison.
      out_track.events << MIDI::NoteOff.new(0, 65, 127, 230)
    end

    File.open(TEMPFILE, 'wb') { |file| out_seq.write(file) }

    # Although start times are not written out to the MIDI file, we
    # calculate them because we are about to compare the out events with the
    # newly-read events which will have their start times set.
    out_track.recalc_times

    in_seq = MIDI::Sequence.new
    File.open(TEMPFILE, 'rb') { |file| in_seq.read(file) }
    in_track = in_seq.tracks[0]
    assert_equal(out_track.events.length + 1, in_track.events.length) # read added end of track meta event
    out_track.events.each_with_index do |event, i|
      assert_equal(event, in_track.events[i])
    end

    # Last event is a end of track meta event
    e = in_track.events.last
    assert(e.is_a?(MIDI::MetaEvent))
    assert(e.meta_type == MIDI::META_TRACK_END)
  end

  def test_preserve_deltas_multiple_note_offs
    out_seq = MIDI::Sequence.new
    out_track = MIDI::Track.new(out_seq)
    out_seq.tracks << out_track
    out_track.events << MIDI::Tempo.new(MIDI::Tempo.bpm_to_mpq(120))

    out_track = MIDI::Track.new(out_seq)
    out_seq.tracks << out_track
    out_track.events << MIDI::NoteOn.new(0, 65, 127, 100)
    out_track.events << MIDI::NoteOff.new(0, 65, 127, 100)
    out_track.events << MIDI::NoteOff.new(0, 65, 127, 100)

    File.open(TEMPFILE, 'wb') { |file| out_seq.write(file) }

    in_seq = MIDI::Sequence.new
    File.open(TEMPFILE, 'rb') { |file| in_seq.read(file) }
    in_track = in_seq.tracks[1]

    out_track.recalc_times # so that start times are correct

    assert_equal(out_track.events.length + 1, in_track.events.length)
    out_track.events.each_with_index do |event, i|
      assert_equal(event.data_as_bytes, in_track.events[i].data_as_bytes)
      assert_equal(event.delta_time, in_track.events[i].delta_time)
      assert_equal(event.time_from_start, in_track.events[i].time_from_start)
    end

    # Last event is a end of track meta event
    e = in_track.events.last
    assert(e.is_a?(MIDI::MetaEvent))
    assert(e.meta_type == MIDI::META_TRACK_END)
  end

  def test_preserve_deltas_multiple_note_on_zero_velocity
    out_seq = MIDI::Sequence.new
    out_track = MIDI::Track.new(out_seq)
    out_seq.tracks << out_track
    out_track.events << MIDI::Tempo.new(MIDI::Tempo.bpm_to_mpq(120))

    out_track = MIDI::Track.new(out_seq)
    out_seq.tracks << out_track
    out_track.events << MIDI::NoteOn.new(0, 65, 127, 100)
    out_track.events << MIDI::NoteOn.new(0, 65, 0, 100)
    out_track.events << MIDI::NoteOn.new(0, 65, 0, 100)

    File.open(TEMPFILE, 'wb') { |file| out_seq.write(file) }

    in_seq = MIDI::Sequence.new
    File.open(TEMPFILE, 'rb') { |file| in_seq.read(file) }
    in_track = in_seq.tracks[1]

    # Turn the note ons with zero velocity into note offs, and recalc start
    # times so that time_from_start is correct.
    [1, 2].each do |i|
      out_track.events[i] = MIDI::NoteOff.new(0, 65, 64, 100)
    end
    out_track.recalc_times # so that start times are correct

    assert_equal(out_track.events.length + 1, in_track.events.length)
    out_track.events.zip(in_track.events).each do |out_event, in_event|
      assert_equal(out_event.data_as_bytes, in_event.data_as_bytes)
      assert_equal(out_event.delta_time, in_event.delta_time)
      assert_equal(out_event.time_from_start, in_event.time_from_start)
    end

    # Last event is a end of track meta event
    e = in_track.events.last
    assert(e.is_a?(MIDI::MetaEvent))
    assert(e.meta_type == MIDI::META_TRACK_END)
  end

  # Regression test. Running status output when writing a track's events was
  # broken.
  def test_running_status_output
    out_seq = MIDI::Sequence.new
    out_track = MIDI::Track.new(out_seq)
    out_seq.tracks << out_track
    out_track.events << MIDI::Tempo.new(MIDI::Tempo.bpm_to_mpq(120))

    out_track = MIDI::Track.new(out_seq)
    out_seq.tracks << out_track
    out_track.events << MIDI::NoteOn.new(0, 65, 127, 100)
    out_track.events << MIDI::NoteOn.new(0, 65, 0, 100)
    out_track.events << MIDI::NoteOn.new(0, 65, 0, 100)

    File.open(TEMPFILE, 'wb') { |file| out_seq.write(file) }

    in_seq = MIDI::Sequence.new
    File.open(TEMPFILE, 'rb') { |file| in_seq.read(file) }
    in_track = in_seq.tracks[1]

    # Turn the note ons with zero velocity into note offs, and recalc start
    # times so that time_from_start is correct.
    [1, 2].each do |i|
      out_track.events[i] = MIDI::NoteOff.new(0, 65, 64, 100)
    end
    out_track.recalc_times # so that start times are correct

    assert_equal(out_track.events.length + 1, in_track.events.length)
    out_track.events.each_with_index do |event, i|
      in_event = in_track.events[i]
      assert_equal(event.data_as_bytes, in_event.data_as_bytes)
      assert_equal(event.delta_time, in_event.delta_time)
      assert_equal(event.time_from_start, in_event.time_from_start)
    end

    # Last event is a end of track meta event
    e = in_track.events.last
    assert(e.is_a?(MIDI::MetaEvent))
    assert(e.meta_type == MIDI::META_TRACK_END)
  end
end
