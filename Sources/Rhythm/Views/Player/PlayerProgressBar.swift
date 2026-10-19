import SwiftUI

struct PlayerProgressBar: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    @State private var isDragging: Bool = false
    @State private var dragProgress: Double = 0
    
    private var currentProgress: Double {
        if isDragging {
            return dragProgress
        } else {
            return playerVM.progress
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let barHeight: CGFloat = isDragging ? 7 : 4
            let clampedProgress = max(0, min(1, currentProgress))
            
            ZStack(alignment: .leading) {
                // Background Track
                Capsule()
                    .fill(Color.white.opacity(0.18))
                    .frame(height: barHeight)
                
                // Progress Fill
                Capsule()
                    .fill(Color.appAccentGradient)
                    .frame(width: max(0, width * CGFloat(clampedProgress)), height: barHeight)
                
                // Draggable Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: isDragging ? 16 : 10, height: isDragging ? 16 : 10)
                    .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 1)
                    .offset(x: max(0, min(width - (isDragging ? 16 : 10), width * CGFloat(clampedProgress) - (isDragging ? 8 : 5))))
            }
            .frame(height: 24)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        let newProgress = Double(value.location.x / width)
                        dragProgress = max(0, min(1, newProgress))
                    }
                    .onEnded { value in
                        let newProgress = Double(value.location.x / width)
                        let finalProgress = max(0, min(1, newProgress))
                        playerVM.seek(toProgress: finalProgress)
                        isDragging = false
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
            )
            .animation(.easeInOut(duration: 0.15), value: isDragging)
        }
        .frame(height: 24)
    }
}
