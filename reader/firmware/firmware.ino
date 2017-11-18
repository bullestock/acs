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
    Serial.println("Cardreader v 0.2");
    swSerial.begin(9600);

    pinMode(PIN_GREEN, OUTPUT);
    pinMode(PIN_RED, OUTPUT);
}

RDM6300 decoder;
int n = 0;

enum State
{
    STATE_IDLE,
    STATE_ERROR,
    STATE_ENTER
};

State state = STATE_IDLE;
unsigned long last_state_tick = 0;

const unsigned long STATE_DURATION = 3000;

void loop()
{
    const auto c = swSerial.read();
    if (c > 0)
        if (decoder.add_byte(c))
            Serial.println(decoder.get_id());

    if (Serial.available())
    {
        const char c = Serial.read();
        switch (c)
        {
        case 'E':
            // Error
            state = STATE_ERROR;
            last_state_tick = millis();
            break;

        case 'A':
            // Entry allowed
            state = STATE_ENTER;
            last_state_tick = millis();
            break;

        default:
            break;
        }
    }

    switch (state)
    {
    case STATE_IDLE:
        {
            const bool green_on = n > 995;
            digitalWrite(PIN_LED, green_on);
            digitalWrite(PIN_GREEN, green_on);
            digitalWrite(PIN_RED, false);
        }
        break;

    case STATE_ERROR:
        {
            const bool red_on = (n % 200) > 100;
            digitalWrite(PIN_LED, false);
            digitalWrite(PIN_GREEN, false);
            digitalWrite(PIN_RED, red_on);
        }
        break;

    case STATE_ENTER:
        {
            const bool green_on = (n % 500) > 250;
            digitalWrite(PIN_LED, green_on);
            digitalWrite(PIN_GREEN, green_on);
            digitalWrite(PIN_RED, false);
        }
        break;
    }

    if (state != STATE_IDLE)
    {
        const auto elapsed = millis() - last_state_tick;
        if (elapsed >= STATE_DURATION)
            state = STATE_IDLE;
    }
    
    if (++n > 1000)
        n = 0;
    delay(1);
}
