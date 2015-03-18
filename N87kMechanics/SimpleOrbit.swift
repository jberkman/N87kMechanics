//
//  SimpleOrbit.swift
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

public class SimpleOrbit: NSObject {

    // Inputs
    public dynamic var primaryBody: Body?
    public dynamic var gravitationalParameter = 0.0

    public dynamic var eccentricity = 0.0
    public dynamic var semiMajorAxis = 0.0
    public dynamic var inclination = 0.0
    public dynamic var longitudeOfAscendingNode = 0.0
    public dynamic var argumentOfPeriapsis = 0.0
    public dynamic var meanAnomalyAtEpoch = 0.0

    public dynamic var epoch: NSTimeInterval = 0
    public dynamic var timeToTransition1: NSTimeInterval = 0
    public dynamic var timeToTransition2: NSTimeInterval = 0

}

extension SimpleOrbit: Orbit {

    // Outputs
    public var isStable: Bool { return N87kMechanics.isStable(self) }

    // Periapsis
    public dynamic var periapsis: Double {
        get { return N87kMechanics.periapsis(self) }
        set { setPeriapsis(self, newValue) }
    }

    @objc public class func keyPathsForValuesAffectingPeriapsis() -> NSSet {
        return NSSet(array: [ "eccentricity", "primaryBody.radius", "semiMajorAxis" ])
    }

    public dynamic var timeOfPeriapsisPassage: NSTimeInterval {
        return N87kMechanics.timeOfPeriapsisPassage(self)
    }

    @objc public class func keyPathsForValuesAffectingTimeOfPeriapsisPassage() -> NSSet {
        return keyPathsForValuesAffectingMeanMotion().setByAddingObject("meanAnomalyAtEpoch")
    }

    public dynamic var timeToPeriapsis: NSTimeInterval {
        return N87kMechanics.timeToPeriapsis(self)
    }

    @objc public class func keyPathsForValuesAffectingTimeToPeriapsis() -> NSSet {
        return keyPathsForValuesAffectingMeanAnomaly().setByAddingObjectsFromSet(keyPathsForValuesAffectingMeanMotion())
    }

    // Apoapsis
    public dynamic var apoapsis: Double {
        get { return N87kMechanics.apoapsis(self) }
        set { setApoapsis(self, newValue) }
    }

    @objc public class func keyPathsForValuesAffectingApoapsis() -> NSSet {
        return keyPathsForValuesAffectingPeriapsis()
    }

    public dynamic var timeToApoapsis: NSTimeInterval {
        return N87kMechanics.timeToApoapsis(self)
    }

    @objc public class func keyPathsForValuesAffectingTimeToApoapsis() -> NSSet {
        return keyPathsForValuesAffectingTimeToPeriapsis()
    }

    // Mean Motion / Period
    public dynamic var meanMotion: Double {
        return N87kMechanics.meanMotion(self)
    }

    @objc public class func keyPathsForValuesAffectingMeanMotion() -> NSSet {
        return NSSet(array: [ "primaryBody.orbit.gravitationalParameter", "semiMajorAxis" ])
    }

    public dynamic var period: NSTimeInterval {
        return N87kMechanics.period(self)
    }

    @objc public class func keyPathsForValuesAffectingPeriod() -> NSSet {
        return keyPathsForValuesAffectingMeanMotion()
    }

    // Mean Anomaly
    public func meanAnomalyAtTime(time: NSTimeInterval) -> Double {
        return N87kMechanics.meanAnomalyAtTime(self, time)
    }

    public var meanAnomaly: Double {
        return N87kMechanics.meanAnomaly(self)
    }

    @objc public class func keyPathsForValuesAffectingMeanAnomaly() -> NSSet {
        return keyPathsForValuesAffectingMeanMotion().setByAddingObjectsFromArray([ "epoch", "meanAnomalyAtEpoch" ])
    }

    public func meanAnomalyWithTrueAnomaly(trueAnomaly: Double) -> Double {
        return N87kMechanics.meanAnomalyWithTrueAnomaly(self, trueAnomaly)
    }

    // True Anomaly
    public func trueAnomalyAtTime(time: NSTimeInterval) -> Double {
        return N87kMechanics.trueAnomalyAtTime(self, time)
    }

    public dynamic var trueAnomaly: Double {
        return N87kMechanics.trueAnomaly(self)
    }

    @objc public class func keyPathsForValuesAffectingTrueAnomaly() -> NSSet {
        return keyPathsForValuesAffectingMeanAnomaly().setByAddingObjectsFromArray([ "eccentricity" ])
    }

    // Eccentric Anomaly
    public func eccentricAnomalyWithTrueAnomaly(trueAnomaly: Double) -> Double {
        return N87kMechanics.eccentricAnomalyWithTrueAnomaly(self, trueAnomaly)
    }

    public var eccentricAnomaly: Double {
        return N87kMechanics.eccentricAnomaly(self)
    }

    @objc public class func keyPathsForValuesAffectingEccentricAnomaly() -> NSSet {
        return keyPathsForValuesAffectingTrueAnomaly()
    }

    // Radius
    public func radiusWithTrueAnomaly(trueAnomaly: Double) -> Double {
        return N87kMechanics.radiusWithTrueAnomaly(self, trueAnomaly)
    }

    public dynamic var radius: Double {
        return N87kMechanics.radius(self)
    }

    @objc public class func keyPathsForValuesAffectingRadius() -> NSSet {
        return keyPathsForValuesAffectingTrueAnomaly().setByAddingObject("semiMajorAxis")
    }

    // Velocity
    public func relativeVelocityWithRadius(radius: Double) -> Double {
        return N87kMechanics.relativeVelocityWithRadius(self, radius)
    }

    public dynamic var relativeVelocity: Double {
        return N87kMechanics.relativeVelocity(self)
    }

    @objc public class func keyPathsForValuesAffectingRelativeVelocity() -> NSSet {
        return NSSet(array: [ "primaryBody.orbit.gravitationalParameter", "radius", "semiMajorAxis" ])
    }

    // Transfers
    public dynamic var anglePrograde: Double {
        return N87kMechanics.anglePrograde(self)
    }

    @objc public class func keyPathsForValuesAffectingAnglePrograde() -> NSSet {
        return keyPathsForValuesAffectingTrueAnomaly().setByAddingObjectsFromArray([ "argumentOfPeriapsis", "primaryBody.orbit.argumentOfPeriapsis", "primaryBody.orbit.longitudeOfAscendingNode", "primaryBody.orbit.trueAnomaly", "longitudeOfAscendingNode" ])
    }

    public func timeIntervalUntilEjectionAngle(ejectionAngle: Double) -> NSTimeInterval {
        return N87kMechanics.timeIntervalUntilEjectionAngle(self, ejectionAngle)
    }

    public func thetaAtTime(time: NSTimeInterval) -> Double {
        return N87kMechanics.thetaAtTime(self, time)
    }

    public dynamic var theta: Double {
        return N87kMechanics.theta(self)
    }

    @objc public class func keyPathsForValuesAffectingTheta() -> NSSet {
        return keyPathsForValuesAffectingTrueAnomaly().setByAddingObject([ "longitudeOfAscendingNode", "meanAnomalyAtEpoch" ])
    }

    // Misc
    public override func copy() -> AnyObject {
        let orbit = SimpleOrbit()
        N87kMechanics.copy(orbit, self)
        return orbit
    }

}
