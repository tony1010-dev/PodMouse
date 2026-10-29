import AppKit
import SwiftUI

/// 실행하면 뜨는 메인 창: 시작하기 / 조작법 / 설정
struct MainView: View {
    let controller: AppController
    @ObservedObject var state = AppState.shared

    var body: some View {
        TabView(selection: $state.guideTab) {
            StartView(controller: controller)
                .tabItem { Label("시작하기", systemImage: "play.circle") }
                .tag(0)
            ControlsView(controller: controller)
                .tabItem { Label("조작법", systemImage: "hand.point.up.left") }
                .tag(1)
            SettingsView(controller: controller)
                .tabItem { Label("설정", systemImage: "slider.horizontal.3") }
                .tag(2)
        }
        .padding(.top, 8)
        .frame(minWidth: 680, minHeight: 720)
    }
}

// MARK: - 시작하기

private struct StartView: View {
    let controller: AppController
    @ObservedObject var state = AppState.shared
    @ObservedObject var settings = Settings.shared
    @ObservedObject var t = Telemetry.shared

    private struct Step: Identifiable {
        let id: Int
        let title: String
        let how: String
        let done: Bool
        var button: (String, () -> Void)? = nil
    }

    private var steps: [Step] {
        let a = { settings.action(for: $0).label }
        return [
            Step(id: 1, title: "손쉬운 사용 권한 허용", how: "커서를 움직이고 클릭하려면 필요해요. 시스템 설정에서 PodMouse를 켜주세요.",
                 done: state.accessibilityOK,
                 button: state.accessibilityOK ? nil : ("설정 열기", {
                     controller.checkAccessibility(prompt: true)
                     NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                 })),
            Step(id: 2, title: "에어팟 귀에 착용", how: "양쪽 다 끼면 헤드 트래킹이 시작돼요. 처음엔 '동작 및 피트니스' 권한을 물어봐요.",
                 done: t.receiving),
            Step(id: 3, title: "마우스 모드 켜기", how: "⌃⌥M 을 누르거나, 고개를 좌우로 빠르게 도리도리 하세요. 다시 하면 꺼져요.",
                 done: state.mouseEnabled,
                 button: state.mouseEnabled ? nil : ("지금 켜기", { controller.setMouse(true) })),
            Step(id: 4, title: "고개를 살짝 돌리고 있기 → 그쪽으로 커서 이동",
                 how: "노트북 정면을 보고 ⌃⌥R 로 커서를 정중앙에 두세요. 정면에서 고개를 조금 돌리거나 숙이고 있으면 그쪽으로 계속 가고, 정면으로 돌아오면 멈춰요. 멈춤 위치가 어긋나면 ⌃⌥ / 한 번.",
                 done: t.cursorMovedByHead),
            Step(id: 5, title: "⌃⌥ , (쉼표) → 왼쪽 클릭", how: "아래 연습 영역에 커서를 두고 Control+Option+쉼표. 꾹 누른 채 고개를 움직이면 드래그돼요. 빠르게 두 번 = 더블클릭.",
                 done: state.practiced.contains("hotkeyLeft")),
            Step(id: 6, title: "⌃⌥ . (마침표) → 오른쪽 클릭", how: "Control+Option+마침표. 쉼표 바로 오른쪽 키예요.",
                 done: state.practiced.contains("hotkeyRight")),
            Step(id: 7, title: "에어팟 기둥 1번 → \(a(.stemSingle)),  2번 → \(a(.stemDouble))",
                 how: "마우스 모드가 켜져 있을 때만 동작해요 (꺼지면 음악 재생/정지로 돌아가요). 양쪽 어느 에어팟을 눌러도 같아요.",
                 done: state.practiced.contains(PodTrigger.stemSingle.rawValue) || state.practiced.contains(PodTrigger.stemDouble.rawValue)),
            Step(id: 8, title: "⌃⌥V 또는 기둥 3번 → 음성 입력", how: "말하고 나서 한 번 더 누르면 지금 창에 입력돼요. ⌃⌥V 를 꾹 누르고 말하면 손을 떼는 순간 입력돼요.",
                 done: state.voiceUsed),
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                checklist
                PracticePad()
                footer
            }
            .padding(24)
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            Image(systemName: "airpods.gen4")
                .font(.system(size: 40))
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 4) {
                Text("PodMouse").font(.largeTitle.bold())
                Text("에어팟을 낀 채로 고개로 커서를 움직이고, 동작으로 클릭하고, 말로 코딩해요.")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                controller.setMouse(!state.mouseEnabled)
            } label: {
                Label(state.mouseEnabled ? "마우스 모드 켜짐" : "마우스 모드 꺼짐",
                      systemImage: state.mouseEnabled ? "cursorarrow.motionlines" : "cursorarrow.slash")
                    .frame(minWidth: 150)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(state.mouseEnabled ? .green : .gray)
            .controlSize(.large)
        }
    }

    private var checklist: some View {
        let s = steps
        let done = s.filter(\.done).count
        return GroupBox {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("따라 해보기").font(.headline)
                    Spacer()
                    Text("\(done) / \(s.count)").monospacedDigit().foregroundStyle(.secondary)
                    ProgressView(value: Double(done), total: Double(s.count)).frame(width: 120)
                }
                .padding(.bottom, 8)
                ForEach(s) { step in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: step.done ? "checkmark.circle.fill" : "\(step.id).circle")
                            .font(.title2)
                            .foregroundStyle(step.done ? Color.green : Color.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.title).font(.body.weight(.semibold))
                                .strikethrough(step.done, color: .secondary)
                            Text(step.how).font(.callout).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                        if let (title, action) = step.button {
                            Button(title, action: action)
                        }
                    }
                    .padding(.vertical, 7)
                    if step.id != s.count { Divider() }
                }
            }
            .padding(6)
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle("실행할 때 이 창 보기", isOn: $settings.showGuideOnLaunch)
            Text("창을 닫아도 앱은 메뉴바(화면 오른쪽 위 에어팟 아이콘)에서 계속 실행돼요. 아이콘 → '사용 안내 열기'로 다시 볼 수 있어요.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}

// MARK: - 연습 영역

/// 연습 영역 카운터 (Command Line Tools에는 SwiftUI @State 매크로가 없어서 ObservableObject로 보관)
private final class PracticeModel: ObservableObject {
    static let shared = PracticeModel()
    @Published var left = 0
    @Published var right = 0
    @Published var double = 0
    @Published var flashText = ""
    @Published var flashOn = false
}

private struct PracticePad: View {
    @ObservedObject var state = AppState.shared
    @ObservedObject var t = Telemetry.shared
    @ObservedObject var m = PracticeModel.shared

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("연습 영역").font(.headline)
                    Spacer()
                    Button("기록 지우기") {
                        m.left = 0; m.right = 0; m.double = 0
                        state.practiced.removeAll()
                        state.voiceUsed = false
                        t.cursorMovedByHead = false
                    }
                    .controlSize(.small)
                }
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(m.flashOn ? Color.accentColor.opacity(0.25) : Color.secondary.opacity(0.08))
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                    ClickCatcher { kind in
                        switch kind {
                        case .left(let count):
                            if count >= 2 { m.double += 1; flash("더블 클릭!") } else { m.left += 1; flash("왼쪽 클릭!") }
                        case .right:
                            m.right += 1; flash("오른쪽 클릭!")
                        }
                    }
                    VStack(spacing: 10) {
                        Text(m.flashText.isEmpty ? "커서를 여기에 두고 ⌃⌥ , 또는 ⌃⌥ . 를 눌러보세요" : m.flashText)
                            .font(.title2.weight(.semibold))
                        HStack(spacing: 24) {
                            counter("왼쪽", m.left)
                            counter("오른쪽", m.right)
                            counter("더블", m.double)
                        }
                        Text("마지막 입력: \(state.lastTrigger?.label ?? "-")")
                            .font(.callout).foregroundStyle(.secondary)
                    }
                    .allowsHitTesting(false)
                }
                .frame(height: 190)
                Text("에어팟 기둥을 1번 / 2번 눌러서도 해보세요 (마우스 모드가 켜져 있어야 해요).")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(6)
        }
    }

    private func counter(_ label: String, _ n: Int) -> some View {
        VStack {
            Text("\(n)").font(.system(size: 28, weight: .bold, design: .rounded)).monospacedDigit()
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }

    private func flash(_ text: String) {
        m.flashText = text
        withAnimation(.easeOut(duration: 0.1)) { m.flashOn = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeIn(duration: 0.3)) { m.flashOn = false }
        }
    }
}

/// 왼쪽/오른쪽 클릭을 구분해서 받는 뷰
private struct ClickCatcher: NSViewRepresentable {
    enum Kind { case left(Int), right }
    let onClick: (Kind) -> Void

    func makeNSView(context: Context) -> CatcherView {
        let v = CatcherView()
        v.onClick = onClick
        return v
    }

    func updateNSView(_ v: CatcherView, context: Context) { v.onClick = onClick }

    final class CatcherView: NSView {
        var onClick: ((Kind) -> Void)?
        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
        override func mouseDown(with event: NSEvent) { onClick?(.left(event.clickCount)) }
        override func rightMouseDown(with event: NSEvent) { onClick?(.right) }
    }
}

// MARK: - 조작법

private struct ControlsView: View {
    let controller: AppController
    @ObservedObject var settings = Settings.shared

    private let gestureInfo: [(PodTrigger, String, String)] = [
        (.nod, "arrow.down.circle", "고개를 빠르게 끄덕였다가 원래대로. 두 번 연속 = 더블클릭."),
        (.tiltRight, "arrow.turn.right.down", "오른쪽 귀를 어깨 쪽으로 기울였다가 1.5초 안에 원위치."),
        (.tiltLeft, "arrow.turn.left.down", "왼쪽 귀를 어깨 쪽으로 기울였다가 원위치."),
        (.shake, "arrow.left.and.right", "고개를 좌우로 빠르게 2~3번 (도리도리)."),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                section("클릭") {
                    infoRow("keyboard", "⌃⌥ ,  (Control + Option + 쉼표)  →  왼쪽 클릭",
                            "빠르게 두 번 = 더블클릭. 꾹 누른 채로 고개를 살짝 기울이면 드래그, 떼면 놓아져요.")
                    infoRow("keyboard", "⌃⌥ .  (Control + Option + 마침표)  →  오른쪽 클릭", nil)
                    infoRow("hand.tap", "에어팟 기둥 1번 누르기  →  \(settings.action(for: .stemSingle).label)", nil)
                    infoRow("hand.tap", "에어팟 기둥 2번 누르기  →  \(settings.action(for: .stemDouble).label)", nil)
                    infoRow("hand.tap", "에어팟 기둥 3번 누르기  →  \(settings.action(for: .stemTriple).label)", nil)
                    Text("macOS는 왼쪽·오른쪽 에어팟 중 어느 쪽을 눌렀는지 알려주지 않아요. 그래서 누른 횟수로 구분해요. 에어팟이 2번 누르기인지 기다렸다가 신호를 보내서, 1번 누르기는 약간(0.3~0.5초) 늦게 클릭돼요.")
                        .font(.caption).foregroundStyle(.secondary)
                    HStack {
                        Text(settings.captureStem ? "기둥 누르기 클릭: 켜짐 · 마우스 모드일 때만 동작하고, 꺼지면 음악 재생/정지로 돌아가요."
                                                  : "기둥 누르기 클릭: 꺼짐 · 켜면 마우스 모드일 때 재생/정지 대신 클릭이 돼요.")
                            .font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Toggle("사용", isOn: Binding(get: { settings.captureStem }, set: { controller.setStemCapture($0) }))
                            .toggleStyle(.switch)
                    }
                }

                section("커서 이동") {
                    infoRow("move.3d", "고개를 살짝 돌리고 있기 (조이스틱)",
                            "정면이 멈춤이에요. 살짝 벗어나 있으면 천천히, 많이 벗어나면 빠르게 계속 이동하고, 정면으로 돌아오면 멈춰요. 4° 이내는 움직이지 않아요.")
                    infoRow("keyboard", "⌃⌥ /  →  지금 고개 위치를 멈춤으로",
                            "자세를 바꿔서 정면이 어긋났을 때 한 번 누르세요. 설정에서 '누르고 있을 때만 이동'을 켜면 키를 누르는 동안만 움직여요.")
                    infoRow("scope", "⌃⌥R  →  정면 기준 + 커서 정중앙",
                            "노트북 정면을 보고 누르세요. 마우스 모드를 켤 때도 커서가 정중앙에서 시작해요.")
                    infoRow("move.3d", "다른 이동 방식",
                            settings.joystickMode
                                ? "설정 탭 → 커서에서 '키 없이 항상 조이스틱', 절대 모드, 상대 모드로 바꿀 수 있어요."
                                : settings.absoluteMode
                                ? "절대 모드: 정면 = 화면 중앙, 고개 방향이 곧 커서 위치예요. 끝을 넘어 더 돌리면 기준이 따라와요. 어긋나면 정면을 보고 ⌃⌥R."
                                : "상대 모드: 움직인 만큼 이동해요. 천천히 = 정밀하게, 빠르게 = 멀리. 어긋나면 ⌃⌥R.")
                    infoRow("dial.medium", "고개를 너무 많이 움직여야 할 때",
                            "설정 탭 → 커서에서 절대 모드의 위아래/좌우 범위를 줄이세요. 작을수록 조금만 움직여도 끝까지 가요.")
                    infoRow("arrow.up.and.down", "스크롤 모드 (⌃⌥S)",
                            "켜면 고개 위아래가 스크롤이 돼요. 긴 코드나 문서 읽을 때 좋아요.")
                    infoRow("hand.draw", "드래그 고정 (⌃⌥D)",
                            "키를 계속 누르고 있기 힘들 때. 한 번 누르면 버튼이 눌린 상태가 되고, 고개로 옮긴 뒤 다시 ⌃⌥D 나 ⌃⌥ , 로 놓아요.")
                }

                section("음성으로 코딩하기 (Claude Code · Codex)") {
                    infoRow("1.circle", "터미널에서 claude 또는 codex 실행", nil)
                    infoRow("2.circle", "⌃⌥V (또는 기둥 3번) → 말하기", "화면 아래에 듣고 있는 내용이 실시간으로 보여요. ⌃⌥V 를 꾹 누르고 말하면 손을 떼는 순간 입력돼요.")
                    infoRow("3.circle", "다시 ⌃⌥V (또는 기둥 3번) → 창에 입력됨",
                            settings.autoEnter ? "Enter 자동이 켜져 있어서 바로 전송돼요." : "Enter 자동이 꺼져 있어요. 확인 후 \"엔터\" 라고 말하거나 Enter 를 눌러 전송하세요.")
                    infoRow("text.bubble", "음성 명령", "\"엔터\" / \"전송\" → Enter,  \"취소\" → Esc")
                    infoRow("mic", "마이크 선택", "macOS 기본 입력 장치를 써요. 제어 센터 → 사운드에서 입력을 에어팟으로 고르세요.")
                }

                section("머리 제스처 (선택)") {
                    ForEach(gestureInfo, id: \.0) { trig, icon, how in
                        infoRow(icon, "\(trig.label)  →  \(settings.action(for: trig).label)", how)
                    }
                    Text("고개로 클릭하는 건 기본으로 꺼져 있어요. 원하면 설정 탭에서 동작을 연결하세요. 제스처 전체는 ⌃⌥G 로 켜고 끌 수 있어요.")
                        .font(.caption).foregroundStyle(.secondary)
                }

                section("단축키  (⌃ Control + ⌥ Option)") {
                    Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 6) {
                        ForEach(controller.hotKeyList, id: \.0) { key, title in
                            GridRow {
                                Text(key).font(.system(.body, design: .monospaced).weight(.semibold))
                                    .padding(.horizontal, 8).padding(.vertical, 2)
                                    .background(RoundedRectangle(cornerRadius: 5).fill(Color.secondary.opacity(0.15)))
                                Text(title)
                            }
                        }
                    }
                }

                section("문제가 생기면") {
                    infoRow("exclamationmark.triangle", "제스처가 멋대로 실행돼요", "⌃⌥G 로 제스처를 끄고 단축키만 쓰거나, 설정 탭에서 인식 기준을 높이세요.")
                    infoRow("arrow.triangle.2.circlepath", "커서가 계속 한쪽으로 흘러요", "⌃⌥R 로 재설정하고, 설정 탭에서 데드존을 올리세요.")
                    infoRow("arrow.left.arrow.right", "방향이 반대예요", "설정 탭 → 좌우/위아래 반전, 갸웃 좌우 반전.")
                    infoRow("cursorarrow.slash", "커서가 아예 안 움직여요", "시작하기 탭의 체크리스트 1~3번을 확인하세요.")
                }
            }
            .padding(24)
        }
    }

    private func section<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                Text(title).font(.headline)
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(6)
        }
    }

    private func infoRow(_ icon: String, _ title: String, _ detail: String?) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).font(.title3).foregroundStyle(.tint).frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body.weight(.semibold))
                if let detail {
                    Text(detail).font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
