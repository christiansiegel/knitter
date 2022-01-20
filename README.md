# knitter

knitter is an open software to generate a circular/rectangular knitting pattern from a picture.
 
The method is inspired by the work of [Petros Vrellis](http://artof01.com/vrellis/works/knit.html).

## Uses and Derivatives

* [Mona Lisa](https://youtu.be/Gx26zk3MpWo) by [Anwer Al-Chalabi](https://www.youtube.com/channel/UCHSDv-MMYOPMMpnS9q8XsCA)
* [Dog portrait](https://imgur.com/gallery/pN5T9) by [Wtfacoconut](https://imgur.com/user/Wtfacoconut)
* Similar [algorithm using Qt/C++](https://github.com/MaloDrougard/knit) by [MaloDrougard](https://github.com/MaloDrougard) (also includes an interesting [report](https://github.com/MaloDrougard/knit/blob/master/Doc/knit-final-report.pdf) on the topic)

# How to use it

1. Clone the repository (or just download [knitter.pde](https://raw.githubusercontent.com/christiansiegel/knitter/master/knitter.pde))
2. Copy your grayscale image into the same folder as the `knitter.pde` and name it `image.jpg`. Make sure your image is square if you want to use modes *CIRCLE* or *SQUARE*, otherwise your picture will be distorted.
3. Open `knitter.pde` with the [Processing IDE](https://processing.org/).
4. Modify the configuration parameters at the top of the file (optional). You can also choose between *CIRCLE*, *SQUARE* and *RECTANGLE* mode here.
5. Run Sketch.
6. Find the best parameters using the sliders.

# Output

## Visual Preview

While running the Sketch, a simulated result is shown in the window.

## Instructions

The knitting order is saved to `instruction.txt`. 

```
String #1454 -> next pin: 84
String #1455 -> next pin: 122
String #1456 -> next pin: 154
String #1457 -> next pin: 128
String #1458 -> next pin: 80
String #1459 -> next pin: 14
String #1460 -> next pin: 83
```

Furthermore, an interactive HTML page displaying and reading the single steps is generated and saved to `instruction.html`.

The pins are numbered counter-clockwise starting from 0:

![Numbering](doc/numbering.png "Numbering")

## Thread Length

To have an estimate how much thread is needed, the total length is printed to the console in the end.

```
Total thread length: 1543 m
```

# Screenshot

An example result of running the current algorithm: 

![Example](doc/example.png "Example")
