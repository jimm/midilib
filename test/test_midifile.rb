# Start looking for MIDI classes in the directory above this one.
# This forces us to use the local copy of MIDI, even if there is
# a previously installed version out there somewhere.
$LOAD_PATH[0, 0] = File.join(File.dirname(__FILE__), '..', 'lib')

require 'test/unit'
require 'stringio'
require 'midilib'

class MIDI::IO::MIDIFile
  attr_writer :io
end

class MIDIFileTester < Test::Unit::TestCase
  def setup
    @m = MIDI::IO::MIDIFile.new
  end

  def test_msg_io
    io = StringIO.new
    io.write('abcdef')
    io.rewind
    @m.io = io
    @m.msg_init
    @m.msg_read(6)
    assert_equal [97, 98, 99, 100, 101, 102], @m.msg
  end

  def test_read32
    io = StringIO.new
    io.write("\0\0\0\6")
    io.rewind
    @m.io = io
    assert_equal 6, @m.read32
  end

  def test_write32
    io = StringIO.new
    old_stdout = $stdout
    $stdout = io
    @m.write32(6)
    $stdout = old_stdout
    io.rewind
    assert_equal "\0\0\0\6", io.string
  end
end
