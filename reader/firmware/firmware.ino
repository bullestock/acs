#include <ctype.h>

#include <RDM6300.h>
#include <SoftwareSerial.h>

// TX is not connected
const int PIN_RX = 3;
const int PIN_TX = A5;
const int PIN_GREEN = 2;
const int PIN_RED = 4;
const int PIN_LED = 13;

SoftwareSerial swSerial(PIN_RX, PIN_TX);

void setup()
{
    Serial.begin(115200);
    Serial.println("Cardreader v 0.5");
    swSerial.begin(9600);

    pinMode(PIN_GREEN, OUTPUT);
    pinMode(PIN_RED, OUTPUT);
}

RDM6300 decoder;
int n = 0;

const int MAX_SEQ_SIZE = 500;
enum class Sequence
{
    Red,
    Green,
    Both,
    None
};
char sequence[MAX_SEQ_SIZE];
int sequence_len = 0;
int sequence_index = 0;
int sequence_period = 1;
int delay_counter = 0;
int sequence_repeats = 1; // to force idle sequence on startup
int sequence_iteration = 0;

bool parse_int(const char* line, int& index, int& value)
{
    if (!isdigit(line[index]))
    {
        Serial.print("Expected number, got ");
        Serial.println(line[index]);
        return false;
    }
    value = 0;
    while (isdigit(line[index]))
    {
        value = value*10 + line[index] - '0';
        ++index;
    }
    return true;
}

bool fill_seq(char* seq, int& index, int reps, Sequence elem)
{
    while (reps--)
    {
        if (index >= MAX_SEQ_SIZE)
        {
            Serial.println("Sequence too long");
            return false;
        }
        seq[index++] = (char) elem;
    }
    return true;
}

void decode_line(const char* line)
{
    int i = 0;
    if (tolower(line[i]) != 'p')
    {
        Serial.println("Line must begin with P");
        return;
    }
    ++i;
    int period = 0;
    if (!parse_int(line, i, period))
    {
        Serial.println("Period must follow P");
        return;
    }
    if (period <= 0)
    {
        Serial.println("Period cannot be zero");
        return;
    }
    if (tolower(line[i]) != 'r')
    {
        Serial.print("Period must be followed by R, got ");
        Serial.println(line[i]);
        return;
    }
    ++i;
    int repeats = 0;
    if (!parse_int(line, i, repeats))
    {
        Serial.println("Repeats must follow R");
        return;
    }
    if (tolower(line[i]) != 's')
    {
        Serial.print("Repeats must be followed by S, got ");
        Serial.println(line[i]);
        return;
    }
    ++i;
    char seq[MAX_SEQ_SIZE];
    int seq_len = 0;
    while (line[i])
    {
        if (seq_len == MAX_SEQ_SIZE)
        {
            Serial.println("Sequence too long");
            return;
        }
        switch (tolower(line[i]))
        {
        case 'r':
            seq[seq_len++] = (char) Sequence::Red;
            break;
        case 'g':
            seq[seq_len++] = (char) Sequence::Green;
            break;
        case 'b':
            seq[seq_len++] = (char) Sequence::Both;
            break;
        case 'n':
            seq[seq_len++] = (char) Sequence::None;
            break;
        case 'x':
            {
                int reps = 0;
                ++i;
                if (!parse_int(line, i, reps))
                {
                    Serial.println("X must be followed by repeats");
                    return;
                }
                switch (tolower(line[i]))
                {
                case 'r':
                    if (!fill_seq(seq, seq_len, reps, Sequence::Red))
                        return;
                    break;
                case 'g':
                    if (!fill_seq(seq, seq_len, reps, Sequence::Green))
                        return;
                    break;
                case 'b':
                    if (!fill_seq(seq, seq_len, reps, Sequence::Both))
                        return;
                    break;
                case 'n':
                    if (!fill_seq(seq, seq_len, reps, Sequence::None))
                        return;
                    break;
                default:
                    Serial.print("Unexpected character after X: ");
                    Serial.println(line[i]);
                    return;
                }
            }
            break;
        default:
            Serial.print("Unexpected sequence character: ");
            Serial.println(line[i]);
            return;
        }
        ++i;
    }
    sequence_index = 0;
    sequence_period = period;
    sequence_repeats = repeats;
    sequence_iteration = 0;
    for (int i = 0; i < seq_len; ++i)
        sequence[i] = seq[i];
    sequence_len = seq_len;
}

const int MAX_LINE_LENGTH = 80;
char line[MAX_LINE_LENGTH+1];
int line_len = 0;

unsigned long card_flash_start = 0;
bool card_flash_active = false;

void loop()
{
    delay(1);

    const auto c = swSerial.read();
    if (c > 0)
        if (decoder.add_byte(c))
        {
            Serial.println(decoder.get_id());
            card_flash_active = true;
            card_flash_start = millis();
        }

    if (card_flash_active)
    {
        digitalWrite(PIN_GREEN, true);
        digitalWrite(PIN_RED, true);
        delay(10);
        if (millis() - card_flash_start > 1000)
            card_flash_active = false;
        return;
    }

    if (++delay_counter < sequence_period)
        return;
    delay_counter = 0;
       
    if (Serial.available())
    {
        const char c = Serial.read();
        if ((c == '\r') || (c == '\n'))
        {
            line[line_len] = 0;
            line_len = 0;
            decode_line(line);
        }
        else if (line_len < MAX_LINE_LENGTH)
            line[line_len++] = c;
        else
        {
            Serial.println("Line too long");
            line_len = 0;
        }
    }

    if (sequence_index >= sequence_len)
    {
        sequence_index = 0;
        if (sequence_repeats > 0)
        {
            if (sequence_iteration >= sequence_repeats)
            {
                // Done
                digitalWrite(PIN_GREEN, false);
                digitalWrite(PIN_RED, false);
                sequence_len = 0;
                decode_line("P5R0SGX199N");
                return;
            }
            ++sequence_iteration;
        }
    }
    if (sequence_index < sequence_len)
    {
        switch ((Sequence) sequence[sequence_index++])
        {
        case Sequence::Red:
            digitalWrite(PIN_GREEN, false);
            digitalWrite(PIN_RED, true);
            break;
        case Sequence::Green:
            digitalWrite(PIN_GREEN, true);
            digitalWrite(PIN_RED, false);
            break;
        case Sequence::Both:
            digitalWrite(PIN_GREEN, true);
            digitalWrite(PIN_RED, true);
            break;
        case Sequence::None:
            digitalWrite(PIN_GREEN, false);
            digitalWrite(PIN_RED, false);
            break;
        }
    }
    digitalWrite(PIN_LED, (sequence_index % 2) == 0);
}
