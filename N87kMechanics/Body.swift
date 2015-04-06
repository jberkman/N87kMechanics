//
//  Body.swift
//  N87kMechanics
//
//  Created by jacob berkman on 2015-03-05.
//  Copyright © 2015 jacob berkman
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

@objc
public protocol Body: NSObjectProtocol {
    var bodyID: Int64 { get }
    var name: String { get }

    var atmosphereContainsOxygen: Bool { get }
    var mass: Double { get }
    var maxAtmosphere: Double { get }
    var radius: Double { get }
    var rotationPeriod: NSTimeInterval { get }
    var sphereOfInfluence: Double { get }

    var tidallyLocked: NSNumber? { get }

    var orbit: Orbit? { get }
    var secondaryBodies: NSSet { get }
    func addSecondaryBody(body: Body)

    var parkingOrbitHeight: NSNumber? { get }
    var synchronousOrbitHeight: NSNumber? { get }
    var semiSynchronousOrbitHeight: NSNumber? { get }
}

public func tidallyLocked(body: Body) -> Bool? {
    if let period = body.orbit?.period {
        return body.rotationPeriod == period
    }
    return nil
}

public func parkingOrbitHeight(body: Body) -> Double {
    return 10_000 + 10_000 * round(body.maxAtmosphere / 10_000)
}

public func synchronousOrbitHeight(body: Body) -> Double? {
    if let µ = body.orbit?.gravitationalParameter {
        return pow(µ * pow(body.rotationPeriod / twoπ, 2), 1.0 / 3) - body.radius
    }
    return nil
}

public func semiSynchronousOrbitHeight(body: Body) -> Double? {
    if let µ = body.orbit?.gravitationalParameter {
        return pow(µ * pow(body.rotationPeriod / (2 * twoπ), 2), 1.0 / 3) - body.radius
    }
    return nil
}

public func generate(body: Body) -> GeneratorOf<Body> {
    var bodies: IndexingGenerator<[Body]>!
    var bodyGenerator: GeneratorOf<Body>!

    return GeneratorOf {
        if bodies == nil {
            bodies = (body.secondaryBodies.allObjects as [Body]).generate()
            return body
        }

        while true {
            while bodyGenerator == nil {
                if let body = bodies.next() {
                    bodyGenerator = generate(body)
                } else {
                    return nil
                }
            }

            if let body = bodyGenerator.next() {
                return body
            } else {
                bodyGenerator = nil
            }
        }
    }
}
