import SwiftUI

struct ContentView: View {
    @State private var isLoaded = false
    
    var body: some View {
        ZStack {
            CloudWebView(isLoaded: $isLoaded)
                .edgesIgnoringSafeArea(.all)
            
            if !isLoaded {
                LaunchScreenView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        // Auto-hide home indicator for immersive full screen
        .modifier(HideHomeIndicatorModifier())
        .preferredColorScheme(.dark)
        .onAppear {
            // Failsafe: hide splash screen after 8 seconds no matter what
            DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
                if !isLoaded {
                    withAnimation { isLoaded = true }
                }
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
            Color.black.edgesIgnoringSafeArea(.all)
            VStack {
                Image(systemName: "gamecontroller.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.green)
                Text("Better xCloud")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 16)
            }
        }
    }
}
