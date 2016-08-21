$LOAD_PATH.unshift File.expand_path File.dirname __FILE__

require 'sinatra'
require 'sinatra/json'

require 'json'
require 'active_support'
require 'active_support/core_ext'

require 'lib/response'
require 'models/cookie'
require 'audio_scraper/audio_scraper'

require 'sinatra/reloader' if development?
also_reload 'lib/response'

get '/' do
  haml :index, locals: {cookie: Cookie.get}
end

post '/cookie' do
  Cookie.set params[:cookie]
  redirect to '/'
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
    end_session = false
    text = ""
    case params[:request][:intent][:name]
    when 'RawText'
      text = params[:request][:intent][:slots][:Text][:value]
      end_session = (text == 'end')
    when 'ReadAgenda'
      text = "reading agenda"
    when 'RecordAgendaItem'
      agendaItem = params[:request][:intent][:slots][:AgendaItem][:value]
      text = "recording agenda item #{agendaItem}"
    when 'ReadActionList'
      text = "reading action list"
    when 'RecordActionItem'
      actionItem = params[:request][:intent][:slots][:ActionItem][:value]
      text = "recording action item #{actionItem}"
    when 'RecordMotion'
      motion = params[:request][:intent][:slots][:Motion][:value]
      text = "recording motion #{motion}"
    when 'RecordMotionResult'
      motionResult = params[:request][:intent][:slots][:MotionResult][:value]
      text = "record motion result #{motionResult}"
    when 'AddAttendee'
      attendee = params[:request][:intent][:slots][:Attendee][:value]
      text = "add attendee #{attendee}"
    when 'RecordNote'
      note = params[:request][:intent][:slots][:Note][:value]
      text = "record note #{note}"
    when 'NextAgendaItem'
      text = "moving along now..."
    end
    Response.speech(text, end_session: end_session)
  when 'SessionEndedRequest'
  end || {}

  logger.info "Response:\n#{JSON.pretty_generate response}"
  json response
end
