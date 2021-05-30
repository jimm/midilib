# = midilib
#
# This is the top-level include file for midilib. You can require this
# file or require individual files from the midilib directory.
#
# See the README.rdoc file or http://midilib.rubyforge.org for details.

require_relative 'midilib/info'
require_relative 'midilib/sequence'
require_relative 'midilib/track'
require_relative 'midilib/io/seqreader'
require_relative 'midilib/io/seqwriter'

# --
# consts.rb, utils.rb, and event.rb are included by these files.
# ++
