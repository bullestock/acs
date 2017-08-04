#include "FastLED.h"

#define BRIGHTNESS  255
#define LED_TYPE    WS2811
#define COLOR_ORDER RGB

CRGB led;
int r = 255;
int g = 255;
int b = 0;
int r2 = 128, g2 = 0, b2 = 128;
bool first_colour = true;
int iterations = 0;
int blink_speed = 40;
enum State
{
    STATE_STEADY,
    STATE_BLINK
};

State state = STATE_BLINK;

const int LED_PIN = 2;
const int GREEN_SW_PIN = 10;
const int RED_SW_PIN = 11;

void setup()
{
  FastLED.addLeds<WS2811, LED_PIN, COLOR_ORDER>(&led, 1).setCorrection(TypicalLEDStrip);
  FastLED.setBrightness(BRIGHTNESS);

  Serial.begin(115200);
  Serial.println("ACS firmware v 0.1");
}

const int BUF_SIZE = 50;
char buf[BUF_SIZE+1];
int buf_index = 0;

int count = 0;

int get_color(const char* buf, int offset)
{
    return (buf[offset] - '0')*100 + (buf[offset+1] - '0')*10 + (buf[offset+2] - '0');
}

void loop()
{
    if (Serial.available())
    {
        // Command
        char c = Serial.read();
        if ((c == '\r') || (c == '\n'))
        {
            buf[buf_index+1] = 0;
            if (buf[0] == 'C')
            {
                r = get_color(buf, 1);
                g = get_color(buf, 4);
                b = get_color(buf, 7);
                state = STATE_STEADY;
            }
            else if (buf[0] == 'B')
            {
                r = get_color(buf, 1);
                g = get_color(buf, 4);
                b = get_color(buf, 7);
                r2 = get_color(buf, 10);
                g2 = get_color(buf, 13);
                b2 = get_color(buf, 16);
                state = STATE_BLINK;
            }
            else if (buf[0] == 'D')
            {
                blink_speed = get_color(buf, 1);
            }
            else
            {
                Serial.println("Unknown command");
            }
            buf_index = 0;
        }
        else
        {
            if (buf_index >= BUF_SIZE)
            {
                Serial.println("Error: Line too long");
                buf_index = 0;
                return;
            }
            buf[buf_index++] = c;
        }
    }

    switch (state)
    {
    case STATE_STEADY:
        led.r = r; led.g = g; led.b = b;
        break;

    case STATE_BLINK:
        if (first_colour)
        {
            led.r = r; led.g = g; led.b = b;
        }
        else
        {
            led.r = r2; led.g = g2; led.b = b2;
        }
        if (++iterations > blink_speed)
        {
            iterations = 0;
            first_colour = !first_colour;
        }
        break;
    }

    ++count;
    if (count > 10)
    {
        count = 0;
        Serial.print("S ");
        Serial.print(!digitalRead(RED_SW_PIN));
        Serial.println(!digitalRead(GREEN_SW_PIN));
    }
    
    FastLED.show();
    FastLED.delay(1);
}
