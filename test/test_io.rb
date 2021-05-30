# Start looking for MIDI classes in the directory above this one.
# This forces us to use the local copy of MIDI, even if there is
# a previously installed version out there somewhere.
$LOAD_PATH[0, 0] = File.join(File.dirname(__FILE__), '..', 'lib')
# Add current directory so we can find event_equality
$LOAD_PATH[0, 0] = File.dirname(__FILE__)

require 'test/unit'
require 'midilib'
require 'midilib/consts'
require 'event_equality'

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
    assert_equal(format_1_count, format_0_count, 'same number of total events')
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

  def test_preserve_meta_deltas
    out_seq = MIDI::Sequence.new
    out_track = MIDI::Track.new(out_seq)
    out_seq.tracks << out_track
    out_track.events << MIDI::Tempo.new(MIDI::Tempo.bpm_to_mpq(120))
    # Normally copyright and sequence name events are at time 0, but non-zero
    # start times are allowed.
    out_track.events << MIDI::MetaEvent.new(MIDI::META_COPYRIGHT, '(C) 1950 Donald Duck', 100)
    out_track.events << MIDI::MetaEvent.new(MIDI::META_SEQ_NAME, 'Quack, Track 1', 200)
    out_track.events << MIDI::NoteOn.new(0, 64, 127, 0)
    out_track.events << MIDI::NoteOff.new(0, 64, 127, 100)
    File.open('/tmp/midilib_test.mid', 'wb') { |file| out_seq.write(file) }

    # Although start times are not written out to the MIDI file, we
    # calculate them because we are about to compare the out events with the
    # newly-read events which will have their start times set.
    out_track.recalc_times

    in_seq = MIDI::Sequence.new
    File.open(TEMPFILE, 'rb') { |file| in_seq.read(file) }
    in_track = in_seq.tracks[0]
    assert_equal(out_track.events.length, in_track.events.length)
    out_track.events.each_with_index do |event, i|
      assert_equal(event, in_track.events[i])
    end
  end
end
