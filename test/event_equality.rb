# This code defines equality operators for all of the event classes. It's
# used by SeqTester.
#
# I don't think it is necessary to include these methods in the base Event
# classes. If someone disagrees, it would be trivial to move them there.

module MIDI
  class Event
    def ==(other)
      other.instance_of?(self.class) &&
        @status == other.status &&
        @delta_time == other.delta_time &&
        @time_from_start == other.time_from_start
    end
  end

  class ChannelEvent
    def ==(other)
      super(other) && @channel == other.channel
    end
  end

  class NoteEvent < ChannelEvent
    def ==(other)
      super(other) &&
        @note == other.note && @velocity == other.velocity
    end
  end

  class Controller < ChannelEvent
    def ==(other)
      super(other) &&
        @controller == other.controller && @value == other.value
    end
  end

  class ProgramChange < ChannelEvent
    def ==(other)
      super(other) && @program == other.program
    end
  end

  class ChannelPressure < ChannelEvent
    def ==(other)
      super(other) && @pressure == other.pressure
    end
  end

  class PitchBend < ChannelEvent
    def ==(other)
      super(other) && @value == other.value
    end
  end

  class SystemExclusive < SystemCommon
    def ==(other)
      super(other) && @data == other.data
    end
  end

  class SongPointer < SystemCommon
    def ==(other)
      super(other) && @pointer == other.pointer
    end
  end

  class SongSelect < SystemCommon
    def ==(other)
      super(other) && @song == other.song
    end
  end

  class MetaEvent < Event
    def ==(other)
      super(other) && @meta_type == other.meta_type &&
        @data == other.data
    end
  end
end
