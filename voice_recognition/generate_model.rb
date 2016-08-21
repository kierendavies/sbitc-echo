require 'diarize'

input_file  = URI('file://' + ARGV[0])
output_file = ARGV[1]
puts output_file

# Do the thing. Just wanted an excuse to write this.
audio = Diarize::Audio.new input_file
audio.analyze!

# See which speaker has the most audio.
# If the sample isn't long enough, or has small snippets of other people in it,
# we might have more than one perceived speaker. Obviously we want to ignore these.
speakers_to_length = {}
audio.segments.each do |segment|
    current_length = speakers_to_length[segment.speaker] || 0
    current_length += segment.duration
    speakers_to_length[segment.speaker] = current_length
end

max_speaker = speakers_to_length.max_by do |key, value|
    value
end

puts max_speaker
puts speakers_to_length[max_speaker]
max_speaker[0].save_model output_file
