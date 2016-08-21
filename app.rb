require 'sinatra'
require 'sinatra/json'

require 'json'
require 'active_support'
require 'active_support/core_ext'

require 'pp'
require 'pry'
require 'set'

require './lib/response'

require 'sinatra/reloader' if development?
also_reload './lib/response'

$sessions = Set.new

get '/' do
  'It works!'
end

post '/echo' do
  request.body.rewind
  @params = JSON.parse(request.body.read).with_indifferent_access

  if !$sessions.include? params[:session][:sessionId]
    logger.info "\n===== new session ====="
    $sessions << params[:session][:sessionId]
  end

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
  end

  logger.info "Response:\n#{JSON.pretty_generate response}"
  json response
end
