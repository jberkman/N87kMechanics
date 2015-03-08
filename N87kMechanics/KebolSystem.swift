//
//  KebolSystem.swift
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

import Foundation

private var _bodies: [Body]?
private var _bodiesByName: [String: Body]?

public class KerbolSystem {

    public class var bodies: [Body] {
        if _bodies == nil {
            if let URL = NSBundle(forClass: self).URLForResource("KerbolSystem", withExtension: "plist") {
                if let bodies = NSArray(contentsOfURL: URL) {
                    _bodies = map(enumerate(bodies)) {
                        let body = Body(bodyID: $0)
                        body.setValuesForKeysWithDictionary($1 as NSDictionary)
                        return body
                    }
                }
            }
        }
        return _bodies ?? []
    }

    public class var bodiesByName: [String: Body] {
        if _bodiesByName == nil {
            _bodiesByName = bodies.reduce([String: Body]()) {
                var ret = $0
                ret[$1.name] = $1
                return ret
            }
        }
        return _bodiesByName ?? [:]
    }

    public class func parentBody(body: Body) -> Body? {
        return bodiesByName[{
            switch body.name {
            case "Moho", "Eve", "Kerbin", "Duna", "Dres", "Jool", "Eeloo":
                return "Sun"
            case "Gilly":
                return "Eve"
            case "Mun", "Minmus":
                return "Kerbin"
            case "Ike":
                return "Duna"
            case "Laythe", "Vall", "Tylo", "Bop", "Pol":
                return "Jool"
            default:
                return ""
            }
        }()]
    }
}
