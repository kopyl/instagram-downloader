import SwiftUI

struct OnboardingContent {
    let description: String
    let image: Image
    let ctaText: String
}

let info: [OnboardingContent] = [
    OnboardingContent(
        description: "Find a reel and press “Share”",
        image: Image("onboarding-1"),
        ctaText: "Next"
    ),
    OnboardingContent(
        description: "Then press on “Share to”",
        image: Image("onboarding-2"),
        ctaText: "Next"
    ),
    OnboardingContent(
        description: "Select Reelsaver",
        image: Image("onboarding-3"),
        ctaText: "Login with Insta"
    )
]

class UIViews {
    class Images {
        static let logo = Image("Logotype")
    }
    class Texts {
        static let restart = WText("Restart")
        static let cta = WText("Save reels to Photos")
    }
}

let borderRadius = 6.0

func dragGesture(step: Step) -> some Gesture {
    return DragGesture()
        .onEnded { value in
            let threshold: CGFloat = 50
            if value.translation.width < -threshold {
                step.increase()
            } else if value.translation.width > threshold {
                step.decrease()
            }
        }
}

struct StepperDotView: View {
    let idx: Int
    let isActive: Bool
    
    var body: some View {
        Rectangle()
            .fill(.white)
            .frame(width: 6, height: 6)
            .cornerRadius(100)
            .opacity(isActive ? 1 : 0.3)
    }
}

struct StepperDotsView: View {
    let activeDotIndex: Int
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(info.indices, id: \.self) { idx in
                StepperDotView(idx: idx, isActive: idx == activeDotIndex)
            }
        }
    }
}

extension Edge {
    var opposite: Edge {
        self == .bottom ? .top : .bottom
    }
}

struct StepperView: View {
    @ObservedObject var stepper: Step
    
    var body: some View {
        VStack {
            HStack {
                WText(info[stepper.index].description)
                    .padding(.vertical, 20)
                    .font(.system(size: 16))
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: stepper.textMoveDirection),
                            removal: .move(edge: stepper.textMoveDirection.opposite)
                        )
                    )
                    .id(stepper.index)
                Spacer()
                StepperDotsView(activeDotIndex: stepper.index)
            }
            .padding(.horizontal, 27)
            .frame(maxWidth: .infinity)
            .background(Color.stepperBg)
            .cornerRadius(borderRadius)
            
            info[stepper.index].image
                .resizable()
                .scaledToFit()
                .transition(.blurReplace)
                .id(stepper.index)
                .cornerRadius(borderRadius)
        }
    }
}

class Step: ObservableObject {
    @Published var index = 0
    @Published var textMoveDirection: Edge = .top
    
    var isLast: Bool {
        index == 2
    }
    
    func reset() {
        textMoveDirection = .top
        withAnimation(.easeInOut(duration: 0.3)) {
            index = 0
        }
    }
    
    func increase() {
        guard index < 2 else { return }
        textMoveDirection = .bottom
        withAnimation(.easeInOut(duration: 0.3)) {
            index += 1
        }
    }
    
    func decrease() {
        guard index > 0 else { return }
        textMoveDirection = .top
        withAnimation(.easeInOut(duration: 0.3)) {
            index -= 1
        }
    }
}

struct OnboardingView: View {
    @State var isInstagramLoginSheetVisible = false
    @State var isLoggingIn = false
    @Binding var hasUserLoggedInAtLeastOnce: Bool
    @Binding var path: [Route]
    @StateObject private var step = Step()
    
    public var notification: AlertNotification
    
    var body: some View {
        VStack {
            HStack(alignment: .center) {
                UIViews.Images.logo
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if step.isLast {
                    Button() {
                        step.reset()
                    } label: {
                        UIViews.Texts.restart
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                            .opacity(0.6)
                            .padding(.leading, 20)
                    }
                    .transition(.move(edge: .trailing))
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 40)
            StepperView(stepper: step)
            Spacer()
            UIViews.Texts.cta
                .font(.system(size: 31))
                .padding(.bottom, 60)
            Button() {
                if step.isLast {
                    isInstagramLoginSheetVisible = true
                    notification.present(type: .loading, title: "Verifying your account")
                }
                step.increase()
            } label: {
                VStack {
                    WText(info[step.index].ctaText)
                    .foregroundStyle(.white)
                    .padding(.vertical, 20)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: step.textMoveDirection),
                            removal: .move(edge: step.textMoveDirection.opposite)
                        )
                    )
                    .id(step.index < 2 ? 0 : step.index)
                }
                    .frame(maxWidth: .infinity)
                    .background(.button)
                    .cornerRadius(borderRadius)
                    .font(.system(size: 14))
            }
        }
        .opacity(isLoggingIn ? 0.1 : 1)
        .animation(.linear(duration: 1), value: isLoggingIn)
        .padding(.horizontal, 18)
        .background(.appBg)
        .contentShape(Rectangle())
        .gesture(dragGesture(step: step))
        .modifier(
            InstagramLoginSheet(
                isPresented: $isInstagramLoginSheetVisible,
                isLoggingIn: $isLoggingIn,
                hasUserLoggedInAtLeastOnce: $hasUserLoggedInAtLeastOnce,
                path: $path,
                notification: notification
            )
        )
        .onAppear {
            AppState.shared.swipeEnabled = false
        }
        .onDisappear {
            AppState.shared.swipeEnabled = true
        }
    }
}
