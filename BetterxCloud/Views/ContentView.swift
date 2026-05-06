import SwiftUI

struct ContentView: View {
    @State private var isLoaded = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            CloudWebView(isLoaded: $isLoaded)
                .edgesIgnoringSafeArea(.all)
            
            LaunchScreenView()
                .opacity(isLoaded ? 0 : 1)
                .allowsHitTesting(!isLoaded)
                .animation(.easeInOut(duration: 0.4), value: isLoaded)
                .zIndex(1)
        }
        .modifier(HideHomeIndicatorModifier())
        .preferredColorScheme(.dark)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
                if !isLoaded { isLoaded = true }
            }
        }
    }
}

struct HideHomeIndicatorModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.persistentSystemOverlays(.hidden)
        } else {
            content
        }
    }
}

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            Color(white: 0.05).edgesIgnoringSafeArea(.all)
            VStack(spacing: 30) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color(red: 0.06, green: 0.80, blue: 0.06))
                    .shadow(color: Color(red: 0.06, green: 0.80, blue: 0.06).opacity(0.4), radius: 20, x: 0, y: 0)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
    }
}
