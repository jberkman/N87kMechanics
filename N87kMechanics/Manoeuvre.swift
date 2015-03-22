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

@objc
public protocol ManoeuvreType: NSObjectProtocol {
    var manoeuvre: Manoeuvre? { get }
}

@objc
public protocol MutableManoeuvreType: ManoeuvreType {
    var manoeuvre: Manoeuvre? { get set }
}

@objc
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

    var ejectionAngle: NSNumber? { get }
    var currentPhaseAngle: NSNumber? { get }
    var ejectionVelocity: NSNumber? { get }

    func ejectionDeltaVWithOrbit(orbit: Orbit) -> NSNumber?
    func deltaVWithOrbit(orbit: Orbit) -> NSNumber?

    var description: String { get }
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

public func ejectionVelocity(manoeuvre: Manoeuvre) -> Double? {
    if let sourceBody = manoeuvre.sourceBody {
        if let periapsis = manoeuvre.sourceOrbit?.periapsis?.doubleValue {
            if let µ = sourceBody.orbit?.gravitationalParameter {
                let r1 = sourceBody.radius + periapsis
                let r2 = sourceBody.sphereOfInfluence
                return sqrt((r1 * (r2 * pow(manoeuvre.deltaV, 2) - 2 * µ) + 2 * r2 * µ) / (r1 * r2))
            }
        }
    }
    return nil
}

public func ejectionAngle(manoeuvre: Manoeuvre) -> Double? {
    if let sourceBody = manoeuvre.sourceBody {
        if let periapsis = manoeuvre.sourceOrbit?.periapsis?.doubleValue {
            if let µ = sourceBody.orbit?.gravitationalParameter {
                if let v = manoeuvre.ejectionVelocity?.doubleValue {
                    let r = sourceBody.radius + periapsis
                    let e1 = v * v / 2 - µ / r
                    let h = r * v
                    let e2 = sqrt(1 + 2 * e1 * h * h / (µ * µ))
                    return M_PI - acos(1 / e2)
                }
            }
        }
    }
    return nil
}

public func currentPhaseAngle(manoeuvre: Manoeuvre) -> Double? {
    if let targetTheta = manoeuvre.targetBody?.orbit?.theta?.doubleValue {
        if let sourceTheta = manoeuvre.targetBody?.orbit?.theta?.doubleValue {
            return (targetTheta - sourceTheta) % twoπ
        }
    }
    return nil
}

public func ejectionDeltaVWithOrbit(manoeuvre: Manoeuvre, orbit: Orbit) -> Double? {
    if let ejectionVelocity = manoeuvre.ejectionVelocity?.doubleValue {
        if let relativeVelocity = orbit.relativeVelocity?.doubleValue {
            return abs(ejectionVelocity - relativeVelocity)
        }
    }
    return nil
}

public func deltaVWithOrbit(manoeuvre: Manoeuvre, orbit: Orbit) -> Double? {
    return ejectionDeltaVWithOrbit(manoeuvre, orbit)
}

private func computeTransfer(manoeuvre: Manoeuvre, t: Double) -> (Window, Double)? {

    if let sourceOrbit = manoeuvre.sourceBody?.orbit {
        if let targetOrbit = manoeuvre.targetBody?.orbit {
            if let µ = sourceOrbit.primaryBody?.orbit?.gravitationalParameter {
                if let sourceTrueAnomaly = sourceOrbit.trueAnomalyAtTime(t)?.doubleValue {
                    if let sourceTheta = sourceOrbit.thetaAtTime(t)?.doubleValue {
                        if let targetTrueAnomaly = targetOrbit.trueAnomalyAtTime(t)?.doubleValue {
                            if let targetTheta = targetOrbit.thetaAtTime(t)?.doubleValue {
                                if let r1 = sourceOrbit.radiusWithTrueAnomaly(sourceTrueAnomaly)?.doubleValue {
                                    if let M1 = targetOrbit.meanAnomalyAtTime(t)?.doubleValue {
                                        let targetTrueAnomaly2 = (targetTrueAnomaly + sourceTheta - targetTheta + M_PI) % twoπ
                                        if let r2 = targetOrbit.radiusWithTrueAnomaly(targetTrueAnomaly2)?.doubleValue {
                                            if let M2 = targetOrbit.meanAnomalyWithTrueAnomaly(targetTrueAnomaly2)?.doubleValue {
                                                if let meanMotion = targetOrbit.meanMotion?.doubleValue {
                                                    let t2 = ((M2 - M1 + twoπ) % twoπ) / meanMotion
                                                    let rtx = (r1 + r2) / 2

                                                    let vel1 = sqrt(µ / r1)
                                                    let vel2 = sqrt(µ * (2 / r1 - 1 / rtx))

                                                    return (Window(time: t,
                                                        travelTime: sqrt(4 * pow(M_PI, 2) * pow(rtx, 3) / µ) / 2,
                                                        phaseAngle: (targetTheta - sourceTheta + twoπ) % twoπ,
                                                        deltaV: abs(vel2 - vel1)),
                                                        t2)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return nil
}

private func deltaTPair(manoeuvre: Manoeuvre, t: Double) -> DoublePair? {
    if let (window, t2) = computeTransfer(manoeuvre, t) {
        return (t, window.travelTime - t2)
    }
    return nil
}

private func bisect(manoeuvre: Manoeuvre, pair: (DoublePair, DoublePair)) -> (DoublePair, DoublePair)? {
    let m = (pair.1.1 - pair.0.1) / (pair.1.0 - pair.0.0)
    if let guess = deltaTPair(manoeuvre, pair.0.0 - pair.0.1 / m) {
        return guess.1 > 0 ? (guess, pair.1) : (pair.0, guess)
    }
    return nil
}

public func deltaV(sourceOrbit: Orbit, targetOrbit: Orbit) -> Double? {
    let transfer = SimpleOrbit()
    copy(transfer, sourceOrbit)
    if let radius = sourceOrbit.primaryBody?.radius {
        if let periapsis = transfer.periapsis?.doubleValue {
            if let apoapsis = targetOrbit.apoapsis?.doubleValue {
                transfer.apoapsis = apoapsis
                if let v0 = sourceOrbit.relativeVelocityWithRadius(radius + periapsis)?.doubleValue {
                    if let v1 = transfer.relativeVelocityWithRadius(radius + periapsis)?.doubleValue {
                        if let v2 = transfer.relativeVelocityWithRadius(radius + apoapsis)?.doubleValue {
                            if let v3 = targetOrbit.relativeVelocityWithRadius(radius + apoapsis)?.doubleValue {
                                return abs(v1 - v0) + abs(v3 - v2)
                            }
                        }
                    }
                }
            }
        }
    }
    return nil
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
            if let relativeVelocity = transfer.relativeVelocityWithRadius(targetBody.radius)?.doubleValue {
                if let deltaV = deltaV(transfer, targetOrbit) {
                    manoeuvre.deltaV = relativeVelocity + deltaV - twoπ * targetBody.radius / targetBody.rotationPeriod
                }
            }
        }
    }
}

private func updateDeltaVWithOrbitalChangeManouevre(manoeuvre: Manoeuvre) {
    if let sourceOrbit = manoeuvre.sourceOrbit {
        if let targetOrbit = manoeuvre.targetOrbit {
            if let deltaV = deltaV(sourceOrbit, targetOrbit) {
                manoeuvre.deltaV = deltaV
            }
        }
    }
}

private func updateDeltaVWithTransferManoeuvre(manoeuvre: Manoeuvre) {
    if let sourceOrbit = manoeuvre.sourceOrbit {
        if let sourcePeriod = sourceOrbit.primaryBody?.orbit?.period?.doubleValue {
            if let targetPeriod = manoeuvre.targetOrbit?.primaryBody?.orbit?.period?.doubleValue {
                if targetPeriod == 0 {
                    return
                }

                let quarterPeriod = targetPeriod / 4
                let startPositive = sourcePeriod < targetPeriod
                let t0 = max(manoeuvre.initialTime, UniversalTime.currentUniversalTime.timeIntervalSinceEpoch)
                println("t0: \(t0)")
                if var lower = deltaTPair(manoeuvre, t0) {
                    let day = 60.0 * 60 * 6

                    while startPositive ? lower.1 < 0 : lower.1 > 0 {
                        lower = deltaTPair(manoeuvre, lower.0 + quarterPeriod)!
                    }
                    var upper = deltaTPair(manoeuvre, lower.0 + quarterPeriod)!

                    while startPositive ? upper.1 > 0 : upper.1 < 0 {
                        lower = upper
                        upper = deltaTPair(manoeuvre, lower.0 + quarterPeriod)!
                    }
                    var pair = (lower, upper)

                    var iterations = 0
                    while min(abs(pair.0.1), abs(pair.1.1)) > 1 {
                        iterations++
                        pair = bisect(manoeuvre, pair)!
                        println("pair: \(pair.0.0 / day), \(pair.1.0 / day)")
                    }
                    println("transfer iterations: \(iterations)")

                    let window = computeTransfer(manoeuvre, abs(pair.0.1) < abs(pair.1.1) ? pair.0.0 : pair.1.0)!.0
                    manoeuvre.transferTime = window.time
                    manoeuvre.travelTime = window.travelTime
                    manoeuvre.transferPhaseAngle = window.phaseAngle
                    if let deltaV = ejectionDeltaVWithOrbit(manoeuvre, sourceOrbit) {
                        manoeuvre.deltaV = deltaV
                    }
                }
            }
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
        if var deltaV = deltaV(sourceOrbit, transfer) {
            deltaV -= twoπ * sourceBody.radius / sourceBody.rotationPeriod
            if manoeuvre.aerobrake {
                if let relativeVelocity = transfer.relativeVelocityWithRadius(sourceBody.radius)?.doubleValue {
                    manoeuvre.deltaV = deltaV + relativeVelocity
                }
            } else {
                manoeuvre.deltaV = deltaV
            }
        }
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
