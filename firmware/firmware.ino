// Note: Use https://github.com/MicroBahner/TFT_22_ILI9225

#include "SPI.h"
#include "TFT_22_ILI9225.h"

#include "logo.h"

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

class Animater
{
public:
    void reset()
    {
        count = 0;
        large_logo = false;
        height = 36;
        tft.clear();
        drawSmallLogo(0, 0);
    }

    void next()
    {
        ++mode;
        count = 0;
    }

    void drawLogo(int x_offset, int y_offset)
    {
        if (large_logo)
            drawLargeLogo(x_offset, y_offset);
        else
            drawSmallLogo(x_offset, y_offset);
    }

    void drawLargeLogo(int x_offset, int y_offset)
    {
        if ((x_offset == 0) && (y_offset == 0))
        {
            tft.drawBitmap(0, 0, logo_large_a, 220, 62, COLOR_WHITE, COLOR_BLACK);
            tft.drawBitmap(0, 66, logo_large_b, 220, 60, COLOR_RED, COLOR_BLACK);
            return;
        }
        if (x_offset > 0)
            tft.fillRectangle(x_offset-1, 0, x_offset-1, 62, COLOR_BLACK);
        if (y_offset > 0)
            tft.fillRectangle(0, y_offset-1, ILI9225_LCD_HEIGHT-1, y_offset-1, COLOR_BLACK);
        int h = 62;
        if (y_offset+h >= height)
            h = height - y_offset;
        tft.drawBitmap(x_offset, y_offset, logo_large_a, 220, h, COLOR_WHITE, COLOR_BLACK);
        h = 60;
        if (y_offset+66+h >= height)
            h = height - 66 - y_offset;
        if (y_offset < height-60)
            tft.drawBitmap(x_offset, y_offset+66, logo_large_b, 220, h, COLOR_RED, COLOR_BLACK);
    }

    void drawSmallLogo(int x_offset, int y_offset)
    {
        if ((x_offset == 0) && (y_offset == 0))
        {
            tft.drawBitmap(0, 0, logo_small_a, 132, 36, COLOR_WHITE);
            tft.drawBitmap(220-86, 0, logo_small_b, 86, 36, COLOR_RED);
            return;
        }
        tft.fillRectangle(x_offset-1, 0, x_offset-1, 36, COLOR_BLACK);
        tft.drawBitmap(x_offset, 0, logo_small_a, 132, 36, COLOR_WHITE, COLOR_BLACK);
        if (x_offset < 220-86)
            tft.drawBitmap(x_offset+220-86, 0, logo_small_b, 86, 36, COLOR_RED, COLOR_BLACK);
    }

    
    void update()
    {
        const auto now = millis();
        if (now - last_tick < 800)
            return;
        last_tick = now;
        switch (mode)
        {
        case 0:
            // Scroll to the right
            if (count == 0)
            {
                tft.fillRectangle(0, 0, ILI9225_LCD_HEIGHT-1, height, COLOR_BLACK);
                ++count;
                return;
            }
            drawLogo(count, 0);
            ++count;
            if (count >= ILI9225_LCD_HEIGHT)
                next();
            break;

        case 1:
            // Scroll to the left
            if (count == 0)
            {
                tft.fillRectangle(0, 0, ILI9225_LCD_HEIGHT-1, height, COLOR_BLACK);
                ++count;
                return;
            }
            drawLogo(ILI9225_LCD_HEIGHT-count-1, 0);
            ++count;
            if (count >= ILI9225_LCD_HEIGHT)
                next();
            break;

        case 2:
            {
                // Erase every other line
                if (count == 0)
                {
                    tft.fillRectangle(0, 0, ILI9225_LCD_HEIGHT-1, height, COLOR_BLACK);
                    drawLogo(0, 0);
                    ++count;
                    return;
                }
                const auto row = (count < height/2) ? count*2-1 : (count-height/2)*2;
                tft.fillRectangle(0, row, ILI9225_LCD_HEIGHT-1, row, COLOR_BLACK);
                ++count;
                if (count >= height)
                    next();
            }
            break;

        case 3:
            // Erase lines from top
            if (count == 0)
            {
                tft.fillRectangle(0, 0, ILI9225_LCD_HEIGHT-1, height, COLOR_BLACK);
                drawLogo(0, 0);
                ++count;
                return;
            }
            tft.fillRectangle(0, count, ILI9225_LCD_HEIGHT-1, count, COLOR_BLACK);
            ++count;
            if (count >= height)
                next();
            break;

        case 4:
            // Scroll up
            if (count == 0)
            {
                tft.fillRectangle(0, 0, ILI9225_LCD_HEIGHT-1, height, COLOR_BLACK);
                drawLogo(0, 0);
                ++count;
                return;
            }
            drawLogo(0, count);
            ++count;
            if (count >= height)
                next();
            break;

        case 5:
            // Scroll down
            if (count == 0)
            {
                tft.fillRectangle(0, 0, ILI9225_LCD_HEIGHT-1, height, COLOR_BLACK);
                ++count;
                return;
            }
            drawLogo(0, height-count);
            ++count;
            if (count >= height)
                next();
            break;

        case 6:
            // Erase from the outside
            {
                if (count == 0)
                {
                    tft.fillRectangle(0, 0, ILI9225_LCD_HEIGHT-1, height, COLOR_BLACK);
                    drawLogo(0, 0);
                    ++count;
                    return;
                }
                int n = count-1;
                tft.fillRectangle(n, n, ILI9225_LCD_HEIGHT-1-n, n, COLOR_BLACK);
                tft.fillRectangle(n, height-1-n, ILI9225_LCD_HEIGHT-1-n, height-1-n, COLOR_BLACK);
                if (count <= height)
                {
                    tft.fillRectangle(n, n, n, height-1-n, COLOR_BLACK);
                    tft.fillRectangle(ILI9225_LCD_HEIGHT-1-n, n, ILI9225_LCD_HEIGHT-1-n, height-1-n, COLOR_BLACK);
                }
                ++count;
                if (count >= height/2)
                    next();
            }
            break;

        case 7:
            // Random dissolve
            if (count == 0)
            {
                tft.fillRectangle(0, 0, ILI9225_LCD_HEIGHT-1, height, COLOR_BLACK);
                drawLogo(0, 0);
                ++count;
                return;
            }
            for (int i = 0; i < 1; ++i)
            {
                int x = random(ILI9225_LCD_HEIGHT);
                int y = random(height);
                int dx = random(16);
                if (x >= dx)
                    x -= dx;
                tft.fillRectangle(x, y, x+dx, y, COLOR_BLACK);
            }
            ++count;
            if (count > ILI9225_LCD_HEIGHT*16) // arbitrary
                next();
            break;
            
        default:
            mode = 0;
        }
    }

private:
    int height = 126;
    int mode = 6;
    bool large_logo = true;
    int count = 0;
    unsigned long last_tick = 0;
};

Animater anim;

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
  tft.drawText(30, 140, "Access Control", COLOR_GREEN);
  tft.setFont(Terminal6x8);
  tft.drawText(100, 158, version, COLOR_GREEN);

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

unsigned long status_millis = 0;

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
                    if ((col < 0) || (col > static_cast<int>(sizeof(colours)/sizeof(colours[0]))))
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
                    if ((col < 0) || (col > static_cast<int>(sizeof(colours)/sizeof(colours[0]))))
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

    const auto now = millis();
    if (now - status_millis > 50)
    {
        status_millis = now;
        Serial.print("S ");
        Serial.print(!digitalRead(RED_SW_PIN));
        Serial.println(!digitalRead(GREEN_SW_PIN));
    }
    anim.update();
}
