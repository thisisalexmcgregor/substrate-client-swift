import XCTest
@testable import SubstrateClientSwift
import BigInt
import ScaleCodecSwift

private struct RpcConstant<T: Equatable> {
    let module: String
    let constant: String
    let expectedValue: T
}

class TestFetchingConstants: XCTestCase {
    private let network: Endpoint = .kusama
    private lazy var client: SubstrateClient? = {
        guard let url = URL(string: network.endpointInfo.url) else { return nil }
        return SubstrateClient(url: url)
    }()
    
    private let constants: [Any] = [
        RpcConstant<UInt64>(module: "babe", constant: "EpochDuration", expectedValue: 600),
        RpcConstant<UInt64>(module: "babe", constant: "ExpectedBlockTime", expectedValue: 6000),
        RpcConstant<UInt64>(module: "balances", constant: "ExistentialDeposit", expectedValue: 333333333), // With -1 digit it fails
        RpcConstant<UInt64>(module: "crowdloan", constant: "MinContribution", expectedValue: 999999999000), // With -1 digit (9) it fails
        RpcConstant<UInt32>(module: "staking", constant: "BondingDuration", expectedValue: 28),
        RpcConstant<UInt32>(module: "staking", constant: "MaxNominations", expectedValue: 24),
        RpcConstant<UInt32>(module: "staking", constant: "SessionsPerEra", expectedValue: 6),
        RpcConstant<UInt32>(module: "system", constant: "BlockHashCount", expectedValue: 4096),
        RpcConstant<UInt16>(module: "system", constant: "SS58Prefix", expectedValue: 2),
        RpcConstant<UInt64>(module: "timestamp", constant: "MinimumPeriod", expectedValue: 3000)
    ]
    
    func testService() {
        guard let client = client else {
            XCTFail()
            return
        }

        for constant in constants {
            if let rpcConstant = rpcConstant(from: constant, with: UInt16.self) {
                testStorageItem(client: client, constant: rpcConstant)
            } else if let rpcConstant = rpcConstant(from: constant, with: UInt32.self) {
                testStorageItem(client: client, constant: rpcConstant)
            } else if let rpcConstant = rpcConstant(from: constant, with: UInt64.self) {
                testStorageItem(client: client, constant: rpcConstant)
            } else {
                XCTFail()
            }
        }
    }
    
    private func testStorageItem<T: Codable>(client: SubstrateClient, constant: RpcConstant<T>) {
        let storageItemFetchingExpectation = XCTestExpectation()
        let storageItemFindingExpectation = XCTestExpectation()
        
        client.constantsService { [weak self] constantService, rpcError in
            guard let `self` = self, let constantService = constantService else {
                XCTFail()
                return
            }
            
            self.testStorageItemFetching(
                constantService: constantService,
                stateRpc: client.module.stateRpc(),
                constant: constant,
                expectation: storageItemFetchingExpectation)
            
            self.testStorageItemFinding(
                constantService: constantService,
                codec: client.codec,
                constant: constant,
                expectation: storageItemFindingExpectation
            )
        }
        
        let expectations = [storageItemFetchingExpectation, storageItemFindingExpectation]
        wait(for: expectations, timeout: Constants.expectationLongTimeout)
    }
    
    private func rpcConstant<T: Equatable>(from constant: Any, with expectedType: T.Type) -> RpcConstant<T>? {
        constant as? RpcConstant<T>
    }
    
    private func testStorageItemFetching<T: Codable>(
        constantService: SubstrateConstantsService,
        stateRpc: StateRpc,
        constant: RpcConstant<T>,
        expectation: XCTestExpectation
    ) {
        constantService.fetch(
            moduleName: constant.module,
            constantName: constant.constant
        ) { (response: T?, error: SubstrateConstantsService.ConstantServiceError?) in
            XCTAssertEqual(response, constant.expectedValue)
            expectation.fulfill()
        }
    }
    
    private func testStorageItemFinding<T: Codable>(
        constantService: SubstrateConstantsService,
        codec: ScaleCoder,
        constant: RpcConstant<T>,
        expectation: XCTestExpectation
    ) {
        let runtimeModuleConstant = constantService.find(
            moduleName: constant.module,
            constantName: constant.constant
        )
        
        XCTAssertNotNil(runtimeModuleConstant)
        
        fetchExpectedValueForModuleConstant(
            runtimeModuleConstant: runtimeModuleConstant,
            for: constant,
            using: constantService,
            expectation: expectation
        )
    }
    
    private func fetchExpectedValueForModuleConstant<T: Codable>(
        runtimeModuleConstant: RuntimeModuleConstant?,
        for constant: RpcConstant<T>,
        using service: SubstrateConstantsService,
        expectation: XCTestExpectation
    ) {
        guard let moduleConstant = runtimeModuleConstant else {
            XCTFail()
            return
        }
        
        do {
            let fetchedValue = try service.fetch(T.self, constant: moduleConstant)
            XCTAssertEqual(constant.expectedValue, fetchedValue)
            expectation.fulfill()
        } catch {
            XCTFail()
        }
    }
}
