
struct ContentView: View {

    @State private var manager = LoopingManager()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text(
                    "Right Mouse up to start viewing accessibility Contents."
                )
                .font(.headline)

                Toggle(
                    isOn: $manager.loopUp,
                    label: {
                        Text("Loop Up?")
                    }
                )

                Divider()

                VStack(spacing: 12) {
                    if manager.processing {
                        ProgressView()
                    } else {
                        if manager.contentFinal.isEmpty {
                            Text("(no content available)")
                        } else {
                            Button(
                                action: {
                                    let board = NSPasteboard.general
                                    board.clearContents()
                                    board.setString(
                                        manager.contentFinal,
                                        forType: .string
                                    )
                                },
                                label: {
                                    Text("Copy To Clipboard")
                                }
                            )
                        }

                    }
                }
            }
            .padding()
            .frame(maxHeight: .infinity, alignment: .top)
            .onAppear {
                AccessibilityService.requestAccessibilityPermission()
                NSEvent.addGlobalMonitorForEvents(
                    matching: .rightMouseUp,
                    handler: { _ in
                        manager.getContent()
                    }
                )
            }

        }
    }

}
