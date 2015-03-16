//
//  ObserverContext.swift
//  N87kMechanics
//
//  Created by jacob berkman on 2015-03-09.
//  Copyright © 2015 jacob berkman
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

public class ObserverContext: NSObject {
    public let keyPath: String
    public let options: NSKeyValueObservingOptions
    public var context = 0
    public init(keyPath: String, options: NSKeyValueObservingOptions = nil) {
        self.keyPath = keyPath
        self.options = options
    }
}

public extension NSObject {

    public func addObserver(observer: NSObject, context: ObserverContext) {
        addObserver(observer, forKeyPath: context.keyPath, options: context.options, context: &context.context)
    }

    public func removeObserver(observer: NSObject, context: ObserverContext) {
        removeObserver(observer, forKeyPath: context.keyPath, context: &context.context)
    }
    
}
