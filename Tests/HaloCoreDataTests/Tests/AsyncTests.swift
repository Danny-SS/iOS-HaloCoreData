//
//  AsyncTests.swift
//  HaloCoreData
//
//  Created by Danny Murphy on 5/18/21.
//

import XCTest
import Combine
@testable import HaloCoreData


struct Demo {

    func trim(array: [Int] = []) -> Future<[Int], Error>  {

        // note that this simple function has a 2 second delay trim our int array to values less than 5
        return Future() { promise in
            DispatchQueue.main.asyncAfter(deadline:.now() + 2) {
                promise(Result.success(array.filter{$0 < 5}))
            }
        }
    }

}


final class AysncTests: XCTestCase {

    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = []
    }


    func testTrim() {
        var error: Error?

        let startArray = [1,2,3,4,5,6,7,8,9]
        var endArray: [Int]?

        let demo = Demo()

        let expected = self.expectation(description: "Trim Expectation")

        // calling out combine function
        demo.trim(array: startArray)
            .sink { completion in
                switch completion {
                    case .finished:
                        break
                    case .failure(let errorFound):
                        error = errorFound
                }
                expected.fulfill()
            } receiveValue: { intValues in
                endArray = intValues
            }
            .store(in: &cancellables)



        // Awaiting fulfilment of our expecation before performing our asserts
        // (fullfilment is done in the sink block)

        waitForExpectations(timeout: 10)

        // Asserting that our Combine pipeline yielded the the correct output (our actual tests)

        XCTAssertNil(error)
        XCTAssertEqual(endArray, [1,2,3,4])

    }

    func testDemoTrimSimplified() throws {

        let startArray = [1,2,3,4,5,6,7,8,9]
        let expectedArray = [1,2,3,4]

        // using our fancy awaitFor extension on XCTest
        let result = try awaitFor(Demo().trim(array: startArray), timeout: 2)

        XCTAssertEqual(expectedArray, result)
    }

}


extension XCTestCase {
    func awaitFor<T: Publisher>(
        _ publisher: T,
        timeout: TimeInterval = 10,
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> T.Output {
        // This time, we use Swift's Result type to keep track
        // of the result of our Combine pipeline:
        var result: Result<T.Output, Error>?
        let expected = self.expectation(description: "Awaiting publisher")

        let cancellable = publisher.sink(
            receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    result = .failure(error)
                case .finished:
                    break
                }
                expected.fulfill()
            },
            receiveValue: { value in
                result = .success(value)
            }
        )

        // Await the expectation that we
        // created at the top of our test, and once done, we
        // also cancel our cancellable to avoid getting any
        // unused variable warnings:
        waitForExpectations(timeout: timeout)
        cancellable.cancel()

        // Here we pass the original file and line number that
        // our utility was called at, to tell XCTest to report
        // any encountered errors at that original call site:
        let unwrappedResult = try XCTUnwrap(
            result,
            "Awaited publisher did not produce any output",
            file: file,
            line: line
        )

        return try unwrappedResult.get()
    }
}
