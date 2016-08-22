require 'net/http'
require 'json'
require 'active_support'
require 'active_support/core_ext'

require 'models/cookie'

module AudioScraper
  def self.request path, **params
    uri = URI 'https://pitangui.amazon.com' + path
    uri.query = URI.encode_www_form params
    request = Net::HTTP::Get.new uri
    request['User-Agent'] = 'curl/7.50.0'
    request['Accept'] = '*/*'
    request['Referer'] = 'http://alexa.amazon.com/spa/index.html'
    request['Cookie'] = Cookie.get
    Net::HTTP.start uri.host, uri.port, use_ssl: true do |http|
      http.request request
    end.body
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
end
