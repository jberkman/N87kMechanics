//
//  KerbolSystem.swift
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

private var sharedBodies: [Body]!

public class KerbolSystem {

    public class var bodies: [Body] {
        if sharedBodies == nil {
            if let URL = NSBundle(forClass: self).URLForResource("KerbolSystem", withExtension: "plist") {
                if let plist = NSArray(contentsOfURL: URL) {
                    let bodies = reduce(enumerate(plist), [String: SimpleBody]()) {
                        let (bodyID, values: AnyObject) = $1
                        let mutableValues = NSMutableDictionary(dictionary: values as! NSDictionary)
                        mutableValues["bodyID"] = bodyID
                        let body = SimpleBody(values: mutableValues)
                        if let orbitValues = values["orbit"] as? [NSObject: AnyObject] {
                            (body.orbit as? SimpleOrbit)?.setValuesForKeysWithDictionary(orbitValues)
                        }

                        var ret = $0
                        ret[body.name] = body
                        return ret
                    }
                    for body in bodies.values {
                        bodies[{
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
                            }()]?.addSecondaryBody(body)
                    }
                    sharedBodies = Array(bodies.values)
                }
            }
        }
        return sharedBodies
    }

}
