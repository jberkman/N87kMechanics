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

private let day = 60.0 * 60 * 6
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
    var hyperbolicExcessEscapeVelocity: Double { get set }
    var hyperbolicExcessCaptureVelocity: Double { get set }
    var transferTime: NSTimeInterval { get set }
    var travelTime: NSTimeInterval { get set }
    var transferPhaseAngle: Double { get set }
    var planeChangeDeltaV: Double { get set }

    var ejectionAngle: NSNumber? { get }
    var currentPhaseAngle: NSNumber? { get }

    var ejectionVelocity: NSNumber? { get }
    func ejectionVelocityWithOrbit(orbit: Orbit) -> NSNumber?

    var ejectionDeltaV: NSNumber? { get }
    func ejectionDeltaVWithOrbit(orbit: Orbit) -> NSNumber?

    var captureDeltaV: NSNumber? { get }

    func deltaVWithOrbit(orbit: Orbit) -> NSNumber?

    var descriptiveText: String { get }

    func recalculateDeltaV()
    func createLaunchOrbit()
}

public func isTransfer(manoeuvre: Manoeuvre) -> Bool {
    return manoeuvre.sourceBody !== manoeuvre.targetBody
}

public func descriptiveText(manoeuvre: Manoeuvre) -> String {
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
    var hyperbolicExcessEscapeVelocity = 0.0
    var hyperbolicExcessCaptureVelocity = 0.0
    var planeChangeDeltaV = 0.0
}

public func ejectionVelocity(manoeuvre: Manoeuvre) -> Double? {
    if let orbit = manoeuvre.sourceOrbit {
        return ejectionVelocityWithOrbit(manoeuvre, orbit)
    }
    return nil
}

public func ejectionVelocityWithOrbit(manoeuvre: Manoeuvre, orbit: Orbit) -> Double? {
    if let periapsis = orbit.periapsis?.doubleValue {
        if let primaryBody = orbit.primaryBody {
            if let µ = primaryBody.orbit?.gravitationalParameter {
                return sqrt(pow(manoeuvre.hyperbolicExcessEscapeVelocity, 2) + 2 * µ / (periapsis + primaryBody.radius))
            }
        }
    }
    return nil
}

public func ejectionAngle(manoeuvre: Manoeuvre) -> Double? {
    if let sourceBody = manoeuvre.sourceBody {
        if let sourceOrbitRadius = sourceBody.orbit?.semiMajorAxis {
            if let targetOrbitRadius = manoeuvre.targetBody?.orbit?.semiMajorAxis {
                if let periapsis = manoeuvre.sourceOrbit?.periapsis?.doubleValue {
                    if let µ = sourceBody.orbit?.gravitationalParameter {
                        if let v = manoeuvre.ejectionVelocity?.doubleValue {
                            let r = sourceBody.radius + periapsis
                            let e1 = v * v / 2 - µ / r
                            let h = r * v
                            let e2 = sqrt(1 + 2 * e1 * h * h / (µ * µ))
                            return (sourceOrbitRadius > targetOrbitRadius ? 2 : 1) * M_PI - acos(1 / e2)
                        }
                    }
                }
            }
        }
    }
    return nil
}

public func currentPhaseAngle(manoeuvre: Manoeuvre) -> Double? {
    if let targetTrueLongitude = manoeuvre.targetBody?.orbit?.trueLongitude?.doubleValue {
        if let sourceTrueLongitude = manoeuvre.sourceBody?.orbit?.trueLongitude?.doubleValue {
            return (targetTrueLongitude - sourceTrueLongitude) % twoπ
        }
    }
    return nil
}

public func ejectionDeltaVWithOrbit(manoeuvre: Manoeuvre, orbit: Orbit) -> Double? {
    if let ejectionVelocity = ejectionVelocityWithOrbit(manoeuvre, orbit) {
        if let radius = orbit.primaryBody?.radius {
            if let periapsis = orbit.periapsis?.doubleValue {
                if let relativeVelocity = orbit.relativeVelocityWithRadius(periapsis + radius)?.doubleValue {
                    return abs(ejectionVelocity - relativeVelocity)
                }
            }
        }
    }
    return nil
}

public func ejectionDeltaV(manoeuvre: Manoeuvre) -> Double? {
    if let orbit = manoeuvre.sourceOrbit {
        return ejectionDeltaVWithOrbit(manoeuvre, orbit)
    }
    return nil
}

public func captureDeltaV(manoeuvre: Manoeuvre) -> Double? {
    if let orbit = manoeuvre.targetOrbit {
        if let primaryBody = orbit.primaryBody {
            if primaryBody.maxAtmosphere > 0 && manoeuvre.aerobrake {
                return 0
            } else if let µ = primaryBody.orbit?.gravitationalParameter {
                if let periapsis = orbit.periapsis?.doubleValue {
                    if let relativeVelocity = manoeuvre.targetOrbit?.relativeVelocityWithRadius(periapsis + primaryBody.radius)?.doubleValue {
                        let captureVelocity = sqrt(pow(manoeuvre.hyperbolicExcessCaptureVelocity, 2) + 2 * µ / (periapsis + primaryBody.radius))
                        return abs(captureVelocity - relativeVelocity)
                    }
                }
            }
        }
    }
    return nil
}

public func deltaVWithOrbit(manoeuvre: Manoeuvre, orbit: Orbit) -> Double? {
    if let ejectionDeltaV = ejectionDeltaVWithOrbit(manoeuvre, orbit) {
        if let captureDeltaV = captureDeltaV(manoeuvre) {
            return ejectionDeltaV + manoeuvre.planeChangeDeltaV + captureDeltaV
        }
    }
    return nil
}

private func computeTransfer(manoeuvre: Manoeuvre, t: Double) -> (Window, Double) {
    let sourceOrbit = manoeuvre.sourceBody!.orbit!
    let targetOrbit = manoeuvre.targetBody!.orbit!

    let sourceTrueAnomaly = sourceOrbit.trueAnomalyAtTime(t)!.doubleValue
    let targetTrueAnomaly = targetOrbit.trueAnomalyAtTime(t)!.doubleValue

    let sourceTrueLongitude = sourceOrbit.trueLongitudeWithTrueAnomaly(sourceTrueAnomaly)
    let targetTrueLongitude = targetOrbit.trueLongitudeWithTrueAnomaly(targetTrueAnomaly)
    let targetTrueLongitude2 = sourceTrueLongitude + M_PI
    let targetTrueAnomaly2 = targetOrbit.trueAnomalyWithTrueLongitude(targetTrueLongitude2)

//    dlog("target goes from \(targetTrueLongitude * 180 / M_PI) to \(targetTrueLongitude2 * 180 / M_PI)")

    let r1 = sourceOrbit.radiusWithTrueAnomaly(sourceTrueAnomaly)!.doubleValue
    let r2 = targetOrbit.radiusWithTrueAnomaly(targetTrueAnomaly2)!.doubleValue

    let tm1 = targetOrbit.meanAnomalyWithTrueAnomaly(targetTrueAnomaly)!.doubleValue
    let tm2 = targetOrbit.meanAnomalyWithTrueAnomaly(targetTrueAnomaly2)!.doubleValue
    let meanMotion = targetOrbit.meanMotion!.doubleValue
    let t2 = ((tm2 - tm1 + twoπ) % twoπ) / meanMotion

    let radius = targetOrbit.primaryBody!.radius
    let orbit = SimpleOrbit()
    orbit.primaryBody = targetOrbit.primaryBody
    orbit.eccentricity = eccentricityWithApoapsis(max(r1, r2) - radius, periapsis: min(r1, r2) - radius, radius: radius)
    orbit.semiMajorAxis = (r1 + r2) / 2
    orbit.inclination = sourceOrbit.inclination
    orbit.argumentOfPeriapsis = (sourceOrbit.argumentOfPeriapsis + sourceTrueAnomaly) % twoπ
    orbit.longitudeOfAscendingNode = sourceOrbit.longitudeOfAscendingNode

    let period = orbit.period!.doubleValue
    let v1 = sourceOrbit.relativeVelocityWithRadius(r1)!.doubleValue
    let v2 = orbit.relativeVelocityWithRadius(r1)!.doubleValue
    let v3 = orbit.relativeVelocityWithRadius(r2)!.doubleValue
    let v4 = targetOrbit.relativeVelocityWithRadius(r2)!.doubleValue

    let orbitDeclination = orbit.declinationWithTrueAnomaly(M_PI_2)
    let targetDeclination = targetOrbit.declinationWithTrueAnomaly(targetTrueAnomaly2)
    let vPlaneChange = orbit.relativeVelocityWithRadius(orbit.radiusWithTrueAnomaly(M_PI_2)!.doubleValue)!.doubleValue

    var window = Window()
    window.time = t
    window.travelTime = orbit.period!.doubleValue / 2
    window.phaseAngle = (targetTrueLongitude - sourceTrueLongitude + twoπ) % twoπ
    window.hyperbolicExcessEscapeVelocity = v2 - v1
    window.hyperbolicExcessCaptureVelocity = v4 - v3
    window.planeChangeDeltaV = 2 * vPlaneChange * abs(sin((targetDeclination - orbitDeclination) / 2))
//    dlog("day \(Int(t / day)) tBody: \(Int(t2 / day)) tTransfer: \(Int(window.travelTime / day)) dV: \(Int(window.deltaV)) phase: \(Int(window.phaseAngle * 180 / M_PI))")
    return (window, t2)
}

private func deltaTPair(manoeuvre: Manoeuvre, t: Double) -> DoublePair {
    let (window, t2) = computeTransfer(manoeuvre, t)
    return (t, window.travelTime - t2)
}

public func deltaV(sourceOrbit: Orbit, targetOrbit: Orbit) -> Double? {
    let transfer = SimpleOrbit()
    copy(transfer, sourceOrbit)
    if let radius = sourceOrbit.primaryBody?.radius {
        if let periapsis = sourceOrbit.periapsis?.doubleValue {
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

private func recalculateDeltaVWithLaunchManoeuvre(manoeuvre: Manoeuvre) {
    if let targetBody = manoeuvre.targetBody {
        if let targetOrbit = manoeuvre.targetOrbit {
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
}

private func recalculateDeltaVWithOrbitalChangeManouevre(manoeuvre: Manoeuvre) {
    if let sourceOrbit = manoeuvre.sourceOrbit {
        if let targetOrbit = manoeuvre.targetOrbit {
            if let deltaV = deltaV(sourceOrbit, targetOrbit) {
                manoeuvre.deltaV = deltaV
            }
        }
    }
}

private func recalculateDeltaVWithTransferManoeuvre(manoeuvre: Manoeuvre) {
    let t = max(manoeuvre.initialTime, UniversalTime.currentUniversalTime.timeIntervalSinceEpoch)

    let sourcePeriod = manoeuvre.sourceBody!.orbit!.period!.doubleValue
    let targetPeriod = manoeuvre.targetBody!.orbit!.period!.doubleValue

    var gamma = min(sourcePeriod, targetPeriod) / 6

    var lower = deltaTPair(manoeuvre, t)
    let startPositive = sourcePeriod < targetPeriod

    while startPositive ? lower.1 < 0 : lower.1 > 0 {
//        dlog("\(Int(lower.0 / day)) | \(Int(lower.1 / day))")
        lower = deltaTPair(manoeuvre, lower.0 + gamma)
    }
    var upper = deltaTPair(manoeuvre, lower.0 + gamma)

    while startPositive ? upper.1 > 0 : upper.1 < 0 {
//        dlog("\(Int(lower.0 / day)) | \(Int(lower.1 / day)) || \(Int(upper.0 / day)) | \(Int(upper.1 / day))")
        lower = upper
        upper = deltaTPair(manoeuvre, lower.0 + gamma)
    }

    while min(abs(lower.1), abs(upper.1)) > 1 {
        let guess = deltaTPair(manoeuvre, (lower.0 + upper.0) / 2)
//        dlog("\(Int(lower.0 / day)) | \(Int(lower.1 / day)) || \(Int(guess.0 / day)) | \(Int(guess.1 / day)) || \(Int(upper.0 / day)) | \(Int(upper.1 / day))")
        if (lower.1 < 0) == (guess.1 < 0) {
            lower = guess
        } else {
            upper = guess
        }
//        dlog("lower.1: \(lower.1) upper.1: \(upper.1)")
    }

//    dlog("\(Int(lower.0 / day)) | \(Int(lower.1 / day)) || \(Int(upper.0 / day)) | \(Int(upper.1 / day))")

    let window = computeTransfer(manoeuvre, (abs(lower.1) < abs(upper.1) ? lower : upper).0).0
    manoeuvre.hyperbolicExcessEscapeVelocity = window.hyperbolicExcessEscapeVelocity
    manoeuvre.hyperbolicExcessCaptureVelocity = window.hyperbolicExcessCaptureVelocity
    manoeuvre.transferTime = window.time
    manoeuvre.travelTime = window.travelTime
    manoeuvre.transferPhaseAngle = window.phaseAngle
    manoeuvre.planeChangeDeltaV = window.planeChangeDeltaV

    manoeuvre.deltaV = deltaVWithOrbit(manoeuvre, manoeuvre.sourceOrbit!)!
}

private func recalculateDeltaVWithLandingManoeuvre(manoeuvre: Manoeuvre) {
    let sourceOrbit = manoeuvre.sourceOrbit!
    if let sourceBody = sourceOrbit.primaryBody {
        let transfer = SimpleOrbit()
        copy(transfer, sourceOrbit)
        let radius = sourceOrbit.primaryBody!.radius
        transfer.apoapsis = sourceOrbit.periapsis
        transfer.periapsis = sourceBody.radius
        if let deltaV = deltaV(sourceOrbit, transfer) {
            let surfaceVelocity = twoπ * sourceBody.radius / sourceBody.rotationPeriod
            if manoeuvre.aerobrake {
                manoeuvre.deltaV = deltaV - surfaceVelocity
            } else if let relativeVelocity = transfer.relativeVelocityWithRadius(sourceBody.radius)?.doubleValue {
                manoeuvre.deltaV = deltaV + relativeVelocity - surfaceVelocity
            }
        }
    }
}

public func recalculateDeltaV(manoeuvre: Manoeuvre) {
    if manoeuvre.isTransfer {
        if manoeuvre.sourceOrbit?.primaryBody?.orbit?.primaryBody?.orbit != nil && manoeuvre.targetOrbit?.primaryBody?.orbit?.primaryBody?.orbit != nil {
            recalculateDeltaVWithTransferManoeuvre(manoeuvre)
        }
    } else {
        switch (manoeuvre.sourceOrbit, manoeuvre.targetOrbit) {
        case (nil, .Some):
            recalculateDeltaVWithLaunchManoeuvre(manoeuvre)
        case (.Some, .Some):
            recalculateDeltaVWithOrbitalChangeManouevre(manoeuvre)
        case (.Some, nil):
            recalculateDeltaVWithLandingManoeuvre(manoeuvre)
        default:
            break
        }
    }
}
