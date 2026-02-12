@preconcurrency import ApplicationServices
import Cocoa
@preconcurrency import Combine

nonisolated final class AccessibilityService {
    static var systemWideElement = AXUIElementCreateSystemWide()
}

// MARK: - Static implementations (Permission)
nonisolated
    extension AccessibilityService
{

    static func checkAccessibilityPermission() throws {
        try self.requestPermissionHelper(displayPrompt: false)
    }

    static func requestAccessibilityPermission() {
        // not throwing here because this is intended to be called to prompt for permission instead of showing error
        try? self.requestPermissionHelper(displayPrompt: true)
    }

    private static func requestPermissionHelper(displayPrompt: Bool) throws {
        let options: NSDictionary = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String:
                displayPrompt
        ]

        let accessEnabled = AXIsProcessTrustedWithOptions(options)

        if !accessEnabled {
            throw AccessibilityError.accessibilityPermissionNotGranted
        }
    }
}

nonisolated extension AccessibilityService {
    static func getAttributesAvailable(on element: AXUIElement) throws
        -> [String]
    {
        var names: CFArray?

        let error = AXUIElementCopyAttributeNames(
            element,
            &names
        )

        try checkAXError(error)

        guard let names = names as? [String] else {
            throw AccessibilityError.generalFailure
        }
        return names
    }

    static func getParameterizedAttributesAvailable(on element: AXUIElement)
        throws -> [String]
    {
        var names: CFArray?

        let error = AXUIElementCopyParameterizedAttributeNames(
            element,
            &names
        )

        try checkAXError(error)

        guard let names = names as? [String] else {
            throw AccessibilityError.generalFailure
        }
        return names
    }

}

// on system wide element
nonisolated extension AccessibilityService {
    static func findFocusedUIElement() throws -> AXUIElement {
        let focusedAXElement = try self.getElementValueForAttribute(
            on: systemWideElement,
            attribute: kAXFocusedUIElementAttribute
        )
        return focusedAXElement
    }

    static func findFocusedApplication() throws -> AXUIElement {
        let focusedAXElement = try self.getElementValueForAttribute(
            on: systemWideElement,
            attribute: kAXFocusedApplicationAttribute
        )
        return focusedAXElement
    }
}

// MARK: - Static implementations (Get/Set AXUI)
nonisolated
    extension AccessibilityService
{
    static func getPidForElement(_ element: AXUIElement) throws -> Int32 {
        var value: pid_t = 0
        let error = withUnsafeMutablePointer(
            to: &value,
            { pointer in
                let error = AXUIElementGetPid(element, pointer)
                return error
            }
        )
        try checkAXError(error)

        return value
    }

    static func getTypeRefForAttribute(
        on element: AXUIElement,
        attribute: String
    ) throws -> CFTypeRef {
        var value: CFTypeRef?

        let error = AXUIElementCopyAttributeValue(
            element,
            attribute as CFString,
            &value
        )

        try checkAXError(error)

        guard let value else {
            throw AccessibilityError.generalFailure
        }

        return value
    }

    static func getElementValueForAttribute(
        on element: AXUIElement,
        attribute: String
    ) throws -> AXUIElement {

        guard
            let value = try self.getTypeRefForAttribute(
                on: element,
                attribute: attribute
            ) as! AXUIElement?
        else {
            throw AccessibilityError.generalFailure
        }

        return value
    }

    static func getStringValueForAttribute(
        on element: AXUIElement,
        attribute: String
    ) throws -> String {

        guard
            let valueString = try self.getTypeRefForAttribute(
                on: element,
                attribute: attribute
            ) as? String
        else {
            throw AccessibilityError.generalFailure
        }

        return valueString
    }

    static func getElementRole(_ element: AXUIElement) throws -> String {
        return try self.getStringValueForAttribute(
            on: element,
            attribute: kAXRoleAttribute
        )
    }

    static func checkAXError(_ error: AXError) throws {
        if let error = AccessibilityError(error) {
            throw error
        }
    }

}

enum CFTypeRefValue {
    case string(String)
    case url(URL)
    case bool(Bool)
    case int(Int)
    case element(AXUIElement)
    case elements([AXUIElement])

    // parameterized
    case cgPoint(CGPoint)
    case cgSize(CGSize)
    case cgRect(CGRect)
    case cfRange(CFRange)

    init(typeRef: CFTypeRef) throws {
        let valueType = AXValueGetType(typeRef as! AXValue)
        switch valueType {

        case .cgPoint:
            var result = CGPoint.zero
            if !AXValueGetValue(typeRef as! AXValue, .cgPoint, &result) {
                throw AccessibilityError.generalFailure
            }
            self = .cgPoint(result)
            return
        case .cgSize:
            var result = CGSize.zero
            if !AXValueGetValue(typeRef as! AXValue, .cgSize, &result) {
                throw AccessibilityError.generalFailure
            }
            self = .cgSize(result)
            return
        case .cgRect:
            var result = CGRect.zero
            if !AXValueGetValue(typeRef as! AXValue, .cgRect, &result) {
                throw AccessibilityError.generalFailure
            }
            self = .cgRect(result)
            return
        case .cfRange:
            var result = CFRange.init(location: 0, length: 0)
            if !AXValueGetValue(typeRef as! AXValue, .cfRange, &result) {
                throw AccessibilityError.generalFailure
            }
            self = .cfRange(result)
            return
        case .axError:
            throw AccessibilityError.generalFailure
        case .illegal:
            break
        @unknown default:
            break
        }

        if let value = typeRef as? URL {
            self = .url(value)
            return
        }

        if let value = typeRef as? String {
            self = .string(value)
            return
        }

        if let value = typeRef as? Bool {
            self = .bool(value)
            return
        }

        if let value = typeRef as? Int {
            self = .int(value)
            return
        }

        if let value = typeRef as? [AXUIElement] {
            self = .elements(value)
            return
        }
        self = .element(typeRef as! AXUIElement)
    }
}


enum AccessibilityError: String, Error, LocalizedError {
    case accessibilityPermissionNotGranted

    // MARK: - AXError mapped
    // AXError.failure
    case generalFailure
    case illegalArgument
    case invalidUIElement
    case invalidUIElementObserver
    case cannotComplete
    case attributeUnsupported
    case actionUnsupported
    case notificationUnsupported
    case notImplemented
    case notificationAlreadyRegistered
    case notificationNotRegistered
    case apiDisabled
    case noValue
    case parameterizedAttributeUnsupported
    case notEnoughPrecision
  
    init?(_ axError: AXError) {
        switch axError {
        case .success:
            return nil
        case .failure:
            self = .generalFailure
        case .illegalArgument:
            self = .illegalArgument
        case .invalidUIElement:
            self = .invalidUIElement
        case .invalidUIElementObserver:
            self = .invalidUIElementObserver
        case .cannotComplete:
            self = .cannotComplete
        case .attributeUnsupported:
            self = .attributeUnsupported
        case .actionUnsupported:
            self = .actionUnsupported
        case .notificationUnsupported:
            self = .notificationUnsupported
        case .notImplemented:
            self = .notImplemented
        case .notificationAlreadyRegistered:
            self = .notificationAlreadyRegistered
        case .notificationNotRegistered:
            self = .notificationNotRegistered
        case .apiDisabled:
            self = .apiDisabled
        case .noValue:
            self = .noValue
        case .parameterizedAttributeUnsupported:
            self = .parameterizedAttributeUnsupported
        case .notEnoughPrecision:
            self = .notEnoughPrecision
        @unknown default:
            self = .generalFailure
        }
    }

}

