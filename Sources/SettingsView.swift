import SwiftUI
import CoreMotion

struct SettingsView: View {
    let controller: AppController
    @ObservedObject var settings = Settings.shared
    @ObservedObject var state = AppState.shared
    @ObservedObject var t = Telemetry.shared

    var body: some View {
        Form {
            Section("상태") {
                row("에어팟 헤드 트래킹", ok: t.connected && t.receiving,
                    detail: t.receiving ? String(format: "수신 중 %.0fHz", t.updateHz) : "귀에 착용하면 연결돼요")
                row("동작 및 피트니스 권한", ok: CMHeadphoneMotionManager.authorizationStatus() == .authorized,
                    detail: authText(CMHeadphoneMotionManager.authorizationStatus()))
                HStack {
                    row("손쉬운 사용 권한 (마우스 제어)", ok: state.accessibilityOK, detail: state.accessibilityOK ? "허용됨" : "필요")
                    if !state.accessibilityOK {
                        Button("열기") {
                            controller.checkAccessibility(prompt: true)
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                        }
                    }
                }
                HStack {
                    Toggle("마우스 모드", isOn: Binding(get: { state.mouseEnabled }, set: { controller.setMouse($0) }))
                    Spacer()
                    Button("기준 자세 재설정") { controller.recenter() }
                }
            }

            Section("실시간 센서 (보정용)") {
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 4) {
                    GridRow { Text("좌우 회전 yaw"); mono(t.yaw, "°"); Text("속도"); mono(t.yawRate, "°/s") }
                    GridRow { Text("위아래 pitch"); mono(t.pitch, "°"); Text("속도"); mono(t.pitchRate, "°/s") }
                    GridRow { Text("갸웃 roll"); mono(t.roll, "°"); Text("기준 대비"); mono(t.rollDev, "°") }
                    GridRow {
                        Text("중력 벡터")
                        Text(String(format: "%.2f, %.2f, %.2f", t.gravity.x, t.gravity.y, t.gravity.z))
                            .font(.system(.body, design: .monospaced)).gridCellColumns(3)
                    }
                }
                LabeledContent("마지막 인식 제스처") { Text(t.lastGesture).bold() }
                Text("까딱/갸웃을 해보면서 위 값과 '마지막 인식 제스처'를 보고 아래 기준값을 맞추세요. 끄덕일 때 pitch 속도가 기준값을 넘어야 인식돼요.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section("커서") {
                Picker("이동 방식", selection: $settings.cursorMode) {
                    Text("조이스틱 (살짝 기울이고 있으면 계속 이동) · 추천").tag("joystick")
                    Text("절대 (고개 방향 = 화면 위치)").tag("absolute")
                    Text("상대 (움직인 만큼, 트랙패드처럼)").tag("relative")
                }
                .pickerStyle(.radioGroup)
                if settings.joystickMode {
                    Toggle("⌃⌥ / 를 누르고 있을 때만 이동 (끄면 항상 이동)", isOn: $settings.joyRequiresKey)
                    slider("최고 속도 (px/초)", $settings.joyMaxSpeed, 300...4000, "%.0f")
                    slider("멈춤 범위 (이만큼은 기울여도 안 움직임)", $settings.joyDeadzone, 0.5...10, "%.1f°")
                    slider("최고 속도가 되는 기울기", $settings.joyRange, 4...30, "%.0f°")
                    slider("위아래 증폭", $settings.verticalBoost, 1...3, "%.1f×")
                    Text(settings.joyRequiresKey
                         ? "⌃⌥ / 를 누르는 순간의 고개 위치가 '멈춤'이에요. 누른 채로 고개를 살짝 기울이면 그쪽으로 계속 가고, 많이 기울일수록 빨라져요. 떼면 그 자리에 멈춰요."
                         : "정면(⌃⌥R 로 맞춘 방향)이 '멈춤'이에요. 거기서 살짝 벗어나 있으면 그쪽으로 계속 가고, 많이 벗어날수록 빨라요. 클릭할 땐 정면으로 돌아오세요. 멈춤 위치가 어긋나면 편한 자세에서 ⌃⌥ / 를 한 번 누르세요.")
                        .font(.caption).foregroundStyle(.secondary)
                } else if settings.absoluteMode {
                    slider("좌우 범위 (화면 끝까지 몇 도)", $settings.yawRange, 8...45, "%.0f°")
                    slider("위아래 범위 (화면 끝까지 몇 도)", $settings.pitchRange, 5...30, "%.0f°")
                    Text("정면을 보면 화면 중앙이에요. 범위를 줄이면 고개를 조금만 움직여도 화면 끝에 닿아요. 화면 끝을 넘어 더 돌리면 기준이 따라와서, 돌아올 때 바로 반응해요. 트랙패드로 옮기면 그 위치가 새 기준이 돼요.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    slider("감도 (px/도)", $settings.sensitivity, 4...80, "%.0f")
                    slider("가속", $settings.acceleration, 0...4, "%.1f")
                    slider("데드존 (도/초, 떨림 무시)", $settings.deadzone, 0...20, "%.1f")
                }
                slider("부드럽게", $settings.smoothing, 0...0.9, "%.2f")
                slider("스크롤 속도", $settings.scrollSpeed, 1...30, "%.0f")
                Toggle("좌우 반전", isOn: $settings.invertX)
                Toggle("위아래 반전", isOn: $settings.invertY)
            }

            Section("머리 제스처") {
                Toggle("제스처 사용 (⌃⌥G)", isOn: $settings.gesturesEnabled)
                slider("까딱 인식 속도 (°/s, 높을수록 둔감)", $settings.nodThreshold, 50...300, "%.0f")
                slider("갸웃 인식 각도 (°)", $settings.tiltAngle, 8...40, "%.0f")
                slider("도리도리 인식 속도 (°/s)", $settings.shakeThreshold, 60...350, "%.0f")
                Toggle("갸웃 좌우 반전 (오른쪽/왼쪽이 반대로 인식될 때)", isOn: $settings.invertTilt)
                ForEach(PodTrigger.allCases.filter(\.isHeadGesture)) { trig in actionPicker(trig) }
                Text("마우스 모드가 꺼져 있을 땐 '마우스 모드 켜기'와 '음성 입력'에 연결된 제스처만 동작해요.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section("에어팟 기둥 누르기") {
                Toggle("기둥 누르기 사용 (마우스 모드일 때만 재생/정지 대신 아래 동작 실행)",
                       isOn: Binding(get: { settings.captureStem }, set: { controller.setStemCapture($0) }))
                ForEach(PodTrigger.allCases.filter { !$0.isHeadGesture }) { trig in actionPicker(trig) }
            }

            Section("음성 입력 (Claude Code · Codex 등)") {
                Picker("언어", selection: $settings.voiceLocale) {
                    Text("한국어").tag("ko-KR")
                    Text("English (US)").tag("en-US")
                    Text("日本語").tag("ja-JP")
                }
                Toggle("입력 후 Enter 자동으로 누르기 (바로 전송)", isOn: $settings.autoEnter)
                LabeledContent("입력 대상") {
                    Text(settings.voiceTargetBundleID.isEmpty ? "현재 포커스된 창" : settings.voiceTargetBundleID)
                }
                Text("메뉴바 → 음성 입력 대상에서 터미널 앱을 고르면, 다른 창을 보고 있어도 그 앱으로 보내요. \"엔터\" / \"전송\" 이라고만 말하면 Enter, \"취소\" 는 Esc 를 눌러요.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section("단축키") {
                ForEach(controller.hotKeyList, id: \.0) { key, title in
                    LabeledContent(title) { Text(key).font(.system(.body, design: .monospaced)) }
                }
            }

            Section {
                Toggle("화면 알림 표시", isOn: $settings.showHUD)
                Button("커서/제스처 설정 기본값으로") { settings.resetToDefaults() }
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 560, minHeight: 600)
    }

    private func row(_ title: String, ok: Bool, detail: String) -> some View {
        LabeledContent {
            Text(detail).foregroundStyle(ok ? .green : .orange)
        } label: {
            Label(title, systemImage: ok ? "checkmark.circle.fill" : "exclamationmark.circle")
        }
    }

    private func authText(_ s: CMAuthorizationStatus) -> String {
        switch s {
        case .authorized: return "허용됨"
        case .denied: return "거부됨 → 시스템 설정에서 허용"
        case .restricted: return "제한됨"
        default: return "에어팟 착용 시 물어봐요"
        }
    }

    private func mono(_ v: Double, _ unit: String) -> some View {
        Text(String(format: "%7.1f%@", v, unit)).font(.system(.body, design: .monospaced))
    }

    private func slider(_ title: String, _ value: Binding<Double>, _ range: ClosedRange<Double>, _ fmt: String) -> some View {
        LabeledContent(title) {
            HStack {
                Slider(value: value, in: range).frame(width: 220)
                Text(String(format: fmt, value.wrappedValue)).monospacedDigit().frame(width: 44, alignment: .trailing)
            }
        }
    }

    private func actionPicker(_ trig: PodTrigger) -> some View {
        Picker(trig.label, selection: Binding(get: { settings.action(for: trig) }, set: { settings.setAction($0, for: trig) })) {
            ForEach(PodAction.allCases) { a in Text(a.label).tag(a) }
        }
    }
}
