//
//  Manoeuvre.swift
//  N87kMechanics
//
//  Created by jacob berkman on 2014-11-29.
//  Copyright © 2014 jacob berkman
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the “Software”), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.

//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//

import Foundation

public class Manoeuvre: NSObject {

    public dynamic var parentBody: Body? { didSet { recompute() } }
    public dynamic var sourceOrbit: Orbit? { didSet { recompute() } }
    public dynamic var targetOrbit: Orbit? { didSet { recompute() } }
    public dynamic var aerobrake: Bool = true { didSet { recompute() } }
    public internal(set) dynamic var deltaV = 0.0

    public func recompute() {
        if let µ = parentBody?.orbit.gravitationalParameter {
            if let source = sourceOrbit {
                if let target = targetOrbit {
                    let transfer = source.copy() as Orbit
                    transfer.semiMajorAxis = (source.periapsis + target.apoapsis) / 2
                    let v0 = source.velocityWithGravitationalConstant(µ, atRadius: source.periapsis)
                    let v1 = transfer.velocityWithGravitationalConstant(µ, atRadius: source.periapsis)
                    let v2 = transfer.velocityWithGravitationalConstant(µ, atRadius: target.apoapsis)
                    let v3 = target.velocityWithGravitationalConstant(µ, atRadius: target.apoapsis)
                    deltaV = abs(v1 - v0) + abs(v3 - v2)
                }
            }
        }
    }

}
