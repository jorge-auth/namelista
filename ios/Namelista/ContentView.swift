import SwiftUI

struct ContentView: View {
    @State private var items: [String] = []
    @State private var newItemText: String = ""
    @State private var showWheel: Bool = false
    @State private var latestResult: String? = nil
    @State private var showResultAlert: Bool = false
    @State private var showResetConfirm: Bool = false

    private let maxItems = 10

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    TextField("Add item", text: $newItemText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button(action: addItem) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28, weight: .semibold))
                    }
                    .disabled(!canAdd)
                    .foregroundColor(canAdd ? .accentColor : .gray)

                    Button(action: { showWheel = true }) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 28, weight: .semibold))
                    }
                    .disabled(items.count < 2)
                    .foregroundColor(items.count >= 2 ? .green : .gray)
                    .accessibilityLabel("Play spinning wheel")
                }
                .padding(.horizontal)

                if items.isEmpty {
                    VStack(spacing: 8) {
                        Text("Add items to your list")
                            .foregroundColor(.secondary)
                        Text("Up to \(maxItems) items. Need at least 2 to play.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 24)
                }

                ItemsListView(items: items) { (index: Int) in
                    withAnimation {
                        if self.items.indices.contains(index) {
                            self.items.remove(at: index)
                        }
                    }
                }

                HStack {
                    Text("\(items.count)/\(maxItems) items")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .navigationTitle("Namelista")
            .navigationBarItems(trailing:
                Button {
                    showResetConfirm = true
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }
                .disabled(items.isEmpty)
                .accessibilityLabel("Reset list")
            )
        }
        .sheet(isPresented: $showWheel) {
            WheelModalView(items: items, duration: 5.0) { selected in
                latestResult = selected
                showResultAlert = true
                // Do not auto-dismiss; user closes manually from modal
            }
        }
        .confirmationDialog("Clear all items?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Clear All", role: .destructive) {
                withAnimation { items.removeAll() }
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert(isPresented: $showResultAlert) {
            Alert(
                title: Text("Selected"),
                message: Text(latestResult ?? ""),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var canAdd: Bool {
        let trimmed = newItemText.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && items.count < maxItems
    }

    private func addItem() {
        let trimmed = newItemText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, items.count < maxItems else { return }
        items.append(trimmed)
        newItemText = ""
    }

    private func deleteItems(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }
}

struct ItemsListView: View {
    let items: [String]
    let onDeleteAtIndex: (Int) -> Void

    var body: some View {
        List {
            ForEach(Array(items.enumerated()), id: \.offset) { pair in
                let index = pair.offset
                let item = pair.element
                HStack {
                    Text("\(index + 1).")
                        .foregroundColor(.secondary)
                    Text(item)
                        .lineLimit(2)
                    Spacer()
                    Button {
                        onDeleteAtIndex(index)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .accessibilityLabel("Delete item \(index + 1)")
                }
                .padding(.vertical, 4)
            }
            .onDelete { offsets in
                for o in offsets.sorted(by: >) {
                    onDeleteAtIndex(o)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct WheelModalView: View {
    let items: [String]
    let duration: Double
    let onDone: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var rotation: Double = 0
    @State private var isSpinning: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                ZStack {
                    WheelView(items: items)
                        .frame(width: 280, height: 280)
                        .rotationEffect(.degrees(rotation))

                    TrianglePointer()
                        .fill(Color.red)
                        .frame(width: 24, height: 24)
                        .offset(y: -160)
                        .shadow(radius: 2)
                }

                if !isSpinning {
                    Text("Tap Start to spin!")
                        .foregroundColor(.secondary)
                }

                Button(action: startSpin) {
                    HStack {
                        Image(systemName: isSpinning ? "hourglass" : "play.fill")
                        Text(isSpinning ? "Spinning..." : "Start")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSpinning || items.count < 2)
            }
            .padding()
            .navigationTitle("Spin")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .disabled(isSpinning)
                }
            }
        }
        .onAppear {
            // Auto-start when presented
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                if !isSpinning && items.count >= 2 {
                    startSpin()
                }
            }
        }
    }

    private func startSpin() {
        guard items.count >= 2 else { return }
        isSpinning = true

        let spins = Int.random(in: 4...7)
        let randomAngle = Double.random(in: 0..<360)
        let finalRotation = Double(spins * 360) + randomAngle

        withAnimation(.easeOut(duration: duration)) {
            rotation = finalRotation
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.05) {
            let chosenIndex = indexAtPointer(rotation: rotation, count: items.count)
            let selected = items[chosenIndex]
            isSpinning = false
            onDone(selected)
        }
    }

    private func indexAtPointer(rotation: Double, count: Int) -> Int {
        guard count > 0 else { return 0 }
        let anglePerSlice = 360.0 / Double(count)

        // Pointer is at absolute -90 degrees (top). Convert to wheel-internal angle space
        var pointerAngleInWheel = -90.0 - rotation
        // Normalize to [0, 360)
        pointerAngleInWheel = fmod(pointerAngleInWheel, 360.0)
        if pointerAngleInWheel < 0 { pointerAngleInWheel += 360.0 }

        // Our slice i spans from (-90 + i*angle) to (-90 + (i+1)*angle)
        // Compute relative offset from -90 baseline and map into slice index
        var relative = pointerAngleInWheel + 90.0
        relative = fmod(relative, 360.0)
        if relative < 0 { relative += 360.0 }

        let rawIndex = Int(floor(relative / anglePerSlice))
        return max(0, min(count - 1, rawIndex))
    }
}

struct TrianglePointer: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w/2, y: 0))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.addLine(to: CGPoint(x: w, y: h))
        path.closeSubpath()
        return path
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


