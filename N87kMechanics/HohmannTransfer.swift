//
//  HohmannTransfer.swift
//  N87kMechanics
//
//  Created by jacob berkman on 2015-04-05.
//  Copyright (c) 2015 jacob berkman. All rights reserved.
//

import Foundation

struct HohmannTransfer {
    enum Type {
        case ToSecondary, ToPrimary, BetweenSecondaries
    }
    let type: Type
    let sourceOrbit: Orbit
    let targetOrbit: Orbit

    init?(manoeuvre: Manoeuvre) {
        if let sourceBody = manoeuvre.sourceBody {
            if let targetBody = manoeuvre.targetBody {
                if sourceBody === manoeuvre.targetBody?.orbit?.primaryBody && manoeuvre.sourceOrbit != nil {
                    type = .ToSecondary
                    sourceOrbit = manoeuvre.sourceOrbit!
                    targetOrbit = targetBody.orbit!
                    return
                } else if targetBody === manoeuvre.sourceBody?.orbit?.primaryBody && manoeuvre.targetOrbit != nil {
                    type = .ToPrimary
                    sourceOrbit = manoeuvre.sourceBody!.orbit!
                    targetOrbit = manoeuvre.targetOrbit!
                    return
                } else if let sourcePrimaryBody = sourceBody.orbit?.primaryBody {
                    if let targetPrimaryBody = targetBody.orbit?.primaryBody {
                        if sourcePrimaryBody === targetPrimaryBody {
                            type = .BetweenSecondaries
                            sourceOrbit = manoeuvre.sourceBody!.orbit!
                            targetOrbit = manoeuvre.targetBody!.orbit!
                            return
                        }
                    }
                }
            }
        }
        return nil
    }

    func transferAtTime(time: NSTimeInterval) -> (orbit: Orbit, error: NSTimeInterval) {
        let sourceTrueAnomaly = trueAnomalyAtTime(sourceOrbit, time)!
        let targetTrueAnomaly: Double = {
            switch self.type {
            case .ToPrimary where self.sourceOrbit.semiMajorAxis < self.targetOrbit.semiMajorAxis:
                return 0
            case .ToPrimary:
                return M_PI
            default:
                return trueAnomalyAtTime(self.targetOrbit, time)!
            }
        }()

        let sourceTrueLongitude = trueLongitudeWithTrueAnomaly(sourceOrbit, sourceTrueAnomaly)
        let targetTrueLongitude = trueLongitudeWithTrueAnomaly(targetOrbit, targetTrueAnomaly)
        let targetTrueAnomaly2: Double = {
            switch self.type {
            case .ToPrimary where self.sourceOrbit.semiMajorAxis < self.targetOrbit.semiMajorAxis:
                return M_PI
            case .ToPrimary:
                return 0
            default:
                return trueAnomalyWithTrueLongitude(self.targetOrbit, sourceTrueLongitude + M_PI)
            }
        }()

//        dlog("target goes from \(targetTrueLongitude * 180 / M_PI) to \(targetTrueLongitude2 * 180 / M_PI)")

        var r1 = radiusWithTrueAnomaly(sourceOrbit, sourceTrueAnomaly)
        let r2 = radiusWithTrueAnomaly(targetOrbit, targetTrueAnomaly2)

        let tm1 = meanAnomalyWithTrueAnomaly(targetOrbit, targetTrueAnomaly)
        let tm2 = meanAnomalyWithTrueAnomaly(targetOrbit, targetTrueAnomaly2)
        let t2 = ((tm2 - tm1 + twoπ) % twoπ) / meanMotion(targetOrbit)!

        let radius = targetOrbit.primaryBody!.radius
        let orbit = SimpleOrbit()
        orbit.primaryBody = targetOrbit.primaryBody
        orbit.eccentricity = eccentricityWithApoapsis(max(r1, r2) - radius, periapsis: min(r1, r2) - radius, radius: radius)
        orbit.semiMajorAxis = (r1 + r2) / 2
        orbit.inclination = sourceOrbit.inclination
        orbit.argumentOfPeriapsis = (sourceOrbit.argumentOfPeriapsis + sourceTrueAnomaly) % twoπ
        orbit.longitudeOfAscendingNode = sourceOrbit.longitudeOfAscendingNode

//        dlog("half period: \(Int(orbit.period!.doubleValue / 2 / day)) t2: \(Int(t2 / day)) error: \(Int((orbit.period!.doubleValue - t2) / day))")

        return (orbit: orbit, error: (orbit.period!.doubleValue / 2) - t2)
    }

}