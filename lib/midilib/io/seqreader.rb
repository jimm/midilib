require_relative 'midifile'
require_relative '../track'
require_relative '../event'

module MIDI
  module IO
    # Reads MIDI files. As a subclass of MIDIFile, this class implements the
    # callback methods for each MIDI event and use them to build Track and
    # Event objects and give the tracks to a Sequence.
    #
    # Ensures that each track ends with an end of track meta event, and that
    # Track#recalc_times is called at the end of the track so it can update
    # each event with its time from the track's start (see end_track below).
    class SeqReader < MIDIFile
      # The optional &block is called once at the start of the file and
      # again at the end of each track. There are three arguments to the
      # block: the track, the track number (1 through _n_), and the total
      # number of tracks.
      def initialize(seq, &block) # :yields: track, num_tracks, index
        super()
        @seq = seq
        @track = nil
        @chan_mask = 0
        @update_block = block
      end

      def header(format, ntrks, division)
        @seq.format = format
        @seq.ppqn = division

        @ntrks = ntrks
        @update_block.call(nil, @ntrks, 0) if @update_block
      end

      def start_track
        @track = Track.new(@seq)
        @seq.tracks << @track

        @pending = []
      end

      def end_track
        # Turn off any pending note on messages
        @pending.each { |on| make_note_off(on, 64) }
        @pending = nil

        # Make sure track has an end of track event and that all of the
        # `time_from_start` values are correct.
        @track.ensure_track_end_meta_event
        @track.recalc_times

        # Store bitmask of all channels used into track
        @track.channels_used = @chan_mask

        # call update block
        @update_block.call(@track, @ntrks, @seq.tracks.length) if @update_block
      end

      def note_on(chan, note, vel)
        if vel == 0
          note_off(chan, note, 64)
          return
        end

        on = NoteOn.new(chan, note, vel, @curr_ticks)
        @track.events << on
        @pending << on
        track_uses_channel(chan)
      end

      def note_off(chan, note, vel)
        # Find note on, create note off, connect the two, and remove
        # note on from pending list.

        corresp_note_on = nil

        @pending.each_with_index do |on, i|
          next unless on.note == note && on.channel == chan

          @pending.delete_at(i)
          corresp_note_on = on
          break
        end

        if corresp_note_on
          make_note_off(corresp_note_on, vel)
        else
          # When a corresponding note on is missing,
          # keep note off as input with lefting on/off attr to nil.
          off = NoteOff.new(chan, note, vel, @curr_ticks)
          @track.events << off

          if $DEBUG
            warn "note off with no earlier note on (ch #{chan}, note" +
                 " #{note}, vel #{vel})"
          end
        end
      end

      def make_note_off(on, vel)
        off = NoteOff.new(on.channel, on.note, vel, @curr_ticks)
        @track.events << off
        on.off = off
        off.on = on
      end

      def pressure(chan, note, press)
        @track.events << PolyPressure.new(chan, note, press, @curr_ticks)
        track_uses_channel(chan)
      end

      def controller(chan, control, value)
        @track.events << Controller.new(chan, control, value, @curr_ticks)
        track_uses_channel(chan)
      end

      def pitch_bend(chan, lsb, msb)
        @track.events << PitchBend.new(chan, (msb << 7) + lsb, @curr_ticks)
        track_uses_channel(chan)
      end

      def program(chan, program)
        @track.events << ProgramChange.new(chan, program, @curr_ticks)
        track_uses_channel(chan)
      end

      def chan_pressure(chan, press)
        @track.events << ChannelPressure.new(chan, press, @curr_ticks)
        track_uses_channel(chan)
      end

      def sysex(msg)
        @track.events << SystemExclusive.new(msg, @curr_ticks)
      end

      def eot
        @track.events << MetaEvent.new(META_TRACK_END, nil, @curr_ticks)
      end

      def meta_misc(type, msg)
        @track.events << MetaEvent.new(type, msg, @curr_ticks)
      end

      # --
      #      def sequencer_specific(type, msg)
      #      end

      #      def sequence_number(num)
      #      end
      # ++

      def text(type, msg)
        case type
        when META_TEXT, META_LYRIC, META_CUE, META_SEQ_NAME, META_COPYRIGHT
          @track.events << MetaEvent.new(type, msg, @curr_ticks)
        when META_INSTRUMENT
          @track.instrument = msg
        when META_MARKER
          @track.events << Marker.new(msg, @curr_ticks)
        else
          warn "text = #{msg}, type = #{type}" if $DEBUG
        end
      end

      def time_signature(numer, denom, clocks, qnotes)
        @seq.time_signature(numer, denom, clocks, qnotes)
        @track.events << TimeSig.new(numer, denom, clocks, qnotes, @curr_ticks)
      end

      # --
      #      def smpte(hour, min, sec, frame, fract)
      #      end
      # ++

      def tempo(microsecs)
        @track.events << Tempo.new(microsecs, @curr_ticks)
      end

      def key_signature(sharpflat, is_minor)
        @track.events << KeySig.new(sharpflat, is_minor, @curr_ticks)
      end

      # --
      #      def arbitrary(msg)
      #      end
      # ++

      # Return true if the current track uses the specified channel.
      def track_uses_channel(chan)
        @chan_mask |= (1 << chan)
      end
    end
  end
end
