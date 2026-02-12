
@Observable
class LoopingManager {
    var processing: Bool = false
    var loopUp: Bool = true
    var contentFinal = ""
    private var content: String = ""

    private var seenElements: [AXUIElement] = []

    private let targetAttributes: [String] = [
        kAXMainWindowAttribute,
        kAXFocusedAttribute,
        kAXMainAttribute, kAXFrontmostAttribute,
        kAXDocumentAttribute,
        kAXLabelValueAttribute,
        kAXTitleAttribute, kAXURLAttribute, kAXFocusedWindowAttribute,
        kAXRoleAttribute, kAXSelectedTextAttribute,
        kAXSelectedTextRangeAttribute, kAXTextAttribute, kAXValueAttribute,
        kAXDescriptionAttribute,
        kAXVisibleChildrenAttribute,
        kAXChildrenAttribute,
        kAXSelectedChildrenAttribute,
        "AXPreferredLanguage",
        kAXFocusedUIElementAttribute, kAXFocusedApplicationAttribute,
    ]

    func getContent() {
        seenElements = []
        contentFinal = ""
        content = ""
        self.processing = true

        print("----------Start----------")
        content += "----------Start----------\n"
        do {
            if loopUp {
                let focusedUI =
                    try AccessibilityService.findFocusedUIElement()
                seenElements.append(focusedUI)
                loopUp(on: focusedUI)
            } else {
                let focusedApplication =
                    try AccessibilityService.findFocusedApplication()

                seenElements.append(focusedApplication)
                loopDown(on: focusedApplication)
            }
        } catch (let error) {
            print(error)
        }

        print("----------Finish----------")
        content += "----------Finish----------\n"
        contentFinal = content
        self.processing = false
    }

    private func loopUp(
        on element: AXUIElement,
    ) {
        let attributesAvailable =
            (try? AccessibilityService.getAttributesAvailable(
                on: element
            )) ?? []

        let attributes = attributesAvailable.filter({
            targetAttributes.contains($0)
        })
        if let role = try? AccessibilityService.getElementRole(element),
            role.lowercased().contains("button")
        {
            return
        }

        content += "----------------------\n"
        content += "Getting attributes: \(attributes) for element \(element)\n"
        print("----------------------")
        print("Getting attributes: \(attributes) for element \(element)")

        for attribute in attributes {
            do {
                let typeRef = try AccessibilityService.getTypeRefForAttribute(
                    on: element,
                    attribute: attribute
                )
                self.seenElements.append(element)

                let converted = try CFTypeRefValue(typeRef: typeRef)
                content += "Attribute: \(attribute) -> Value: \(converted)\n"

                print("Attribute: \(attribute) -> Value: \(converted)")

                if case .element(let aXUIElement) = converted {

                    if seenElements.contains(where: { CFEqual(aXUIElement, $0) }
                    ) {
                        continue
                    }
                    loopDown(on: aXUIElement)
                }

                if case .elements(let array) = converted {
                    for element in array {
                        if seenElements.contains(where: { CFEqual(element, $0) }
                        ) {
                            continue
                        }
                        loopDown(on: element)
                    }

                }
            } catch (let error) {
                print("error on attribute \(attribute): \(error)")
            }
        }

        content += "----------------------\n"
        print("----------------------")

        if let parent = try? AccessibilityService.getElementValueForAttribute(
            on: element,
            attribute: kAXParentAttribute
        ) {
            self.loopUp(on: parent)
        }
    }

    private func loopDown(
        on element: AXUIElement,
    ) {
        let attributesAvailable =
            (try? AccessibilityService.getAttributesAvailable(
                on: element
            )) ?? []

        let attributes = attributesAvailable.filter({
            targetAttributes.contains($0)
        })
        if let role = try? AccessibilityService.getElementRole(element),
            role.lowercased().contains("button")
        {
            return
        }
        content += "----------------------\n"
        content += "Getting attributes: \(attributes) for element \(element)\n"
        print("----------------------")
        print("Getting attributes: \(attributes) for element \(element)")

        for attribute in attributes {
            do {
                let typeRef = try AccessibilityService.getTypeRefForAttribute(
                    on: element,
                    attribute: attribute
                )
                self.seenElements.append(element)

                let converted = try CFTypeRefValue(typeRef: typeRef)
                content += "Attribute: \(attribute) -> Value: \(converted)\n"

                print("Attribute: \(attribute) -> Value: \(converted)")
                if case .element(let aXUIElement) = converted {

                    if seenElements.contains(where: { CFEqual(aXUIElement, $0) }
                    ) {
                        continue
                    }
                    loopDown(on: aXUIElement)
                }
                if case .elements(let array) = converted {
                    for element in array {
                        if seenElements.contains(where: { CFEqual(element, $0) }
                        ) {
                            continue
                        }

                        loopDown(on: element)
                    }

                }
            } catch (let error) {
                print("error on attribute \(attribute): \(error)")
            }

        }

        content += "----------------------\n"
        print("----------------------")
    }
}
