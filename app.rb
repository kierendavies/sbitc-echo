require 'sinatra'
require 'sinatra/json'
require 'sinatra/reloader' if development?

require 'json'
require 'active_support'
require 'active_support/core_ext'

require 'pp'

require './audio_scraper/audio_scraper'

get '/' do
  cards = AudioScraper.get_cards
  cards.map do |card|
      card[:id]
  end.join
end

post '/echo' do
  request.body.rewind
  @params = JSON.parse(request.body.read).with_indifferent_access

  # case params[]

  json({
    response: {
      outputSpeech: {
        type: 'PlainText',
        text: 'recording meeting minutes, starting now'
      },
      shouldEndSession: true
    }
  })
end
