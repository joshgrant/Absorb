//
// Created by Joshua Grant on 10/13/21
// Copyright © 2021 Joshua Grant. All rights reserved.
//

import Foundation

public extension Hashable
{
    static func hashTogether(_ values: [AnyHashable]) -> Int
    {
        let sortedValues = values.sorted { $0.hashValue < $1.hashValue }
        
        var hasher = Hasher()
        for value in sortedValues {
            hasher.combine(value)
        }
        return hasher.finalize()
    }
}
