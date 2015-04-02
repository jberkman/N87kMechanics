//
//  SimpleManoeuvre.swift
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

private let apoapsisContext = ObserverContext(keyPath: "apoapsis")
private let periapsisContext = ObserverContext(keyPath: "periapsis")
private let observerContexts = [ apoapsisContext, periapsisContext ]

public class SimpleManoeuvre: NSObject {

    // Inputs
    public dynamic var sourceBody: Body? { didSet { recalculateDeltaV() } }
    public dynamic var sourceOrbit: Orbit? {
        didSet {
            for context in observerContexts {
                oldValue?.removeObserver(self, context: context)
                sourceOrbit?.addObserver(self, context: context)
            }
            recalculateDeltaV()
        }
    }

    public dynamic var targetBody: Body? { didSet { recalculateDeltaV() } }
    public dynamic var targetOrbit: Orbit? {
        didSet {
            for context in observerContexts {
                oldValue?.removeObserver(self, context: context)
                targetOrbit?.addObserver(self, context: context)
            }
            recalculateDeltaV()
        }
    }

    public dynamic var aerobrake: Bool = true { didSet { recalculateDeltaV() } }
    public dynamic var initialTime: NSTimeInterval = 0 { didSet { recalculateDeltaV() } }

    // Outputs
    public dynamic var deltaV = 0.0

    public dynamic var hyperbolicExcessEscapeVelocity = 0.0
    public dynamic var hyperbolicExcessCaptureVelocity = 0.0
    public dynamic var transferTime: NSTimeInterval = 0
    public dynamic var travelTime: NSTimeInterval = 0
    public dynamic var transferPhaseAngle = 0.0

    deinit {
        for context in observerContexts {
            sourceOrbit?.removeObserver(self, context: context)
            targetOrbit?.removeObserver(self, context: context)
        }
    }

}

extension SimpleManoeuvre: Manoeuvre {

    public var isTransfer: Bool { return N87kMechanics.isTransfer(self) }

    @objc public class func keyPathsForValuesAffectingIsTransfer() -> NSSet {
        return NSSet(array: [ "sourceBody", "targetBody" ])
    }

    public dynamic var ejectionAngle: NSNumber? { return N87kMechanics.ejectionAngle(self) }

    @objc public class func keyPathsForValuesAffectingEjectionAngle() -> NSSet {
        return keyPathsForValuesAffectingEjectionVelocity()
    }

    public dynamic var currentPhaseAngle: NSNumber? { return N87kMechanics.currentPhaseAngle(self) }
    public dynamic var ejectionVelocity: NSNumber? { return N87kMechanics.ejectionVelocity(self) }

    @objc public class func keyPathsForValuesAffectingEjectionVelocity() -> NSSet {
        return NSSet(array: [ "sourceBody.radius", "sourceOrbit.periapsis", "sourceBody.sphereOfInfluence", "sourceBody.orbit.gravitationalParameter", "deltaV" ])
    }

    public func ejectionVelocityWithOrbit(orbit: Orbit) -> NSNumber? { return N87kMechanics.ejectionVelocityWithOrbit(self, orbit) }

    public dynamic var ejectionDeltaV: NSNumber? { return N87kMechanics.ejectionDeltaV(self) }
    public func ejectionDeltaVWithOrbit(orbit: Orbit) -> NSNumber? { return N87kMechanics.ejectionDeltaVWithOrbit(self, orbit) }

    public var captureDeltaV: NSNumber? { return N87kMechanics.captureDeltaV(self) }

    public func deltaVWithOrbit(orbit: Orbit) -> NSNumber? { return N87kMechanics.deltaVWithOrbit(self, orbit) }

    public var descriptiveText: String { return N87kMechanics.descriptiveText(self) }

    public override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        switch context {
        case &apoapsisContext.context, &periapsisContext.context: recalculateDeltaV()
        default: super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }

    public func createLaunchOrbit() {
    }

    public func recalculateDeltaV() { N87kMechanics.recalculateDeltaV(self) }

}
