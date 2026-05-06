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
        .persistentSystemOverlays(.hidden)
        .preferredColorScheme(.dark)
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
