////////////////////////////////////////////////////////////////////////////////
// CONFIGURATION
////////////////////////////////////////////////////////////////////////////////

// Image's filename. Should be a square image.
final String FILENAME = "image.jpg";

// Number of pins
final int NR_PINS = 200;

// Default number of strings used
final int DEFAULT_STRINGS = 3000;

// Default color value lines are darkened if a string runs through
final int DEFAULT_FADE = 25;

// Default minimal distance between two consecutive pins
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

// Returns the coordinates of the circular pins based on their number, the
// circle's center and radius.
ArrayList<Point> calcCirclePins(int number, Point center, int radius) {
  ArrayList<Point> pins = new ArrayList<Point>();
  final float angle = PI * 2.0 / number;
  for (int i = 0; i < number; ++i) {
    pins.add(new Point(round(center.x + radius * cos(i * angle)),
                       round(center.y + radius * sin(i * angle))));
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
    String pair = pinPair(current, i);
    
    // Prevent two consecutive pins with less than minimal distance
    int diff = abs(current - i);
    float dist = random(minDistance * 2/3, minDistance * 4/3);
    if (diff < dist || diff > NR_PINS - dist) continue;
  
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
    rect(width - SIZE + p.x, p.y, 2, 2);
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
  
  // Work on copy of image
  PImage imgCopy = createImage(img.width, img.height, RGB);
  imgCopy.copy(img, 0, 0, img.width, img.height, 0, 0, img.width, img.height);
  
  // Always start from pin 0
  int current = 0;  
  steps.push(current);
  
  StringList used = new StringList();
  for (int i = 0; i < stringSlider.value; ++i) {
    // Get next pin
    int next = nextPin(current, lines, used, imgCopy, minDistanceSlider.value);
    if(next < 0) {
      stringSlider.setValue(used.size());
      break;
    }
    
    // Reduce darkness in image
    String pair = pinPair(current, next);
    reduceLine(imgCopy, lines.get(pair), fadeSlider.value);

    print("String #" + (i + 1) + " -> next pin: " + next + "\n");

    used.push(pair);
    steps.push(next);
    current = next;
  }
  redraw = true;
  redraw();
}

void setup() {
  size(1410, 835);
  randomSeed(0);

  // Load image from file.
  img = loadImage(FILENAME);
  img.filter(GRAY);
  img.resize(SIZE, SIZE);
  cropImageCircle(img);

  // Calculate circular pins
  Point center = new Point(round(img.width / 2.0),
                           round(img.height / 2.0));
  int radius = SIZE / 2;
  pins = calcCirclePins(NR_PINS, center, radius);

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
  minDistanceSlider = new Slider(5, SIZE + 60, width - 10, 20, DEFAULT_MIN_DIST, 0, NR_PINS / 2, "average minimal distance");
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
  minDistanceSlider.drawSelf();
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
  