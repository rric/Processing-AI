# Vector function demo in Processing.py

from __future__ import division
       
def setup():
    size(960, 720)

# The coordinate system for pixels in a window usually has its
# y-axis top-down; i.e. it looks like this:
#      
#      +------------------->
#      |              x-coordinate, in [0, width)
#      |
#      |
#      |
#      V  y-coordinate, in [0, height)
#
# (see https://py.processing.org/tutorials/drawing/)
#
# In this sketch, coordinates are transformed to a "Cartesian"
# coordinate system, with its origin at 3/4 of the windows height:
# 
#              ^  y-coordinate, in [-height/4, 3*height/4)
#              |
#              |
#              |
#              |     x-coordinate, in [-width/2, width/2)
#    ----------+---------->
#              |
#              |
#

# Returns the current mouse position in Cartesian coordinates
def mousePosition():
    x = mouseX - width/2
    y = 3 * height/4 - mouseY
    return PVector(x, y)


# Draws an arrow --> from the begining point (bx, by) to the
# end point (ex, ey), and places a label to the middle of it
def arrow(bx, by, ex, ey, label=""):
    fill(0)
    stroke(0)
    
    dx = ex - bx
    dy = ey - by
    if dy > 0:
        angle = PI + PVector(dx, dy).heading()
    else:
        angle = PVector(-dx, -dy).heading()
        
    leftend = PVector(ex, ey) + 12 * PVector.fromAngle(angle + 0.4)
    rightend = PVector(ex, ey) + 12 * PVector.fromAngle(angle - 0.4)

    line(bx, by, ex, ey)
    triangle(ex, ey, leftend.x, leftend.y, rightend.x, rightend.y)
    
    if label:
        textAlign(CENTER)
        pushMatrix()

        translate(lerp(bx, ex, 0.5), lerp(by, ey, 0.5))
        scale(-1, 1)
        if angle > HALF_PI and angle < 3*HALF_PI:
            rotate(-angle)
        else:
            rotate(PI-angle)
            
        text(label, 0, -8)
        popMatrix()


# Draws a sequence of arrows, from one position to the next
def drawArrows(positions, labels = []):
    n = len(positions)
    for k in range(n-1):
        arrow(positions[k].x, positions[k].y, 
              positions[k+1].x, positions[k+1].y, 
              labels[k] if k < len(labels) else "")


# Draws a sequence of circles, with colors lerped from black
def drawCircles(positions, col):
    n = len(positions)
    for k, pos in enumerate(positions):
        fill(lerpColor(0, col, (k+1)/n))
        circle(pos.x, pos.y, 40)


# Color hex triplets taken from http://latexcolor.com/
ivory = "#FFFFF0"
airforceblue = "#5D8AA8"
americanrose = "#FF033E"
bananayellow = "#FFE135"
lasallegreen = "#087830"

startpos = 100 * PVector.random2D()
firstvec = 150 * PVector.random2D()
secondvec = 150 * PVector.random2D()

# Generates new random positions and vectors on mouse click
def mousePressed():
    global startpos, firstvec, secondvec
    startpos = 100 * PVector.random2D()
    firstvec = 150 * PVector.random2D()
    secondvec = 150 * PVector.random2D()


def draw():
    background(ivory) 
    rectMode(CENTER)

    # === DO NOT REMOVE OR CHANGE THESE LINES ===
    # Transforms coordinates to Cartesian system
    translate(width/2, 3*height/4)
    scale(1, -1)
    # === DO NOT REMOVE OR CHANGE THESE LINES ===

    strokeWeight(2)
    textSize(24)

    mousevec = mousePosition()
    
    arrow(0, 0, mousevec.x, mousevec.y, "mouse")

    pos1 = startpos + 0.8 * mousevec
    pos2 = pos1 + firstvec
    pos3 = pos2 + 0.4 * mousevec
    pos4 = pos3 + secondvec

    positions = [startpos, pos1, pos2, pos3, pos4]
    labels = ["0.8 mouse", "random", "0.4 mouse", "random"]
    drawCircles(positions, americanrose)
    drawArrows(positions, labels)
