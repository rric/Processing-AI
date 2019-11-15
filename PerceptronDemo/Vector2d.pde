/* Vector2d.pde
 *
 * Copyright 2013, 2014, 2015 Roland Richter.
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


// Class Vector2d replaces built-in PVector and adds functions
// add(.,.), sub(.,.), mult(.,.), dot(.,.), dist(.), magn(.), 
// and a modified version of angleBetween(.)

class Vector2d
{
    public Vector2d() {
        this.x = 0.;
        this.y = 0.;
    }

    public Vector2d(float x, float y) {
        this.x = x;
        this.y = y;
    }


    public void set(float x, float y) {
        this.x = x;
        this.y = y;
    }

    public float x, y;
}


float dot(Vector2d v, Vector2d w) 
{
    return v.x * w.x + v.y * w.y;
}


// Returns the squared magnitude of the vector.
float magnSq(Vector2d v) 
{
    return v.x * v.x + v.y * v.y; // i.e. dot(v, v);
}


// Returns the magnitude of the vector.
float magn(Vector2d v) 
{
    return (float) Math.sqrt(magnSq(v));
}


Vector2d neg(Vector2d v) 
{
    return new Vector2d(-v.x, -v.y);
}


Vector2d add(Vector2d v, Vector2d w)
{
    return new Vector2d(v.x + w.x, v.y + w.y);
}


Vector2d sub(Vector2d v, Vector2d w)
{
    return new Vector2d(v.x - w.x, v.y - w.y);
}


// Multiplies a vector by a scalar.
Vector2d mult(float l, Vector2d v)
{
    return new Vector2d(l * v.x, l * v.y);
}


// Returns the Euclidean distance of v and w.
float distn(Vector2d v, Vector2d w) 
{
    float dx = v.x - w.x;
    float dy = v.y - w.y;

    return (float) Math.sqrt(dx * dx + dy * dy);
}


// Computes angle between vectors v and w in the range of [0, 2 PI).
// This differs from PVector.angleBetween() which returns a value in [0, PI].
float angleBetween2D(Vector2d v, Vector2d w)
{
    float magV = magn(v);
    float magW = magn(w);

    if (magV == 0. || magW == 0.) {
        return 0.;
    }

    float cosPhi = dot(v, w) / (magV * magW);
    float sinPhi = (v.x * w.y - w.x * v.y) / (magV * magW);

    float angle = acos(cosPhi);

    if (sinPhi < 0) {
        angle = TWO_PI - angle;
    }

    return angle;
}

