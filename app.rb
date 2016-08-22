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
require 'lib/audio_scraper'
require 'lib/end_meeting_job'
require './voice_recognition/voice_recognition'

require 'sinatra/reloader' if development?
require 'models/meeting'
require 'models/session'
require 'models/properties'

GoogleCalendar.authorize

get '/' do
  haml :index, locals: {
    participants: Meeting.participants.map { |p| p[:participant] || 'Unknown' },
    agenda_items: Meeting.agenda.map { |i| i[:agenda_item] },
    action_items: Meeting.action_list.map { |i| i[:action] }
  }
end

get '/properties' do
  haml :properties, locals: {cookie: Properties.get('cookie')}
end

post '/properties' do
  Properties.set 'cookie', params[:cookie]
  redirect to '/properties'
end

get '/guytest' do
  timestamp = Time.parse params[:request][:timestamp]
  timestamp_sec = timestamp.to_i
  activities = AudioScraper.activities(timestamp - 1, timestamp + 1).select do |card|
      (card[:time]/1000).to_i == timestamp_sec
  end

  if activities.length == 0
      text = "couldn't find audio. you are probably tae"
  end
  
  id = activities[0][:id]
  wav_uri = AudioScraper.wav_file id
  voices = VoiceRecognition.parse wav_uri

  text = "I think it is #{voices[0][:speaker]} speaking"
  puts text
end

post '/echo' do
  request.body.rewind
  @params = JSON.parse(request.body.read).with_indifferent_access
  logger.info "Request:\n#{JSON.pretty_generate params}"

  response = case params[:request][:type]
  when 'LaunchRequest'
    Response.speech(
      # 'recording meeting minutes, starting now',
      'what would you like to do?',
      end_session: false
    )
  when 'IntentRequest'
    end_session = true
    text = ""
    case params[:request][:intent][:name]
    when 'RawText'
      text = params[:request][:intent][:slots][:Text][:value]
      end_session = (text == 'end')
    when 'StartMeeting'
      meeting = GoogleCalendar.current_event
      text = if meeting.nil?
        'there are no meetings scheduled.  do you want to start one anyway?'
      else
        Meeting.delete_participants
        meeting[:attendees].each do |p|
          Meeting.add_participant p
        end
        'starting meeting.  the participants are: ' + meeting[:attendees].map {|p| p || 'Unknown'}.join(', ')
      end
    when 'EndMeeting'
      EndMeetingJob.perform_async
      text = 'meeting ended.  minutes will be emailed to all participants.'
    when 'ReadAgenda'
      text = if Meeting.agenda.empty?
        'there is nothing on the agenda'
      else
        'the agenda items are: ' + Meeting.agenda.map{|i| i[:agenda_item]}.join('. ')
      end
    when 'RecordAgendaItem'
      agenda_item = params[:request][:intent][:slots][:AgendaItem][:value]
      Meeting.add_agenda_item(agenda_item)
      text = "added #{agenda_item} to the agenda"
    when 'ReadActionList'
      text = 'the action items are: ' + Meeting.action_list.map {|i| i[:action]}.join('. ')
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
      text = if item.nil?
        'There is nothing left on the agenda'
      else
        "Moving on to #{item}"
      end
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
      text = if session_id == Session.get[:id] && Session.get[:state] == 'CastVote'
        Meeting.cast_vote(true)
        "voted yes"
      else
        'ok'
      end
    when 'AMAZON.NoIntent'
      session_id = params[:session][:sessionId]
      text = if session_id == Session.get[:id] && Session.get[:state] == 'CastVote'
        Meeting.cast_vote(false)
        "voted no"
      else
        'ok'
      end
    when "WhoAmI"
      timestamp = Time.parse params[:request][:timestamp]
      timestamp_sec = timestamp.to_i
      activities = AudioScraper.activities(timestamp - 1, timestamp + 1).select do |card|
          (card[:time]/1000).to_i == timestamp_sec
      end

      if activities.length == 0
          text = "Couldn't find audio."
          break
      end
      
      id = activities[0][:id]
      wav_uri = AudioScraper.wav_file id
      voices = VoiceRecognition.parse wav_uri

      text = "I think it is #{voices[0][:speaker]} speaking."
    end
    Response.speech(text, end_session: end_session)
  when 'SessionEndedRequest'
  end || {}

  logger.info "Response:\n#{JSON.pretty_generate response}"
  json response
end
