import SwiftUI

struct SettingsView: View {
    @ObservedObject var state: AppState

    var body: some View {
        Form {
            Toggle("Launch at Login", isOn: Binding(
                get: { state.launchAtLogin },
                set: { state.setLaunchAtLogin($0) }
            ))

            Button("Refresh Apps") {
                state.refreshApps()
            }

            HStack {
                Text("Accessibility")
                Spacer()
                Text(state.accessibilityState.label)
                    .foregroundStyle(state.accessibilityState == .allowed ? .green : .orange)
            }

            HStack {
                Text("Trackpad")
                Spacer()
                Text(state.trackpadGateState.label)
                    .foregroundStyle(state.trackpadGateState == .exactFourFinger ? .green : .orange)
            }

            Button("Request Accessibility Permission") {
                state.requestAccessibilityPermission()
            }

            if let error = state.loginItemError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(24)
        .frame(width: 360)
    }
}
