//
//  OrbitTests.swift
//  N87kMechanics
//
//  Created by jacob berkman on 2015-04-16.
//  Copyright (c) 2015 jacob berkman. All rights reserved.
//

import N87kMechanics
import XCTest

class OrbitTests: XCTestCase {
    var orbit: Orbit!

    override func setUp() {
        super.setUp()
        orbit = SimpleOrbit()
        orbit.primaryBody = KerbolSystem.bodies.filter { $0.name == "Kerbin" }.first
        orbit.semiMajorAxis = orbit.primaryBody!.synchronousOrbitHeight!.doubleValue
    }
    
    override func tearDown() {
        orbit = nil
        super.tearDown()
    }

    func testEccentricAnomalyWithMeanAnomaly() {
        for eccentricity in 0 ..< 10 {
            orbit.eccentricity = Double(eccentricity) / 10
            for meanAnomaly in 0 ..< 360 {
                let eccentricAnomaly = eccentricAnomalyWithMeanAnomaly(orbit, Double(meanAnomaly) * M_PI / 180)
                let testValue = meanAnomalyWithEccentricAnomaly(orbit, eccentricAnomaly)
                println("\(meanAnomaly) -> \(testValue * 180 / M_PI): \(eccentricAnomaly * 180 / M_PI)")
                XCTAssertEqualWithAccuracy(testValue * 180 / M_PI, Double(meanAnomaly), 0.1)
            }
        }
    }

}
