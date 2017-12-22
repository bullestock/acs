#include "SPI.h"
#include "TFT_22_ILI9225.h"

const int GREEN_SW_PIN = 5;
const int RED_SW_PIN = 6;

const int RELAY_PIN = 12;

const int TFT_RST = 8;
const int TFT_RS = 9;
const int TFT_CS = 10;   // SS
const int TFT_SDI = 11;  // MOSI
const int TFT_CLK = 13;  // SCK
const int TFT_LED = 7;

const int TFT_BRIGHTNESS = 200;

TFT_22_ILI9225 tft = TFT_22_ILI9225(TFT_RST, TFT_RS, TFT_CS, TFT_LED, TFT_BRIGHTNESS);

void setup()
{
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, 0);
  
  tft.begin();

  Serial.begin(115200);
  Serial.println("ACS firmware v 0.2");

  tft.drawRectangle(0, 0, tft.maxX() - 1, tft.maxY() - 1, COLOR_WHITE);
  tft.setFont(Terminal6x8);
  tft.drawText(10, 10, "hello!");
}

const int BUF_SIZE = 50;
char buf[BUF_SIZE+1];
int buf_index = 0;

int count = 0;

void loop()
{
    if (Serial.available())
    {
        // Command
        char c = Serial.read();
        if ((c == '\r') || (c == '\n'))
        {
            buf[buf_index+1] = 0;
            if (buf[0] == 'L')
            {
                // Control lock
                // L<on>
                digitalWrite(RELAY_PIN, buf[1] == '1');
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

    ++count;
    if (count > 10)
    {
        count = 0;
        Serial.print("S ");
        Serial.print(!digitalRead(RED_SW_PIN));
        Serial.println(!digitalRead(GREEN_SW_PIN));
    }
    
}
