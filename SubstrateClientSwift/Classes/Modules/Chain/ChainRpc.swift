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
import ScaleCodecSwift

/// An interface for chain RPC client
public protocol ChainRpc: AnyObject {
    /// Gets block hash using the provided number as a parameter for `RPC` request
    /// - Parameters:
    ///     - number: Number for which block hash should be fetched.
    /// - Returns: Block hash for the provided number
    func blockHash(number: UInt) async throws -> String?
}

/// Handles chain block hash fetching
final class ChainRpcClient: ChainRpc {
    private weak var rpcClient: RpcClient?
    
    init(rpcClient: RpcClient?) {
        self.rpcClient = rpcClient
    }
    
    func blockHash(number: UInt) async throws -> String? {
        try await rpcClient?.sendRequest(
            [NumericAdapter.toData(number).hex.encode(includePrefix: true)],
            method: "chain_getBlockHash"
        )
    }
}
