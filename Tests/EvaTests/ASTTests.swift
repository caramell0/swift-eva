import XCTest
@testable import Eva

final class ASTTests: XCTestCase {
    
    // MARK: Self evaluating expressions
    
    func testNumber() throws {
        let eva = Eva()
        
        // given
        let input = 1
        
        // do
        let result = eva.eval(expression: input)
        
        // assert
        XCTAssertEqual(result as? Int, .some(1))
    }
    
    func testString() throws {
        let eva = Eva()
        
        // given
        let input = "\"hello\""
        
        // do
        let result = eva.eval(expression: input)
        
        // assert
        XCTAssertEqual(result as? String, .some("hello"))
    }
    
    // MARK: Math operations
    
    func testAddition() throws {
        let eva = Eva()
        
        // given
        let input: [Any] = ["+", 1, 5]
        
        // do
        let result = eva.eval(expression: input)
        
        // assert
        XCTAssertEqual(result as? Int, .some(6))
    }
    
    func testComplexAddition() throws {
        let eva = Eva()
        
        // given
        let input: [Any] = ["+", ["+", 3, 2] as [Any], 5]
        
        // do
        let result = eva.eval(expression: input)
        
        // assert
        XCTAssertEqual(result as? Int, .some(10))
    }
    
    func testMultiplication() throws {
        let eva = Eva()
        
        // given
        let input: [Any] = ["+", ["*", 3, 2] as [Any], 5]
        
        // do
        let result = eva.eval(expression: input)
        
        // assert
        XCTAssertEqual(result as? Int, .some(11))
    }
    
    func testSubtraction() throws {
        let eva = Eva()
        
        // given
        let input: [Any] = ["-", ["+", 3, 2] as [Any], 5]
        
        // do
        let result = eva.eval(expression: input)
        
        // assert
        XCTAssertEqual(result as? Int, .some(0))
    }
    
    func testDivision() throws {
        let eva = Eva()
        
        // given
        let input: [Any] = ["/", ["+", 3, 2] as [Any], 5]
        
        // do
        let result = eva.eval(expression: input)
        
        // assert
        XCTAssertEqual(result as? Int, .some(1))
    }
    
    // MARK: Variables
    
    func testVariable() throws {
        let environment = Eva.Environment.global
        let eva = Eva(globalEnvironment: environment)
        
        // given
        let input: [Any] = ["var", "x", 10]
        
        // do
        let result = eva.eval(expression: input)
        
        // assert
        XCTAssertEqual(result as? Int, .some(10))
        XCTAssertEqual(environment.lookup(name: "x") as? Int, .some(10))
    }
    
    func testVariableLookup() throws {
        let environment = Eva.Environment.global
        let eva = Eva(globalEnvironment: environment)
        
        // given
        let input: [Any] = ["var", "isUser", "true"]
        
        // do
        let result = eva.eval(expression: input)
        
        // assert
        XCTAssertEqual(result as? Bool, .some(true))
        XCTAssertEqual(environment.lookup(name: "isUser") as? Bool, .some(true))
    }
    
    func testBlocks() throws {
        let environment = Eva.Environment.global
        let eva = Eva(globalEnvironment: environment)
        
        // given
        let input: [Any] = [
            "begin",
            ["var", "x", 10] as [Any],
            ["var", "y", 20] as [Any],
            ["+", ["*", "x", "y"], 30] as [Any]
        ]
        
        // do
        let result = eva.eval(expression: input)
        
        // assert
        XCTAssertEqual(result as? Int, .some(230))
    }
    
    func testNestedBlocksRedeclaresVariable() throws {
        let environment = Eva.Environment.global
        let eva = Eva(globalEnvironment: environment)
        
        // given
        let input: [Any] = [
            "begin",
            ["var", "x", 10] as [Any],
            [
                "begin",
                ["var", "x", 20] as [Any],
                "x"
            ] as [Any],
            "x"
        ]
        
        // do
        let result = eva.eval(expression: input)
        
        // assert
        XCTAssertEqual(result as? Int, .some(10))
    }
    
    func testNestedBlocksOuterScopeAccess() throws {
        let environment = Eva.Environment.global
        let eva = Eva(globalEnvironment: environment)
        
        // given
        let input: [Any] = [
            "begin",
            ["var", "value", 10] as [Any],
            ["var", "result",
             [
                "begin",
                ["var", "x", ["+", "value", 10] as [Any]] as [Any],
                "x"
             ] as [Any]
            ] as [Any],
            "result"
        ]
        
        // do
        let result = eva.eval(expression: input)
        
        // assert
        XCTAssertEqual(result as? Int, .some(20))
    }
    
    func testNestedBlocksOuterScopeAssignment() throws {
        let environment = Eva.Environment.global
        let eva = Eva(globalEnvironment: environment)
        
        // given
        let input: [Any] = [
            "begin",
            ["var", "data", 10] as [Any],
            ["var", "result",
             [
                "begin",
                ["set", "data", 100] as [Any],
             ] as [Any]
            ] as [Any],
            "data"
        ]
        
        // do
        let result = eva.eval(expression: input)
        
        // assert
        XCTAssertEqual(result as? Int, .some(100))
    }
    
    func testIf() throws {
        let environment = Eva.Environment.global
        let eva = Eva(globalEnvironment: environment)
        
        // given
        let input: [Any] = [
            "begin",
            ["var", "x", 10] as [Any],
            ["var", "y", 20] as [Any],
            [
                "if",
                [">", "x", 10] as [Any],
                ["set", "y", 20] as [Any],
                ["set", "y", 30] as [Any]
            ] as [Any],
            "y"
        ]
        
        // do
        let result = eva.eval(expression: input)
        
        // assert
        XCTAssertEqual(result as? Int, .some(30))
    }
    
    func testWhile() throws {
        let environment = Eva.Environment.global
        let eva = Eva(globalEnvironment: environment)
        
        // given
        let input: [Any] = [
            "begin",
            ["var", "counter", 0] as [Any],
            ["var", "result", 0] as [Any],
            [
                "while",
                ["<", "counter", 10] as [Any],
                [
                    "begin",
                    [
                        "set",
                        "result",
                        ["+", "result", 1] as [Any]
                    ] as [Any],
                    [
                        "set",
                        "counter",
                        ["+", "counter", 1] as [Any]
                    ] as [Any]
                ] as [Any],
            ] as [Any],
            "result"
        ]
        
        // do
        let result = eva.eval(expression: input)
        
        // assert
        XCTAssertEqual(result as? Int, .some(10))
    }
}
