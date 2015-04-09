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

public func ejectionVelocity(manoeuvre: Manoeuvre) -> Double? {
    if let orbit = manoeuvre.sourceOrbit {
        return ejectionVelocityWithOrbit(manoeuvre, orbit)
    }
    return nil
}

public func ejectionVelocityWithOrbit(manoeuvre: Manoeuvre, orbit: Orbit) -> Double? {
    if let periapsis = periapsis(orbit) {
        if let primaryBody = orbit.primaryBody {
            if let µ = primaryBody.orbit?.gravitationalParameter {
                return sqrt(pow(manoeuvre.hyperbolicExcessEscapeVelocity, 2) + 2 * µ / (periapsis + primaryBody.radius))
            }
        }
    }
    return nil
}

public func ejectionAngle(manoeuvre: Manoeuvre) -> Double? {
    if let sourceBody = manoeuvre.sourceBody,
        sourceOrbitRadius = sourceBody.orbit?.semiMajorAxis,
        targetOrbitRadius = manoeuvre.targetBody?.orbit?.semiMajorAxis,
        periapsis = manoeuvre.sourceOrbit?.periapsis?.doubleValue,
        µ = sourceBody.orbit?.gravitationalParameter,
        v = ejectionVelocity(manoeuvre) {
            let r = sourceBody.radius + periapsis
            let e1 = v * v / 2 - µ / r
            let h = r * v
            let e2 = sqrt(1 + 2 * e1 * h * h / (µ * µ))
            return (sourceOrbitRadius > targetOrbitRadius ? 2 : 1) * M_PI - acos(1 / e2)
    }
    return nil
}

public func currentPhaseAngle(manoeuvre: Manoeuvre) -> Double? {
    if let targetTrueLongitude = manoeuvre.targetBody?.orbit?.trueLongitude?.doubleValue,
        sourceTrueLongitude = manoeuvre.sourceBody?.orbit?.trueLongitude?.doubleValue {
            return (targetTrueLongitude - sourceTrueLongitude) % twoπ
    }
    return nil
}

public func ejectionDeltaVWithOrbit(manoeuvre: Manoeuvre, orbit: Orbit) -> Double? {
    if orbit.primaryBody === manoeuvre.targetBody?.orbit?.primaryBody {
        return manoeuvre.hyperbolicExcessEscapeVelocity
    } else if let ejectionVelocity = ejectionVelocityWithOrbit(manoeuvre, orbit),
        radius = orbit.primaryBody?.radius,
        periapsis = periapsis(orbit),
        relativeVelocity = relativeVelocityWithRadius(orbit, periapsis + radius) {
            return abs(ejectionVelocity - relativeVelocity)
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
    if let orbit = manoeuvre.targetOrbit,
        primaryBody = orbit.primaryBody {
            if primaryBody.maxAtmosphere > 0 && manoeuvre.aerobrake {
                return 0
            } else if primaryBody === manoeuvre.sourceBody?.orbit?.primaryBody {
                return manoeuvre.hyperbolicExcessCaptureVelocity
            } else if let µ = primaryBody.orbit?.gravitationalParameter,
                periapsis = periapsis(orbit),
                relativeVelocity = manoeuvre.targetOrbit?.relativeVelocityWithRadius(periapsis + primaryBody.radius)?.doubleValue {
                    let captureVelocity = sqrt(pow(manoeuvre.hyperbolicExcessCaptureVelocity, 2) + 2 * µ / (periapsis + primaryBody.radius))
                    return abs(captureVelocity - relativeVelocity)
            }
    }
    return nil
}

public func deltaVWithOrbit(manoeuvre: Manoeuvre, orbit: Orbit) -> Double? {
    if let ejectionDeltaV = ejectionDeltaVWithOrbit(manoeuvre, orbit),
        captureDeltaV = captureDeltaV(manoeuvre) {
            return ejectionDeltaV + manoeuvre.planeChangeDeltaV + captureDeltaV
    }
    return nil
}

public func deltaV(sourceOrbit: Orbit, targetOrbit: Orbit) -> Double? {
    let transfer = SimpleOrbit()
    copy(transfer, sourceOrbit)
    if let radius = sourceOrbit.primaryBody?.radius,
        periapsis = periapsis(sourceOrbit),
        apoapsis = apoapsis(targetOrbit) {
            transfer.semiMajorAxis = (apoapsis + periapsis) / 2 + radius
            transfer.eccentricity = eccentricityWithApoapsis(apoapsis, periapsis: periapsis, radius: radius)
            if let v0 = relativeVelocityWithRadius(sourceOrbit, radius + periapsis),
                v1 = relativeVelocityWithRadius(transfer, radius + periapsis),
                v2 = relativeVelocityWithRadius(transfer, radius + apoapsis),
                v3 = relativeVelocityWithRadius(targetOrbit, radius + apoapsis) {
                    return abs(v1 - v0) + abs(v3 - v2)
            }
    }
    return nil
}

private func recalculateDeltaVWithLaunchManoeuvre(manoeuvre: Manoeuvre) {
    if let targetBody = manoeuvre.targetBody,
        targetOrbit = manoeuvre.targetOrbit {
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
            } else if let periapsis = periapsis(targetOrbit) {
                let transfer = SimpleOrbit()
                copy(transfer, targetOrbit)
                transfer.semiMajorAxis = periapsis / 2 + targetBody.radius
                transfer.eccentricity = eccentricityWithApoapsis(periapsis, periapsis: 0, radius: targetBody.radius)
                if let relativeVelocity = relativeVelocityWithRadius(transfer, targetBody.radius),
                    deltaV = deltaV(transfer, targetOrbit) {
                        manoeuvre.deltaV = relativeVelocity + deltaV - twoπ * targetBody.radius / targetBody.rotationPeriod
                }
            }
    }
}

private func recalculateDeltaVWithOrbitalChangeManouevre(manoeuvre: Manoeuvre) {
    if let sourceOrbit = manoeuvre.sourceOrbit,
        targetOrbit = manoeuvre.targetOrbit,
        deltaV = deltaV(sourceOrbit, targetOrbit) {
            manoeuvre.deltaV = deltaV
    }
}

private func recalculateDeltaVWithTransferManoeuvre(manoeuvre: Manoeuvre) {
    if let transfer = HohmannTransfer(manoeuvre: manoeuvre) {
        let t = max(manoeuvre.initialTime, UniversalTime.currentUniversalTime.timeIntervalSinceEpoch)
        var lower = (time: t, transfer: transfer.transferAtTime(t))
        if transfer.type != .ToPrimary {
            let gamma = min(period(transfer.sourceOrbit)!, period(transfer.targetOrbit)!) / 6
            func nextWindow() -> (time: Double, transfer: (orbit: Orbit, error: Double)) {
                let t2 = lower.time + gamma
                return (time: t2, transfer: transfer.transferAtTime(t2))
            }

            let startPositive = period(transfer.sourceOrbit)! < period(transfer.targetOrbit)!
            while startPositive ? lower.transfer.error < 0 : lower.transfer.error > 0 {
                lower = nextWindow()
            }
            var upper = nextWindow()

            while startPositive ? upper.transfer.error > 0 : upper.transfer.error < 0 {
                lower = upper
                upper = nextWindow()
            }

            while min(abs(lower.transfer.error), abs(upper.transfer.error)) > 1 {
                let t5 = (lower.time + upper.time) / 2
                let guess = (time: t5, transfer: transfer.transferAtTime(t5))
//                dlog("\(Int(lower.time / day)) | \(Int(lower.transfer.error / day)) || \(Int(guess.time / day)) | \(Int(guess.transfer.error / day)) || \(Int(upper.time / day)) | \(Int(upper.transfer.error / day))")
                if (lower.transfer.error < 0) == (guess.transfer.error < 0) {
                    lower = guess
                } else {
                    upper = guess
                }
//                dlog("lower.transfer.error: \(lower.transfer.error) upper.1: \(upper.transfer.error)")
            }

//            dlog("\(Int(lower.time / day)) | \(Int(lower.transfer.error / day)) || \(Int(upper.time / day)) | \(Int(upper.transfer.error / day))")

            lower = abs(lower.transfer.error) < abs(upper.transfer.error) ? lower : upper
        }

        var r = [ 0, M_PI_2, M_PI ].map { radiusWithTrueAnomaly(lower.transfer.orbit, $0) }
        if transfer.sourceOrbit.semiMajorAxis > transfer.targetOrbit.semiMajorAxis {
            r = r.reverse()
        }

        let v1 = relativeVelocityWithRadius(transfer.sourceOrbit, r[0])!
        let v2 = relativeVelocityWithRadius(lower.transfer.orbit, r[0])!
        let v3 = relativeVelocityWithRadius(lower.transfer.orbit, r[2])!
        let v4 = relativeVelocityWithRadius(transfer.targetOrbit, r[2])!

        let tPeriod = period(lower.transfer.orbit)!
        let orbitDeclination = declinationWithTrueAnomaly(lower.transfer.orbit, M_PI_2)
        let targetTrueAnomaly2 = trueAnomalyAtTime(transfer.targetOrbit, lower.time + tPeriod / 2)!
        let targetDeclination = declinationWithTrueAnomaly(transfer.targetOrbit, targetTrueAnomaly2)
        let vPlaneChange = relativeVelocityWithRadius(lower.transfer.orbit, r[1])!

        let sourceTrueLongitude = trueLongitudeWithTrueAnomaly(transfer.sourceOrbit, trueAnomalyAtTime(transfer.sourceOrbit, lower.time)!)
        let targetTrueLongitude = trueLongitudeWithTrueAnomaly(transfer.targetOrbit, trueAnomalyAtTime(transfer.targetOrbit, lower.time)!)

        manoeuvre.hyperbolicExcessEscapeVelocity = abs(v2 - v1)
        manoeuvre.hyperbolicExcessCaptureVelocity = abs(v4 - v3)

        manoeuvre.transferTime = lower.time
        manoeuvre.travelTime = tPeriod / 2
        manoeuvre.transferPhaseAngle = (targetTrueLongitude - sourceTrueLongitude + twoπ) % twoπ
        manoeuvre.planeChangeDeltaV = 2 * vPlaneChange * abs(sin((targetDeclination - orbitDeclination) / 2))

        manoeuvre.deltaV = deltaVWithOrbit(manoeuvre, manoeuvre.sourceOrbit!)!

//        dlog("day \(Int(window.time / day)) tBody: \(Int(window.transfer.error / day)) tTransfer: \(Int(manoeuvre.travelTime / day)) dV: \(Int(manoeuvre.deltaV)) phase: \(Int(manoeuvre.transferPhaseAngle * 180 / M_PI))")
    }
}

private func recalculateDeltaVWithLandingManoeuvre(manoeuvre: Manoeuvre) {
    let sourceOrbit = manoeuvre.sourceOrbit!
    if let sourceBody = sourceOrbit.primaryBody,
        periapsis = periapsis(sourceOrbit) {
            let transfer = SimpleOrbit()
            copy(transfer, sourceOrbit)
            let radius = sourceOrbit.primaryBody!.radius
            transfer.semiMajorAxis = periapsis / 2 + sourceBody.radius
            transfer.eccentricity = eccentricityWithApoapsis(periapsis, periapsis: 0, radius: sourceBody.radius)
            if let deltaV = deltaV(sourceOrbit, transfer) {
                if manoeuvre.aerobrake {
                    manoeuvre.deltaV = deltaV
                } else if let relativeVelocity = relativeVelocityWithRadius(transfer, sourceBody.radius) {
                    let surfaceVelocity = twoπ * sourceBody.radius / sourceBody.rotationPeriod
                    manoeuvre.deltaV = deltaV + relativeVelocity - surfaceVelocity
                }
            }
    }
}

public func recalculateDeltaV(manoeuvre: Manoeuvre) {
    if manoeuvre.isTransfer {
        if manoeuvre.sourceOrbit?.primaryBody === manoeuvre.sourceBody &&
            manoeuvre.targetOrbit?.primaryBody === manoeuvre.targetBody &&
            manoeuvre.sourceBody?.orbit != nil && manoeuvre.targetBody?.orbit != nil {
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
