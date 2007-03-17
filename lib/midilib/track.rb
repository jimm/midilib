require 'midilib/event'

module MIDI

# A Track is a list of events.
#
# When you modify the +events+ array, make sure to call recalc_times so
# each Event gets its +time_from_start+ recalculated.
#
# A Track also holds a bitmask that specifies the channels used by the track.
# This bitmask is set when the track is read from the MIDI file by an
# IO::SeqReader but is _not_ kept up to date by any other methods.

class Track

    include Enumerable

    UNNAMED = 'Unnamed'

    attr_accessor :instrument, :events, :channels_used
    attr_reader :sequence

    def initialize(sequence)
	@sequence = sequence
	@events = Array.new()

	# Bitmask of all channels used. Set when track is read in from
	# a MIDI file.
	@channels_used = 0
    end

    # Return track name. If there is no name, return UNNAMED.
    def name
	event = @events.detect { | e |
	    e.meta? && e.meta_type == META_SEQ_NAME
	}
	return event ? event.data : UNNAMED
    end

    # Set track name. Replaces or creates a name meta-event.
    def name=(name)
	event = @events.detect { | e |
	    e.meta? && e.meta_type == META_SEQ_NAME
	}
	if event
	    event.data = name
	else
	    event = MetaEvent.new(META_SEQ_NAME, name, 0)
	    @events[0, 0] = event
	end
    end

    # Merges an array of events into our event list. After merging, the
    # events' time_from_start values are correct so you don't need to worry
    # about calling recalc_times.
    def merge(event_list)
	@events = merge_event_lists(@events, event_list)
    end

    # Merges two event arrays together. Does not modify this track.
    def merge_event_lists(list1, list2)
	recalc_times(0, list1)
	recalc_times(0, list2)
	list = (list1 + list2).sort_by { | e | e.time_from_start }
	recalc_delta_from_times(0, list)
	return list
    end

    # Quantize every event. length_or_note is either a length (1 = quarter,
    # 0.25 = sixteenth, 4 = whole note) or a note name ("sixteenth", "32nd",
    # "8th triplet", "dotted quarter").
    #
    # Since each event's time_from_start is modified, we call
    # recalc_delta_from_times after each event quantizes itself.
    def quantize(length_or_note)
	delta = case length_or_note
		when String
		    @sequence.note_to_delta(length_or_note)
		else
		    @sequence.length_to_delta(length_or_note.to_i)
		end
	@events.each { | event | event.quantize_to(delta) }
	recalc_delta_from_times
    end

    # Recalculate start times for all events in +list+ from starting_at to
    # end.
    def recalc_times(starting_at=0, list=@events)
	t = (starting_at == 0) ? 0 : list[starting_at - 1].time_from_start
	list[starting_at .. -1].each { | e |
	    t += e.delta_time
	    e.time_from_start = t
	}
    end

    # The opposite of recalc_times: recalculates delta_time for each event
    # from each event's time_from_start. This is useful, for example, when
    # merging two event lists. As a side-effect, elements from starting_at
    # are sorted by time_from_start.
    def recalc_delta_from_times(starting_at=0, list=@events)
	prev_time_from_start = 0
	# We need to sort the sublist. sublist.sort! does not do what we want.
	list[starting_at .. -1] = list[starting_at .. -1].sort { | e1, e2 |
	    e1.time_from_start <=> e2.time_from_start
	}
	list[starting_at .. -1].each { | e |
	    e.delta_time = e.time_from_start - prev_time_from_start
	    prev_time_from_start = e.time_from_start
	}
    end

    # Iterate over events.
    def each			# :yields: event
	@events.each { | event | yield event }
    end

    # Sort events by their time_from_start. After sorting,
    # recalc_delta_from_times is called to make sure that the delta times
    # reflect the possibly new event order.
    def sort
	@events = @events.sort_by { | e | e.time_from_start }
	recalc_delta_from_times()
    end
end

end
