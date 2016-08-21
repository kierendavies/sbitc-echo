require 'diarize'

module VoiceRecognition
    MODEL_NAMES = ['guy', 'anya', 'kieren', 'tae']

    def self.models
        @@models ||= nil
        return @@models if @@models
        
        @@models = MODEL_NAMES.map do |name|
            Diarize::Speaker.new nil, nil, "models/#{name}.gmm"
        end  
    end

    def self.model_weights
        @@model_weights ||= nil
        return @@model_weights if @@model_weights

        # Our weights are based on the premise that if you are close to the base model, 
        # the model is probably bad.
        base_model = Diarize::Speaker.new nil, nil, "models/ubm.gmm"
        @@model_weights = models.map do |model|
            1/Diarize::Speaker.divergence(base_model, model)
        end
    end

    # Takes in a URI to a WAV file to be analyzed.
    # Returns a list of structs of the following form:
    # {
    #     start_time  :    the time an audio snippet begins in seconds
    #     duration    :    duration of audio snippet in seconds
    #     speaker     :    lowercase name of the person most likely to be speaking
    #                      in this snippet
    # }
    def self.parse uri
        audio = Diarize::Audio.new uri
        audio.analyze!

        # Generate map of speaker URI to name.
        speaker_names = audio.speakers.inject({}) do |hash, speaker|
            hash[speaker.uri] = recognise speaker
            hash
        end 

        audio.segments.map do |segment|
            puts speaker_names
            {
                :start_time => segment.start,
                :duration => segment.duration,
                :speaker => speaker_names[segment.speaker.uri]
            }
        end
    end

    # Takes in a Diarize::Speaker object and attempts to do
    # voice recognition on it.
    def self.recognise speaker
        scores = models.zip(model_weights).map do |model, weight|
            Diarize::Speaker.divergence(model, speaker) * weight
        end

        puts "\nSCORES\n#{scores}\n"

        MODEL_NAMES[scores.index(scores.min)]
    end
end

puts VoiceRecognition.parse URI("file://#{ARGV[0]}") 
