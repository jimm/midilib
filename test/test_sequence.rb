require 'test/unit'
require_relative '../lib/midilib'

class SequenceTester < Test::Unit::TestCase
  def setup
    @seq = MIDI::Sequence.new
    @track = MIDI::Track.new(@seq)
    @seq.tracks << @track
    3.times { @track.events << MIDI::NoteOn.new(0, 64, 64, 100) }
    @track.recalc_times
    @seq_bpm_diff = MIDI::Sequence.new
  end

  def test_basics
    assert_equal(120, @seq.beats_per_minute)
    assert_equal(1, @seq.tracks.length)
    assert_equal(MIDI::Track::UNNAMED, @seq.name)
    assert_equal(MIDI::Sequence::DEFAULT_TEMPO, @seq.bpm)
  end

  def test_pulses_to_seconds
    # At a tempo of 120 BPM 480 pulses (one quarter note) should take 0.5 seconds
    assert_in_delta 0.5, @seq.pulses_to_seconds(480), 0.00001

    # A half note should take one second
    assert_in_delta 1.0, @seq.pulses_to_seconds(480 * 2), 0.00001

    # An eight note should take 0.25 seconds
    assert_in_delta 0.25, @seq.pulses_to_seconds(480 / 2), 0.00001

    # At a tempo of 120 BPM 480 pulses (one quarter note) should take 0.5 seconds
    assert_in_delta 0.5, @seq.pulses_to_seconds(480, 1000), 0.00001

    # Should use offset = 0 if offset is not present
    assert_in_delta 0.5, @seq.pulses_to_seconds(480), 0.00001

    # Should retun nil if offset is out of range
    assert_equal(nil, @seq.pulses_to_seconds(480, 1920))
  end

  def test_length_to_delta
    assert_equal(480, @seq.ppqn)
    assert_equal(480, @seq.length_to_delta(1))
    assert_equal(240, @seq.length_to_delta(0.5))

    @seq.ppqn = 12
    assert_equal(12, @seq.ppqn)
    assert_equal(12, @seq.length_to_delta(1))
    assert_equal(6, @seq.length_to_delta(0.5))
    # rounding tests
    assert_equal(6, @seq.length_to_delta(0.49))
    assert_equal(5, @seq.length_to_delta(0.45))
  end

  def test_note_to_length
    assert_equal(1, @seq.note_to_length('quarter'))
    assert_equal(4, @seq.note_to_length('whole'))
    assert_equal(1.5, @seq.note_to_length('dotted quarter'))
    assert_equal(1.0 / 3.0, @seq.note_to_length('quarter triplet'))
    assert_equal(0.5, @seq.note_to_length('dotted quarter triplet'))
    assert_equal(1.0 / 4, @seq.note_to_length('sixteenth'))
    assert_equal(1.0 / 4, @seq.note_to_length('16th'))
    assert_equal(1.0 / 8, @seq.note_to_length('thirty second'))
    assert_equal(1.0 / 8, @seq.note_to_length('32nd'))
    assert_equal(1.0 / 16, @seq.note_to_length('sixty fourth'))
    assert_equal(1.0 / 16, @seq.note_to_length('sixtyfourth'))
    assert_equal(1.0 / 16, @seq.note_to_length('64th'))
  end

  def test_note_to_delta
    assert_equal(480, @seq.note_to_delta('quarter'))
    assert_equal(480 * 4, @seq.note_to_delta('whole'))
    assert_equal(720, @seq.note_to_delta('dotted quarter'))
    assert_equal(480 / 3.0, @seq.note_to_delta('quarter triplet'))
    assert_equal((480 / 3.0) * 1.5,
                 @seq.note_to_delta('dotted quarter triplet'))
    assert_equal(480 / 4, @seq.note_to_delta('sixteenth'))
    assert_equal(480 / 4, @seq.note_to_delta('16th'))
    assert_equal(480 / 8, @seq.note_to_delta('thirty second'))
    assert_equal(480 / 8, @seq.note_to_delta('32nd'))
    assert_equal(480 / 16, @seq.note_to_delta('sixty fourth'))
    assert_equal(480 / 16, @seq.note_to_delta('sixtyfourth'))
    assert_equal(480 / 16, @seq.note_to_delta('64th'))
  end

  def test_beats_per_minute
    # Using file with 2 different tempos whithin sequence (bpm change at 15600)
    File.open('examples/ex2.mid', 'rb') do | file |
      @seq_bpm_diff.read(file)
      assert_equal(nil, @seq_bpm_diff.beats_per_minute(-1000))
      assert_equal(120.0, @seq_bpm_diff.beats_per_minute)
      assert_equal(120.0, @seq_bpm_diff.beats_per_minute(15599))
      assert_equal(131.34, @seq_bpm_diff.beats_per_minute(15600))
      assert_equal(131.34, @seq_bpm_diff.beats_per_minute(15601))
      assert_equal(nil, @seq_bpm_diff.beats_per_minute(5000000))
    end

    # Using regular testing sequence
    assert_equal(120.0, @seq.beats_per_minute(1918))
    assert_equal(nil, @seq.beats_per_minute(1920))
  end
end
