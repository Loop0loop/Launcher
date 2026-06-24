import AppKit
import SwiftUI

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.6)
            VStack(alignment: .leading, spacing: 14) { content }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .settingsGlassCard()
        }
    }
}

struct SettingsRow<Trailing: View>: View {
    let title: String
    @ViewBuilder let trailing: Trailing

    var body: some View {
        HStack {
            Text(title).font(.subheadline)
            Spacer(minLength: 12)
            trailing
        }
    }
}

struct SettingsToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        SettingsRow(title: title) {
            Toggle("", isOn: $isOn).labelsHidden().toggleStyle(.switch)
        }
    }
}

struct SettingsSliderRow: View {
    let title: String
    let help: String
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...1
    let display: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.subheadline.weight(.medium))
                Spacer()
                Text(display).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range)
            Text(help).font(.caption).foregroundStyle(.secondary)
        }
    }
}

struct SettingsActionRow: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .buttonStyle(.plain)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Color.accentColor)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AppIconPicker: View {
    @Binding var selection: AppIconOption

    var body: some View {
        HStack(spacing: 10) {
            ForEach(AppIconOption.allCases) { option in
                Button {
                    selection = option
                } label: {
                    Image(nsImage: option.image() ?? NSImage())
                        .resizable()
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(Color.accentColor, lineWidth: selection == option ? 2.5 : 0)
                        }
                }
                .buttonStyle(.plain)
                .help(option.title)
            }
        }
    }
}

struct SettingsStatusRow: View {
    let title: String
    let status: String
    let positive: Bool

    var body: some View {
        SettingsRow(title: title) {
            Text(status)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Capsule().fill((positive ? Color.green : Color.orange).opacity(0.18)))
                .foregroundStyle(positive ? .green : .orange)
        }
    }
}
