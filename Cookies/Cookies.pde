/* Cookies.pde
 *
 * Copyright 2015 Johannes Kepler Universität Linz,
 * Institut f. Wissensbasierte Mathematische Systeme.
 * Copyright 2019 Roland Richter.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty
 * of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import org.opencv.core.Mat;
import org.opencv.core.MatOfPoint;
import org.opencv.core.CvType;
import org.opencv.core.Scalar;
import org.opencv.imgproc.*;
import gab.opencv.*;
import processing.video.*;
import java.awt.*;
import java.util.List;


int VideoWidth  = 0;
int VideoHeight = 0;
int PanelWidth = 0;
int PanelHeight = 0;
int lowestLabelPos;

boolean showFeaturePanel = false;
boolean magnifyYAxis = true;

// The left, right, top, and bottom edges of the drawing panel,
// in worlds coordinates.
final float WorldLeft   =  -10.0;
final float WorldRight  = +110.0;
final float WorldTop    = +110.0;
final float WorldBottom =  -10.0;

// Select the video data source, either a camera, or a video file.
//
// Unfortunately, code to switch between these two modes must be commented
// out here, and also in setup().
// a) Java does not provide a mechanism to switch code at compile time
//    (i.e., no #ifdef - #endif blocks)
// b) Capture and Movie have some methods of equal name (e.g., available() and read()),
//    but do not share a common base class other than PImage.

final boolean liveVideo = true;
Capture video;
// final boolean liveVideo = false;
// Movie video;

OpenCV opencv;

char lastKey = 0;
boolean isLabeling = false;
String label = "";
int threshold = 32;
boolean hasBackground = false;

PImage background, input;
ArrayList<Contour> contours;

// Contains features extracted from current image, one row per object
Table currentFeatures = new Table();

// Contains saved features, one row per object
Table features = new Table();

IntDict labelDict = new IntDict();
int nextLabelIndex = 0;

ArrayList<Perceptron> perceptrons = new ArrayList<Perceptron>();


void setup()
{
    frame.setResizable(true);

    if (liveVideo) {
        String[] cameras = Capture.list();

        if (cameras.length == 0) {
            println("There are no cameras available for capture.");
            exit();
        } else {
            println("There are", cameras.length, "cameras available for capture.");

            // for (int i = 0; i < cameras.length; ++i) {
            //    println(i, ":", cameras[i]);
            // }

            // Determine best camera device available, and open it.
            // For the KinderUni 2015 demo, that is an "AverVision" device of size
            // 640x480 with a frame rate of 30 fps. If this was not found, fall
            // back to another AverVision device, or to the very first device.

            int bestCamera = 0;
            boolean found = false;

            for (int i = 0; !found && i < cameras.length; ++i) {
                if (match(cameras[i], "AverVision") != null) {
                    bestCamera = i;
                    if (match(cameras[i], "size=640x480") != null
                        && match(cameras[i], "fps=30") != null) {
                        found = true;
                    }
                }
            }

            print("Opening camera", bestCamera, ":", cameras[bestCamera], "...");

            video = new Capture(this, cameras[bestCamera]);
            video.start();
        }
    } else {
        String movieName = "Kekse_2015-07-02.mp4";

        print("Opening movie", movieName, "...");

        // video = new Movie(this, movieName);
        // video.loop();
    }

    // Wait for first frame, and read it. Only then, width and height are
    // initialized, and are used to set width and height of the drawing panel.

    int sec = second();

    while (!video.available()) {
        if (sec != second()) {
            print(".");
            sec = second();
        }
    }

    video.read();

    VideoWidth = video.width;
    VideoHeight = video.height;
    PanelWidth = VideoHeight;
    PanelHeight = VideoHeight;
    lowestLabelPos = VideoHeight - 8; // Keep all text visible.

    println(" ready.");
    println("Capturing frames of size", VideoWidth, "x", VideoHeight);

    opencv = new OpenCV(this, VideoWidth, VideoHeight);

    PFont myFont = createFont("Arial", 16);
    textFont(myFont);

    colorMode(HSB, 360, 100, 100);

    currentFeatures.addColumn("hue");
    currentFeatures.addColumn("brightness");
    currentFeatures.addColumn("size");
    currentFeatures.addColumn("label"); // unused column for compatibility with the table 'features'

    features.addColumn("hue");
    features.addColumn("brightness");
    features.addColumn("size");
    features.addColumn("label");
}


String brightness2Text(float brightness)
{
    if (brightness < 50) {
        return "very dark";
    } else if (brightness < 75) {
        return "dark";
    } else if (brightness < 90) {
        return "bright";
    } else {
        return "very bright";
    }
}


String hue2Text(float hue)
{
    if (hue < 30) {
        return "red";
    } else if (hue < 90) {
        return "yellow";
    } else if (hue < 150) {
        return "green";
    } else if (hue < 210) {
        return "cyan";
    } else if (hue < 270) {
        return "blue";
    } else if (hue < 330) {
        return "magenta";
    } else {
        return "red";
    }
}


void drawCoordinateAxes()
{
    pushMatrix();
    translate(VideoWidth, 0);
    scale(PanelWidth / (WorldRight - WorldLeft), PanelHeight / (WorldBottom - WorldTop));
    translate(-WorldLeft, -WorldTop);

    // Draw coordinate axes
    stroke(#000000); strokeWeight(0.5); fill(#A0A0A0);
    line(-5, 0, 100, 0); triangle(0, 105, +2, 100, -2, 100);
    line(0, -5, 0, 100); triangle(105, 0, 100, -2, 100, +2);

    for (int k = 10; k <= 100; k += 10) {
        line(k, 0, k, 2);
        line(0, k, 2, k);
    }

    // Label the axes
    pushMatrix();
    scale(1, -1); // Text needs a downwards y axis.
    textSize(8);
    text("Helligkeit", 35, 7);
    rotate(-HALF_PI);
    text("Größe", 35, -3);
    popMatrix();

    popMatrix();
}


void drawDecisionBoundaries()
{
    pushMatrix();
    translate(VideoWidth, 0);
    scale(PanelWidth / (WorldRight - WorldLeft), PanelHeight / (WorldBottom - WorldTop));
    translate(-WorldLeft, -WorldTop);

    for (int label = 0; label < perceptrons.size(); ++label) {
        // Determine angle of vector w to rotate separating lines.

        Vector2d w = perceptrons.get(label).weights();
        float wRad = angleBetween2D(new Vector2d(0., 1.), new Vector2d(w.x, w.y / magnify(1)));

        Vector2d M = new Vector2d(50., 50.);
        perceptrons.get(label).moveToSeparator(M);

        pushMatrix();
        translate(M.x, magnify(M.y));
        rotate(wRad);

        // Draw decision boundary
        int labelHue = (label * 65) % 360; // to reach a value of 30 at the first 360° overflow
        int brightness = 80;

        stroke(labelHue, 100, brightness);
        strokeWeight(0.5);

        line(-200, 0, 200, 0);

        popMatrix();
    }

    popMatrix();
}


float magnify(float y)
{
    return magnifyYAxis ? 2 * y : y;
}


void drawPoints()
{
    pushMatrix();
    translate(VideoWidth, 0);
    scale(PanelWidth / (WorldRight - WorldLeft), PanelHeight / (WorldBottom - WorldTop));
    translate(-WorldLeft, -WorldTop);

    final float YOutside = 105;

    // Draw stored points as triangles, in a color indicating label
    for (TableRow row : features.rows()) {
        int label = row.getInt("label");

        Vector2d p = getFeatureVector2d(row);
        int labelHue = (label * 65) % 360; // to reach a value of 30 at the first 360° overflow
        int brightness = 80;

        stroke(labelHue, 100, brightness);
        strokeWeight(0.5);
        fill(labelHue, 60, brightness);

        float y = min(magnify(p.y), YOutside);
        triangle(p.x - 1, y - 1,
                 p.x,     y + 1,
                 p.x + 1, y - 1);
    }

    // Draw labels near the center
    textSize(4);
    fill(#000080);
    for (int i = 0; i < nextLabelIndex; ++i) {
        float mean_x = 0;
        float mean_y = 0;
        int count = 0;
        float min_x = Float.MAX_VALUE;
        float max_x = -Float.MAX_VALUE;
        for (TableRow row : features.rows()) {
            if (row.getInt("label") != i) {
                continue;
            }

            Vector2d p = getFeatureVector2d(row);
            mean_x += p.x;
            mean_y += magnify(p.y);
            ++count;
            min_x = min(min_x, p.x);
            max_x = max(max_x, p.x);
        }
        mean_x /= count;
        mean_y /= count;

        pushMatrix();
        translate(mean_x, min(mean_y, YOutside));
        scale(1, -1); // Text needs a downwards y axis.
        String label = getLabelName(i);
        text(label, (max_x - min_x < 3 ? 2 : -label.length()), // Do not hide close points; try to center otherwise.
                              3 * (i % 3)); // Reduce overlaps at top border.
        popMatrix();
    }

    // Draw current points as gray dots
    for (TableRow row : currentFeatures.rows ()) {
        Vector2d p = getFeatureVector2d(row);

        stroke(#606060);
        strokeWeight(0.5);
        noFill();

        ellipse(p.x, min(magnify(p.y), YOutside), 2, 2);
    }

    popMatrix();
}


void draw()
{
    handleKeystrokes();

    if (isLabeling) {
        return;
    }

    int frameWidth = VideoWidth + (showFeaturePanel ? PanelWidth : 0);
    int borderHeight = 25;
    int borderWidth = 6;
    frame.setSize(frameWidth + borderWidth, VideoHeight + borderHeight);

    if (video.available()) {
        video.read();
    }

    background(#FFFFFF);

    if (showFeaturePanel) {
        drawCoordinateAxes();
        drawDecisionBoundaries();
    }

    pushMatrix();

    image(video, 0, 0);

    if (hasBackground) {
        opencv.useColor();
        opencv.loadImage(video);

        input = opencv.getInput();

        opencv.gray();
        opencv.diff(background);
        opencv.threshold(threshold);

        for (int i = 0; i < 5; ++i) {
            opencv.dilate();
        }

        for (int i = 0; i < 5; ++i) {
            opencv.erode();
        }

        // Find contours without holes, and sort them
        contours = opencv.findContours(false, true);

        processContours(contours);
    }

    popMatrix();

    if (showFeaturePanel) {
        drawPoints();
    }
}


Vector2d getFeatureVector2d(TableRow row)
{
    float featureX = row.getFloat("brightness");
    float featureY = row.getFloat("size");

    return new Vector2d(featureX, featureY);
}


void processContours(ArrayList<Contour> contours)
{
    input.loadPixels();
    currentFeatures.clearRows();

    for (Contour contour : contours) {

        int n = (int)Imgproc.contourArea(contour.pointMat);

        if (n < 100) { // too small
            continue;
        }

        Mat contourMask = Mat.zeros(input.height, input.width, CvType.CV_8UC1); // type "unsigned char"
        List<MatOfPoint> contourToDraw = new ArrayList<MatOfPoint>();
        contourToDraw.add(contour.pointMat);
        Imgproc.drawContours(contourMask, contourToDraw, -1, new Scalar(255), -1);

        Rectangle box = contour.getBoundingBox();

        // Compute average hue and brightness of this contour.
        // Since hue is a circular quantity, the mean is computed
        // by converting hue values to points on the unit circle,
        // taking their mean, and converting back to hue, see
        // https://en.wikipedia.org/wiki/Mean_of_circular_quantities.
        // Brightness is linear, so its mean is computed straightforward.

        int maskArea = 0;
        float sumHx = 0.;
        float sumHy = 0.;
        float sumB = 0.;

        for (int y = box.y; y < box.y + box.height; ++y) {
            int index = box.x + y * input.width;

            for (int x = box.x; x < box.x + box.width; ++x, ++index) {
                if ((int)contourMask.get(y, x)[0] == 0) {
                    continue;
                }

                maskArea += 1;

                float h = hue(input.pixels[index]); // in [0, 360)

                sumHx += cos(radians(h));
                sumHy += sin(radians(h));

                sumB += brightness(input.pixels[index]); // in [0, 100]
            }
        }

        float avgHx = sumHx / (float)maskArea;
        float avgHy = sumHy / (float)maskArea;
        float a = atan2(avgHy, avgHx);

        float avgHue = degrees(a >= 0. ? a : (a + TWO_PI));
        float avgBrightness = sumB / (float)maskArea;
        final int MaxSize = (int)(sqrt(VideoWidth * VideoHeight) * 0.8);
        float size = 100. * min(norm(sqrt(maskArea), 0, MaxSize), 1.);

        // Scale features to [0,100]
        TableRow newRow = currentFeatures.addRow();
        newRow.setFloat("hue", avgHue / 3.6);
        newRow.setFloat("brightness", avgBrightness);
        newRow.setFloat("size", size);

        noFill();
        stroke(#FF0000);
        strokeWeight(1);

        contour.draw();

        // Add a label.
        textSize(16);
        fill(#000080);
        text(classify(newRow), box.x, min(box.y + box.height + 16, lowestLabelPos));
        ;
    }
}


String classify(TableRow features)
{
    if (labelDict.size() == 0) {
        return "";
    }
    if (labelDict.size() == 1) {
        return labelDict.keys().iterator().next();
    }

    Vector2d newP = getFeatureVector2d(features);

    if (perceptrons.size() == 1) {
        float confidence = perceptrons.get(0).evaluate(newP);
        return getLabelName(confidence > 0 ? 1 : 0);
    }

    // In general, each perceptron decides "my label" vs. "not my label",
    // and it is possible that each perceptron decides "not my label".

    float maxConfidence = 0.;
    int bestLabel = -1;

    for (int label = 0; label < perceptrons.size(); ++label) {
        float confidence = perceptrons.get(label).evaluate(newP);

        if (confidence > maxConfidence) {
            bestLabel = label;
            maxConfidence = confidence;
        }
    }

    return bestLabel >= 0 ? getLabelName(bestLabel) : "???";
}


int getLabelIndex(String label)
{
    // Direct lookup is impossible:
    // We want to be case sensitive when storing the label, case insensitive when comparing labels.
    for (String k : labelDict.keys()) {
        if (k.toLowerCase().equals(label.toLowerCase())) {
            return labelDict.get(k);
        }
    }

    labelDict.set(label, nextLabelIndex);
    return nextLabelIndex++;
}


String getLabelName(int index)
{
    for (String label : labelDict.keys()) {
        if (labelDict.get(label) == index) {
            return label;
        }
    }

    return "";
}


void stopLabeling()
{
    label = "";
    isLabeling = false;
}


void handleKeystrokes()
{
    if (lastKey == 0 || lastKey == CODED) {
        return;
    }

    print(lastKey);

    if (isLabeling) {
        switch (lastKey) {

        case 10: // <return> or <enter>
            int labelIndex = getLabelIndex(label.trim());
            println("Ok.");

            // Add points to be drawn to the panel
            for (TableRow row : currentFeatures.rows()) {
                row.setInt("label", labelIndex);
                features.addRow(row);
            }

            // If there are two labels, train just one classifier to
            // decide "1" vs. "0". If there are n labels (n > 2), train n
            // one-vs-rest classifiers to decide "my label" vs. "not my label".
            if (labelDict.size() >= 2) {
                perceptrons.clear();

                int label = (labelDict.size() == 2 ? 1 : 0);

                for (; label < labelDict.size(); ++label) {
                    ArrayList<Vector2d> ns = new ArrayList<Vector2d>();
                    ArrayList<Vector2d> ps = new ArrayList<Vector2d>();

                    for (TableRow row : features.rows()) {
                        if (row.getInt("label") == label) {
                            ps.add(getFeatureVector2d(row));
                        } else {
                            ns.add(getFeatureVector2d(row));
                        }
                    }

                    Perceptron perceptron = new Perceptron(100.);
                    perceptron.initialize(ns, ps);
                    perceptron.learn(ns, ps);

                    perceptrons.add(perceptron);
                }
            }

            stopLabeling();
            break;

        case ESC:
            println("\nEingabe abgebrochen.");
            stopLabeling();
            break;

        default:
            label = label + char(lastKey);
            break;
        }
    } else {
        switch (Character.toUpperCase(lastKey)) {
            // Toggle the feature panel
        case 'F':
            showFeaturePanel = !showFeaturePanel;
            println();
            break;

            // Toggle the feature panel Y axis scale
        case 'G':
            if (!showFeaturePanel) {
                println();
                break;
            }
            magnifyYAxis = !magnifyYAxis;
            println(" => Vergrößerung", magnifyYAxis ? "an" : "aus");
            break;

            // Reset background image
        case 'H':
            println(" => Neuer Hintergrund");
            background = video.get();
            hasBackground = true;
            break;

            // Increase gray level threshold
        case '+':
            threshold = min(threshold + 2, 192);
            println(" =>", "Schwelle = ", threshold);
            break;

            // Decrease gray level threshold
        case '-':
            threshold = max(threshold - 2, 0);
            println(" =>", "Schwelle = ", threshold);
            break;

            // Clear all points
        case 'V':
            println(" => Gelerntes ist vergessen.");
            features.clearRows();
            labelDict.clear();
            nextLabelIndex = 0;
            perceptrons.clear();
            break;

            // label/learn the objects
        case 'L':
            if ( currentFeatures.getRowCount() == 0 ) {
                println(" => Keine Dinge sichtbar.");
                break;
            }
            println(" => Was ist das?");
            isLabeling = true;
            break;

            // Terminate program
        case 'Q':
            println(" =>", "Ende.");
            exit();
            break;

        default:
            println("?");
            break;
        }
    }

    lastKey = 0;
}


void keyPressed() {
    lastKey = key;

    if (key == ESC) {
        key = 0;  // Do not stop the sketch at ESC
    }
}
