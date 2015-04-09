//
//  SimpleBody.swift
//  N87kMechanics
//
//  Created by jacob berkman on 2015-03-15.
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

public class SimpleBody: NSObject {

    public let bodyID: Int64
    public let name: String

    public let atmosphereContainsOxygen: Bool
    public let mass: Double
    public let maxAtmosphere: Double
    public let radius: Double
    public let rotationPeriod: NSTimeInterval
    public let sphereOfInfluence: Double

    public let orbit: Orbit? = SimpleOrbit()
    public let secondaryBodies: NSSet = NSMutableSet()

    public init(bodyID: Int64, name: String, mass: Double, radius: Double, rotationPeriod: Double, sphereOfInfluence: Double, maxAtmosphere: Double = 0, atmosphereContainsOxygen: Bool = false) {
        self.bodyID = bodyID
        self.name = name
        self.mass = mass
        self.radius = radius
        self.rotationPeriod = rotationPeriod
        self.sphereOfInfluence = sphereOfInfluence
        self.maxAtmosphere = maxAtmosphere
        self.atmosphereContainsOxygen = atmosphereContainsOxygen
        super.init()
    }

    public init(values: NSDictionary) {
        bodyID = (values["bodyID"] as! NSNumber).longLongValue
        name = values["name"] as! String
        mass = (values["mass"] as! NSNumber).doubleValue
        radius = (values["radius"] as! NSNumber).doubleValue
        rotationPeriod = (values["rotationPeriod"] as! NSNumber).doubleValue
        sphereOfInfluence = (values["sphereOfInfluence"] as! NSNumber).doubleValue
        maxAtmosphere = (values["maxAtmosphere"] as? NSNumber)?.doubleValue ?? 0
        atmosphereContainsOxygen = (values["atmosphereContainsOxygen"] as? NSNumber)?.boolValue ?? false
        super.init()
    }

}

extension SimpleBody: Body {

    public var tidallyLocked: NSNumber? { return N87kMechanics.tidallyLocked(self) }

    public var parkingOrbitHeight: Double { return N87kMechanics.parkingOrbitHeight(self) }
    public var synchronousOrbitHeight: NSNumber? { return N87kMechanics.synchronousOrbitHeight(self) }
    public var semiSynchronousOrbitHeight: NSNumber? { return N87kMechanics.semiSynchronousOrbitHeight(self) }

    public func addSecondaryBody(body: Body) {
        body.orbit?.primaryBody = self
        (secondaryBodies as! NSMutableSet).addObject(body)
    }

}
