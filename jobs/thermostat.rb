require 'net/http'
require 'json'
require 'yaml'

APP_CONFIG ||= YAML.load_file( File.join(Sinatra::Application.root, 'config.yml') )
#search_term = URI::encode("#{APP_CONFIG['thermostatIP']}")

SCHEDULER.every '10s', :first_in => 0 do |job|
#  page = HTTParty.get("http://#{APP_CONFIG['thermostatIP']}/tstat").body rescue nil
#  status = JSON.parse(page) rescue nil

  http = Net::HTTP.new("#{APP_CONFIG['thermostatIP']}")
  response = http.request(Net::HTTP::Get.new("/tstat")) rescue nil
  status = JSON.parse(response.body) rescue nil

  device_type = 'filtrete ct50'
  current_temp = '0'
  target_temp = '0'
  current_status = 'offline'

  if status
    #returnStatus[returnStatus.length] = "The temperature is currently #{status["temp"]} degrees."
    current_temp = "#{status["temp"]} degrees"
    if status["tmode"] != 0
      device_type = (status["tmode"] == 1 ? "heater" : "air conditioner")
      target_temp = (status["tmode"] == 1 ? status["t_heat"] : status["t_cool"])

      #returnStatus[returnStatus.length] =  "The #{device_type} is set to engage at #{target_temp} degrees."

      if status["tstate"] == 0
        current_status = "The #{device_type} is off."
      elsif (status["tmode"] == 1 and status["tstate"] == 1) or (status["tmode"] == 2 and status["tstate"] == 2)
        current_status =  "The #{device_type} is running."
      end
    end
  end

  thermostat_info = {title: "#{device_type}", text:"Current: #{current_temp}<br/>Target: #{target_temp}", moreinfo: "#{current_status}"}
  send_event('thermostat_info', thermostat_info)

end
