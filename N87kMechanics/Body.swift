//
//  Body.swift
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

public class Body: NSObject {
    public let bodyID: Int
    public let orbit = Orbit()
    public dynamic var atmosphereContainsOxygen = false
    public dynamic var name = ""
    public dynamic var maxAtmosphere = 0.0
    public dynamic var radius = 0.0
    //public dynamic var mass = 0.0
    private var _mass: Double?
    public var mass: Double {
        get {
            return _mass ?? KerbolSystem.bodiesByName[name]?.mass ?? 0
        }
        set {
            _mass = newValue
        }
    }
    public dynamic var rotationPeriod: NSTimeInterval = 0
    public dynamic var sphereOfInfluence = 0.0
    public dynamic var tidallyLocked = false

    public init(bodyID: Int) {
        self.bodyID = bodyID
        super.init()
    }

    public override func setValue(value: AnyObject?, forKey key: String) {
        if key == "orbit" && value is NSDictionary {
            orbit.setValuesForKeysWithDictionary(value as NSDictionary)
        } else {
            super.setValue(value, forKey: key)
        }
    }

}