require 'json'

require 'sinatra'
require 'sinatra-websocket'

class Client
end

class Toilet < Sinatra::Application
  set :clients, []

  get '/' do
    halt 404 unless request.websocket?

    request.websocket do |ws|
      ws.onopen do
        settings.clients << ws
      end

      ws.onmessage do |message|
        p message
        settings.sockets.each do |socket|
        end
      end

      ws.onclose do |ws|
        settings.sockets.delete(ws)
      end
    end
  end
end
