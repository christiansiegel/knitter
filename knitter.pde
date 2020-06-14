////////////////////////////////////////////////////////////////////////////////
// CONFIGURATION
////////////////////////////////////////////////////////////////////////////////

// Image's filename. Should be a square image.
final String FILENAME = "image.jpg";

// Number of pins
final int NR_PINS = 200;

// SQUARE or CIRCLE shape
final Mode MODE = Mode.CIRCLE;

// Real size to calculate total thread length (circle diameter or square size)
final float REAL_SIZE = 0.8; // [m]

////////////////////////////////////////////////////////////////////////////////
// DEFAULT VALUES
////////////////////////////////////////////////////////////////////////////////

// Default number of strings used
final int DEFAULT_STRINGS = 3000;

// Default color value lines are darkened if a string runs through
final int DEFAULT_FADE = 25;

// Default minimal distance between two consecutive pins (only for CIRCLE mode)
final int DEFAULT_MIN_DIST = 25;

// Default value specifying how much the drawn lines vary from a straight 
// line (preventing a moiré effect) 
final int DEFAULT_LINE_VARATION = 3;

// Default opacity of drawn lines.
final int DEFAULT_OPACITY = 50;

////////////////////////////////////////////////////////////////////////////////
// CLASSES
////////////////////////////////////////////////////////////////////////////////

// Simple point class storing x and y coordinates of a point.
class Point {
  int x;
  int y;

  Point() {
    this.x = 0;
    this.y = 0;
  }

  Point(int x, int y) {
    this.x = x;
    this.y = y;
  }
  
  public Point(Point p) {
    this.x = p.x;
    this.y = p.y;
  }

  public String toString() { 
    return "(" + x + ", " + y + ")"; 
  }
}

// Simple slider control for integer values.
class Slider {
  int x, y;
  int w, h;
  int value, min, max;
  String text;

  Slider(int x, int y, int w, int h, int value, int min, int max, String text) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.min = min;
    this.max = max;
    this.value = value;
    this.text = text;
  }
  
  // Set slider value and redraw.
  void setValue(int value) {
    this.value = value;
    drawSelf();
  }

  // Draw slider 
  void drawSelf() {
    noStroke();
    
    // Dark blue background
    fill(0, 43, 91);
    rect(x, y, w, h, h);

    // Light blue slider value
    fill(0, 113, 220);
    float v = (float)abs(value - min) / abs(max - min);
    rect(x, y, w * v, h, h);

    // White text
    fill(255);
    textAlign(LEFT, CENTER);
    textSize(16);
    text(text + ": " + value, x + h / 2, y + h / 2 - 2);
  }

  // Check if mouse is pressed on slider and update value accordingly.
  // True is returned if value was changed.
  Boolean handleMousePressed() {
    if (mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h) {
      float v = (float)(mouseX - x) / w;
      int newValue = round(min + abs(max - min) * v);
      if(newValue != value) {
        value = newValue;
        return true;
      }
    }
    return false;
  }
}

enum Mode {
  CIRCLE,
  SQUARE
}

////////////////////////////////////////////////////////////////////////////////
// GENERIC FUNCTIONS
////////////////////////////////////////////////////////////////////////////////

// Crops image to a circular shape.
void cropImageCircle(PImage image) {
  final color white = color(255);
  final Point center = new Point(round(image.width / 2.0), 
                                 round(image.height / 2.0));
  final int radius = image.width < image.height 
                   ? round(image.width / 2.0) 
                   : round(image.height / 2.0);
  for (int i = 0; i < image.width; i++) {
    for (int j = 0; j < image.height; j++) {
      if (pow(center.x - i, 2) + pow(center.y - j, 2) > pow(radius, 2)) {
        image.set(i, j, white);
      }
    }
  }
}

// Returns the coordinates of the circular/square pins based on their number
// and the size of the cirlce (diameter) or square (width and height).
ArrayList<Point> calcPins(int number, int size, Mode mode) {
  ArrayList<Point> pins = new ArrayList<Point>();
  if (mode == Mode.CIRCLE) {
    final float radius = size / 2.0;
    final float angle = PI * 2.0 / number;
    for (int i = 0; i < number; ++i) {
      pins.add(new Point(round(radius + radius * cos(i * angle)),
                         round(radius + radius * sin(i * angle))));
    }
  } else { // SQUARE
    if (number % 4 != 0) {
      println("Number of pins must be a multiple of 4 in SQUARE mode!");
      return null;
    }
    int perSide = number / 4;
    float spaceBetween = size / (perSide - 1);
    // top left -> top right
    for (int i = 0; i < perSide; ++i) {
      pins.add(new Point(round(spaceBetween * i), 0));
    }
    // top right -> bottom right
    for (int i = 0; i < perSide; ++i) {
      pins.add(new Point(size, round(spaceBetween * i)));
    }
    // bottom right -> bottom left
    for (int i = 0; i < perSide; ++i) {
      pins.add(new Point(size - round(spaceBetween * i), size));
    }
    // bottom left -> top left
    for (int i = 0; i < perSide; ++i) {
      pins.add(new Point(0, size - round(spaceBetween * i)));
    }
  }
  return pins;
}

// Returns vector of pixels a line from a to b passes through.
ArrayList<Point> linePixels(Point a, Point b) {
  ArrayList<Point> points = new ArrayList<Point>();
  int dx = abs(b.x - a.x);
  int dy = -abs(b.y - a.y);
  int sx = a.x < b.x ? 1 : -1;
  int sy = a.y < b.y ? 1 : -1;
  int e = dx + dy, e2;
  a = new Point(a);
  while (true) {
    points.add(new Point(a));
    if (a.x == b.x && a.y == b.y) break;
    e2 = 2 * e;
    if (e2 > dy) {
      e += dy;
      a.x += sx;
    }
    if (e2 < dx) {
      e += dx;
      a.y += sy;
    }
  }
  return points;
}

// Returns the score of a line from a to b, based on the image's pixels it
// passes through (linear; black pixel gets maximum score of 255).
double lineScore(PImage image, ArrayList<Point> points) {
  int score = 0;
  for (Point p : points) {
    color c = image.get(p.y, p.x) & 0xff;
    score += 0xff - c;
  }
  return (double)score / points.size();
}

// Reduce darkness of image's pixels the line from a to b passes through by 
// a given value (0 - 255);
void reduceLine(PImage image, ArrayList<Point> points, int value) {
  for (Point p : points) {
    int c = image.get(p.y, p.x) & 0xff;
    c += value;
    if (c > 0xff) c = 0xff;
    image.set(p.y, p.x, color(c));
  }
}

// Returns values a and b sorted in a string (e.g. a = 5 and b = 2 becomes 
// "2-5"). This can be used as key in a map storing the lines between all
// pins in a non-redundant manner.
String pinPair(int a, int b) { 
  return a < b ? a + "-" + b : b + "-" + a; 
}

// Returns true if the list contains a specific element.
Boolean contains(StringList list, String element) {
  for (String e : list)
    if (e.equals(element)) return true;
  return false;
}

// Returns the next pin, so that the string from the current pin achieves the
// maximum score. To prevent a string path from beeing used twice, a list of 
// already used pin pairs can be given. The minimum distance between to 
// consecutive pins is specified by minDistance. If no valid next pin can be 
// found -1 is returned.
int nextPin(int current, HashMap<String, ArrayList<Point>> lines,
            StringList used, PImage image, int minDistance) {
  double maxScore = 0;
  int next = -1;
  for (int i = 0; i < NR_PINS; ++i) {
    if (current == i) continue;
    String pair = pinPair(current, i);
    
    if (MODE == Mode.CIRCLE) {
      // Prevent two consecutive pins with less than minimal distance
      int diff = abs(current - i);
      float dist = random(minDistance * 2/3, minDistance * 4/3);
      if (diff < dist || diff > NR_PINS - dist) continue;
    } else { // SQUARE
      // Prevent two consecutive pins on the same side
      int side_current = (current * 4) / NR_PINS;
      int side_i = (i * 4) / NR_PINS;
      if (side_current == side_i) continue;
    }
  
    // Prevent usage of already used pin pair
    if (contains(used, pair)) continue;

    // Calculate line score and save next pin with maximum score
    double score = lineScore(image, lines.get(pair));
    if (score > maxScore) {
      maxScore = score;
      next = i;
    }
  }
  return next;
}

// Calculates total thread length based on steps
int totalThreadLength(IntList steps) {
  ArrayList<Point> p = calcPins(NR_PINS, int(REAL_SIZE * 1000), MODE);
  float len = 0;
   for (int i = 0; i < steps.size() - 1; i++) {
      // Get pin pair
      Point a = p.get(steps.get(i));
      Point b = p.get(steps.get(i + 1));
      // Calculate distance and add to total length
      int x = a.x - b.x;
      int y = a.y - b.y;
      len += sqrt(x*x + y*y);
   }
   return int(len/1000);
}

void saveInstructions(String filename, IntList steps) {
  String html = "<!DOCTYPE html><html> <head> <meta content=\"text/html;chars" + 
                "et=utf-8\" http-equiv=\"Content-Type\"/> <style>*{box-sizing" + 
                ": border-box;}body{-webkit-touch-callout: none; -webkit-user" + 
                "-select: none; -khtml-user-select: none; -moz-user-select: n" + 
                "one; -ms-user-select: none; user-select: none;}div{text-alig" + 
                "n: center; font-family: sans-serif; line-height: 150%; text-" + 
                "shadow: 0 2px 2px #b6701e; height: 100%; color: #fff;}p{font" + 
                "-size: 4vw;}input{width: 100%; text-align: center;}.pin{posi" + 
                "tion: absolute; top: 50%; left: 50%; transform: translate(-5" + 
                "0%, -50%); width: 100%; padding: 20px; font-size: 16vw;}.con" + 
                "tainer{display: table; width: 100%;}.left-half{background-co" + 
                "lor: #0071DC; position: absolute; left: 0px; width: 50%;}.ri" + 
                "ght-half{background-color: #002B5B; position: absolute; righ" + 
                "t: 0px; width: 50%;}#step-input{font-size: 3vw;}</style> <sc" + 
                "ript src=\"https://ajax.googleapis.com/ajax/libs/jquery/3.1." + 
                "1/jquery.min.js\"> </script> <script src='https://code.respo" + 
                "nsivevoice.org/responsivevoice.js'></script> <script type=\"" + 
                "text/javascript\">var stepList=[\"start\",0,\"end\"]; var cu" + 
                "rrent=0; function previous(){if (current > 0){current--; sho" + 
                "wStep();}}function next(){if (current < stepList.length - 2)" + 
                "{current++; showStep();}}function showStep(){$(\"#from-pin\"" + 
                ").text(stepList[current]); $(\"#to-pin\").text(stepList[curr" + 
                "ent + 1]); $(\"#step-input\").val(current); responsiveVoice." + 
                "speak((stepList[current + 1]).toString());}function jumpToSt" + 
                "ep(){current=parseInt($(\"#step-input\").val()); if (current" + 
                " < 0) current=0; else if (current > stepList.length - 2) cur" + 
                "rent=stepList.length - 2; showStep();}</script> <title>knitt" + 
                "er</title> </head> <body onload=\"showStep()\"> <section cla" + 
                "ss=\"container\"> <input id=\"step-input\" onchange=\"jumpTo" + 
                "Step()\" type=\"tel\"> <div class=\"left-half\" onclick=\"pr" + 
                "evious()\"> <p>from</p><span class=\"pin\" id=\"from-pin\">?" + 
                "??</span> </div><div class=\"right-half\" onclick=\"next()\"" + 
                "> <p>to</p><span class=\"pin\" id=\"to-pin\">???</span> </di" + 
                "v></section> </body></html>";
  String list = ",";
  for (int i = 0; i < steps.size(); i++) {
    list += steps.get(i) + ",";
  }
  html = html.replace(",0,", list);
  saveBytes(filename, html.getBytes());
}

////////////////////////////////////////////////////////////////////////////////
// GLOBAL VARIABLES
////////////////////////////////////////////////////////////////////////////////

// Size of image in pixels (DO NOT CHANGE!)
final int SIZE = 700;

// Original image
PImage img;

// List of pin coordinates
ArrayList<Point> pins;

// List of all possible lines (keys are generated by pinPair())
HashMap<String, ArrayList<Point>> lines;

// List of steps that generate the pattern
IntList steps;

// Slider specifying the number of strings used
Slider stringSlider;

// Slider specifying the color value lines are darkened if a string runs through
Slider fadeSlider;

// Slider specifying the how much drawn lines vary from a straight line (preventing 
// a moiré effect)
Slider lineVariationSlider;

// Slider specifying the opacity of drawn lines.
Slider opacitySlider;

// Slider specifying the minimal distance between two consecutive pins
Slider minDistanceSlider;

// Causes string pattern to be redrawn on next draw()
Boolean redraw = false;

////////////////////////////////////////////////////////////////////////////////
// FUNCTIONS USING GLOBAL VARIABLES
////////////////////////////////////////////////////////////////////////////////

// Clear area were strings were drawn
void clearStrings() {
  noStroke();
  fill(255);
  rect(width - SIZE, 0, SIZE, SIZE);
}

// Draws pins
void drawPins() {
  noStroke();
  fill(0);
  for (Point p : pins) {
    rect(width - SIZE + p.x - 1, p.y - 1, 2, 2);
  }
}

// Draw strings
void drawStrings() {
  stroke(0, opacitySlider.value);
  strokeWeight(1);
  noFill();
  randomSeed(0);
  int variation = lineVariationSlider.value;
  for (int i = 0; i < steps.size() - 1; i++) {
    // Get pin pair
    Point a = pins.get(steps.get(i));
    Point b = pins.get(steps.get(i + 1));
    // Move pin pair to output location
    a = new Point(width - SIZE + a.y, a.x);
    b = new Point(width - SIZE + b.y, b.x);
    // Generate third point to introduce line variation (bezier control point)
    Point c = new Point(round(random(-variation, variation) + (a.x + b.x) / 2),
                        round(random(-variation, variation) + (a.y + b.y) / 2));
    // Draw string as bezier curve
    bezier(a.x, a.y, c.x, c.y, c.x, c.y, b.x, b.y);
  }
}

// Generate string pattern
void generatePattern() {
  steps = new IntList();
  String stepsInstructions = "";
  
  // Work on copy of image
  PImage imgCopy = createImage(img.width, img.height, RGB);
  imgCopy.copy(img, 0, 0, img.width, img.height, 0, 0, img.width, img.height);
  
  // Always start from pin 0
  int current = 0;  
  steps.append(current);
  
  StringList used = new StringList();
  for (int i = 0; i < stringSlider.value; ++i) {
    // Get next pin
    int next = nextPin(current, lines, used, imgCopy, MODE == Mode.CIRCLE ? minDistanceSlider.value : -999);
    if(next < 0) {
      stringSlider.setValue(used.size());
      break;
    }
    
    // Reduce darkness in image
    String pair = pinPair(current, next);
    reduceLine(imgCopy, lines.get(pair), fadeSlider.value);

    String instruction = "String #" + i + " -> next pin: " + next + "\r\n";
    print(instruction);
    stepsInstructions += instruction;
  
    used.append(pair);
    steps.append(next);
    current = next;
  }
  
  println("Total thread length: " + totalThreadLength(steps) + " m");
  
  // Save instructions in two different formats
  saveBytes("instruction.txt", stepsInstructions.getBytes());
  saveInstructions("instruction.html", steps);
  
  redraw = true;
  redraw();
}

void setup() {
  size(1410, 835);
  randomSeed(0);

  // Load image from file.
  img = loadImage(FILENAME);
  if (img == null) {
    println("Couldn't load image file '" + sketchFile(FILENAME) + "'!");
    exit();
    return;
  }
  img.filter(GRAY);
  img.resize(SIZE, SIZE);
  if (MODE == Mode.CIRCLE) {
    cropImageCircle(img);
  }

  // Calculate pins
  pins = calcPins(NR_PINS, SIZE, MODE);
  if (pins == null) {
    exit();
    return;
  }

  // Calculate the pixels of all possible lines
  lines = new HashMap<String, ArrayList<Point>>();
  for (int i = 0; i < NR_PINS; ++i) {
    for (int j = i + 1; j < NR_PINS; ++j) {
      lines.put(pinPair(i, j), linePixels(pins.get(i), pins.get(j)));
    }
  }

  // Init sliders
  stringSlider = new Slider(5, SIZE + 10, width - 10, 20, DEFAULT_STRINGS, 0, 10000, "strings");
  fadeSlider = new Slider(5, SIZE + 35, width - 10, 20, DEFAULT_FADE, 0, 255, "fade");
  if (MODE == Mode.CIRCLE) {
    minDistanceSlider = new Slider(5, SIZE + 60, width - 10, 20, DEFAULT_MIN_DIST, 0, NR_PINS / 2, "average minimal distance");
  }
  lineVariationSlider = new Slider(5, SIZE + 85, width - 10, 20, DEFAULT_LINE_VARATION, 0, 20, "line variation");
  opacitySlider = new Slider(5, SIZE + 110, width - 10, 20, DEFAULT_OPACITY, 0, 100, "opacity");

  // Init output window with original image
  background(255);
  image(img, 0, 0);
  
  // Generate pattern with yet default values
  generatePattern();
}

void draw() {
  // Draw string pattern if necessary
  if (redraw) {
    clearStrings();
    drawPins();
    drawStrings();
    redraw = false;
  }
  // Draw sliders
  stringSlider.drawSelf();
  fadeSlider.drawSelf();
  lineVariationSlider.drawSelf();
  if (MODE == Mode.CIRCLE) minDistanceSlider.drawSelf();
  opacitySlider.drawSelf();
}

void mouseReleased() {
  Boolean generateNeeded = false;
  Boolean redrawNeeded = false;

  generateNeeded |= stringSlider.handleMousePressed();
  generateNeeded |= fadeSlider.handleMousePressed();
  generateNeeded |= minDistanceSlider.handleMousePressed();

  redrawNeeded |= lineVariationSlider.handleMousePressed();
  redrawNeeded |= opacitySlider.handleMousePressed();

  if (generateNeeded) {
    generatePattern();
  } else if (redrawNeeded) {
    redraw = true;
    redraw();
  }
}
  
