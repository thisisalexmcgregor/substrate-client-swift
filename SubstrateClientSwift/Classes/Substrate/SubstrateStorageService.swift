import Foundation
import ScaleCodecSwift
import Combine

/// Substrate storage service
class SubstrateStorageService {
    private let lookup: SubstrateLookupService
    private let stateRpc: StateRpc
    private var anyCancellable = Set<AnyCancellable>()
    
    /// Creates a substrate storage service
    /// - Parameters:
    ///     - lookup: Substrate lookup serivce
    ///     - stateRpc: An interface for getting Runtime metadata and fetching Storage Items
    init(lookup: SubstrateLookupService, stateRpc: StateRpc) {
        self.lookup = lookup
        self.stateRpc = stateRpc
    }
    
    /// Finds a storage item previously fetching the module
    /// - Parameters:
    ///     - moduleName: Module's name to fetch
    ///     - itemName: Storage item's name
    /// - Returns: `AnyPublisher` which contains an optional storage item result
    func find(moduleName: String, itemName: String) -> AnyPublisher<FindStorageItemResult?, Never> {
        lookup.findStorageItem(moduleName: moduleName, itemName: itemName)
    }
    
    /// Fetches a storage item after getting a module first
    /// - Parameters:
    ///     - moduleName: Module's name to fetch
    ///     - itemName: Storage item's name
    ///     - completion: Completion with either a generic `T` or `RpcError`
    func fetch<T: Decodable>(
        moduleName: String,
        itemName: String,
        completion: @escaping(T?, RpcError?) -> Void
    ) {
        find(moduleName: moduleName, itemName: itemName)
            .sink { [weak self] result in
                self?.handleFetchingStorageItem(from: result, completion: completion)
            }
            .store(in: &anyCancellable)
    }
    
    /// Fetches a storage item after getting a module first
    /// - Parameters:
    ///     - moduleName: Module's name to fetch
    ///     - itemName: Storage item's name
    ///     - key: Key to use for fetching a storage item
    ///     - completion: Completion with either a generic `T` or `RpcError`
    func fetch<T: Decodable>(
        moduleName: String,
        itemName: String,
        key: Data,
        completion: @escaping(T?, RpcError?) -> Void
    ) {
        find(moduleName: moduleName, itemName: itemName)
            .sink { [weak self] result in
                self?.handleFetchingStorageItem(from: result, key: key, completion: completion)
            }
            .store(in: &anyCancellable)
    }
    
    /// Fetches a storage item after getting a module first
    /// - Parameters:
    ///     - moduleName: Module's name to fetch
    ///     - itemName: Storage item's name
    ///     - keys: Keys to use for fetching a storage item
    ///     - completion: Completion with either a generic `T` or `RpcError`
    func fetch<T: Decodable>(
        moduleName: String,
        itemName: String,
        keys: [Data],
        completion: @escaping(T?, RpcError?) -> Void
    ) {
        find(moduleName: moduleName, itemName: itemName)
            .sink { [weak self] result in
                self?.handleFetchingStorageItem(from: result, keys: keys, completion: completion)
            }
            .store(in: &anyCancellable)
    }
    
    /// Fetches storage item from a specified storage
    ///  - Parameters:
    ///     - item: An item to be hashed
    ///     - storage: Storage for which a storage hasher is created, which hashes the item
    ///     - completion: Completion with either a generic `T` or `RpcError`
    func fetch<T: Decodable>(
        item: RuntimeModuleStorageItem,
        storage: RuntimeModuleStorage,
        completion: @escaping (T?, RpcError?) -> Void
    ) throws {
        try stateRpc.fetchStorageItem(item: item, storage: storage, completion: completion)
    }
    
    /// Fetches storage item from a specified storage
    ///  - Parameters:
    ///     - item: An item to be hashed
    ///     - key: A key to be used when hashing in a storage hasher
    ///     - storage: Storage for which a storage hasher is created, which hashes the item
    ///     - completion: Completion with either a generic `T` or `RpcError`
    func fetch<T: Decodable>(
        item: RuntimeModuleStorageItem,
        key: Data,
        storage: RuntimeModuleStorage,
        completion: @escaping (T?, RpcError?) -> Void
    ) throws {
        try stateRpc.fetchStorageItem(item: item, key: key, storage: storage, completion: completion)
    }
    
    /// Fetches storage item from a specified storage
    ///  - Parameters:
    ///     - item: An item to be hashed
    ///     - keys: Keys to be used when hashing in a storage hasher
    ///     - storage: Storage for which a storage hasher is created, which hashes the item
    ///     - completion: Completion with either a generic `T` or `RpcError`
    func fetch<T: Decodable>(
        item: RuntimeModuleStorageItem,
        keys: [Data],
        storage: RuntimeModuleStorage,
        completion: @escaping (T?, RpcError?) -> Void
    ) throws {
        try stateRpc.fetchStorageItem(item: item, keys: keys, storage: storage, completion: completion)
    }
    
    // MARK: - Private
    
    /// Handles fetching storage item from a `FindStorageItemResult`
    ///  - Parameters:
    ///     - findStorageItemResult: The `findStorageItemResult` object
    ///     - key: Key to use for fetching a storage item
    ///     - keys: Keys to use for fetching a storage item result
    ///     - completion: The completion with either a generic type `T` or `RpcError`
    private func handleFetchingStorageItem<T: Decodable>(
        from findStorageItemResult: FindStorageItemResult?,
        key: Data? = nil,
        keys: [Data]? = nil,
        completion: @escaping(T?, RpcError?) -> Void
    ) {
        guard let result = findStorageItemResult, let item = result.item else {
            completion(nil, .responseError(.noData))
            return
        }
        
        do {
            if let key = key {
                try stateRpc.fetchStorageItem(item: item, key: key, storage: result.storage, completion: completion)
            } else if let keys = keys {
                try stateRpc.fetchStorageItem(item: item, keys: keys, storage: result.storage, completion: completion)
            } else {
                try stateRpc.fetchStorageItem(item: item, storage: result.storage, completion: completion)
            }
        } catch {
            completion(nil, .responseError(.noData))
        }
    }
}
