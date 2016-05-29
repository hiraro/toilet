require 'json'

require 'sinatra'
require 'sinatra-websocket'

def image(damage)
  "/img/iphone/cracked.jpg" if damage < 0

  case damage
  when 1..200
    "/img/iphone/001.png"
  when 201..500
    "/img/iphone/002.png"
  when 501..800
    "/img/iphone/003.png"
  when 801..1000
    "/img/iphone/004.png"
  end
end

def damage(weapon_name)
  100
end

class Toilet < Sinatra::Application
  set :hp, 1000
  set :clients, []

  get '/' do
    halt 404 unless request.websocket?

    request.websocket do |ws|
      ws.onopen do
        settings.clients << ws

      end

      ws.onmessage do |message|
        request = JSON.parse(message, symbolize_keys: true)
        type = response.dig(:type)

        case type
        when "attack"
          if response.dig(:attack, :name) && response.dig(:attack, :weapon)
            attacker = response[:attack][:name]
            weapon = response[:attack][:weapon]
            damage = damage(weapon)
            set settings.hp, settings.hp - damage

            response_obj = {
              type: "status",
              status: {
                alive: true,
                image: image(damage),
                last_attack: {
                  name: attacker,
                  damage: damage
                }
              }
            }
            response = JSON.generate(response)

            EM.next_tick {
              settings.sockets.each do |socket|
                socket.send(response)
              end
            }
          end
        end
      end
    end

    ws.onclose do |ws|
      settings.sockets.delete(ws)
    end
  end
end
end
