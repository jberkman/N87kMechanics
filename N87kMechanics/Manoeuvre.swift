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

private let twoπ = 2 * M_PI

//@objc
public protocol ManoeuvreType: NSObjectProtocol {
    var manoeuvre: Manoeuvre? { get }
}

//@objc
public protocol MutableManoeuvreType: ManoeuvreType {
    var manoeuvre: Manoeuvre? { get set }
}

//@objc
public protocol Manoeuvre: Observable {

    // Inputs
    var sourceBody: Body? { get set }
    var sourceOrbit: Orbit? { get set }

    var targetBody: Body? { get set }
    var targetOrbit: Orbit? { get set }

    var aerobrake: Bool { get set }
    var initialTime: NSTimeInterval { get set }

    // Outputs
    var deltaV: Double { get set }

    // Transfers
    var isTransfer: Bool { get }
    var transferTime: NSTimeInterval { get set }
    var travelTime: NSTimeInterval { get set }
    var transferPhaseAngle: Double { get set }

    var ejectionAngle: Double { get }
    var currentPhaseAngle: Double { get }
    var ejectionVelocity: Double { get }

    func ejectionDeltaVWithOrbit(orbit: Orbit) -> Double
    func deltaVWithOrbit(orbit: Orbit) -> Double

    var description: String { get }

    func createLaunchOrbit()
}

public func isTransfer(manoeuvre: Manoeuvre) -> Bool {
    return manoeuvre.sourceBody !== manoeuvre.targetBody
}

public func description(manoeuvre: Manoeuvre) -> String {
    let sourceBodyName = manoeuvre.sourceBody?.name ?? "Unknown body"
    let targetBodyName = manoeuvre.targetBody?.name ?? "Unknown body"
    switch (manoeuvre.sourceOrbit, manoeuvre.targetOrbit) {
    case (nil, nil): return "Empty manoeuvre"
    case (nil, _): return "Launch from \(sourceBodyName)"
    case (_, nil): return "Land on \(targetBodyName)"
    case (_, _) where sourceBodyName != targetBodyName: return "Transfer to \(targetBodyName)"
    default: return "Change \(sourceBodyName) orbit"
    }
}

private typealias DoublePair = (Double, Double)
private struct Window {
    var time: NSTimeInterval = 0
    var travelTime: NSTimeInterval = 0
    var phaseAngle = 0.0
    var deltaV = 0.0
}

public func ejectionVelocity(manoeuvre: Manoeuvre) -> Double {
    let r1 = manoeuvre.sourceBody!.radius + manoeuvre.sourceOrbit!.periapsis
    let r2 = manoeuvre.sourceBody!.sphereOfInfluence
    let µ = manoeuvre.sourceBody!.orbit.gravitationalParameter
    return sqrt((r1 * (r2 * pow(manoeuvre.deltaV, 2) - 2 * µ) + 2 * r2 * µ) / (r1 * r2))
}

public func ejectionAngle(manoeuvre: Manoeuvre) -> Double {
    let r = manoeuvre.sourceBody!.radius + manoeuvre.sourceOrbit!.periapsis
    let v = manoeuvre.ejectionVelocity
    let mu = manoeuvre.sourceBody!.orbit.gravitationalParameter
    let e1 = v * v / 2 - mu / r
    let h = r * v
    let e2 = sqrt(1 + 2 * e1 * h * h / (mu * mu))
    return M_PI - acos(1 / e2)
}

public func currentPhaseAngle(manoeuvre: Manoeuvre) -> Double {
    let targetOrbit = manoeuvre.targetBody!.orbit
    let sourceOrbit = manoeuvre.sourceBody!.orbit
    let theta1 = targetOrbit.trueAnomaly + targetOrbit.argumentOfPeriapsis + targetOrbit.longitudeOfAscendingNode
    let theta2 = sourceOrbit.trueAnomaly + sourceOrbit.argumentOfPeriapsis + sourceOrbit.longitudeOfAscendingNode
    return (theta1 - theta2) % twoπ
}

public func ejectionDeltaVWithOrbit(manoeuvre: Manoeuvre, orbit: Orbit) -> Double {
    return abs(manoeuvre.ejectionVelocity - orbit.relativeVelocity)
}

public func deltaVWithOrbit(manoeuvre: Manoeuvre, orbit: Orbit) -> Double {
    return ejectionDeltaVWithOrbit(manoeuvre, orbit)
}

private func computeTransfer(manoeuvre: Manoeuvre, t: Double) -> (Window, Double) {
    var window = Window()
    window.time = t

    let sourceOrbit = manoeuvre.sourceBody!.orbit
    let targetOrbit = manoeuvre.targetBody!.orbit
    let µ = sourceOrbit.primaryBody!.orbit.gravitationalParameter

    let sourceTrueAnomaly = sourceOrbit.trueAnomalyAtTime(t)
    let sourceTheta = sourceOrbit.thetaAtTime(t)
    let targetTrueAnomaly = targetOrbit.trueAnomalyAtTime(t)
    let targetTheta = targetOrbit.thetaAtTime(t)

    window.phaseAngle = (targetTheta - sourceTheta + twoπ) % twoπ

    let r1 = sourceOrbit.radiusWithTrueAnomaly(sourceTrueAnomaly)
    let M1 = targetOrbit.meanAnomalyAtTime(t)
    let targetTrueAnomaly2 = (targetTrueAnomaly + sourceTheta - targetTheta + M_PI) % twoπ

    let r2 = targetOrbit.radiusWithTrueAnomaly(targetTrueAnomaly2)
    let M2 = targetOrbit.meanAnomalyWithTrueAnomaly(targetTrueAnomaly2)

    let t2 = ((M2 - M1 + twoπ) % twoπ) / targetOrbit.meanMotion
    let rtx = (r1 + r2) / 2
    window.travelTime = sqrt(4 * pow(M_PI, 2) * pow(rtx, 3) / µ) / 2

    let vel1 = sqrt(µ / r1)
    let vel2 = sqrt(µ * (2 / r1 - 1 / rtx))
    window.deltaV = abs(vel2 - vel1)

    return (window, t2)
}

private func deltaTPair(manoeuvre: Manoeuvre, t: Double) -> DoublePair {
    let (window, t2) = computeTransfer(manoeuvre, t)
    return (t, window.travelTime - t2)
}

private func bisect(manoeuvre: Manoeuvre, pair: (DoublePair, DoublePair)) -> (DoublePair, DoublePair) {
    let m = (pair.1.1 - pair.0.1) / (pair.1.0 - pair.0.0)
    let guess = deltaTPair(manoeuvre, pair.0.0 - pair.0.1 / m)
    return guess.1 > 0 ? (guess, pair.1) : (pair.0, guess)
}

public func deltaV(sourceOrbit: Orbit, targetOrbit: Orbit) -> Double {
    let transfer = SimpleOrbit()
    copy(transfer, sourceOrbit)
    let radius = sourceOrbit.primaryBody!.radius
    transfer.apoapsis = targetOrbit.apoapsis
    let v0 = sourceOrbit.relativeVelocityWithRadius(radius + transfer.periapsis)
    let v1 = transfer.relativeVelocityWithRadius(radius + transfer.periapsis)
    let v2 = transfer.relativeVelocityWithRadius(radius + transfer.apoapsis)
    let v3 = targetOrbit.relativeVelocityWithRadius(radius + transfer.apoapsis)
    return abs(v1 - v0) + abs(v3 - v2)
}

private func updateDeltaVWithLaunchManoeuvre(manoeuvre: Manoeuvre) {
    let targetOrbit = manoeuvre.targetOrbit!
    if let targetBody = targetOrbit.primaryBody {
        if targetBody.maxAtmosphere > 0 {
            if targetOrbit.eccentricity == 0 && targetOrbit.apoapsis == targetBody.parkingOrbitHeight {
                switch targetBody.name {
                case "Duna": manoeuvre.deltaV = 1_300
                case "Eve": manoeuvre.deltaV = 12_000
                case "Kerbin": manoeuvre.deltaV = 4_550
                case "Laythe": manoeuvre.deltaV = 3_200
                default: break
                }
            }
        } else {
            let transfer = SimpleOrbit()
            copy(transfer, targetOrbit)
            transfer.apoapsis = targetOrbit.periapsis
            transfer.periapsis = targetBody.radius
            manoeuvre.deltaV = transfer.relativeVelocityWithRadius(targetBody.radius) + deltaV(transfer, targetOrbit) - twoπ * targetBody.radius / targetBody.rotationPeriod
        }
    }
}

private func updateDeltaVWithOrbitalChangeManouevre(manoeuvre: Manoeuvre) {
    if manoeuvre.sourceOrbit!.primaryBody != nil && manoeuvre.targetOrbit!.primaryBody != nil {
        manoeuvre.deltaV = deltaV(manoeuvre.sourceOrbit!, manoeuvre.targetOrbit!)
    }
}

private func updateDeltaVWithTransferManoeuvre(manoeuvre: Manoeuvre) {
    if let sourceBody = manoeuvre.sourceOrbit!.primaryBody {
        if let targetBody = manoeuvre.targetOrbit!.primaryBody {
            if targetBody.orbit.period == 0 {
                return
            }
            let quarterPeriod = targetBody.orbit.period / 4
            let startPositive = sourceBody.orbit.period < targetBody.orbit.period
            let t0 = max(manoeuvre.initialTime, UniversalTime.currentUniversalTime.timeIntervalSinceEpoch)
            println("t0: \(t0)")
            var lower = deltaTPair(manoeuvre, t0)
            let day = 60.0 * 60 * 6

            while startPositive ? lower.1 < 0 : lower.1 > 0 {
                lower = deltaTPair(manoeuvre, lower.0 + quarterPeriod)
            }
            var upper = deltaTPair(manoeuvre, lower.0 + quarterPeriod)

            while startPositive ? upper.1 > 0 : upper.1 < 0 {
                lower = upper
                upper = deltaTPair(manoeuvre, lower.0 + quarterPeriod)
            }
            var pair = (lower, upper)

            var iterations = 0
            while min(abs(pair.0.1), abs(pair.1.1)) > 1 {
                iterations++
                pair = bisect(manoeuvre, pair)
                println("pair: \(pair.0.0 / day), \(pair.1.0 / day)")
            }
            println("transfer iterations: \(iterations)")

            let window = computeTransfer(manoeuvre, abs(pair.0.1) < abs(pair.1.1) ? pair.0.0 : pair.1.0).0
            manoeuvre.transferTime = window.time
            manoeuvre.travelTime = window.travelTime
            manoeuvre.transferPhaseAngle = window.phaseAngle
            manoeuvre.deltaV = ejectionDeltaVWithOrbit(manoeuvre, manoeuvre.sourceOrbit!)
        }
    }
}

private func updateDeltaVWithLandingManoeuvre(manoeuvre: Manoeuvre) {
    let sourceOrbit = manoeuvre.sourceOrbit!
    if let sourceBody = sourceOrbit.primaryBody {
        let transfer = SimpleOrbit()
        copy(transfer, sourceOrbit)
        let radius = sourceOrbit.primaryBody!.radius
        transfer.apoapsis = sourceOrbit.periapsis
        transfer.periapsis = sourceBody.radius
        manoeuvre.deltaV = deltaV(sourceOrbit, transfer) + (manoeuvre.aerobrake ? 0 : transfer.relativeVelocityWithRadius(sourceBody.radius)) - twoπ * sourceBody.radius / sourceBody.rotationPeriod
    }
}

public func updateDeltaV(manoeuvre: Manoeuvre) {
    switch (manoeuvre.sourceOrbit, manoeuvre.targetOrbit) {
    case (nil, .Some):
        updateDeltaVWithLaunchManoeuvre(manoeuvre)
    case (.Some(let sourceOrbit), .Some(let targetOrbit)) where sourceOrbit.primaryBody?.bodyID == targetOrbit.primaryBody?.bodyID:
        updateDeltaVWithOrbitalChangeManouevre(manoeuvre)
    case (.Some, .Some):
        updateDeltaVWithTransferManoeuvre(manoeuvre)
    case (.Some, nil):
        updateDeltaVWithLandingManoeuvre(manoeuvre)
    default:
        break
    }
}
