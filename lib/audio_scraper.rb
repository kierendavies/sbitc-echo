require 'httparty'
require 'json'
require 'active_support'
require 'active_support/core_ext'

require 'models/cookie'

require 'tempfile'

module AudioScraper
  def self.request path, **params
    HTTParty.get 'https://pitangui.amazon.com' + path,
      query: params.with_indifferent_access,
      headers: {
        'User-Agent' => 'curl/7.50.0',
        'Accept' => '*/*',
        'Referer' => 'http://alexa.amazon.com/spa/index.html',
        'Cookie' => Cookie.get
      }
  end

  # Returns a list of hashes of audio clips in a given range:
  # {
  #   :text  :  Text of the audio clip.
  #   :id    :  Audio clip id.
  #   :time  :  Time the clip was recorded.
  # }
  def self.activities start_time, end_time
    start_millis = (start_time.to_f * 1000).to_i
    end_millis = (end_time.to_f * 1000).to_i

    # depaginate
    activities = []
    earliest_millis = end_millis
    while earliest_millis > start_millis
      response = request '/api/activities', endTime: end_millis, size: 50, offset: -1
      data = JSON.parse(response).with_indifferent_access
      activities += data[:activities] unless data[:activities].nil?
      earliest_millis = data[:startDate]
    end
    activities.reject! { |activity| activity[:creationTimestamp] < start_millis }
    activities.sort_by! { |activity| activity[:creationTimestamp] }
    activities.each do |activity|
      activity[:description] = JSON.parse activity[:description]
    end

    activities.map do |activity|
      {
        id: activity[:utteranceId],
        text: activity[:description][:summary],
        time: activity[:creationTimestamp]
      }
    end
  end

  def self.audio id
    self.request '/api/utterance/audio/data', id: id
  end

  # Get a URI to a WAV version of the given audio file.
  def self.wav_file id
    file = Tempfile.new("echo_audio")
    file.write audio id
    
    out_path = file.path + '.wav'
    system "ffmpeg -i #{file.path} #{out_path}"

    file.close
    URI("file://#{out_path}")
  end
end
