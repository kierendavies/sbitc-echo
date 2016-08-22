$LOAD_PATH.unshift File.expand_path File.dirname __FILE__

require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'sinatra/json'

require 'json'
require 'active_support'
require 'active_support/core_ext'

require 'lib/audio_scraper'
require 'lib/google_calendar'
require 'lib/response'

GoogleCalendar.authorize
require 'lib/audio_scraper'

require 'sinatra/reloader' if development?
require 'models/meeting'
require 'models/session'
require 'models/properties'

get '/' do
  redirect to '/properties'
end

get '/properties' do
  haml :properties, locals: {cookie: Properties.get('cookie')}
end

post '/properties' do
  Properties.set 'cookie', params[:cookie]
  redirect to '/properties'
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
    end_session = true
    text = ""
    case params[:request][:intent][:name]
    when 'RawText'
      text = params[:request][:intent][:slots][:Text][:value]
      end_session = (text == 'end')
    when 'ReadAgenda'
      agenda = Meeting.agenda.map{|k,v| "#{k[:agenda_item]}"}.join('. ')
      text = "reading agenda #{agenda}"
    when 'RecordAgendaItem'
      agenda_item = params[:request][:intent][:slots][:AgendaItem][:value]
      Meeting.add_agenda_item(agenda_item)
      text = "recorded agenda item #{agenda_item}"
    when 'ReadActionList'
      action_list = Meeting.action_list.map{|k,v| "#{k[:action]}"}.join('. ')
      text = "reading action list #{action_list}"
    when 'RecordActionItem'
      action_item = params[:request][:intent][:slots][:ActionItem][:value]
      Meeting.add_action_item(action_item)
      text = "recorded action item #{action_item}"
    when 'AddParticipant'
      participant = params[:request][:intent][:slots][:Participant][:value]
      Meeting.add_participant(participant)
      text = "added participant #{participant}"
    when 'RecordNote'
      note = params[:request][:intent][:slots][:Note][:value]
      Meeting.add_note(note)
      text = "recorded note #{note}"
    when "GetCurrentAgendaItem"
      item = Meeting.current_agenda_item
      text = "current agenda item is #{item}"
    when 'NextAgendaItem'
      Meeting.next_agenda_item
      item = Meeting.current_agenda_item
      text = "Moving on to #{item}"
    when 'RecordMotion'
      motion = params[:request][:intent][:slots][:Motion][:value]
      Meeting.add_motion(motion)
      text = "recorded motion #{motion}"
    when 'CastVote'
      session_id = params[:session][:sessionId]
      Session.add(session_id, 'CastVote')
      end_session = false
      # text = "session is #{session_id}"
    when 'AMAZON.YesIntent'
      session_id = params[:session][:sessionId]
      if session_id == Session.get[:id] && Session.get[:state] == 'CastVote'
        Meeting.cast_vote(true)
        text = "voted yes"
      end
      text = "couldn't cast a vote"
    when 'AMAZON.NoIntent'
      session_id = params[:session][:sessionId]
      if session_id == Session.get[:id] && Session.get[:state] == 'CastVote'
        Meeting.cast_vote(false)
        text = "voted no"
      end
    when "WhoAmI"
      text = params[:request][:intent][:slots][:Text][:value]
      text="you are you #{text}"
    end
    Response.speech(text, end_session: end_session)
  when 'SessionEndedRequest'
  end || {}

  logger.info "Response:\n#{JSON.pretty_generate response}"
  json response
end
