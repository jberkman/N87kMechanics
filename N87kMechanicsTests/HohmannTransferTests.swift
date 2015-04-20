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

let day = 60.0 * 60 * 6
let year = 426.0

class HohmannTransferTests: XCTestCase {

    var bodies = [Body]()
    var transfer: Manoeuvre!

    var sun: Body!
    var eve: Body!
    var kerbin: Body!
    var mun: Body!
    var minmus: Body!
    var duna: Body!
    var dres: Body!

    override func setUp() {
        super.setUp()
        bodies = KerbolSystem.bodies

        sun = bodies.filter { $0.name == "Sun" }.first!
        eve = bodies.filter { $0.name == "Eve" }.first!
        kerbin = bodies.filter { $0.name == "Kerbin" }.first!
        mun = bodies.filter { $0.name == "Mun" }.first!
        minmus = bodies.filter { $0.name == "Minmus" }.first!
        duna = bodies.filter { $0.name == "Duna" }.first!
        dres = bodies.filter { $0.name == "Dres" }.first!

        transfer = SimpleManoeuvre()
        transfer.aerobrake = false
        transfer.sourceBody = kerbin
        transfer.sourceOrbit = SimpleOrbit()
        transfer.sourceOrbit!.primaryBody = kerbin
        transfer.sourceOrbit!.semiMajorAxis = kerbin.radius + 100_000
    }

    override func tearDown() {
        bodies = []
        transfer = nil
        kerbin = nil
        duna = nil
        super.tearDown()
    }

//    func testPractice1() {
//        transfer.targetBody!.orbit.semiMajorAxis = 3 * transfer.sourceBody!.orbit.semiMajorAxis
//        transfer.targetBody!.orbit.period = 2 * M_PI * sqrt(pow(transfer.targetBody!.orbit.semiMajorAxis, 3) / transfer.parentBody!.orbit.gravitationalParameter)
//        transfer.recompute()
//
//        XCTAssertEqualWithAccuracy(transfer.travelTime, 1.2897e7, 1000)
//        XCTAssertEqualWithAccuracy(transfer.transferPhaseAngle, 82.0 * M_PI / 180, 0.001)
//        XCTAssertEqualWithAccuracy(transfer.deltaV, 2090.4, 0.1)
//        XCTAssertEqualWithAccuracy(transfer.ejectionVelocity, 3790.9, 0.1)
//        XCTAssertEqualWithAccuracy(transfer.ejectionAngle, 122.7 * M_PI / 180, 0.1)
//    }

//    func testPractice2() {
//        transfer.targetBody!.orbit.semiMajorAxis = 0.7 * transfer.sourceBody!.orbit.semiMajorAxis
//        transfer.targetBody!.orbit.period = 2 * M_PI * sqrt(pow(transfer.targetBody!.orbit.semiMajorAxis, 3) / transfer.parentBody!.orbit.gravitationalParameter)
//        transfer.recompute()
//
//        XCTAssertEqualWithAccuracy(transfer.travelTime, 3.5733e6, 1000)
//        XCTAssertEqualWithAccuracy(transfer.transferPhaseAngle, (360 - 60.9) * M_PI / 180, 0.001)
//        XCTAssertEqualWithAccuracy(transfer.deltaV, 860.5, 0.1)
//        XCTAssertEqualWithAccuracy(transfer.ejectionVelocity, 3277.4, 0.1)
//        XCTAssertEqualWithAccuracy(transfer.ejectionAngle, 152.3 * M_PI / 180, 0.1)
//    }

    func testFirstDunaTransfer() {
        transfer.targetBody = duna
        transfer.targetOrbit = SimpleOrbit()
        transfer.targetOrbit!.primaryBody = duna
        transfer.targetOrbit!.semiMajorAxis = duna.parkingOrbitHeight + duna.radius

        transfer.recalculateDeltaV()

        println("day: \(transfer.transferTime / day)")
        println("days: \(transfer.travelTime / day)")
        println(transfer.ejectionVelocity)
        XCTAssertEqualWithAccuracy(transfer.transferTime / day, 235, 1)
        XCTAssertEqualWithAccuracy(transfer.travelTime / day, 295, 1)
        XCTAssertEqualWithAccuracy(transfer.transferPhaseAngle * 180 / M_PI, 36.66, 1)
        XCTAssertEqualWithAccuracy(transfer.ejectionDeltaV!.doubleValue, 1046, 10)
        XCTAssertEqualWithAccuracy(transfer.planeChangeDeltaV, 7, 5)
        XCTAssertEqualWithAccuracy(transfer.captureDeltaV!.doubleValue, 641, 10)
        XCTAssertEqualWithAccuracy(transfer.deltaV, 1687, 20)

        transfer.aerobrake = true
        transfer.recalculateDeltaV()

        XCTAssertEqual(transfer.captureDeltaV!.doubleValue, 0)
    }

    func testFirstEveTransfer() {
        transfer.targetBody = eve
        transfer.targetOrbit = SimpleOrbit()
        transfer.targetOrbit!.primaryBody = eve
        transfer.targetOrbit!.semiMajorAxis = eve.parkingOrbitHeight + eve.radius

        transfer.recalculateDeltaV()

        println("day: \(Int((transfer.transferTime / day) / year)) \((transfer.transferTime / day) % year)")
        println("days: \(transfer.travelTime / day)")
        XCTAssertEqualWithAccuracy(transfer.transferTime / day, year + 121, 1)
        XCTAssertEqualWithAccuracy(transfer.travelTime / day, 170, 1)
        XCTAssertEqualWithAccuracy(transfer.transferPhaseAngle * 180 / M_PI, 304, 1)
        XCTAssertEqualWithAccuracy(transfer.ejectionDeltaV!.doubleValue, 1024, 10)
        XCTAssertEqualWithAccuracy(transfer.planeChangeDeltaV, 375, 10)
        XCTAssertEqualWithAccuracy(transfer.captureDeltaV!.doubleValue, 1400, 10)
        XCTAssertEqualWithAccuracy(transfer.deltaV, 2800, 20)

        transfer.aerobrake = true
        transfer.recalculateDeltaV()

        XCTAssertEqual(transfer.captureDeltaV!.doubleValue, 0)
    }

    func testFirstDresTransfer() {
        transfer.targetBody = dres
        transfer.targetOrbit = SimpleOrbit()
        transfer.targetOrbit!.primaryBody = dres
        transfer.targetOrbit!.semiMajorAxis = dres.parkingOrbitHeight + dres.radius

        transfer.recalculateDeltaV()

        println("day: \(Int((transfer.transferTime / day) / year)) \((transfer.transferTime / day) % year)")
        println("days: \(transfer.travelTime / day)")

        XCTAssertEqualWithAccuracy(transfer.transferTime / day, 388, 1)
        XCTAssertEqualWithAccuracy(transfer.travelTime / day - year, 100, 1)
        XCTAssertEqualWithAccuracy(transfer.transferPhaseAngle * 180 / M_PI, 91, 1)
        XCTAssertEqualWithAccuracy(transfer.ejectionDeltaV!.doubleValue, 1458, 10)
        XCTAssertEqualWithAccuracy(transfer.planeChangeDeltaV, 550, 10)
        XCTAssertEqualWithAccuracy(transfer.captureDeltaV!.doubleValue, 1510, 10)
        XCTAssertEqualWithAccuracy(transfer.deltaV, 3516, 20)

        transfer.aerobrake = true
        transfer.recalculateDeltaV()

        XCTAssertEqualWithAccuracy(transfer.captureDeltaV!.doubleValue, 1510, 10)
    }

    func testMunTransfer() {
        transfer.targetBody = mun
        transfer.targetOrbit = SimpleOrbit()
        transfer.targetOrbit!.primaryBody = mun
        transfer.targetOrbit!.semiMajorAxis = mun.parkingOrbitHeight + mun.radius

        transfer.recalculateDeltaV()

        println("day: \(Int((transfer.transferTime / day) / year)) \((transfer.transferTime / day) % year)")
        println("days: \(transfer.travelTime / day)")

        XCTAssertEqualWithAccuracy(transfer.transferTime / 60, 31, 1)
        XCTAssertEqualWithAccuracy(transfer.travelTime / 60 / 60, 7.5, 0.5)
        XCTAssertEqualWithAccuracy(transfer.transferPhaseAngle * 180 / M_PI, 110, 1)
        XCTAssertEqualWithAccuracy(transfer.ejectionDeltaV!.doubleValue, 840, 10)
        XCTAssertEqual(transfer.planeChangeDeltaV, 0)
        XCTAssertEqualWithAccuracy(transfer.captureDeltaV!.doubleValue, 310, 10)
        XCTAssertEqualWithAccuracy(transfer.deltaV, 1150, 10)

        transfer.aerobrake = true
        transfer.recalculateDeltaV()

        XCTAssertEqualWithAccuracy(transfer.captureDeltaV!.doubleValue, 310, 10)
    }

    func testMunReturn() {
        transfer.targetBody = transfer.sourceBody
        transfer.targetOrbit = transfer.sourceOrbit
        transfer.sourceBody = mun
        transfer.sourceOrbit = SimpleOrbit()
        transfer.sourceOrbit!.primaryBody = mun
        transfer.sourceOrbit!.semiMajorAxis = mun.parkingOrbitHeight + mun.radius

        transfer.recalculateDeltaV()

        println("day: \(Int((transfer.transferTime / day) / year)) \((transfer.transferTime / day) % year)")
        println("days: \(transfer.travelTime / day)")

        XCTAssertEqual(transfer.transferTime, 0)
        XCTAssertEqualWithAccuracy(transfer.travelTime / 60 / 60, 7.5, 0.5)
        // XCTAssertEqualWithAccuracy(transfer.transferPhaseAngle * 180 / M_PI, 41, 1)
        XCTAssertEqualWithAccuracy(transfer.ejectionDeltaV!.doubleValue, 310, 10)
        XCTAssertEqual(transfer.planeChangeDeltaV, 0)
        XCTAssertEqualWithAccuracy(transfer.captureDeltaV!.doubleValue, 840, 10)
        XCTAssertEqualWithAccuracy(transfer.deltaV, 1150, 10)

        transfer.aerobrake = true
        transfer.recalculateDeltaV()

        XCTAssertEqual(transfer.captureDeltaV!.doubleValue, 0)
    }

    func testMinmusTransfer() {
        transfer.targetBody = minmus
        transfer.targetOrbit = SimpleOrbit()
        transfer.targetOrbit!.primaryBody = minmus
        transfer.targetOrbit!.semiMajorAxis = minmus.parkingOrbitHeight + minmus.radius

        transfer.recalculateDeltaV()

        println("day: \(Int((transfer.transferTime / day) / year)) \((transfer.transferTime / day) % year)")
        println("days: \(transfer.travelTime / day)")

        XCTAssertEqualWithAccuracy(transfer.transferTime / 60, 5, 1)
        XCTAssertEqualWithAccuracy(transfer.travelTime / day, 9, 1 / 6.0)
        XCTAssertEqualWithAccuracy(transfer.transferPhaseAngle * 180 / M_PI, 115, 1)
        XCTAssertEqualWithAccuracy(transfer.ejectionDeltaV!.doubleValue, 906, 10)
        XCTAssertEqualWithAccuracy(transfer.planeChangeDeltaV, 100, 10)
        XCTAssertEqualWithAccuracy(transfer.captureDeltaV!.doubleValue, 160, 10)
        XCTAssertEqualWithAccuracy(transfer.deltaV, 1166, 10)

        transfer.aerobrake = true
        transfer.recalculateDeltaV()

        XCTAssertEqualWithAccuracy(transfer.captureDeltaV!.doubleValue, 160, 10)
    }

    func testMinmusReturn() {
        transfer.targetBody = transfer.sourceBody
        transfer.targetOrbit = transfer.sourceOrbit
        transfer.sourceBody = minmus
        transfer.sourceOrbit = SimpleOrbit()
        transfer.sourceOrbit!.primaryBody = minmus
        transfer.sourceOrbit!.semiMajorAxis = minmus.parkingOrbitHeight + minmus.radius

        transfer.recalculateDeltaV()

        println("day: \(Int((transfer.transferTime / day) / year)) \((transfer.transferTime / day) % year)")
        println("days: \(transfer.travelTime / day)")

        XCTAssertEqual(transfer.transferTime, 0)
        XCTAssertEqualWithAccuracy(transfer.travelTime / day, 9, 1 / 6.0)
        //XCTAssertEqualWithAccuracy(transfer.transferPhaseAngle * 180 / M_PI, 293, 1)
        XCTAssertEqualWithAccuracy(transfer.ejectionDeltaV!.doubleValue, 160, 10)
        XCTAssertEqualWithAccuracy(transfer.planeChangeDeltaV, 2, 10)
        XCTAssertEqualWithAccuracy(transfer.captureDeltaV!.doubleValue, 906, 10)
        XCTAssertEqualWithAccuracy(transfer.deltaV, 1069, 10)

        transfer.aerobrake = true
        transfer.recalculateDeltaV()
            
        XCTAssertEqual(transfer.captureDeltaV!.doubleValue, 0)
    }

    func testKerinSunL4() {
        transfer.targetBody = sun
        transfer.targetOrbit = SimpleOrbit()
        transfer.targetOrbit!.primaryBody = sun
        let a = kerbin.orbit!.semiMajorAxis * pow(25.0 / 36, 1.0 / 3)
        let apoapsis = kerbin.orbit!.apoapsis!.doubleValue
        let periapsis = 2 * (a - sun.radius) - apoapsis
        transfer.targetOrbit!.semiMajorAxis = a
        transfer.targetOrbit!.eccentricity = eccentricityWithApoapsis(apoapsis, periapsis: periapsis, radius: sun.radius)

        transfer.recalculateDeltaV()

        println("day: \(Int((transfer.transferTime / day) / year)) \((transfer.transferTime / day) % year)")
        println("days: \(transfer.travelTime / day)")

        XCTAssertEqual(transfer.transferTime, 0)
        XCTAssertEqualWithAccuracy(transfer.travelTime / day, 178, 1)
        //XCTAssertEqualWithAccuracy(transfer.transferPhaseAngle * 180 / M_PI, 91, 1)
        XCTAssertEqualWithAccuracy(transfer.ejectionDeltaV!.doubleValue, 990, 10)
        XCTAssertEqual(transfer.planeChangeDeltaV, 0)
        XCTAssertEqualWithAccuracy(transfer.captureDeltaV!.doubleValue, 0, 1)
        XCTAssertEqualWithAccuracy(transfer.deltaV, 990, 20)

        transfer.aerobrake = true
        transfer.recalculateDeltaV()

        XCTAssertEqualWithAccuracy(transfer.captureDeltaV!.doubleValue, 0, 10)
    }

    func testKerinSunL5() {
        transfer.targetBody = sun
        transfer.targetOrbit = SimpleOrbit()
        transfer.targetOrbit!.primaryBody = sun
        let a = kerbin.orbit!.semiMajorAxis * pow(49.0 / 36, 1.0 / 3)
        let periapsis = kerbin.orbit!.apoapsis!.doubleValue
        let apoapsis = 2 * (a - sun.radius) - periapsis
        transfer.targetOrbit!.semiMajorAxis = a
        transfer.targetOrbit!.eccentricity = eccentricityWithApoapsis(apoapsis, periapsis: periapsis, radius: sun.radius)
        //transfer.targetOrbit!.argumentOfPeriapsis = trueLongitudeWithTrueAnomaly(kerbin.orbit!, trueAnomalyAtTime(kerbin.orbit!, 0)!)

        transfer.recalculateDeltaV()

        println("day: \(Int((transfer.transferTime / day) / year)) \((transfer.transferTime / day) % year)")
        println("days: \(transfer.travelTime / day)")

        XCTAssertEqual(transfer.transferTime, 0)
        XCTAssertEqualWithAccuracy(transfer.travelTime / day, 248, 1)
        //XCTAssertEqualWithAccuracy(transfer.transferPhaseAngle * 180 / M_PI, 91, 1)
        XCTAssertEqualWithAccuracy(transfer.ejectionDeltaV!.doubleValue, 960, 10)
        XCTAssertEqual(transfer.planeChangeDeltaV, 0)
        XCTAssertEqualWithAccuracy(transfer.captureDeltaV!.doubleValue, 0, 1)
        XCTAssertEqualWithAccuracy(transfer.deltaV, 960, 20)

        transfer.aerobrake = true
        transfer.recalculateDeltaV()

        XCTAssertEqualWithAccuracy(transfer.captureDeltaV!.doubleValue, 0, 10)
    }
}
