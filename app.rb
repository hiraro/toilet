require 'json'

require 'sinatra'
require 'sinatra-websocket'

def image(hp)
  return "/img/iphone/cracked.jpg" if hp < 0

  case hp
  when 1..200
    "/img/iphone/004.JPG"
  when 201..500
    "/img/iphone/003.jpg"
  when 501..800
    "/img/iphone/002.jpg"
  when 801..1000
    "/img/iphone/001.jpg"
  end
end

def damage(weapon_name)
  case weapon_name
  when "shoes"
    damage = 10
  when "geta"
    damage = 20
  when "hammer"
    damage = 60
  when "powerhammer"
    damage = 100
  end

  random = Random.new
  damage * random.rand(75..100) / 100
end

class Toilet < Sinatra::Application
  set :hp, 1000
  set :sockets, []

  def initialize
    super

    @hp = 1000
  end

  get '/' do
    send_file File.join(settings.public_folder, 'index.html') unless request.websocket?

    request.websocket do |ws|
      ws.onopen do
        settings.sockets << ws
        response_obj = {
          type: "status",
          status: {
            alive: (@hp >= 0),
            image: image(@hp)
          }
        }
        response = JSON.generate(response_obj)

      end

      ws.onmessage do |message|
        request = JSON.parse(message, { symbolize_names: true })
        p request
        type = request.dig(:type)

        case type
        when "attack"
          if request.dig(:attack, :name) && request.dig(:attack, :weapon)
            attacker = request[:attack][:name]
            weapon = request[:attack][:weapon]
            damage_occured = damage(weapon)
            @hp -= damage_occured

            response_obj = {
              type: "status",
              status: {
                alive: (@hp >= 0),
                image: image(@hp),
                last_attack: {
                  name: attacker,
                  damage: damage_occured
                }
              }
            }
            response = JSON.generate(response_obj)
            p @hp

            EM.next_tick {
              settings.sockets.each do |socket|
                socket.send(response)
              end
            }
          end
        end
      end

      ws.onclose do
        settings.sockets.delete(ws)
      end
    end

  end
end
