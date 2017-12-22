#include "SPI.h"
#include "TFT_22_ILI9225.h"

#include "logo.h"

const char* version = "0.0.1";

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
const int lcd_last_large_line = (ILI9225_LCD_HEIGHT - lcd_top)/lcd_line_height_large - 1;
const int lcd_last_small_line = (ILI9225_LCD_HEIGHT - lcd_top)/lcd_line_height_small - 1;

void setup()
{
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, 0);
  
  tft.begin();

  Serial.begin(115200);
  Serial.print("ACS firmware v ");
  Serial.println(version);

  tft.setOrientation(1);
  tft.setFont(Terminal12x16);
  tft.clear();
  tft.setBackgroundColor(COLOR_BLACK);
  tft.drawBitmap(0, 0, logo_large_a, 220, 62, COLOR_WHITE);
  tft.drawBitmap(0, 66, logo_large_b, 220, 60, COLOR_RED);
  tft.drawText(30, 140, "Access Control", COLOR_GREEN);
  tft.setFont(Terminal6x8);
  tft.drawText(100, 158, version, COLOR_GREEN);

  delay(2000);
  tft.clear();
  tft.drawBitmap(0, 0, logo_small_a, 132, 36, COLOR_WHITE);
  tft.drawBitmap(220-86, 0, logo_small_b, 86, 36, COLOR_RED);
  tft.setFont(Terminal12x16);
  tft.drawText(80, 140, "Waiting...", COLOR_GREEN);
}

const int BUF_SIZE = 50;
char buf[BUF_SIZE+1];
int buf_index = 0;

int count = 0;

const int colours[] =
{
    COLOR_WHITE,
    COLOR_BLUE,
    COLOR_GREEN,
    COLOR_RED,
    COLOR_NAVY,
    COLOR_DARKBLUE,
    COLOR_DARKGREEN,
    COLOR_DARKCYAN,
    COLOR_CYAN,
    COLOR_TURQUOISE,
    COLOR_INDIGO,
    COLOR_DARKRED,
    COLOR_OLIVE,
    COLOR_GRAY,
    COLOR_GREY,
    COLOR_SKYBLUE,
    COLOR_BLUEVIOLET,
    COLOR_LIGHTGREEN,
    COLOR_DARKVIOLET,
    COLOR_YELLOWGREEN,
    COLOR_BROWN,
    COLOR_DARKGRAY,
    COLOR_DARKGREY,
    COLOR_SIENNA,
    COLOR_LIGHTBLUE,
    COLOR_GREENYELLOW,
    COLOR_SILVER,
    COLOR_LIGHTGRAY,
    COLOR_LIGHTGREY,
    COLOR_LIGHTCYAN,
    COLOR_VIOLET,
    COLOR_AZUR,
    COLOR_BEIGE,
    COLOR_MAGENTA,
    COLOR_TOMATO,
    COLOR_GOLD,
    COLOR_ORANGE,
    COLOR_SNOW,
    COLOR_YELLOW
};

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
                break;
            case 'C':
                // Clear screen
                tft.fillRectangle(0, lcd_top, ILI9225_LCD_HEIGHT-1, ILI9225_LCD_WIDTH-1, COLOR_BLACK);
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
                    if ((col < 0) || (col > sizeof(colours)/sizeof(colours[0])))
                    {
                        Serial.println("Bad colour");
                        break;
                    }
                    tft.setFont(Terminal12x16);
                    tft.drawText(0, lcd_top+line*lcd_line_height_large, String(buf+3), colours[col]);
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
                    if ((col < 0) || (col > sizeof(colours)/sizeof(colours[0])))
                    {
                        Serial.println("Bad colour");
                        break;
                    }
                    tft.setFont(Terminal6x8);
                    tft.drawText(0, lcd_top+line*lcd_line_height_small, String(buf+3), colours[col]);
                }
                break;
            default:
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
