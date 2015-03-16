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
    var periapsis: Double { get set }
    var apoapsis: Double { get set }

    // Output
    var isStable: Bool { get }

    var timeOfPeriapsisPassage: NSTimeInterval { get }
    var timeToPeriapsis: NSTimeInterval { get }
    var timeToApoapsis: NSTimeInterval { get }

    var meanMotion: Double { get }
    var period: Double { get }

    var meanAnomaly: Double { get }
    func meanAnomalyAtTime(time: NSTimeInterval) -> Double
    func meanAnomalyWithTrueAnomaly(trueAnomaly: Double) -> Double

    var trueAnomaly: Double { get }
    func trueAnomalyAtTime(time: NSTimeInterval) -> Double

    var eccentricAnomaly: Double { get }
    func eccentricAnomalyWithTrueAnomaly(trueAnomaly: Double) -> Double

    var radius: Double { get }
    func radiusWithTrueAnomaly(trueAnomaly: Double) -> Double

    var relativeVelocity: Double { get }
    func relativeVelocityWithRadius(radius: Double) -> Double

    var anglePrograde: Double { get }
    func timeIntervalUntilEjectionAngle(ejectionAngle: Double) -> NSTimeInterval

    var theta: Double { get }
    func thetaAtTime(time: NSTimeInterval) -> Double
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

public func isStable(orbit: Orbit) -> Bool {
    return orbit.periapsis > orbit.primaryBody!.maxAtmosphere && orbit.apoapsis < orbit.primaryBody!.sphereOfInfluence
}

public func periapsis(orbit: Orbit) -> Double {
    return orbit.semiMajorAxis * (1 - orbit.eccentricity) - orbit.primaryBody!.radius
}

public func setPeriapsis(orbit: Orbit, periapsis: Double) {
    let oldApoapsis = apoapsis(orbit)
    orbit.eccentricity = abs(oldApoapsis - periapsis) / (oldApoapsis + periapsis + 2 * orbit.primaryBody!.radius)
    orbit.semiMajorAxis = (oldApoapsis + periapsis) / 2 + orbit.primaryBody!.radius
}

public func timeOfPeriapsisPassage(orbit: Orbit) -> NSTimeInterval {
    return (twoπ - orbit.meanAnomalyAtEpoch) / meanMotion(orbit)
}

public func timeToPeriapsis(orbit: Orbit) -> NSTimeInterval {
    return (twoπ - meanAnomaly(orbit)) / meanMotion(orbit)
}

// Apoapsis
public func apoapsis(orbit: Orbit) -> Double {
    return orbit.semiMajorAxis * (1 + orbit.eccentricity) - orbit.primaryBody!.radius
}

public func setApoapsis(orbit: Orbit, apoapsis: Double) {
    let oldPeriapsis = periapsis(orbit)
    orbit.eccentricity = abs(apoapsis - oldPeriapsis) / (apoapsis + oldPeriapsis + 2 * orbit.primaryBody!.radius)
    orbit.semiMajorAxis = (apoapsis + oldPeriapsis) / 2 + orbit.primaryBody!.radius
}

public func timeToApoapsis(orbit: Orbit) -> NSTimeInterval {
    return ((3 * M_PI - meanAnomaly(orbit)) % twoπ) / meanMotion(orbit)
}

// Mean Motion / Period
public func meanMotion(orbit: Orbit) -> Double {
    return sqrt(orbit.primaryBody!.orbit.gravitationalParameter / pow(orbit.semiMajorAxis, 3))
}

public func period(orbit: Orbit) -> NSTimeInterval {
    return twoπ * meanMotion(orbit)
}

// Mean Anomaly
public func meanAnomalyAtTime(orbit: Orbit, time: NSTimeInterval) -> Double {
    return (orbit.meanAnomalyAtEpoch + (time - orbit.epoch) * meanMotion(orbit)) % twoπ
}

public func meanAnomaly(orbit: Orbit) -> Double {
    return meanAnomalyAtTime(orbit, UniversalTime.currentUniversalTime.timeIntervalSinceEpoch)
}

public func meanAnomalyWithTrueAnomaly(orbit: Orbit, trueAnomaly: Double) -> Double {
    let E = eccentricAnomalyWithTrueAnomaly(orbit, trueAnomaly)
    return E - orbit.eccentricity * sin(E)
}

// True Anomaly
public func trueAnomalyAtTime(orbit: Orbit, time: NSTimeInterval) -> Double {
    let M = meanAnomalyAtTime(orbit, time)
    return (M + 2 * orbit.eccentricity * sin(M) + 1.25 * pow(orbit.eccentricity, 2) * sin(2 * M)) % twoπ
}

public func trueAnomaly(orbit: Orbit) -> Double {
    return trueAnomalyAtTime(orbit, UniversalTime.currentUniversalTime.timeIntervalSinceEpoch)
}

// Eccentric Anomaly
public func eccentricAnomalyWithTrueAnomaly(orbit: Orbit, trueAnomaly: Double) -> Double {
    let cosv = cos(trueAnomaly)
    let tmp = acos((orbit.eccentricity + cosv) / (1 + orbit.eccentricity * cosv))
    return trueAnomaly >= M_PI ? twoπ - tmp : tmp
}

public func eccentricAnomaly(orbit: Orbit) -> Double {
    return eccentricAnomalyWithTrueAnomaly(orbit, trueAnomaly(orbit))
}

// Radius
public func radiusWithTrueAnomaly(orbit: Orbit, trueAnomaly: Double) -> Double {
    return orbit.semiMajorAxis * (1 - pow(orbit.eccentricity, 2)) / (1 + orbit.eccentricity * cos(trueAnomaly))
}

public func radius(orbit: Orbit) -> Double {
    return radiusWithTrueAnomaly(orbit, trueAnomaly(orbit))
}

// Velocity
public func relativeVelocityWithRadius(orbit: Orbit, radius: Double) -> Double {
    return sqrt(orbit.primaryBody!.orbit.gravitationalParameter * (2 / radius - 1 / orbit.semiMajorAxis))
}

public func relativeVelocity(orbit: Orbit) -> Double {
    return relativeVelocityWithRadius(orbit, radius(orbit))
}

// Transfers
public func anglePrograde(orbit: Orbit) -> Double {
    let primaryOrbit = orbit.primaryBody!.orbit
    let a = (primaryOrbit.trueAnomaly + primaryOrbit.longitudeOfAscendingNode + primaryOrbit.argumentOfPeriapsis + M_PI_2) % twoπ
    let b = (trueAnomaly(orbit) + orbit.longitudeOfAscendingNode + orbit.argumentOfPeriapsis) % twoπ
    return (a - b + twoπ) % twoπ
}

public func timeIntervalUntilEjectionAngle(orbit: Orbit, ejectionAngle: Double) -> NSTimeInterval {
    return period(orbit) * ((anglePrograde(orbit) - ejectionAngle + twoπ) % twoπ) / twoπ
}


// "Theta"
public func thetaAtTime(orbit: Orbit, time: NSTimeInterval) -> Double {
    return (orbit.meanAnomalyAtEpoch + orbit.longitudeOfAscendingNode + trueAnomalyAtTime(orbit, time)) % twoπ
}

public func theta(orbit: Orbit) -> Double {
    return thetaAtTime(orbit, UniversalTime.currentUniversalTime.timeIntervalSinceEpoch)
}
