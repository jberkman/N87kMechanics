//
//  HohmannTransferTests.swift
//  N87kMechanics
//
//  Created by jacob berkman on 2014-11-30.
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

import N87kMechanics
import XCTest

class HohmannTransferTests: XCTestCase {

    var transfer: HohmannTransfer!

    override func setUp() {
        super.setUp()
        transfer = HohmannTransfer()
        transfer.sourceBody = Body(bodyID: 0)
        transfer.sourceBody!.orbit.semiMajorAxis = 13_500_000_000
        transfer.sourceBody!.orbit.gravitationalParameter = 3530.461e9
        transfer.sourceBody!.sphereOfInfluence = 82_000_000
        transfer.sourceBody!.radius = 600_000
        transfer.sourceOrbit = Orbit()
        transfer.sourceOrbit!.periapsis = 100_000

        transfer.parentBody = Body(bodyID: 0)
        transfer.parentBody!.orbit.gravitationalParameter = 1.167922e18

        transfer.sourceBody!.orbit.period = 2 * M_PI * sqrt(pow(transfer.sourceBody!.orbit.semiMajorAxis, 3) / transfer.parentBody!.orbit.gravitationalParameter)

        transfer.targetBody = Body(bodyID: 0)
        transfer.targetOrbit = Orbit()
    }

    var orbit: Orbit {
        let orbit = Orbit()
        orbit.semiMajorAxis = transfer.sourceOrbit!.periapsis + transfer.sourceBody!.radius
        return orbit
    }

    override func tearDown() {
        transfer = nil
        super.tearDown()
    }

    func testPractice1() {
        transfer.targetBody!.orbit.semiMajorAxis = 3 * transfer.sourceBody!.orbit.semiMajorAxis
        transfer.targetBody!.orbit.period = 2 * M_PI * sqrt(pow(transfer.targetBody!.orbit.semiMajorAxis, 3) / transfer.parentBody!.orbit.gravitationalParameter)
        transfer.recompute()

        XCTAssertEqualWithAccuracy(transfer.travelTime, 1.2897e7, 1000)
        XCTAssertEqualWithAccuracy(transfer.transferPhaseAngle, 82.0 * M_PI / 180, 0.001)
        XCTAssertEqualWithAccuracy(transfer.deltaV, 2090.4, 0.1)
        XCTAssertEqualWithAccuracy(transfer.ejectionVelocity, 3790.9, 0.1)
        XCTAssertEqualWithAccuracy(transfer.ejectionAngle, 122.7 * M_PI / 180, 0.1)
    }

    func testPractice2() {
        transfer.targetBody!.orbit.semiMajorAxis = 0.7 * transfer.sourceBody!.orbit.semiMajorAxis
        transfer.targetBody!.orbit.period = 2 * M_PI * sqrt(pow(transfer.targetBody!.orbit.semiMajorAxis, 3) / transfer.parentBody!.orbit.gravitationalParameter)
        transfer.recompute()

        XCTAssertEqualWithAccuracy(transfer.travelTime, 3.5733e6, 1000)
        XCTAssertEqualWithAccuracy(transfer.transferPhaseAngle, (360 - 60.9) * M_PI / 180, 0.001)
        XCTAssertEqualWithAccuracy(transfer.deltaV, 860.5, 0.1)
        XCTAssertEqualWithAccuracy(transfer.ejectionVelocity, 3277.4, 0.1)
        XCTAssertEqualWithAccuracy(transfer.ejectionAngle, 152.3 * M_PI / 180, 0.1)
    }

    func testFirstDunaTransfer() {
        transfer.parentBody = KerbolSystem.bodiesByName["Sun"]
        transfer.sourceBody = KerbolSystem.bodiesByName["Kerbin"]
        transfer.sourceOrbit = Orbit()
        transfer.sourceOrbit!.periapsis = 100_000
        transfer.targetBody = KerbolSystem.bodiesByName["Duna"]
        transfer.targetOrbit = Orbit()
        transfer.recompute()

        let day = 60.0 * 60 * 6
        println("day: \(transfer.transferTime / day)")
        println("days: \(transfer.travelTime / day)")
        println(transfer.ejectionVelocity)
        XCTAssertEqualWithAccuracy(transfer.transferTime / day, 233, 1)
        XCTAssertEqualWithAccuracy(transfer.travelTime / day, 295, 1)
        XCTAssertEqualWithAccuracy(transfer.transferPhaseAngle * 180 / M_PI, 36.66, 1)
        XCTAssertEqualWithAccuracy(transfer.deltaVWithOrbit(orbit), 1034, 1)
    }

    func testFirstEveTransfer() {
        transfer.parentBody = KerbolSystem.bodiesByName["Sun"]
        transfer.sourceBody = KerbolSystem.bodiesByName["Kerbin"]
        transfer.sourceOrbit = Orbit()
        transfer.sourceOrbit!.periapsis = 100_000
        transfer.targetBody = KerbolSystem.bodiesByName["Eve"]
        transfer.targetOrbit = Orbit()
        transfer.recompute()

        let day = 60.0 * 60 * 6
        let year = 426.0 * day
        println("day: \(transfer.transferTime / day)")
        println("days: \(transfer.travelTime / day)")
        XCTAssertEqualWithAccuracy(transfer.transferTime, year + 121 * day, day)
        XCTAssertEqualWithAccuracy(transfer.travelTime, 170 * day, day)
        XCTAssertEqualWithAccuracy(transfer.transferPhaseAngle, (360 - 36.4) * M_PI / 180, 0.01)
        XCTAssertEqualWithAccuracy(transfer.deltaVWithOrbit(orbit), 1012, 10)
    }
}
