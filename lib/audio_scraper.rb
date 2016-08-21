require 'curb'
require 'json'
require 'active_support'
require 'active_support/core_exts'

require 'models/cookie'

module AudioScraper
  USER_AGENT = 'curl/7.50.0'
  ACCEPT = '*/*'

  # Returns a list of hashes of audio clips in a given range:
  # {
  #   :text  :  Text of the audio clip.
  #   :id    :  Audio clip id.
  #   :time  :  Time the clip was recorded.
  # }
  def self.cards start_time, end_time
    start_millis = (start_time.to_f * 1000).to_i
    end_millis = (end_time.to_f * 1000).to_i
    url = "https://pitangui.amazon.com/api/cards?beforeCreationTime=#{end_millis}&_=#{start_millis}"

    curl_response = Curl::Easy.perform url do |curl|
      curl.headers['User-Agent'] = USER_AGENT
      curl.headers['Accept'] = ACCEPT
      curl.headers['Cookie'] = Cookie.get
    end.body_str

    response = JSON.parse(curl_response).with_indifferent_access

    # Nom out the audio clips.
    response[:cards].map do |card|
      id = /\/api\/utterance\/audio\/data\?id=(.*)/.match(card[:playbackAudioAction][:url])[1]
      text = card[:descriptiveText].join "\n"
      time = card[:creationTimestamp].to_i

      if time > start_millis && time < end_millis
        {
          :id => id,
          :text => text,
          :time => time / 1000
        }
      else
        nil
      end
    end.compact
  end

  def self.audio id
    url = "https://pitangui.amazon.com//api/utterance/audio/data?id=#{id}"
    Curl::Easy.perform url do |curl|
      curl.headers['User-Agent'] = USER_AGENT
      curl.headers['Accept'] = ACCEPT
      curl.headers['Cookie'] = SESSION_COOKIE
    end.body_str
  end
end
