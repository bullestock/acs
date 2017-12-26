// Note: Use https://github.com/MicroBahner/TFT_22_ILI9225

#include "SPI.h"
#include "TFT_22_ILI9225.h"

#include "animater.h"

const char* version = "0.0.2";

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

const int lcd_top = 38;
const int lcd_line_height_large = 18;
const int lcd_line_height_small = 10;
const int lcd_last_large_line = (ILI9225_LCD_WIDTH - lcd_top)/lcd_line_height_large - 1;
const int lcd_last_small_line = (ILI9225_LCD_WIDTH - lcd_top)/lcd_line_height_small - 1;

Animater anim(tft);

void setup()
{
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, 0);
  
  tft.begin();

  Serial.begin(115200);
  Serial.print("ACS UI v ");
  Serial.println(version);

  tft.setOrientation(1);
  tft.setFont(Terminal12x16);
  tft.clear();
  tft.setBackgroundColor(COLOR_BLACK);

  randomSeed(analogRead(0));
}

const int BUF_SIZE = 50;
char buf[BUF_SIZE+1];
int buf_index = 0;

const int colours[] =
{
    static_cast<int>(COLOR_WHITE),
    static_cast<int>(COLOR_BLUE),
    static_cast<int>(COLOR_GREEN),
    static_cast<int>(COLOR_RED),
    static_cast<int>(COLOR_NAVY),
    static_cast<int>(COLOR_DARKBLUE),
    static_cast<int>(COLOR_DARKGREEN),
    static_cast<int>(COLOR_DARKCYAN),
    static_cast<int>(COLOR_CYAN),
    static_cast<int>(COLOR_TURQUOISE),
    static_cast<int>(COLOR_INDIGO),
    static_cast<int>(COLOR_DARKRED),
    static_cast<int>(COLOR_OLIVE),
    static_cast<int>(COLOR_GRAY),
    static_cast<int>(COLOR_GREY),
    static_cast<int>(COLOR_SKYBLUE),
    static_cast<int>(COLOR_BLUEVIOLET),
    static_cast<int>(COLOR_LIGHTGREEN),
    static_cast<int>(COLOR_DARKVIOLET),
    static_cast<int>(COLOR_YELLOWGREEN),
    static_cast<int>(COLOR_BROWN),
    static_cast<int>(COLOR_DARKGRAY),
    static_cast<int>(COLOR_DARKGREY),
    static_cast<int>(COLOR_SIENNA),
    static_cast<int>(COLOR_LIGHTBLUE),
    static_cast<int>(COLOR_GREENYELLOW),
    static_cast<int>(COLOR_SILVER),
    static_cast<int>(COLOR_LIGHTGRAY),
    static_cast<int>(COLOR_LIGHTGREY),
    static_cast<int>(COLOR_LIGHTCYAN),
    static_cast<int>(COLOR_VIOLET),
    static_cast<int>(COLOR_AZUR),
    static_cast<int>(COLOR_BEIGE),
    static_cast<int>(COLOR_MAGENTA),
    static_cast<int>(COLOR_TOMATO),
    static_cast<int>(COLOR_GOLD),
    static_cast<int>(COLOR_ORANGE),
    static_cast<int>(COLOR_SNOW),
    static_cast<int>(COLOR_YELLOW)
};

bool drawn_logo = false;

void loop()
{
    if (Serial.available())
    {
        // Command
        char c = Serial.read();
        if ((c == '\r') || (c == '\n'))
        {
            buf[buf_index+1] = 0;
            switch (buf[0])
            {
            case 'L':
                // Control lock
                // L<on>
                digitalWrite(RELAY_PIN, buf[1] == '1');
                Serial.println("OK");
                break;
            case 'C':
                // Clear screen
                if (!drawn_logo)
                {
                    drawn_logo = true;
                    anim.reset();
                }
                else
                    tft.fillRectangle(0, lcd_top, ILI9225_LCD_HEIGHT-1, ILI9225_LCD_WIDTH-1, COLOR_BLACK);
                Serial.println("OK");
                break;
            case 'E':
                {
                    // Erase large line
                    // E<line>
                    const int line = buf[1] - '0';
                    if ((line < 0) || (line > lcd_last_large_line))
                    {
                        Serial.println("Bad line number");
                        break;
                    }
                    tft.fillRectangle(0, lcd_top+line*lcd_line_height_large,
                                      ILI9225_LCD_HEIGHT-1, lcd_top+(line+1)*lcd_line_height_large,
                                      COLOR_BLACK);
                    Serial.println("OK");
                }
                break;
            case 'e':
                {
                    // Erase small line
                    // e<line>
                    const int line = buf[1] - '0';
                    if ((line < 0) || (line > lcd_last_large_line))
                    {
                        Serial.println("Bad line number");
                        break;
                    }
                    tft.fillRectangle(0, lcd_top+line*lcd_line_height_small,
                                      ILI9225_LCD_HEIGHT-1, lcd_top+(line+1)*lcd_line_height_small,
                                      COLOR_BLACK);
                    Serial.println("OK");
                }
                break;
            case 'T':
                {
                    // Large text
                    // T<line><colour><text>
                    const int line = buf[1] - '0';
                    if ((line < 0) || (line > lcd_last_large_line))
                    {
                        Serial.println("Bad line number");
                        break;
                    }
                    const int col = buf[2] - 'A';
                    if ((col < 0) || (col > static_cast<int>(sizeof(colours)/sizeof(colours[0]))))
                    {
                        Serial.println("Bad colour");
                        break;
                    }
                    tft.setFont(Terminal12x16);
                    tft.drawText(0, lcd_top+line*lcd_line_height_large, String(buf+3), colours[col]);
                    Serial.println("OK");
                }
                break;
            case 't':
                {
                    // Small text
                    // t<line><colour><text>
                    const int line = buf[1] - '0';
                    if ((line < 0) || (line > lcd_last_small_line))
                    {
                        Serial.println("Bad line number");
                        break;
                    }
                    const int col = buf[2] - 'A';
                    if ((col < 0) || (col > static_cast<int>(sizeof(colours)/sizeof(colours[0]))))
                    {
                        Serial.println("Bad colour");
                        break;
                    }
                    tft.setFont(Terminal6x8);
                    tft.drawText(0, lcd_top+line*lcd_line_height_small, String(buf+3), colours[col]);
                    Serial.println("OK");
                }
                break;

            case 'S':
                Serial.print("S ");
                Serial.print(!digitalRead(RED_SW_PIN));
                Serial.println(!digitalRead(GREEN_SW_PIN));
                break;
                
            default:
                Serial.println("Unknown command");
                break;
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
    anim.update();
}
