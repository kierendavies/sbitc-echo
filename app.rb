require 'sinatra'
require 'sinatra/json'
require 'sinatra/reloader' if development?

require 'json'
require 'active_support'
require 'active_support/core_ext'

require 'pp'

get '/' do
  'It works!'
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
