require 'optparse'
require 'serialport'
require 'rest-client'

HOST = 'localhost'
#HOST = 'https://panopticon.hal9k.dk'

ENTER = 'P250R12SGN'
NO_ENTRY = 'P100R30SRN'
WAIT = 'P10R0SGNN'
WARN = 'P5R0SGX10NX100RX100N'

def find_ports()
  r = {}
  for p in 0..1
    port = "/dev/ttyUSB#{p}"
    begin
      sp = SerialPort.new(port,
                          { 'baud' => 115200,
                            'data_bits' => 8,
                            'parity' => SerialPort::NONE
                          })
      if sp
        puts "Found #{port}"
        begin
          while true
            begin
              line = sp.gets
            end while !line || line.empty?
            puts "Got #{line}"
            line.strip!
            if line.include? "ACS"
              puts("Version: #{line}")
              if line.include? "UI"
                r['ui'] = sp
                break
              elsif line.include? "cardreader"
                r['reader'] = sp
                break
              end
            end
          end
        end
      end
    rescue
      # No port here
    end
  end
  return r
end

class Ui
  def initialize(port)
    @port = port
    @locked = true
    @color_map = {
      'white' => 'A',
      'blue' => 'B',
      'green' => 'C',
      'red' => 'D',
      'navy' => 'E',
      'darkblue' => 'F',
      'darkgreen' => 'G',
      'darkcyan' => 'H',
      'cyan' => 'I',
      'turquoise' => 'J',
      'indigo' => 'K',
      'darkred' => 'L',
      'olive' => 'M',
      'gray' => 'N',
      'grey' => 'O',
      'skyblue' => 'P',
      'blueviolet' => 'Q',
      'lightgreen' => 'R',
      'darkviolet' => 'S',
      'yellowgreen' => 'T',
      'brown' => 'U',
      'darkgray' => 'V',
      'darkgrey' => 'W',
      'sienna' => 'X',
      'lightblue' => 'Y',
      'greenyellow' => 'Z',
      'silver' => '[',
      'lightgray' => '\\',
      'lightgrey' => ']',
      'lightcyan' => '^',
      'violet' => '_',
      'azur' => '`',
      'beige' => 'a',
      'magenta' => 'b',
      'tomato' => 'c',
      'gold' => 'd',
      'orange' => 'e',
      'snow' => 'f',
      'yellow' => 'g'
    }
  end

  def clear()
    @port.puts("C")
  end

  def write(large, line, text, col = 'white')
    s = "#{large ? 'T' :'t'}#{('0'.ord+line).chr()}#{@color_map[col]}#{text}"
    puts("WRITE #{s}")
    @port.puts(s)
  end

  def set_lock_state(locked)
    @locked = locked
  end

  def unlock()
    puts "UNLOCKING"
  end
  
  def wait_response(s)
    begin
      line = @port.gets
    end while !line || line.empty?
    line.strip!
    #puts "Reply: #{line}"
    if line != "OK"
      puts "ERROR: Expected 'OK', got '#{line}' (in response to #{s})"
      Process.exit()
    end
  end

  def send_and_wait(s)
    #puts("Sending #{s}")
    @port.flush_input()
    @port.puts(s)
    wait_response(s)
  end
  
  def update()
    send_and_wait("L#{@locked ? '1' : '0'}")
    write(true, 6, @locked ? '         Locked' : '         Open', @locked ? 'red' : 'green')
    ct = DateTime.now.to_time.strftime("%H:%M")
    write(false, 12, ct, 'blue')
  end
end

class CardReader
  def initialize(port)
    @port = port
    @port.read_timeout = 10
    @last_card = ''
    @last_card_time = Time.now()
    @api_key = File.read('apikey.txt')
  end

  def set_ui(ui)
    @ui = ui
  end

  def update()
    line = @port.gets
    if !line || line.empty?
      return
    end
    line.strip!
    puts "CARD: #{line}"
    now = Time.now()
    if (line != @last_card) || (now - @last_card_time > 5)
      @last_card = line
      @last_card_time = now
      # Let user know we are doing something
      @port.puts(WAIT)
      allowed = nil
      begin
        response = RestClient::Request.execute(method: :post,
                                               url: "#{HOST}/api/v1/permissions",
                                               timeout: 10,
                                               payload: { api_token: @api_key,
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
            @port.puts(WARN)
          end
        end
      rescue SystemCallError => e  
        puts "#{e.class} Failed to connect to server"
        @port.puts(WARN)
      end
      if response
        if response == true
          @port.puts(ENTER)
          @ui.unlock()
        elsif response == false
          @port.puts(NO_ENTRY)
        else
          puts("Impossible! allowed is neither true nor false")
          @port.puts(WARN)
        end
      end
    end
  end

end # end CardReader

ports = find_ports()
if !ports['ui']
  puts("Fatal error: No UI found")
  Process.exit
end

ui = Ui.new(ports['ui'])

if !ports['reader']
  ui.clear();
  ui.write(true, 2, '    FATAL ERROR:', 'red')
  ui.write(true, 4, '  NO READER FOUND', 'red')
  puts("Fatal error: No card reader found")
  Process.exit
end

# - handle reader
# - handle keypad
# - handle lock state
# - update clock

reader = CardReader.new(ports['reader'])

while true
  ui.update()
  reader.update()
  sleep 1
end
