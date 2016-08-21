# {
#   version: "string",
#   sessionAttributes: {
#     string: object
#   },
#   response: {
#     outputSpeech: {
#       type: "string",
#       text: "string",
#       ssml: "string"
#     },
#     card: {
#       type: "string",
#       title: "string",
#       content: "string",
#       text: "string",
#       image: {
#         smallImageUrl: "string",
#         largeImageUrl: "string"
#       }
#     },
#     reprompt: {
#       outputSpeech: {
#         type: "string",
#         text: "string",
#         ssml: "string"
#       }
#     },
#     shouldEndSession: boolean
#   }
# }

module Response
  def self.speech speech, **opts
    if speech.is_a? String
      type = :PlainText
    else
      type = :SSML
      speech = build_ssml speech
    end

    response = {
      response: {
        outputSpeech: {
          type: type,
          text: speech
        },
        shouldEndSession: opts.fetch(:end_session, true)
      }
    }
    if opts[:reprompt]
      response[:response][:reprompt] = {
        outputSpeech: {
          type: 'PlainText',
          text: opts[:reprompt] || speech
        },
      }
    end

    response
  end

  def self.build_ssml obj, root=true
    if root
      "<speak>#{build_ssml obj, false}</speak>"
    elsif obj.is_a? String
      "<s>#{obj}</s>"
    elsif obj.is_a? Array
      obj.map { |o| build_ssml o, false }.join ' '
    elsif obj.is_a? Hash
      key = obj.keys.first
      val = obj[key]
      case key
      when :audio
        "<audio src=\"#{val}\"/>"
      when :break
        if val =~ /\d+m?s/
          "<break time=\"#{val}\"/>"
        else
          "<break strength=\"#{val}\"/>"
        end
      when :p
        "<p>#{val}</p>"
      when :phoneme
        "<phoneme alphabet=\"#{val.fetch(:alphabet, 'x-sampa')}\" ph=\"#{val[:ph]}\">#{val[:text]}</phoneme>"
      when :s
        "<s>#{val}</s>"
      when :say_as
        "<say-as interpret-as=\"#{val[:interpret_as]}\" format=\"#{val[:format]}\">#{val[:text]}</say-as>"
      when :w
        "<w role=\"ivona:#{val[:role].upcase}\">#{val[:text]}</w>"
      else
        raise 'unsupported key'
      end
    else
      raise 'unsupported type'
    end
  end
end
