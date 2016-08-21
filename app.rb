$LOAD_PATH.unshift File.expand_path File.dirname __FILE__

require 'sinatra'
require 'sinatra/json'

require 'json'
require 'active_support'
require 'active_support/core_ext'

require 'lib/response'
require 'audio_scraper/audio_scraper'

require 'sinatra/reloader' if development?
also_reload 'lib/response'

get '/' do
  haml :index
end

post '/echo' do
  request.body.rewind
  @params = JSON.parse(request.body.read).with_indifferent_access
  logger.info "Request:\n#{JSON.pretty_generate params}"

  response = case params[:request][:type]
  when 'LaunchRequest'
    Response.speech(
      # 'recording meeting minutes, starting now',
      'starting',
      end_session: false
    )
  when 'IntentRequest'
    case params[:request][:intent][:name]
    when 'RawText'
      text = params[:request][:intent][:slots][:Text][:value]
      end_session = (text == 'end')
      Response.speech(text, end_session: end_session)
    end
  when 'SessionEndedRequest'
  end || {}

  logger.info "Response:\n#{JSON.pretty_generate response}"
  json response
end
