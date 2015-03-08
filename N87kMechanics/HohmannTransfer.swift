//
//  HohmannTransfer.swift
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

private let twoπ = 2 * M_PI

public class HohmannTransfer: Manoeuvre {

    private typealias DoublePair = (Double, Double)
    private struct Window {
        var time: NSTimeInterval = 0
        var travelTime: NSTimeInterval = 0
        var phaseAngle = 0.0
        var deltaV = 0.0
    }

    public dynamic var sourceBody: Body? { didSet { recompute() } }
    public dynamic var targetBody: Body? { didSet { recompute() } }
    public dynamic var useAerobrakeCapture: Bool = true { didSet { recompute() } }
    public dynamic var initialTime: NSTimeInterval = 0 { didSet { recompute() } }

    public private(set) dynamic var transferTime: NSTimeInterval = 0
    public private(set) dynamic var travelTime: NSTimeInterval = 0
    public private(set) dynamic var transferPhaseAngle = 0.0

    public private(set) var ejectionVelocity = 0.0
    private var computedEjectionVelocity: Double {
        let r1 = sourceBody!.radius + sourceOrbit!.periapsis
        let r2 = sourceBody!.sphereOfInfluence
        let µ = sourceBody!.orbit.gravitationalParameter
        return sqrt((r1 * (r2 * deltaV * deltaV - 2 * µ) + 2 * r2 * µ) / (r1 * r2))
    }

    public private(set) var ejectionAngle = 0.0
    private var computedEjectionAngle: Double {
        let r = sourceBody!.radius + sourceOrbit!.periapsis
        let v = ejectionVelocity
        let mu = sourceBody!.orbit.gravitationalParameter
        let e1 = v * v / 2 - mu / r
        let h = r * v
        let e2 = sqrt(1 + 2 * e1 * h * h / (mu * mu))
        return M_PI - acos(1 / e2)
    }

    public private(set) var currentPhaseAngle = 0.0
    private var computedPhaseAngle: Double {
        let theta1 = targetBody!.orbit.trueAnomaly + targetBody!.orbit.argumentOfPeriapsis + targetBody!.orbit.longitudeOfAscendingNode
        let theta2 = sourceBody!.orbit.trueAnomaly + sourceBody!.orbit.argumentOfPeriapsis + sourceBody!.orbit.longitudeOfAscendingNode
        return (theta1 - theta2) % twoπ
    }

    public func ejectionDeltaVWithOrbit(orbit: Orbit) -> Double {
        return abs(ejectionVelocity - orbit.velocityWithGravitationalConstant(sourceBody!.orbit.gravitationalParameter))
    }

    public func deltaVWithOrbit(orbit: Orbit) -> Double {
        return ejectionDeltaVWithOrbit(orbit)
    }

    private func computeTransfer(t: Double) -> (Window, Double) {
        var window = Window()
        window.time = t

        let µ = parentBody!.orbit.gravitationalParameter

        let source = sourceBody!.orbit.copy() as Orbit
        source.trueAnomaly = source.trueAnomalyWithGravitationalConstant(µ, atTime: t)

        let dest = targetBody!.orbit.copy() as Orbit
        dest.trueAnomaly = dest.trueAnomalyWithGravitationalConstant(µ, atTime: t)

        window.phaseAngle = (dest.theta - source.theta + twoπ) % twoπ

        let r1 = source.radius
        let M1 = dest.meanAnomaly
        let deltaAnomaly = (source.theta + M_PI - dest.theta) % twoπ

        dest.trueAnomaly += deltaAnomaly
        dest.trueAnomaly %= twoπ
        let r2 = dest.radius
        let M2 = dest.meanAnomaly

        let t2 = ((M2 - M1 + twoπ) % twoπ) / dest.meanMotionWithGravitationConstant(µ)
        let rtx = (r1 + r2) / 2
        window.travelTime = sqrt(4 * pow(M_PI, 2) * pow(rtx, 3) / µ) / 2

        let vel1 = sqrt(µ / r1)
        let vel2 = sqrt(µ * (2 / r1 - 1 / rtx))
        window.deltaV = abs(vel2 - vel1)

        return (window, t2)
    }

    private func deltaTPair(t: Double) -> DoublePair {
        let (window, t2) = computeTransfer(t)
        return (t, window.travelTime - t2)
    }

    private func bisect(pair: (DoublePair, DoublePair)) -> (DoublePair, DoublePair) {
        let m = (pair.1.1 - pair.0.1) / (pair.1.0 - pair.0.0)
        let guess = deltaTPair(pair.0.0 - pair.0.1 / m)
        return guess.1 > 0 ? (guess, pair.1) : (pair.0, guess)
    }

    public override func recompute() {
        if parentBody == nil || sourceBody == nil || targetBody == nil || sourceOrbit == nil || targetOrbit == nil || targetBody?.orbit.period == 0 {
            return
        }
        let quarterPeriod = targetBody!.orbit.period / 4
        let startPositive = sourceBody!.orbit.period < targetBody!.orbit.period
        println("t_0: \(initialTime)")
        var lower = deltaTPair(initialTime)
        let day = 60.0 * 60 * 6

        while startPositive ? lower.1 < 0 : lower.1 > 0 {
            lower = deltaTPair(lower.0 + quarterPeriod)
        }
        var upper = deltaTPair(lower.0 + quarterPeriod)

        while startPositive ? upper.1 > 0 : upper.1 < 0 {
            lower = upper
            upper = deltaTPair(lower.0 + quarterPeriod)
        }
        var pair = (lower, upper)

        var iterations = 0
        while min(abs(pair.0.1), abs(pair.1.1)) > 1 {
            iterations++
            pair = bisect(pair)
            println("pair: \(pair.0.0 / day), \(pair.1.0 / day)")
        }
        println("transfer iterations: \(iterations)")

        let window = computeTransfer(abs(pair.0.1) < abs(pair.1.1) ? pair.0.0 : pair.1.0).0
        transferTime = window.time
        travelTime = window.travelTime
        transferPhaseAngle = window.phaseAngle
        deltaV = window.deltaV

        ejectionVelocity = computedEjectionVelocity
        ejectionAngle = computedEjectionAngle
        currentPhaseAngle = computedPhaseAngle
    }

}
