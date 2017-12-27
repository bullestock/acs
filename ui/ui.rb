require 'optparse'
require 'serialport'
require 'rest-client'

HOST = 'http://localhost'
#HOST = 'https://panopticon.hal9k.dk'

ENTER = 'P250R12SGN'
NO_ENTRY = 'P100R30SRN'
WAIT = 'P10R0SGNN'
WARN = 'P5R10SGX10NX100RX100N'

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
  STATUS = 6 # Display line for lock status
  UNLOCK_TIME_SECS = 3 # How long to keep the door open after valid card is presented
  
  def initialize(port)
    @port = port
    @lock_state = :locked
    @unlock_time = nil
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
    @last_time = ''
    @last_lock_state = ''
  end

  def clear()
    @port.puts("C")
  end

  def clear_line(large, line)
    line_ch = ('0'.ord+line).chr()
    @port.puts("#{large ? 'E' :'e'}#{line_ch}")
  end

  def write(large, line, text, col = 'white')
    line_ch = ('0'.ord+line).chr()
    s = "#{large ? 'T' :'t'}#{line_ch}#{@color_map[col]}#{text}"
    #puts("WRITE #{s}")
    @port.puts(s)
  end

  def set_lock_state(locked)
    @lock_state = locked ? :locked : :unlocked
  end

  def unlock()
    @lock_state = :unlocking
    @unlock_time = Time.now
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
    puts("Last #{@last_lock_state} current #{@lock_state}")
    if @last_lock_state != @lock_state
      clear_line(true, STATUS)
      @last_lock_state = @lock_state
    end
    if @lock_state == :locked
      send_and_wait("L0")
      write(true, STATUS, '         Locked', 'red')
    elsif @lock_state == :unlocked
      send_and_wait("L1")
      write(true, STATUS, '         Open', 'green')
    elsif @lock_state == :unlocking
      elapsed = Time.now - @unlock_time
      if elapsed > UNLOCK_TIME_SECS
        @lock_state = :locked
      else
        send_and_wait("L1")
        write(true, STATUS, '         Enter   ', 'blue')
      end
    else
      ui.clear();
      ui.write(true, 2, '    FATAL ERROR:', 'red')
      ui.write(true, 4, '  UNKNOWN LOCK STATE', 'red')
      puts("Fatal error: Unknown lock state")
      Process.exit
    end
    ct = DateTime.now.to_time.strftime("%H:%M")
    if ct != @last_time
      clear_line(true, 12)
      write(false, 12, ct, 'blue')
      @last_time = ct
    end
  end
end

class CardReader
  def initialize(port)
    @port = port
    @port.read_timeout = 10
    @last_card = ''
    @last_card_time = Time.now()
    @api_key = File.read('apikey.txt').strip()
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
    if line.length != 10
      puts "Invalid card ID: #{line}"
      line = ''
    end
    now = Time.now()
    if !line.empty? && ((line != @last_card) || (now - @last_card_time > 5))
      puts "Card ID: #{line}"
      @last_card = line
      @last_card_time = now
      # Let user know we are doing something
      @port.puts(WAIT)
      rest_start = Time.now
      allowed = nil
      begin
        url = "#{HOST}/api/v1/permissions"
        puts("URL #{url}")
        response = RestClient::Request.execute(method: :post,
                                               url: url,
                                               timeout: 60,
                                               payload: { api_token: @api_key,
                                                          card_id: line
                                                        }.to_json(),
                                               headers: {
                                                 'Content-Type': 'application/json',
                                                 'Accept': 'application/json'
                                               })
        puts("Got server reply in #{Time.now - rest_start} s")
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
      rescue Exception => e  
        puts "#{e.class} Failed to connect to server"
        @port.puts(WARN)
      end
      if allowed
        if allowed == true
          @port.puts(ENTER)
          @ui.unlock()
        elsif allowed == false
          @port.puts(NO_ENTRY)
        else
          puts("Impossible! allowed is neither true nor false: #{allowed}")
          @port.puts(WARN)
        end
      end
      # TODO: Add log entry
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

# - handle keypad

reader = CardReader.new(ports['reader'])
reader.set_ui(ui)

while true
  ui.update()
  reader.update()
  sleep 0.5
end
