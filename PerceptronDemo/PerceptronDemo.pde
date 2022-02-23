/* PerceptronDemo.pde
 *
 * Copyright 2013, 2014, 2015, 2022 Roland Richter.
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

/** Interactive demonstration of the Perceptron algorithm.
 */

// In literature on the Perceptron algorithm, a data sample point is
// usually denoted by X in R^n, and its label is denoted by Y in {-1,+1}.
// In this demo, data sample points are restricted to two-dimensional real
// vectors, and are represented as two different sets P (positive, i.e.
// with label = +1), and N (negative, i.e. label = -1).

ArrayList<Vector2d> Ps;
ArrayList<Vector2d> Ns;

Perceptron perceptron = new Perceptron(100.);

Vector2d M = new Vector2d(50., 50.);


// The left, right, top, and botton screen limits in worlds coordinates.
final float WorldLeft   =  -10.0;
final float WorldRight  = +130.0;
final float WorldTop    = +110.0;
final float WorldBottom =  -10.0;

boolean showLineEq = true;

// Indicates which point was left-pressed, if any.
int leftState = 0; // 0: not pressed, -1: an N was pressed; +1: a P was pressed
int leftIndex;     // Index of left-pressed point, if leftState != 0

// Indicates which point was right-pressed, if any.
int rightState = 0; // 0: not pressed, -1: an N was pressed; +1: a P was pressed
int rightIndex;     // Index of the right-pressed point, if rightState != 0

boolean mouseDragsM = false;
boolean mouseDragsW = false;


// Converts screen to world coordinates.
Vector2d screen2world(int x, int y)
{
    return new Vector2d(map(x, 0, width, WorldLeft, WorldRight),
    map(y, 0, height, WorldTop, WorldBottom));
}


// Converts world to screen coordinates.
Vector2d world2screen(Vector2d p)
{
    return new Vector2d(map(p.x, WorldLeft, WorldRight, 0, width),
    map(p.y, WorldTop, WorldBottom, 0, height));
}


// Formats a float with 1 digit after the comma.
String format1(float v)
{
    int width = max(floor(log(v) / log(10)), 1);
    return nfp(v, width, 1);
}



// Use one of three different scenarios to generate random samples.
// Scenario 0: clear the list, do not generate any samples
// Scenario 1: samples are linearly separated, but only by a narrow gap
// Scenario 2: samples are linearly separated by a huge gap
// Scenario 3: samples are NOT linearly separated -- note that the ordinary
//             Perceptron algorithm will NOT converge in this scenario.
void initSamples(int scenario)
{
    Ps = new ArrayList<Vector2d>();
    Ns = new ArrayList<Vector2d>();

    if (scenario != 0) {
        // Generate n negative and p positive samples.
        // The line w . (x,y) + b separates negative from positive samples;
        // i.e. this is the "model" we want the Perceptron to learn.
        int n = round(random(20, 40));
        int p = round(random(20, 40));
        Vector2d w = new Vector2d(5, 3);
        float b = -400;
    
        Vector2d offset = new Vector2d(0., 0.);
    
        switch (scenario) {
        case 1:
        default:
            break;
    
        case 2:
            offset = new Vector2d(10., 10.);
            break;
    
        case 3:
            offset = new Vector2d(-5., -5.);
            break;
        }
    
        while (Ns.size () < n || Ps.size() < p) {
            Vector2d r = new Vector2d(random(0., 100.), random(0., 100.));
    
            if (dot(w, r) + b < 0) {
                if (Ns.size() < n) {
                    Ns.add(sub(r, offset));
                }
            } else {
                if (Ps.size() < p) {
                    Ps.add(add(r, offset));
                }
            }
        }
    }

    //perceptron = new Perceptron(100.);

    perceptron.setWeights(new Vector2d(15., 15.));
    perceptron.setBias(-600.);

    // Move M onto the new separating line.
    M.set(50., 50.);
    perceptron.moveToSeparator(M);
}


void setup()
{
    size(700, 600);

    PFont myFont = createFont("Arial", 20);
    textFont(myFont);

    //randomSeed(42);

    initSamples(1);
    
    rectMode(CENTER);
}


void draw()
{
    background(255);

    // Determine whether mouse is over one of the two "buttons":
    Vector2d world = screen2world(mouseX, mouseY);
    boolean mouseOverM = (distn(world, M) <= 4.);
    boolean mouseOverW = (distn(world, add(M, perceptron.weights())) <= 4.);

    // Determine angle of vector w to rotate separating lines.
    float wMag = magn(perceptron.weights());
    float wRad = angleBetween2D(new Vector2d(0., 1.), perceptron.weights());

    pushMatrix();
    scale(width / (WorldRight - WorldLeft), height / (WorldBottom - WorldTop));
    translate(-WorldLeft, -WorldTop);

    pushMatrix();
    translate(M.x, M.y);
    rotate(wRad);

    // Draw red and blue gradients around separating line
    strokeWeight(1);

    for (int c = 1; c < 16; ++c) {
        stroke(lerpColor(#FF2020, #FFFFFF, c/16.));
        line(-200, c / 2., 200, c / 2.);
        stroke(lerpColor(#2020FF, #FFFFFF, c/16.));
        line(-200, -c / 2., 200, -c / 2.);
    }

    // Draw separating line
    stroke(#000000);
    strokeWeight(0.5);
    line(-200, 0, 200, 0);

    popMatrix();

    // Draw coordinate system
    stroke(#000000);
    strokeWeight(0.5);
    fill(#A0A0A0);
    line(-5, 0, 100, 0);
    triangle(0, 105, +2, 100, -2, 100);
    line(0, -5, 0, 100);
    triangle(105, 0, 100, -2, 100, +2);

    for (int k = 10; k <= 100; k += 10) {
        line(k, 0, k, 2);
        line(0, k, 2, k);
    }

    // Draw all negative and positive points
    stroke(#FF2020);
    strokeWeight(0.5);
    fill(#FF60A0);

    for (int k = 0; k < Ps.size (); ++k) {
        triangle(Ps.get(k).x - 1, Ps.get(k).y - 1,
        Ps.get(k).x, Ps.get(k).y + 1,
        Ps.get(k).x + 1, Ps.get(k).y - 1);
    }

    stroke(#2020FF);
    strokeWeight(0.5);
    fill(#60A0FF);

    for (int k = 0; k < Ns.size (); ++k) {
        triangle(Ns.get(k).x - 1, Ns.get(k).y + 1,
        Ns.get(k).x, Ns.get(k).y - 1,
        Ns.get(k).x + 1, Ns.get(k).y + 1);
    }

    pushMatrix();
    translate(M.x, M.y);
    rotate(wRad);

    // Draw handle with "buttons".
    stroke(#000000);
    strokeWeight(1);
    fill(#808080);
    line(0, 0, 0, wMag);

    strokeWeight((mouseOverM || mouseDragsM) ? 1.5 : 1);
    ellipse(0, 0, 5, 5);

    strokeWeight((mouseOverW || mouseDragsW) ? 1.5 : 1);
    triangle(-2, wMag - 2, 0, wMag + 2, +2, wMag - 2);

    popMatrix();

    // Create string for separating line. As the Java variant,
    //     String.format("%.1f x + %.1f y", w.x, w.y);
    // does not work in JavaScript mode, format it in a portable way:
    String separating = format1(perceptron.weights().x) + new String(" x")
        + format1(perceptron.weights().y) + new String(" y")
            + format1(perceptron.bias());

    // Print the equation of the separating line.
    if (showLineEq) {
        pushMatrix();
        scale(1, -1);

        ArrayList<Integer> cf = perceptron.getConfusionMatrix(Ns, Ps);

        String cf1 = nf(cf.get(0), 2) + new String(", ") + nf(cf.get(1), 2);
        String cf2 = nf(cf.get(2), 2) + new String(", ") + nf(cf.get(3), 2);

        String separating2 = separating + new String(" = 0");

        fill(#000000);

        textSize(4);
        textAlign(LEFT, CENTER);
        text(separating2, M.x + 4, -M.y + 4);
        //text(cf1, M.x + 8, -M.y + 10);
        //text(cf2, M.x + 8, -M.y + 14);

        popMatrix();
    }

    // Draw left-pressed point (if any).
    if (leftState != 0) {
        Vector2d U = (leftState < 0 ? Ns.get(leftIndex) : Ps.get(leftIndex));

        strokeWeight(0.8);

        if (leftState == -1) {
            stroke(#2020FF);
            fill(#60A0FF);
            triangle(U.x - 1, U.y + 1, U.x, U.y - 1, U.x + 1, U.y + 1);
        } else if (leftState == +1) {
            stroke(#FF2020);
            fill(#FF60A0);
            triangle(U.x - 1, U.y - 1, U.x, U.y + 1, U.x + 1, U.y - 1);
        }
    }

    // Draw right-pressed point (if any), and pop up some informative text.
    if (rightState != 0) {
        Vector2d U = (rightState < 0 ? Ns.get(rightIndex) : Ps.get(rightIndex));

        strokeWeight(0.8);

        if (rightState == -1) {
            stroke(#2020FF);
            fill(#60A0FF);
            triangle(U.x - 1, U.y + 1, U.x, U.y - 1, U.x + 1, U.y + 1);
        } else if (rightState == +1) {
            stroke(#FF2020);
            fill(#FF60A0);
            triangle(U.x - 1, U.y - 1, U.x, U.y + 1, U.x + 1, U.y - 1);
        }

        float rhs = perceptron.evaluate(U);

        String line1 = new String("(") + format1(U.x) + new String(",")
            + format1(U.y) + new String(")");

        String line2 = format1(rhs);

        stroke(#000000);
        strokeWeight(0.6);
        fill(#FFFFFF);
        rect(U.x + 20, U.y, 36, 12);

        pushMatrix();
        scale(1, -1);

        fill(#000000);
        textSize(4);
        textAlign(LEFT, CENTER);
        text(line1, U.x + 4, -U.y - 5);
        text(line2, U.x + 4, -U.y + 1);

        popMatrix();
    }

    popMatrix();
    
    stroke(#000000);
    textSize(20);
    textAlign(CENTER, CENTER);

    // Draw the "Estimate" and "Learn" buttons
    fill(#FFE010);
    rect(640, 50, 40, 40, 12);
    fill(#000000);
    text("~", 640, 50);

    fill(#90FF20);
    rect(640, 100, 40, 40, 12);
    fill(#000000);
    text("!", 640, 100);

    // Draw the "scenario" buttons
    fill(#9090FF);
    rect(640, 400, 40, 40, 12);
    fill(#000000);
    text("X", 640, 400);
    
    fill(#9090FF);
    rect(640, 450, 40, 40, 12);
    fill(#000000);
    text("1", 640, 450);

    fill(#9090FF);
    rect(640, 500, 40, 40, 12);
    fill(#000000);
    text("2", 640, 500);

    fill(#9090FF);
    rect(640, 550, 40, 40, 12);
    fill(#000000);
    text("3", 640, 550);
}


void mousePressed()
{
    // Handle the following cases:
    // 1) Left-press on one of the buttons: trigger associated action
    // 2) Left-press on midpoint or arrow head: start to drag
    // 3) Left- or right-press on one of N or P points: set state/index
    // 4) Left- or right-press in empty region: add one N or P point

    if (mouseButton == LEFT && dist(mouseX, mouseY, 640, 50) < 22) {
        if (Ns.size() > 0 && Ps.size() > 0) {
            perceptron.initialize(Ns, Ps);
            M.set(50, 50);
            perceptron.moveToSeparator(M);
        }
    } else if (mouseButton == LEFT && dist(mouseX, mouseY, 640, 100) < 22) {
        if (Ns.size() > 0 && Ps.size() > 0) {
            perceptron.learn(Ns, Ps);
            M.set(50, 50);
            perceptron.moveToSeparator(M);
        }
    } else if (mouseButton == LEFT && dist(mouseX, mouseY, 640, 400) < 22) {
        initSamples(0);
    } else if (mouseButton == LEFT && dist(mouseX, mouseY, 640, 450) < 22) {
        initSamples(1);
    } else if (mouseButton == LEFT && dist(mouseX, mouseY, 640, 500) < 22) {
        initSamples(2);
    } else if (mouseButton == LEFT && dist(mouseX, mouseY, 640, 550) < 22) {
        initSamples(3);
    } else {
        Vector2d world = screen2world(mouseX, mouseY);
        Vector2d Mw = add(M, perceptron.weights());

        // Handle midpoint and arrow, which might be dragged.
        if (mouseButton == LEFT && distn(world, M) <= 4.) {
            mouseDragsM = true;
        } else if (mouseButton == LEFT && distn(world, Mw) <= 4.) {
            mouseDragsW = true;
        } else {
            int pressedState = 0;
            int pressedIndex = 0;

            for (int k = 0; pressedState == 0 && k < Ns.size (); ++k) {
                if (distn(world, Ns.get(k)) <= 2.) {
                    pressedState = -1;
                    pressedIndex = k;
                }
            }

            for (int k = 0; pressedState == 0 && k < Ps.size (); ++k) {
                if (distn(world, Ps.get(k)) <= 2.) {
                    pressedState = +1;
                    pressedIndex = k;
                }
            }

            if (mouseButton == LEFT) {
                leftState = pressedState;
                leftIndex = pressedIndex;
            } else if (mouseButton == RIGHT) {
                rightState = pressedState;
                rightIndex = pressedIndex;
            }
            
            // If no point was clicked with left mouse, add one to N
            if (mouseButton == LEFT && leftState == 0) {
                Vector2d r = screen2world(mouseX, mouseY);
                Ns.add(r);
            }
            // If no point was clicked with right mouse, add one to P
            else if (mouseButton == RIGHT && rightState == 0) {
                Vector2d r = screen2world(mouseX, mouseY);
                Ps.add(r);
            }
        }
    }
}


void mouseDragged()
{
    if (mouseButton == LEFT) {
        Vector2d world = screen2world(mouseX, mouseY);
        world.x = constrain(world.x, WorldLeft, WorldRight);
        world.y = constrain(world.y, WorldBottom, WorldTop);

        if (mouseDragsM) {
            M = world;
            perceptron.setBias(dot(neg(perceptron.weights()), M));
        } else if (mouseDragsW) {
            perceptron.setWeights(sub(world, M));
            perceptron.setBias(dot(neg(perceptron.weights()), M));
        }
    }
}


void mouseReleased()
{
    // If a point was left-pressed before, update the Perceptron weights w.r.t.
    // this point on mouse release.
    if (leftState != 0) {
        Vector2d U = (leftState == -1 ? Ns.get(leftIndex) : Ps.get(leftIndex));
        float label = leftState; // -1 or +1

        if (perceptron.update(U, label)) {
            M.x = 50;
            M.y = 50;
            perceptron.moveToSeparator(M);
        }
    }

    mouseDragsM = false;
    mouseDragsW = false;

    leftState = 0;
    rightState = 0;
}
