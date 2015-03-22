//
//  Orbit.swift
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

private let twoπ = 2 * M_PI

@objc
public protocol Orbit: Observable {

    // Inputs
    var primaryBody: Body? { get set }
    var gravitationalParameter: Double { get set }

    var eccentricity: Double { get set }
    var semiMajorAxis: Double { get set }
    var inclination: Double { get set }
    var longitudeOfAscendingNode: Double { get set }
    var argumentOfPeriapsis: Double { get set }
    var meanAnomalyAtEpoch: Double { get set }

    var epoch: NSTimeInterval { get set }
    var timeToTransition1: NSTimeInterval { get set }
    var timeToTransition2: NSTimeInterval { get set }

    // inout
    var periapsis: NSNumber? { get set }
    var apoapsis: NSNumber? { get set }

    // Output
    var isStable: NSNumber? { get }

    var timeOfPeriapsisPassage: NSNumber? { get }
    var timeToPeriapsis: NSNumber? { get }
    var timeToApoapsis: NSNumber? { get }

    var meanMotion: NSNumber? { get }
    var period: NSNumber? { get }

    var meanAnomaly: NSNumber? { get }
    func meanAnomalyAtTime(time: NSTimeInterval) -> NSNumber?
    func meanAnomalyWithTrueAnomaly(trueAnomaly: Double) -> NSNumber?

    var trueAnomaly: NSNumber? { get }
    func trueAnomalyAtTime(time: NSTimeInterval) -> NSNumber?

    var eccentricAnomaly: NSNumber? { get }
    func eccentricAnomalyWithTrueAnomaly(trueAnomaly: Double) -> NSNumber?

    var radius: NSNumber? { get }
    func radiusWithTrueAnomaly(trueAnomaly: Double) -> NSNumber?

    var relativeVelocity: NSNumber? { get }
    func relativeVelocityWithRadius(radius: Double) -> NSNumber?

    var anglePrograde: NSNumber? { get }
    func timeIntervalUntilEjectionAngle(ejectionAngle: Double) -> NSNumber?

    var theta: NSNumber? { get }
    func thetaAtTime(time: NSTimeInterval) -> NSNumber?

}

public func copy(dest: Orbit, source: Orbit) {
    dest.primaryBody = source.primaryBody
    dest.gravitationalParameter = source.gravitationalParameter

    dest.eccentricity = source.eccentricity
    dest.semiMajorAxis = source.semiMajorAxis
    dest.inclination = source.inclination
    dest.longitudeOfAscendingNode = source.longitudeOfAscendingNode
    dest.argumentOfPeriapsis = source.argumentOfPeriapsis
    dest.meanAnomalyAtEpoch = source.meanAnomalyAtEpoch

    dest.epoch = source.epoch
    dest.timeToTransition1 = source.timeToTransition1
    dest.timeToTransition2 = source.timeToTransition2
}

public func isStable(orbit: Orbit) -> Bool? {
    if let primaryBody = orbit.primaryBody {
        if let apoapsis = orbit.apoapsis?.doubleValue {
            if let periapsis = orbit.periapsis?.doubleValue {
                return periapsis > primaryBody.maxAtmosphere && apoapsis < primaryBody.sphereOfInfluence
            }
        }
    }
    return nil
}

public func periapsis(orbit: Orbit) -> Double? {
    if let radius = orbit.primaryBody?.radius {
        return orbit.semiMajorAxis * (1 - orbit.eccentricity) - radius
    }
    return nil
}

public func setPeriapsis(orbit: Orbit, periapsis: Double) {
    if let radius = orbit.primaryBody?.radius {
        if let oldApoapsis = apoapsis(orbit) {
            orbit.eccentricity = abs(oldApoapsis - periapsis) / (oldApoapsis + periapsis + 2 * radius)
            orbit.semiMajorAxis = (oldApoapsis + periapsis) / 2 + radius
        }
    }
}

public func timeOfPeriapsisPassage(orbit: Orbit) -> NSTimeInterval? {
    if let meanMotion = meanMotion(orbit) {
        return (twoπ - orbit.meanAnomalyAtEpoch) / meanMotion
    }
    return nil
}

public func timeToPeriapsis(orbit: Orbit) -> NSTimeInterval? {
    if let meanMotion = meanMotion(orbit) {
        if let meanAnomaly = meanAnomaly(orbit) {
            return (twoπ - meanAnomaly) / meanMotion
        }
    }
    return nil
}

// Apoapsis
public func apoapsis(orbit: Orbit) -> Double? {
    if let radius = orbit.primaryBody?.radius {
        return orbit.semiMajorAxis * (1 + orbit.eccentricity) - radius
    }
    return nil
}

public func setApoapsis(orbit: Orbit, apoapsis: Double) {
    if let radius = orbit.primaryBody?.radius {
        if let oldPeriapsis = periapsis(orbit) {
            orbit.eccentricity = abs(apoapsis - oldPeriapsis) / (apoapsis + oldPeriapsis + 2 * radius)
            orbit.semiMajorAxis = (apoapsis + oldPeriapsis) / 2 + radius
        }
    }
}

public func timeToApoapsis(orbit: Orbit) -> NSTimeInterval? {
    if let meanMotion = meanMotion(orbit) {
        if let meanAnomaly = meanAnomaly(orbit) {
            return ((3 * M_PI - meanAnomaly) % twoπ) / meanMotion
        }
    }
    return nil
}

// Mean Motion / Period
public func meanMotion(orbit: Orbit) -> Double? {
    if let µ = orbit.primaryBody?.orbit?.gravitationalParameter {
        return sqrt(µ / pow(orbit.semiMajorAxis, 3))
    }
    return nil
}

public func period(orbit: Orbit) -> NSTimeInterval? {
    if let meanMotion = meanMotion(orbit) {
        return twoπ / meanMotion
    }
    return nil
}

// Mean Anomaly
public func meanAnomalyAtTime(orbit: Orbit, time: NSTimeInterval) -> Double? {
    if let meanMotion = meanMotion(orbit) {
        return (orbit.meanAnomalyAtEpoch + (time - orbit.epoch) * meanMotion) % twoπ
    }
    return nil
}

public func meanAnomaly(orbit: Orbit) -> Double? {
    return meanAnomalyAtTime(orbit, UniversalTime.currentUniversalTime.timeIntervalSinceEpoch)
}

public func meanAnomalyWithTrueAnomaly(orbit: Orbit, trueAnomaly: Double) -> Double {
    let E = eccentricAnomalyWithTrueAnomaly(orbit, trueAnomaly)
    return E - orbit.eccentricity * sin(E)
}

// True Anomaly
public func trueAnomalyAtTime(orbit: Orbit, time: NSTimeInterval) -> Double? {
    if let M = meanAnomalyAtTime(orbit, time) {
        return (M + 2 * orbit.eccentricity * sin(M) + 1.25 * pow(orbit.eccentricity, 2) * sin(2 * M)) % twoπ
    }
    return nil
}

public func trueAnomaly(orbit: Orbit) -> Double? {
    return trueAnomalyAtTime(orbit, UniversalTime.currentUniversalTime.timeIntervalSinceEpoch)
}

// Eccentric Anomaly
public func eccentricAnomalyWithTrueAnomaly(orbit: Orbit, trueAnomaly: Double) -> Double {
    let cosv = cos(trueAnomaly)
    let tmp = acos((orbit.eccentricity + cosv) / (1 + orbit.eccentricity * cosv))
    return trueAnomaly >= M_PI ? twoπ - tmp : tmp
}

public func eccentricAnomaly(orbit: Orbit) -> Double? {
    if let trueAnomaly = trueAnomaly(orbit) {
        return eccentricAnomalyWithTrueAnomaly(orbit, trueAnomaly)
    }
    return nil
}

// Radius
public func radiusWithTrueAnomaly(orbit: Orbit, trueAnomaly: Double) -> Double {
    return orbit.semiMajorAxis * (1 - pow(orbit.eccentricity, 2)) / (1 + orbit.eccentricity * cos(trueAnomaly))
}

public func radius(orbit: Orbit) -> Double? {
    if let trueAnomaly = trueAnomaly(orbit) {
        return radiusWithTrueAnomaly(orbit, trueAnomaly)
    }
    return nil
}

// Velocity
public func relativeVelocityWithRadius(orbit: Orbit, radius: Double) -> Double? {
    if let µ = orbit.primaryBody?.orbit?.gravitationalParameter {
        return sqrt(µ * (2 / radius - 1 / orbit.semiMajorAxis))
    }
    return nil
}

public func relativeVelocity(orbit: Orbit) -> Double? {
    if let radius = radius(orbit) {
        return relativeVelocityWithRadius(orbit, radius)
    }
    return nil
}

// Transfers
public func anglePrograde(orbit: Orbit) -> Double? {
    if let primaryOrbit = orbit.primaryBody?.orbit {
        if let primaryTrueAnomaly = primaryOrbit.trueAnomaly?.doubleValue {
            if let trueAnomaly = trueAnomaly(orbit) {
                let a = (primaryTrueAnomaly + primaryOrbit.longitudeOfAscendingNode + primaryOrbit.argumentOfPeriapsis + M_PI_2) % twoπ
                let b = (trueAnomaly + orbit.longitudeOfAscendingNode + orbit.argumentOfPeriapsis) % twoπ
                return (a - b + twoπ) % twoπ
            }
        }
    }
    return nil
}

public func timeIntervalUntilEjectionAngle(orbit: Orbit, ejectionAngle: Double) -> NSTimeInterval? {
    if let period = period(orbit) {
        if let anglePrograde = anglePrograde(orbit) {
            return period * ((anglePrograde - ejectionAngle + twoπ) % twoπ) / twoπ
        }
    }
    return nil
}

// "Theta"
public func thetaAtTime(orbit: Orbit, time: NSTimeInterval) -> Double? {
    if let trueAnomaly = trueAnomalyAtTime(orbit, time) {
        return (orbit.longitudeOfAscendingNode + orbit.argumentOfPeriapsis + trueAnomaly) % twoπ
    }
    return nil
}

public func theta(orbit: Orbit) -> Double? {
    return thetaAtTime(orbit, UniversalTime.currentUniversalTime.timeIntervalSinceEpoch)
}
