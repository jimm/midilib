# Start looking for MIDI classes in the directory above this one.
# This forces us to use the local copy of MIDI, even if there is
# a previously installed version out there somewhere.
$LOAD_PATH[0, 0] = File.join(File.dirname(__FILE__), '..', 'lib')
# Add current directory so we can find event_equality
$LOAD_PATH[0, 0] = File.dirname(__FILE__)

require 'test/unit'
require 'midilib'
require 'stringio'

class TestableSeqWriter < MIDI::IO::SeqWriter
  def initialize(seq, io)
    @bytes_written = 0
    @io = io
    super(seq)
  end
end

class SeqWriterTests < Test::Unit::TestCase

  def test_writes_header()
    io = StringIO.new()
    version = 0
    seq = MIDI::Sequence.new(version)
    TestableSeqWriter.new(seq, io).write_header

    io.rewind()
    MIDI::IO::MIDIFile.new()
    header = ""
    (0..3).to_a.each{|_|
      header += io.getc()
    }
    assert_equal(header, 'MThd')

    @m = MIDI::IO::MIDIFile.new
    @m.io = io
    @m.msg_init
    assert_equal(@m.read32(), 6)
    assert_equal(@m.read16(), 0)

  end
end

