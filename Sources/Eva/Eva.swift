import Foundation

// TODO: Abstract all Any's into some kind of enum for all possible types

public final class Eva {
    
    public class Environment {
        private let parent: Environment?
        private var storage: [String: Any?]
        
        public static var global: Environment {
            var storage = [String:Any]()
            
            storage["null"] = nil
            
            storage["true"] = true
            storage["false"] = false
            
            storage["VERSION"] = "0.1"
            
            
            return Environment(storage: storage)
        }
        
        public init(storage: [String : Any] = [String:Any](), parent: Environment? = nil) {
            self.storage = storage
            self.parent = parent
        }
        
        func define(name: String, value: Any?) {
            storage[name] = value
        }
        
        func assign(name: String, value: Any?) {
            let isInCurrentScope = storage.contains(where: { $0.key == name })
            
            guard isInCurrentScope else {
                parent?.assign(name: name, value: value)
                return
            }
            
            storage[name] = value
        }
        
        func lookup(name: String) -> Any? {
            var value: Any?
            
            if let localValue = storage[name] {
                value = localValue
            } else if let parentValue = parent?.lookup(name: name) {
                value = parentValue
            } else {
                fatalError("variable \"\(name)\" is not defined")
            }
            
            return value
        }
        
        func createChild() -> Environment {
            Environment(parent: self)
        }
    }
    
    private let globalEnvironment: Environment
    
    public init(globalEnvironment: Environment = .global) {
        self.globalEnvironment = globalEnvironment
    }
    
    public func eval(expression: Any) -> Any? {
        eval(expression: expression, environment: globalEnvironment)
    }
    
    public func eval(expression: Any, environment: Environment) -> Any? {
        // Self evaluating expressions
        if expression is Int {
            return expression
        }
        
        if isString(value: expression), let string = expression as? String {
            return String(string.dropFirst().dropLast())
        }
        
        // Math operations
        if isMathOperation("+", value: expression),
           let array = expression as? [Any] {
            
            let left: Int = resolve(value: array[1], environment: environment)
            let right: Int = resolve(value: array[2], environment: environment)
            
            return left + right
        }
        
        if isMathOperation("*", value: expression),
           let array = expression as? [Any] {
            
            let left: Int = resolve(value: array[1], environment: environment)
            let right: Int = resolve(value: array[2], environment: environment)
            
            return left * right
        }
        
        if isMathOperation("-", value: expression),
           let array = expression as? [Any] {
            
            let left: Int = resolve(value: array[1], environment: environment)
            let right: Int = resolve(value: array[2], environment: environment)
            
            return left - right
        }
        
        if isMathOperation("/", value: expression),
           let array = expression as? [Any] {
            
            let left: Int = resolve(value: array[1], environment: environment)
            let right: Int = resolve(value: array[2], environment: environment)
            
            return left / right
        }
        
        // Keywords
        
        if let array = expression as? [Any],
           let tag = array[0] as? String,
           tag == "begin" {
            let blockEnvironment = environment.createChild()
            return eval(block: array, environment: blockEnvironment)
        }
        
        if let array = expression as? [Any],
           let tag = array[0] as? String,
           tag == "set",
           let name = array[1] as? String {
            let value = eval(expression: array[2], environment: environment)
            environment.assign(name: name, value: value)
            return value
        }
        
        // Control flow
        
        if let array = expression as? [Any],
           let tag = array[0] as? String,
           tag == "if" {
            let result = eval(expression: array[1], environment: environment)
            
            if let result = result as? Bool, result {
                return eval(expression: array[2], environment: environment)
            } else {
                return eval(expression: array[3], environment: environment)
            }
        }
        
        if let array = expression as? [Any],
           let tag = array[0] as? String,
           tag == "while" {
            let performEvaluation: () -> Bool = { [unowned self] in
                guard let result = self.eval(expression: array[1], environment: environment) as? Bool else {
                    return false
                }
                
                return result
            }
            
            var result: Any?
            
            while performEvaluation() {
                result = eval(expression: array[2], environment: environment)
            }
            
            return result
        }
        
        // Comparison
        
        if let array = expression as? [Any],
           let comparison = array[0] as? String,
           comparison == ">",
           let lhs = eval(expression: array[1], environment: environment) as? Int,
           let rhs = eval(expression: array[2], environment: environment) as? Int {
            return lhs > rhs
        }
        
        if let array = expression as? [Any],
           let comparison = array[0] as? String,
           comparison == "<",
           let lhs = eval(expression: array[1], environment: environment) as? Int,
           let rhs = eval(expression: array[2], environment: environment) as? Int {
            return lhs < rhs
        }
        
        if let array = expression as? [Any],
           let comparison = array[0] as? String,
           comparison == "==",
           let lhs = eval(expression: array[1], environment: environment) as? Int,
           let rhs = eval(expression: array[2], environment: environment) as? Int{
            return lhs == rhs
        }
        
        // Variables
        
        if isVariable(value: expression),
           let array = expression as? [Any],
           let name = array[1] as? String {
            let value = array[2]
            
            let evaluatedValue = eval(expression: value, environment: environment)
            environment.define(name: name, value: evaluatedValue)
            
            return evaluatedValue
        }
        
        if isVariableName(value: expression), let variableName = expression as? String {
            return environment.lookup(name: variableName)
        }
        
        fatalError("unimplemented")
    }
    
    private func eval(block array: [Any], environment: Environment) -> Any? {
        guard array.count > 1 else {
            fatalError("unable to evaluate block")
        }
        
        let expressions = array.dropFirst()
        
        var result: Any?
        
        for expression in expressions {
            result = eval(expression: expression, environment: environment)
        }
        
        return result
    }
    
    // MARK: Helpers
    
    private func isString(value: Any) -> Bool {
        guard let string = value as? String else {
            return false
        }
        
        let doubleQuotes: Character = "\""
        return string.first == doubleQuotes && string.last == doubleQuotes
    }
    
    private func isMathOperation(_ operand: String, value: Any) -> Bool {
        guard
            let array = value as? [Any],
            array.count == 3,
            let firstItem = array[0] as? String,
            firstItem == operand
        else {
            return false
        }
        
        return true
    }
    
    private func isVariable(value: Any) -> Bool {
        // TODO: Ensure only letters followed by numbers can be used as variable names
        guard
            let array = value as? [Any],
            let firstItem = array[0] as? String
        else {
            return false
        }
        
        return firstItem == "var"
    }
    
    private func isVariableName(value: Any) -> Bool {
        // TODO: Ensure only letters followed by numbers can be used as variable names
        guard
            let string = value as? String,
            let matches = try? string.matches(of: Regex("^[a-zA-Z][a-zA-Z0-9_]*$"))
        else {
            return false
        }
        
        return !matches.isEmpty
    }
    
    private func resolve<T>(value: Any, environment: Environment) -> T {
        if let value = value as? T {
            return value
        } else if let value = eval(expression: value, environment: environment) as? T {
            return value
        } else {
            fatalError("unable to resolve value")
        }
    }
    
}
