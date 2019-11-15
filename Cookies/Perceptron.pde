/* Perceptron.pde
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

// The Perceptron class.

class Perceptron
{
    // The separating line which is to be found by the Perceptron algorithm
    // is given by the normal vector w (weights) and the offset b (bias).
    // The expression
    //      w.x * u.x + w.y * u.y + b
    // should be positive for all u in Ps, and negative for u in Ns.

    private Vector2d w;
    private float b;
    private float eps;


    Perceptron(float epsilon) {
        eps = epsilon;
    }


    void setWeights(Vector2d newW) {
        w = newW;
    }


    Vector2d weights() {
        return w;
    }


    void setBias(float newB) {
        b = newB;
    }


    float bias() {
        return b;
    }


    // Evaluates point u w.r.t. the Percetrons weights and bias.
    float evaluate(Vector2d u) {
        return dot(w, u) + b;
    }


    // Initializes weight and bias of this Perceptron using centers
    // of negative and positive points, respectively.
    void initialize(ArrayList<Vector2d> neg, ArrayList<Vector2d> pos) {
        Vector2d sumNeg = new Vector2d(0., 0.);

        for (int k = 0; k < neg.size (); ++k) {
            sumNeg = add(sumNeg, neg.get(k));
        }

        Vector2d sumPos = new Vector2d(0., 0.);

        for (int k = 0; k < pos.size (); ++k) {
            sumPos = add(sumPos, pos.get(k));
        }

        Vector2d avgN = mult(1. / (float)neg.size(), sumNeg);
        Vector2d avgP = mult(1. / (float)pos.size(), sumPos);

        Vector2d mean = mult(1. / (float)(neg.size() + pos.size()),
        add(sumNeg, sumPos));

        w = sub(avgP, avgN);
        b = -dot(w, mean);

        normalizeTo(10.);

        println("Initialized: " + w.x + " " + w.y + " " + b);
    }


    // Returns a list of the number of
    // true negatives, false negatives, false positives, and true positives.
    ArrayList<Integer> getConfusionMatrix(ArrayList<Vector2d> neg, ArrayList<Vector2d> pos) {
        int tn = 0;
        int fn = 0;
        int fp = 0;
        int tp = 0;

        for (int k = 0; k < neg.size (); ++k) {
            if (evaluate(neg.get(k)) < 0.) {
                ++tn;
            } else {
                ++fp;
            }
        }

        for (int k = 0; k < pos.size (); ++k) {
            if (evaluate(pos.get(k)) < 0.) {
                ++fn;
            } else {
                ++tp;
            }
        }

        ArrayList<Integer> cf = new ArrayList<Integer>();

        cf.add(tn);
        cf.add(fn);
        cf.add(fp);
        cf.add(tp);

        return cf;
    }


    void normalizeTo(float newMag) {
        float mag = magn(w);

        if (mag > 0) {
            w = mult(newMag/mag, w);
            b = (newMag/mag) * b;
        }
    }


    boolean update(Vector2d u, float label) {
        // The two error cases
        // label == -1 && w . u + b >= 0 (an N was wrongly classified as P), and
        // label == +1 && w . u + b <= 0 (an P was wrongly classified as N)
        // can be summarized as
        float delta = -label * evaluate(u);
        // which is positive if and only if the classification is wrong.

        if (delta >= 0) {
            // The Perceptron is often formulated with the update rule
            // w += label * u;
            // b += label;
            // which would be equivalent to set our lambda value to
            // float lambda = 1.;
            // However, one might also choose other values for lambda.
            // The following choice (for any eps being positive),
            float lambda = (delta + eps) / (u.x * u.x + u.y * u.y + 1);
            // has the property that, after updating, w . u + b is _exactly_ eps.

            w.x += label * lambda * u.x;
            w.y += label * lambda * u.y;
            b += label * lambda;

            normalizeTo(10.);

            return true;
        } else {
            return false;
        }
    }


    boolean updateWithTolerance(Vector2d u, float label, float tolerance) {
        // Calculate delta as above; this time, however, only update
        // if delta is "quite large", i.e. if it exceeds the tolerance.
        // This makes only sense if w, b are normalized.
        normalizeTo(10.);

        float delta = -label * evaluate(u);

        if (delta >= tolerance) {
            float lambda = (delta + eps) / (u.x * u.x + u.y * u.y + 1);

            w.x += label * lambda * u.x;
            w.y += label * lambda * u.y;
            b += label * lambda;

            normalizeTo(10.);

            return true;
        } else {
            return false;
        }
    }


    void learn(ArrayList<Vector2d> neg, ArrayList<Vector2d> pos) {
        learnByLists(neg, pos);
    }


    private void learnByRandom(ArrayList<Vector2d> neg, ArrayList<Vector2d> pos) {
        // Learn for a "long" time until (hopefully) finished
        for (int t = 0; t < 1000000; ++t) {

            // Take either a negative or positive sample at random
            float label = (random(1) < 0.5 ? -1 : +1);
            Vector2d u;

            if (label > 0) {
                int r = int(random(pos.size()));
                u = pos.get(r);
            } else {
                int r = int(random(neg.size()));
                u = neg.get(r);
            }

            if (update(u, label)) {
                println("Step " + t + " => " + w.x + " " + w.y + " " + b);
            }
        }
    }


    private void learnByLists(ArrayList<Vector2d> neg, ArrayList<Vector2d> pos) {
        // Create lists of indices of wrongly classified samples
        ArrayList<Vector2d> wrongNeg = new  ArrayList<Vector2d>();
        ArrayList<Vector2d> wrongPos = new  ArrayList<Vector2d>();

        for (int k = 0; k < neg.size (); ++k) {
            if (evaluate(neg.get(k)) > 0) {
                wrongNeg.add(neg.get(k));
            }
        }

        for (int k = 0; k < pos.size (); ++k) {
            if (evaluate(pos.get(k)) < 0) {
                wrongPos.add(pos.get(k));
            }
        }

        int t = 1;
        float tol = 0.;

        int sec = second();

        // As long as there are wrongly classified negative or positive samples,
        // update the Perceptron, then recompute the lists.
        while (wrongNeg.size () > 0 || wrongPos.size() > 0) {

            // If this perceptron classifies most samples wrongly, the reverse
            // perceptron would classifiy most samples correctly!
            // Hence, reverse the perceptron in this case, then continue.
            // This enhances performance *a lot*.
            if (wrongNeg.size() > neg.size()/2 && wrongPos.size() > pos.size()/2) {
                w = neg(w);
                b = -b;
                println("Step", t, ": reverse =>",
                        "w =", w.x, w.y, "b =", b);
            } else {
                float label;

                // If no negative samples are wrong, take a positive one
                if (wrongNeg.size() == 0) {
                    label = +1;
                }
                // If no positve samples are wrong, take a negative one
                else if (wrongPos.size() == 0) {
                    label = -1;
                }
                // Otherwise, take either a negative or positive one
                else {
                    label = (random(1) < 0.5 ? -1 : +1);
                }

                Vector2d u;

                if (label > 0) {
                    int r = int(random(wrongPos.size()));
                    u = wrongPos.get(r);
                } else {
                    int r = int(random(wrongNeg.size()));
                    u = wrongNeg.get(r);
                }

                // First, learn with no tolerance; if not finished after
                // some time, start to use tolerance, and increase it slowly.
                if (t < 10 * (neg.size() + pos.size())) {
                    tol = 0.;
                } else {
                    tol = (float)sqrt(t - 10. * (neg.size() + pos.size()));
                }

                if (updateWithTolerance(u, label, tol)) {
                    if (sec != second()) {
                        println("Step", t,  ": update with tolerance", tol, "=>",
                                "w =", w.x, w.y, "b =", b);
                        sec = second();
                    }
                }
            }

            // Recompute the lists of wrongly classified samples
            wrongNeg.clear();
            wrongPos.clear();

            for (int k = 0; k < neg.size (); ++k) {
                if (evaluate(neg.get(k)) > tol) {
                    wrongNeg.add(neg.get(k));
                }
            }

            for (int k = 0; k < pos.size (); ++k) {
                if (evaluate(pos.get(k)) < -tol) {
                    wrongPos.add(pos.get(k));
                }
            }

            ++t;
        }

        println("Finished after", t, "steps with tolerance", tol, ":",
                "w =", w.x, w.y, "b =", b);
    }


    void moveToSeparator(Vector2d u) {
        float l = (-b - dot(w, u)) / magnSq(w);
        u.x += l * w.x;
        u.y += l * w.y;
    }
}

