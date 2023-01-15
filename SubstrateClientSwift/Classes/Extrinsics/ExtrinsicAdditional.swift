/**
 *
 * Copyright 2023 SUBSTRATE LABORATORY LLC <info@sublab.dev>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0

 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * 
 */

import Foundation

/// Additional information for extrinsics
class ExtrinsicAdditional {
    let specVersion: UInt32
    let txVersion: UInt32
    let genesisHash: Data
    let mortalityCheckpoint: Data
    let marker: Any
    
    init(
        specVersion: UInt32,
        txVersion: UInt32,
        genesisHash: Data,
        mortalityCheckpoint: Data,
        marker: Any
    ) {
        self.specVersion = specVersion
        self.txVersion = txVersion
        self.genesisHash = genesisHash
        self.mortalityCheckpoint = mortalityCheckpoint
        self.marker = marker
    }
}
