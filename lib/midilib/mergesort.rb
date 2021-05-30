# This code was originally taken from
# http://github.com/adamjmurray/cosy/blob/master/lib/cosy/helper/midi_file_renderer_helper.rb
# with permission from Adam Murray, who originally suggested this fix.
# See http://wiki.github.com/adamjmurray/cosy/midilib-notes for details.

# A stable sorting algorithm that maintains the relative order of equal
# elements.
#
# This code used to be in a new subclass of Array, but that started causing
# problems in Ruby 3.0, apparently due to the return type of the `[]`
# operator which was the parent Array class.
#
# This code borrowed from 'Moser' http://codesnippets.joyent.com/posts/show/1699
def mergesort(arr, &cmp)
  cmp = ->(a, b) { a <=> b } if cmp.nil?
  if arr.size <= 1
    arr.dup
  else
    halves = mergesort_split(arr).map { |half| mergesort(half, &cmp) }
    mergesort_merge(*halves, &cmp)
  end
end

def mergesort_split(arr)
  n = (arr.length / 2).floor - 1
  [arr[0..n], arr[n + 1..-1]]
end

def mergesort_merge(first, second, &predicate)
  result = []
  until first.empty? || second.empty?
    result << if predicate.call(first.first, second.first) <= 0
                first.shift
              else
                second.shift
              end
  end
  result.concat(first).concat(second)
end
