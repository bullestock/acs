require 'optparse'
require 'serialport'
require 'rest-client'

OptionParser.new do |opts|
  opts.banner = "Usage: door.rb [options] [port]"

  opts.on("-v", "--verbose", "Verbose") do |n|
    $verbose = true
  end
end.parse!

api_key = File.read('apikey.txt')

HOST = 'localhost'
#HOST = 'https://panopticon.hal9k.dk'

ENTER = 'P250R12SGN'
NO_ENTRY = 'P100R30SRN'
WAIT = 'P10R0SGNN'
WARN = 'P5R0SGX10NX100RX100N'

def find_port()
  for p in 0..1
    port = "/dev/ttyUSB#{p}"
    puts "Trying #{port}"
    sp = SerialPort.new(port
                        { 'baud' => 115200,
                          'data_bits' => 8,
                          'parity' => SerialPort::NONE
                        })
    begin
      line = $sp.gets
    end while !line || line.empty?
    line.strip!
    puts "Response: $line"
  end
end

port = '/dev/ttyUSB0'
if ARGV.size > 0
  port = ARGV[0]
else
  port = find_port()
end

sp = SerialPort.new(port,
                    { 'baud' => 115200,
                      'data_bits' => 8,
                      'parity' => SerialPort::NONE
                    })
line = sp.gets
puts("Version: #{line}")

last_card = ''
last_card_time = Time.now()
while true
  begin
    line = sp.gets
  end while !line || line.empty?
  line.strip!
  puts "CARD: #{line}"
  now = Time.now()
  if (line != last_card) || (now - last_card_time > 5)
    last_card = line
    last_card_time = now
    # Let user know we are doing something
    sp.puts(WAIT)
    allowed = nil
    begin
      response = RestClient::Request.execute(method: :post,
                                             url: "#{HOST}/api/v1/permissions",
                                             timeout: 10,
                                             payload: { api_token: api_key,
                                                        card_id: line
                                                      },
                                             headers: {
                                               'Content-Type': 'application/json',
                                                       'Accept': 'application/json'
                                             })
      if response.body
        begin
          j = JSON.parse(response.body)
          allowed = j['allowed']
          user_id = j["id"]
        rescue JSON::ParserError => e
          puts("Bad JSON received: #{response.body}")
          sp.puts(WARN)
        end
      end
    rescue SystemCallError => e  
      puts "#{e.class} Failed to connect to server"
      sp.puts(WARN)
    end
    if response
      if response == true
        sp.puts(ENTER)
      elsif response == false
        sp.puts(NO_ENTRY)
      else
        puts("Impossible! allowed is neither true nor false")
        sp.puts(WARN)
      end
    end
  end
end
