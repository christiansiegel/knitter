#include <math.h>
#include <iostream>
#include <string>

#include <opencv2/core.hpp>
#include <opencv2/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>

// Image's filename. Should be a square image.
const std::string IMAGE = "image.jpg";

// Size of image in pixels
const unsigned int SIZE = 700;

// Number of hooks
const unsigned int NR_HOOKS = 200;

// Number of strings
const unsigned int NR_STRINGS = 4000;

// Reduce color (0-255) by this value if string runs through
const unsigned int FADE = 30;

// Minimal distance between two consecutive pins
const unsigned int MIN_DISTANCE = 20;

// Returns the coordinates of the circular hooks based on their number, the
// circle's center and radius.
std::vector<cv::Point> calcHooks(unsigned int number, cv::Point center,
                                 unsigned int radius) {
  std::vector<cv::Point> hooks;
  float angle = 2.0 * M_PI / number;
  for (unsigned int i = 0; i < number; ++i) {
    cv::Point hook;
    hook.x = center.x + radius * std::cos(angle * i);
    hook.y = center.y + radius * std::sin(angle * i);
    hooks.push_back(hook);
  }
  return hooks;
}

// Returns vector of pixels a line from a to b passes through.
std::vector<cv::Point> linePixels(cv::Point a, cv::Point b) {
  std::vector<cv::Point> points;
  int dx = abs(b.x - a.x);
  int dy = -abs(b.y - a.y);
  int sx = a.x < b.x ? 1 : -1;
  int sy = a.y < b.y ? 1 : -1;
  int e = dx + dy, e2;
  while (1) {
    points.push_back(a);
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
// passes through.
double lineScore(cv::Mat &image, cv::Point a, cv::Point b) {
  unsigned long score = 0;
  std::vector<cv::Point> points = linePixels(a, b);
  for (auto &p : points) {
    // linear; black pixel gets maximum score of 255
    score += 0xff - image.at<uchar>(p.y, p.x);
  }
  return (double)score / points.size();
}

// Reduce darkness of image's pixels the line from a to b passes through.
void reduceLine(cv::Mat &image, cv::Point a, cv::Point b) {
  std::vector<cv::Point> points = linePixels(a, b);
  for (auto &p : points) {cd
    unsigned int color = image.at<uchar>(p.y, p.x);
    color += FADE;
    if (color > 0xff) color = 0xff;
    image.at<uchar>(p.y, p.x) = color;
  }
}

// Returns the next hook, so that the string from the current hook achieves the
// maximum score.
unsigned int nextHook(unsigned int current, std::vector<cv::Point> hooks,
                      cv::Mat &mat) {
  double maxScore = 0;
  unsigned int next = 0;
  for (unsigned int i = 0; i < hooks.size(); ++i) {
    // Prevent two consecutive pins with less than minimal distance
    unsigned int diff = (unsigned int)std::abs((int)current - (int)i);
    if(diff < MIN_DISTANCE || diff > NR_HOOKS - MIN_DISTANCE) continue;
    // Calculate line score
    double score = lineScore(mat, hooks.at(current), hooks.at(i));
    if (score > maxScore) {
      maxScore = score;
      next = i;
    }
  }
  return next;
}

int main(int argc, char **argv) {
  // Load image from file.
  cv::Mat original = cv::imread(IMAGE, cv::IMREAD_COLOR);
  if (original.empty()) {
    std::cout << "Could not open or find the image" << std::endl;
    return -1;
  }

  cv::Point center = cv::Point(SIZE / 2, SIZE / 2);
  std::vector<cv::Point> hooks = calcHooks(NR_HOOKS, center, SIZE / 2);

  // Resize the original image and convert it to grayscale.
  cv::Mat img;
  cv::cvtColor(original, img, cv::COLOR_RGB2GRAY);
  cv::resize(img, img, cv::Size(SIZE, SIZE));

  // Image with the simulated result.
  cv::Mat result(SIZE, SIZE, CV_8U, 255);

  // Output windows
  cv::namedWindow("Image", cv::WINDOW_AUTOSIZE);
  cv::namedWindow("Result", cv::WINDOW_AUTOSIZE);

  // Generate string pattern
  unsigned int current = 0;  // always start from hook 0
  for (unsigned int i = 0; i < NR_STRINGS; ++i) {
    // Get next hook
    unsigned int next = nextHook(current, hooks, img);
    std::cout << "String #" << i << " -> next hook: " << next << std::endl;
    //std::cout << next << ",";

    // Update resulting image and reduce darkness in original image
    reduceLine(img, hooks.at(current), hooks.at(next));
    cv::line(result, hooks.at(current), hooks.at(next), 0, 1, CV_AA);

    // Update windows
    cv::imshow("Result", result);
    cv::imshow("Image", img);
    cv::waitKey(10);

    current = next;
  }

  imwrite("result.png", result);
  return 0;
}
