# knitter

knitter is an open software to generate a circular knitting pattern from a picture.
 
The method is inspired by the work of [Petros Vrellis](http://artof01.com/vrellis/works/knit.html).

## Showcase

* http://imgur.com/gallery/pN5T9

# How to use it

1. Clone the repository (or just download [knitter.pde](https://raw.githubusercontent.com/christiansiegel/knitter/master/knitter.pde))
2. Copy your square, grayscale image into the same folder as the `knitter.pde` and name it `image.jpg`.
3. Open `knitter.pde` with the [Processing IDE](https://processing.org/).
4. Modify the configuration parameters at the top of the file (optional).
5. Run Sketch.
6. Find the best parameters using the sliders.

# Output

## Visual Preview

While running the Sketch, a simulated result is shown in the window.

## Console

The knitting order is printed to the console like

```
String #1454 -> next pin: 84
String #1455 -> next pin: 122
String #1456 -> next pin: 154
String #1457 -> next pin: 128
String #1458 -> next pin: 80
String #1459 -> next pin: 14
String #1460 -> next pin: 83
```

To have an estimate how much string is needed, the total length is printed in the end.

```
Total string length: 1543 m
```

## HTML

An interactive HTML page displaying and reading the single steps is generated and saved to `instruction.html`.

# Screenshot

An example result of running the current algorithm: 

![Example](doc/example.png "Example")
