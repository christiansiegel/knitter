import java.util.HashSet;

////////////////////////////////////////////////////////////////////////////////
// CONFIGURATION
////////////////////////////////////////////////////////////////////////////////

// Image's filename. Should be a square image for circle and square mode.
final String FILENAME = "image.jpg";

// Number of pins
final int NR_PINS = 200;

// RECTANGLE, SQUARE or CIRCLE shape
final Mode MODE = Mode.CIRCLE;

// Real size to calculate total thread length (circle diameter or square/recangle longest side)
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
static class Point {
  final int x;
  final int y;

  private Point(int x, int y) {
    this.x = x;
    this.y = y;
  }
  
  static Point of(int x, int y) {
    return new Point(x, y);
  }
}

// Simple slider control for integer values.
class Slider {
  private final int x, y, w, h, min, max;
  private final String text;
  private int value;

  Slider(int x, int y, int w, int h, int value, int min, int max, String text) {
    SLIDERS.add(this);
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
    textAlign(LEFT, TOP);
    textSize(h - 2);
    text(text + ": " + value, x + h / 2, y);
  }

  // Check if mouse is pressed on slider and update value accordingly.
  // True is returned if value was changed.
  boolean handleMousePressed() {
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
  SQUARE,
  RECTANGLE
}

////////////////////////////////////////////////////////////////////////////////
// GENERIC FUNCTIONS
////////////////////////////////////////////////////////////////////////////////

// Crops image to a circular shape.
void cropImageCircle(PImage image) {
  final color white = color(255);
  final Point center = Point.of(round(image.width / 2.0), 
                                round(image.height / 2.0));
  final int radius = min(center.x, center.y);
  for (int i = 0; i < image.width; i++) {
    for (int j = 0; j < image.height; j++) {
      if (pow(center.x - i, 2) + pow(center.y - j, 2) > pow(radius, 2)) {
        image.set(i, j, white);
      }
    }
  }
}

// Returns the coordinates of the circular/square/rectangle pins based on their number
// and the size of the cirlce, square or rectangle.
ArrayList<Point> calcPins(int number, int w, int h, Mode mode) {
  ArrayList<Point> pins = new ArrayList<Point>();
  if (mode == Mode.CIRCLE) {
    assert w == h;
    final int size = w;
    final float radius = size / 2.0;
    final float angle = PI * 2.0 / number;
    for (int i = 0; i < number; ++i) {
      pins.add(Point.of(round(radius + radius * sin(i * angle)),
                        round(radius + radius * cos(i * angle))));
    }
  } else { // SQUARE / RECTANGLE
    int xPins = (number * w) / (2 * (h + w));
    int yPins = (number - (2 * xPins)) / 2;
    float spaceX = (float)w / xPins;
    float spaceY = (float)h / yPins;
    // top left -> bottom left
    for (int i = 0; i < yPins; ++i) {
      pins.add(Point.of(0, round(spaceY * i)));
    }
    // bottom left -> bottom right
    for (int i = 0; i < xPins; ++i) {
      pins.add(Point.of(round(spaceX * i), h));
    }
    // bottom right -> top right
    for (int i = 0; i < yPins; ++i) {
      pins.add(Point.of(w, h - round(spaceY * i)));
    }
    // top right -> top left
    for (int i = 0; i < xPins; ++i) {
      pins.add(Point.of(w - round(spaceX * i), 0));
    }
  }
  minX = minY = 999999;
  maxX = maxY = -1;
  for (Point p : pins) {
    minX = min(minX, p.x);
    minY = min(minY, p.y);
    maxX = max(maxX, p.x);
    maxY = max(maxY, p.y);
  }
  return pins;
}

// Returns vector of pixels a line from a to b passes through.
ArrayList<Point> linePixels(Point a, Point b) {
  ArrayList<Point> points = new ArrayList<Point>();
  final int dx = abs(b.x - a.x);
  final int dy = -abs(b.y - a.y);
  final int sx = a.x < b.x ? 1 : -1;
  final int sy = a.y < b.y ? 1 : -1;
  int e = dx + dy, e2;
  int px = a.x;
  int py = a.y;
  while (true) {
    points.add(Point.of(px, py));
    if (px == b.x && py == b.y) break;
    e2 = 2 * e;
    if (e2 > dy) {
      e += dy;
      px += sx;
    }
    if (e2 < dx) {
      e += dx;
      py += sy;
    }
  }
  return points;
}

// Returns the score of a line from a to b, based on the image's pixels it
// passes through (linear; black pixel gets maximum score of 255).
double lineScore(PImage image, ArrayList<Point> points) {
  int score = 0;
  for (Point p : points) {
    color c = image.get(p.x, p.y) & 0xff;
    score += 0xff - c;
  }
  return (double)score / points.size();
}

// Reduce darkness of image's pixels the line from a to b passes through by 
// a given value (0 - 255);
void reduceLine(PImage image, ArrayList<Point> points, int value) {
  for (Point p : points) {
    int c = image.get(p.x, p.y) & 0xff;
    c += value;
    if (c > 0xff) c = 0xff;
    image.set(p.x, p.y, color(c));
  }
}

// Returns a unique pin pair key independent of pin order.
// This can be used as key in a map storing the lines between all
// pins in a non-redundant manner.
int pinPair(int a, int b) {
  return a < b ? (10000 * a) + b : a + (10000 * b);
}

// Returns the next pin, so that the string from the current pin achieves the
// maximum score. To prevent a string path from beeing used twice, a list of 
// already used pin pairs can be given. The minimum distance between to 
// consecutive pins is specified by minDistance. If no valid next pin can be 
// found -1 is returned.
int nextPin(int current, HashMap<Integer, ArrayList<Point>> lines,
            HashSet<Integer> used, PImage image, int minDistance) {
  double maxScore = 0;
  int next = -1;
  for (int i = 0; i < pins.size(); ++i) {
    if (current == i) continue;
    int pair = pinPair(current, i);
    
    if (MODE == Mode.CIRCLE) {
      // Prevent two consecutive pins with less than minimal distance
      int diff = abs(current - i);
      float dist = random(minDistance * 2/3, minDistance * 4/3);
      if (diff < dist || diff > pins.size() - dist) continue;
    } else { // SQUARE / RECTANGLE
      // Prevent two consecutive pins on the same side
      Point pCurr = pins.get(current);
      Point pNext = pins.get(i);
      if (pCurr.x == minX && pNext.x == minX) continue;
      if (pCurr.x == maxX && pNext.x == maxX) continue;
      if (pCurr.y == minY && pNext.y == minY) continue;
      if (pCurr.y == maxY && pNext.y == maxY) continue;
    }
  
    // Prevent usage of already used pin pair
    if (used.contains(pair)) continue;

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
  double len = 0;
  for (int i = 0; i < steps.size() - 1; i++) {
    // Get pin pair
    Point a = pins.get(steps.get(i));
    Point b = pins.get(steps.get(i + 1));
    // Calculate distance and add to total length
    int x = a.x - b.x;
    int y = a.y - b.y;
    len += sqrt(x*x + y*y);
   }
   return round((float)((len * REAL_SIZE) / SIZE));
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

// Min/max pin coordinates
int minX, minY, maxX, maxY; 

// List of all possible lines (keys are generated by pinPair())
HashMap<Integer, ArrayList<Point>> lines;

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
boolean redraw = true;

final HashSet<Slider> SLIDERS = new HashSet<Slider>();

////////////////////////////////////////////////////////////////////////////////
// FUNCTIONS USING GLOBAL VARIABLES
////////////////////////////////////////////////////////////////////////////////

// Clear area were strings were drawn
void clearStrings() {
  noStroke();
  fill(255);
  rect(0, 0, SIZE, SIZE);
}

void drawPins() {
  noStroke();
  fill(0);
  rectMode(CENTER);
  for (Point p : pins) {
    rect(p.x, p.y, 2, 2);
  }
  rectMode(CORNER);
}

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
    // Generate third point to introduce line variation (bezier control point)
    Point c = Point.of(round(random(-variation, variation) + (a.x + b.x) / 2),
                       round(random(-variation, variation) + (a.y + b.y) / 2));
    // Draw string as bezier curve
    bezier(a.x, a.y, c.x, c.y, c.x, c.y, b.x, b.y);
  }
}

void drawPinHint() {
  int topLeft, topRight, bottomLeft, bottomRight;
  topLeft = topRight = bottomLeft = bottomRight = 0;
  int i = 0;
  for (Point p : pins) {
    if (p.x == minX && p.y == minY) topLeft = i;
    if (p.x == minX && p.y == maxY) bottomLeft = i;
    if (p.x == maxX && p.y == maxY) bottomRight = i;
    if (p.x == maxX && p.y == minY) topRight = i;
    i++;
  }
  noStroke();
  fill(255, 0, 0);
  int hintSize = 10;
  rectMode(CENTER);
  rect(minX, minY, hintSize, hintSize);
  rect(minX, maxY, hintSize, hintSize);
  rect(maxX, maxY, hintSize, hintSize);
  rect(maxX, minY, hintSize, hintSize);
  rectMode(CORNER);
  textSize(30);
  textAlign(LEFT, TOP);
  whiteOutlinedRedText("#" + topLeft, minX + 18, minY + 18);
  textAlign(LEFT, BOTTOM);
  whiteOutlinedRedText("#" + bottomLeft, minX + 18, maxY - 18);
  textAlign(RIGHT, BOTTOM);
  whiteOutlinedRedText("#" + bottomRight, maxX - 18, maxY - 18);
  textAlign(RIGHT, TOP);
  whiteOutlinedRedText("#" + topRight, maxX - 18, minY + 18);
  fill(0);
  textAlign(LEFT, TOP);
  textSize(16);
  text("Total pins: " + pins.size(), 10, height - 22);
}

void whiteOutlinedRedText(String s, int x, int y) {
  fill(255);
  for(int i = -1; i < 2; i++){
    text(s, x + i, y);
    text(s, x, y + i);
  }
  fill(255, 0, 0);
  text(s, x, y);
}

void drawPattern() {
  pushMatrix();
  {
    translate(width - SIZE, 0);
    clearStrings();
    drawPins();
    drawStrings();
    if (MODE == Mode.SQUARE || MODE == Mode.RECTANGLE) {
      drawPinHint();
    }
  }
  popMatrix();
}

void drawSliders() {
  for (Slider s : SLIDERS) {
    s.drawSelf();
  }
}

// Generate string pattern
void generatePattern() {
  steps = new IntList();
  StringBuilder stepsInstructions = new StringBuilder();
  
  // Work on copy of image
  PImage imgCopy = createImage(img.width, img.height, RGB);
  imgCopy.copy(img, 0, 0, img.width, img.height, 0, 0, img.width, img.height);
  
  // Always start from pin 0
  int current = 0;  
  steps.append(current);
  
  HashSet<Integer> used = new HashSet<Integer>();
  for (int i = 0; i < stringSlider.value; ++i) {
    // Get next pin
    int next = nextPin(current, lines, used, imgCopy, MODE == Mode.CIRCLE ? minDistanceSlider.value : -999);
    if(next < 0) {
      stringSlider.setValue(used.size());
      break;
    }
    
    // Reduce darkness in image
    int pair = pinPair(current, next);
    reduceLine(imgCopy, lines.get(pair), fadeSlider.value);

    stepsInstructions.append("String #").append(i).append(" -> next pint: ").append(next).append("\r\n");
  
    used.add(pair);
    steps.append(next);
    current = next;
  }
  
  println("Total thread length: " + totalThreadLength(steps) + " m");
  
  // Save instructions in two different formats
  saveBytes("instruction.txt", stepsInstructions.toString().getBytes());
  saveInstructions("instruction.html", steps);
}

void initSliders() {
  int x = 5;
  int w = width - 10;
  int h = 20;
  int y = SIZE + 10;
  int spaceY = 25;
  stringSlider = new Slider(x, y, w, h, DEFAULT_STRINGS, 0, 10000, "strings");
  fadeSlider = new Slider(x, y += spaceY, w, h, DEFAULT_FADE, 0, 255, "fade");
  if (MODE == Mode.CIRCLE) {
    minDistanceSlider = new Slider(x, y += spaceY, w, h, DEFAULT_MIN_DIST, 0, pins.size() / 2, "average minimal distance");
  }
  lineVariationSlider = new Slider(x, y += spaceY, w, h, DEFAULT_LINE_VARATION, 0, 20, "line variation");
  opacitySlider = new Slider(x, y += spaceY, w, h, DEFAULT_OPACITY, 0, 100, "opacity");
}

void setup() {
  size(1410, 835);
  background(255);
  randomSeed(0);

  // Load image from file and draw it
  img = loadImage(FILENAME);
  if (img == null) {
    println("Couldn't load image file '" + sketchFile(FILENAME) + "'!");
    exit();
    return;
  }
  img.filter(GRAY);
  if (MODE == Mode.RECTANGLE) {
    if (img.width > img.height) {
      img.resize(SIZE, 0);
    } else {
      img.resize(0, SIZE);
    }
  } else {
    img.resize(SIZE, SIZE);
  }
  if (MODE == Mode.CIRCLE) {
    cropImageCircle(img);
  }
  image(img, 0, 0);

  // Calculate pins
  pins = calcPins(NR_PINS, img.width, img.height, MODE);
  if (pins == null) {
    exit();
    return;
  }

  // Calculate the pixels of all possible lines
  lines = new HashMap<Integer, ArrayList<Point>>();
  for (int i = 0; i < pins.size(); ++i) {
    for (int j = i + 1; j < pins.size(); ++j) {
      lines.put(pinPair(i, j), linePixels(pins.get(i), pins.get(j)));
    }
  }

  initSliders();
  generatePattern();
}

void draw() {
  if (redraw) {
    drawPattern();
    drawSliders();
    redraw = false;
  }
}

void mouseReleased() {
  boolean generateNeeded = false;
  generateNeeded |= stringSlider.handleMousePressed();
  generateNeeded |= fadeSlider.handleMousePressed();
  if (minDistanceSlider != null) {
    generateNeeded |= minDistanceSlider.handleMousePressed();
  }

  if (generateNeeded) {
    generatePattern();
  }

  redraw |= generateNeeded;
  redraw |= lineVariationSlider.handleMousePressed();
  redraw |= opacitySlider.handleMousePressed();
}
  
