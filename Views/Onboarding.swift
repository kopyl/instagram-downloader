import SwiftUI

struct Content {
    let description: String
    let image: Image
    let ctaText: String
}

let info: [Content] = [
    Content(
        description: "Find a reel and press “Share”",
        image: Image("onboarding-1"),
        ctaText: "Next"
    ),
    Content(
        description: "Then press on “Share to”",
        image: Image("onboarding-2"),
        ctaText: "Next"
    ),
    Content(
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
        static let restart = Text("Restart")
        static let cta = Text("Save reels to Photos")
    }
}

let borderRadius = 6.0

struct StepperDotView: View {
    let idx: Int
    let isActive: Bool
    
    var body: some View {
        Rectangle()
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
                Text(info[stepper.index].description)
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
    @State var isSheetVisible: Bool = false
    @State var isLoggingIn = false
    @Binding var hasUserLoggedInAtLeastOnce: Bool
    @Binding var path: NavigationPath
    @StateObject private var step = Step()
    
    public var notification = Notification()
    
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
                    isSheetVisible = true
                    notification.present(type: .loading, title: "Veifying your account")
                }
                step.increase()
            } label: {
                VStack {
                    Text(info[step.index].ctaText)
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
        .gesture(
            DragGesture()
                .onEnded { value in
                    let threshold: CGFloat = 50
                    if value.translation.width < -threshold {
                        step.increase()
                    } else if value.translation.width > threshold {
                        step.decrease()
                    }
                }
        )
        .sheet(
            isPresented: $isSheetVisible,
            onDismiss: {
                Task() {
                    do {
                        let response = try await makeRequest(strUrl: "https://www.instagram.com/api/v1/friendships/pending/")
                        try JSONSerialization.jsonObject(with: response, options: [])
                        notification.dismiss()
                        isLoggingIn = false
                        hasUserLoggedInAtLeastOnce = true
                        path.append("Home")
                    }
                    catch {
                        notification.present(type: .error, title: "Login failed. Please login.")
                        isLoggingIn = false
                    }
                }
            },
            content: {
                WebView(url: URL(string: "https://instagram.com")!)
                    .onAppear {
                        isLoggingIn = true
                    }
            }
        )
        .onAppear {
            notification.setWindowScene()
        }
    }
}
