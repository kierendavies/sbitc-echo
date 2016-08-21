require 'curb'
require 'json'

module AudioScraper
    USER_AGENT = "curl/7.50.0"
    ACCEPT = "*/*"
    SESSION_COOKIE = "aws-target-static-id=1471602327112-621333; aws-target-data=%7B%22support%22%3A%221%22%7D; aws-target-visitor-id=1471602327115-217015.21_38; x-main=8sxwi1sEGI@JmLHuiFfr5WfE1bZZwvZSEsykg9JeG4S8aLYDZOQ7Dl3PZP2irJul; at-main=Atza|IwEBIGcQnQxbExCBD5UAv7kfoxR0pjDJG_1-9_79FZnu3WxkLienxjWtmS-FMV0EJOlBmcZWUX-hwhZEPSiBilm8f-q04dRe8dLoSxsXrSDkVCc-KsJiDdbaq9_ge1JykBXJX4KHkn6F0Ah2QBQwjEK2Cm9hez21800LLd7-Sab948MUoGsk9TSCtGCb4W7ulQ4UxXmZZFWJWN94glhztSTOFafIKwpzoIYoRgwFJE_Ow6JBu2mgyRX_jvmOdfJFMSejy8FHv60UFi5nZAvRLf8Qk7ODHHGyd_Z1Ms3HR_5G6Cubl7fXDjDdMNymc5fPHP3nkYzZ1MbLXq3UoW1F5oSu2xk_; sess-at-main=xdzQ9DB/H0n2VZL3ZvG20um9WkTdOYkCN+CHk9VsFps=; skin=noskin; x-wl-uid=1NP09ZYqLompS5qeG8100CXYcAPM93NyJdC6R1vtrukf7lKuItgL4YkJnYnnZ1zHal0mv/ZcEKAfrpBZkxRypPVSm3H9i8aRJ7bomWXy6UNs7WiNiS95o4kAL02BkExFpdJLU6mdyESM=; session-id-time=2082787201l; csrf=-7171874; s_vnum=1472680800574%26vn%3D2; s_cc=true; s_fid=39CCBAAC68547359-3C1C30374BCC729D; s_nr=1471770610718-Repeat; s_invisit=true; s_sq=%5B%5BB%5D%5D; session-id=168-7294360-0549408; ubid-main=175-4826109-8188010; session-token=J93GE0ugBwDYx2vdZ1LrP2Ix8Tpu67dyYJPRTaKgzh/HTeui/Hhgu7tZJ0FkYwwWwfJuSW3UWsI1pv0oHXD5mB8MRjCD8P14lrM+ibqnzz9wFJ0eXU7BOThihb/4oBdb1YxtSu6GLvbpt3LeNOenrWu5gFb58B3fWzmvOaCo+GktGOrneRdZAHHur7RX6w2Z; appstore-devportal-locale=en_US"
        
    # Returns a list of hashes of audio clips in a given range:
    # {
    #   :text    :    Text of the audio clip.
    #   :id      :    Audio clip id.
    #   :time    :    Time the clip was recorded.
    # }
    def self.get_cards fromTime, toTime
        fromMillis = (fromTime.to_f * 1000).to_i
        toMillis   = (toTime.to_f   * 1000).to_i
        url = "https://pitangui.amazon.com/api/cards?beforeCreationTime=#{toMillis}&_=#{fromMillis}"

        curl_response = Curl::Easy.perform(url) do |curl|
            curl.headers['User-Agent'] = USER_AGENT
            curl.headers['Accept'] = ACCEPT
            curl.headers['Cookie'] = SESSION_COOKIE
        end.body_str

        response = JSON.parse(curl_response).with_indifferent_access  

        # Nom out the audio clips.
        response[:cards].map do |card|
            id = /\/api\/utterance\/audio\/data\?id=(.*)/.match(card[:playbackAudioAction][:url])[1]
            text = card[:descriptiveText].join
            time = card[:creationTimestamp].to_i

            if time > fromMillis && time < toMillis
                {
                    :id => id,
                    :text => text,
                   :time => time
                }
            else
                nil
            end
        end.compact
    end

    def self.get_audio_for id
        puts id
        Curl::Easy.perform("https://pitangui.amazon.com//api/utterance/audio/data?id=#{id}") do |curl|
            curl.headers['User-Agent'] = USER_AGENT
            curl.headers['Accept'] = ACCEPT
            curl.headers['Cookie'] = SESSION_COOKIE
        end.body_str
    end
end


