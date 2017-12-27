require 'optparse'
require 'serialport'
require 'rest-client'

HOST = 'http://localhost'
#HOST = 'https://panopticon.hal9k.dk'

ENTER = 'P250R12SGN'
NO_ENTRY = 'P100R30SRN'
WAIT = 'P10R0SGNN'
WARN = 'P5R10SGX10NX100RX100N'

UNLOCK_PERIOD_S = 5*60 # 15*60
UNLOCK_WARN_S = 3*60 #10*60

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
            line.gsub!(/[^[:print:]]/i, '')
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
    @color_map = [
      'white',
      'blue',
      'green',
      'red',
      'navy',
      'darkblue',
      'darkgreen',
      'darkcyan',
      'cyan',
      'turquoise',
      'indigo',
      'darkred',
      'olive',
      'gray',
      'grey',
      'skyblue',
      'blueviolet',
      'lightgreen',
      'darkviolet',
      'yellowgreen',
      'brown',
      'darkgray',
      'darkgrey',
      'sienna',
      'lightblue',
      'greenyellow',
      'silver',
      'lightgray',
      'lightgrey',
      'lightcyan',
      'violet',
      'azure',
      'beige',
      'magenta',
      'tomato',
      'gold',
      'orange',
      'snow',
      'yellow'
    ]
    @last_time = ''
    @last_lock_state = ''
    @green_pressed_at = nil
    @unlocked_at = nil
    @last_warning_at = nil
  end

  def clear()
    send_and_wait("C")
  end

  def clear_line(large, line)
    send_and_wait(sprintf("#{large ? 'E' :'e'}%02d", line))
  end

  def write(large, erase, line, text, col = 'white')
    s = sprintf("#{large ? 'T' :'t'}%02d%02d%s%s",
                line, @color_map.find_index(col), erase ? '1' : '0', text)
    send_and_wait(s)
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
    if line != "OK #{s[0]}"
      puts "ERROR: Expected 'OK #{s[0]}', got '#{line}' (in response to #{s})"
      Process.exit()
    end
  end

  def send_and_wait(s)
    #puts("Sending #{s}")
    @port.flush_input()
    @port.puts(s)
    wait_response(s)
  end

  def read_keys()
    @port.flush_input()
    @port.puts("S")
    begin
      line = @port.gets
    end while !line || line.empty?
    line.strip!
    #puts "Reply: #{line}"
    if line[0] != "S"
      puts "ERROR: Expected 'Sxx', got '#{line}'"
      Process.exit()
    end
    return line[1] != '0', line[2] != '0'
  end
  
  def update()
    # Lock state
    if @lock_state == :locked
      send_and_wait("L0")
      write(true, true, STATUS, '         Locked', 'red')
    elsif @lock_state == :unlocked
      send_and_wait("L1")
      if !@last_warning_at
        write(true, true, STATUS, '          Open', 'green')
      end
    elsif @lock_state == :unlocking
      elapsed = Time.now - @unlock_time
      if elapsed > UNLOCK_TIME_SECS
        @lock_state = :locked
      else
        send_and_wait("L1")
        write(true, true, STATUS, '         Enter   ', 'blue')
      end
    else
      ui.clear();
      ui.write(true, false, 2, '    FATAL ERROR:', 'red')
      ui.write(true, false, 4, '  UNKNOWN LOCK STATE', 'red')
      puts("Fatal error: Unknown lock state")
      Process.exit
    end
    # Buttons
    red, green = read_keys()
    if red
      @lock_state = :locked
    elsif green
      if !@green_pressed_at
        @green_pressed_at = Time.now
      else
        green_pressed_for = Time.now - @green_pressed_at
        if green_pressed_for >= 1 and !@unlocked_at
          @lock_state = :unlocked
          @unlocked_at = Time.now
          puts("Unlocked at #{@unlocked_at}")
        end
      end
    else
      @green_pressed_at = nil
    end
    # Automatic locking
    if @unlocked_at
      unlocked_for = Time.now - @unlocked_at
      if unlocked_for >= UNLOCK_PERIOD_S
        @unlocked_at = nil
        @lock_state = :locked
        @last_warning_at = nil
      end
      if unlocked_for >= UNLOCK_WARN_S
        if !@last_warning_at
          @last_warning_at = @unlocked_at
        end
        since_last_warning = Time.now - @last_warning_at
        if since_last_warning > 20
          write(true, true, STATUS, "Locking in #{((UNLOCK_PERIOD_S - unlocked_for)/60).to_i} minutes", 'orange')
          @last_warning_at = Time.now
        end
      end
    end
    # Time display
    ct = DateTime.now.to_time.strftime("%H:%M")
    if ct != @last_time
      write(false, true, 12, ct, 'blue')
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
  ui.write(true, false, 2, '    FATAL ERROR:', 'red')
  ui.write(true, false, 4, '  NO READER FOUND', 'red')
  puts("Fatal error: No card reader found")
  Process.exit
end

# - handle keypad

reader = CardReader.new(ports['reader'])
reader.set_ui(ui)

while true
  ui.update()
  reader.update()
  sleep 1
end
