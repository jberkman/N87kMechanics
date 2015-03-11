//
//  Orbit.swift
//  N87kMechanics
//
//  Created by jacob berkman on 2015-03-05.
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

private let twoπ = 2 * M_PI

public class Orbit: NSObject {

    public dynamic var relativeVelocity = 0.0
    public dynamic var periapsis = 0.0
    public dynamic var apoapsis = 0.0
    public dynamic var timeToApoapsis: NSTimeInterval = 0
    public dynamic var timeToPeriapsis: NSTimeInterval = 0
    public dynamic var inclination = 0.0
    public dynamic var eccentricity = 0.0
    public dynamic var epoch = 0.0
    public dynamic var period: NSTimeInterval = 0
    public dynamic var argumentOfPeriapsis = 0.0
    public dynamic var timeToTransition1: NSTimeInterval = 0
    public dynamic var timeToTransition2: NSTimeInterval = 0
    public dynamic var semiMajorAxis = 0.0
    public dynamic var longitudeOfAscendingNode = 0.0
    public dynamic var meanAnomalyAtEpoch = 0.0
    public dynamic var timeOfPeriapsisPassage: NSTimeInterval = 0
    public dynamic var trueAnomaly = 0.0
    public dynamic var gravitationalParameter = 0.0

    public var eccentricAnomaly: Double {
        let cosv = cos(trueAnomaly)
        let tmp = acos((eccentricity + cosv) / (1 + eccentricity * cosv))
        return trueAnomaly >= M_PI ? twoπ - tmp : tmp
    }

    public func eccentricityWithParentRadius(parentRadius: Double) -> Double {
        return 1.0 - 2 / ((apoapsis + parentRadius) / (periapsis + parentRadius) + 1)
    }

    public var meanAnomaly: Double {
        let E = eccentricAnomaly
        return E - eccentricity * sin(E)
    }

    public func meanMotionWithGravitationConstant(GM: Double) -> Double {
        return sqrt(GM / pow(semiMajorAxis, 3))
    }

    public func trueAnomalyWithMeanAnomaly(M: Double) -> Double {
        return (M + 2 * eccentricity * sin(M) + 1.25 * pow(eccentricity, 2) * sin(2 * M)) % (twoπ)
    }

    public func trueAnomalyWithGravitationalConstant(GM: Double, atTime t: NSTimeInterval) -> Double {
        return trueAnomalyWithMeanAnomaly(meanAnomalyAtEpoch + meanMotionWithGravitationConstant(GM) * t)
    }

    public var theta: Double {
        return (meanAnomalyAtEpoch + longitudeOfAscendingNode + trueAnomaly) % (twoπ)
    }

    public var radius: Double {
        return radiusWithTrueAnomaly(trueAnomaly)
    }

    public func radiusWithTrueAnomaly(trueAnomaly: Double) -> Double {
        return semiMajorAxis * (1 - pow(eccentricity, 2)) / (1 + eccentricity * cos(trueAnomaly))
    }

    public func velocityWithGravitationalConstant(µ: Double, atRadius radius: Double) -> Double {
        return sqrt(µ * (2 / radius - 1 / semiMajorAxis))
    }

    public func velocityWithGravitationalConstant(µ: Double) -> Double {
        return velocityWithGravitationalConstant(µ, atRadius: radius)
    }

    public func angleProgradeWithParentOrbit(orbit: Orbit) -> Double {
        let a = (orbit.trueAnomaly + orbit.longitudeOfAscendingNode + orbit.argumentOfPeriapsis + M_PI_2) % twoπ
        let b = (trueAnomaly + longitudeOfAscendingNode + argumentOfPeriapsis) % twoπ
        return (a - b + twoπ) % twoπ
    }

    public func timeIntervalUntilEjectionAngle(ejectionAngle: Double, parentOrbit: Orbit) -> NSTimeInterval {
        return period * ((angleProgradeWithParentOrbit(parentOrbit) - ejectionAngle + twoπ) % twoπ) / twoπ
    }

    public func periodWithGravitationalConstant(GM: Double) -> Double {
        return sqrt(pow(semiMajorAxis, 3) / GM) * twoπ
    }

    public override func copy() -> AnyObject {
        let obj = Orbit()
        obj.relativeVelocity = relativeVelocity
        obj.apoapsis = apoapsis
        obj.periapsis = periapsis
        obj.timeToApoapsis = timeToApoapsis
        obj.timeToPeriapsis = timeToPeriapsis
        obj.inclination = inclination
        obj.eccentricity = eccentricity
        obj.epoch = epoch
        obj.period = period
        obj.argumentOfPeriapsis = argumentOfPeriapsis
        obj.timeToTransition1 = timeToTransition1
        obj.timeToTransition2 = timeToTransition2
        obj.semiMajorAxis = semiMajorAxis
        obj.longitudeOfAscendingNode = longitudeOfAscendingNode
        obj.meanAnomalyAtEpoch = meanAnomalyAtEpoch
        obj.timeOfPeriapsisPassage = timeOfPeriapsisPassage
        obj.trueAnomaly = trueAnomaly
        obj.gravitationalParameter = gravitationalParameter
        return obj
    }

}
