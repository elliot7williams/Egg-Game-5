//
//  ContentView.swift
//  Egg Game 5
//
//  Created by Elliot Williams on 2025-06-23.
//

import SwiftUI
import Combine

// MARK: - Game Constants
struct GameConstants {
    static let eggCount = 20
    static let initialTime = CGFloat.random(in: 3000...6000)
    static let backgroundColor = Color(red: 244/255, green: 76/255, blue: 186/255)
}

// MARK: - Game State
final class GameState: ObservableObject {
    @Published var score = 0
    @Published var highScore = 0
    @Published var level = 1
    @Published var highestLevel = 1
    @Published var speedFactor: CGFloat = 1.0
    @Published var timeLeft = GameConstants.initialTime
    @Published var isGameActive = false
    @Published var isInstructions = true
    @Published var isGameOver = false
    
    var basket = Basket()
    var eggs = [Egg]()
    var specialEggs = [SpecialEgg]()
    var goldenEggs = [GoldenEgg]()
    var bunny = Bunny()
    var chicken = Chicken()
    var floatingBunny = FloatingBunny()
    var secondBunny = SecondBunny()
    
    init() {
        resetGame()
    }
    
    func resetGame() {
        score = 0
        level = 1
        timeLeft = CGFloat.random(in: 1500...6000)
        isGameActive = false
        isGameOver = false
        
        // Initialize entities
        basket = Basket()
        eggs = (0..<GameConstants.eggCount).map { _ in Egg() }
        specialEggs = (0..<GameConstants.eggCount).map { _ in SpecialEgg() }
        goldenEggs = (0..<GameConstants.eggCount).map { _ in GoldenEgg() }
        bunny = Bunny()
        chicken = Chicken()
        floatingBunny = FloatingBunny()
        secondBunny = SecondBunny()
    }
    
    func updateEntities() {
        // Update positions
        eggs.forEach { $0.move(speedFactor: speedFactor) }
        specialEggs.forEach { $0.move(speedFactor: speedFactor) }
        goldenEggs.forEach { $0.move(speedFactor: speedFactor) }
        
        // Check collisions
        checkCollisions()
        
        // Update level based on score
        updateLevel()
    }
    
    private func checkCollisions() {
        // Example collision check (simplified)
        for egg in eggs {
            if basket.intersects(egg: egg) {
                score += 3
                egg.reset()
            }
        }
    }
    
    private func updateLevel() {
        if score > 179 {
            level = 5
            speedFactor = CGFloat.random(in: 7...9)
        } else if score > 110 {
            level = 4
        } else if score > 79 {
            level = 3
        } else if score > 20 {
            level = 2
            speedFactor = 3.0
        }
        
        if score > highScore {
            highScore = score
            highestLevel = level
        }
    }
}

// MARK: - Game Entities
struct Basket {
    var position = CGPoint(x: 220, y: 345)
    let size: CGFloat = 60
    
    mutating func setPosition(_ point: CGPoint) {
        position = point
        constrainToScreen()
    }
    
    private mutating func constrainToScreen() {
        // Simplified constraints
        position.x = max(0, min(position.x, UIScreen.main.bounds.width - 225))
        position.y = max(0, min(position.y, UIScreen.main.bounds.height - 90))
    }
    
    func intersects(egg: Egg) -> Bool {
        let distance = hypot(position.x - egg.position.x, position.y - egg.position.y)
        return distance < (size + egg.size)
    }
    
    func draw(context: inout GraphicsContext) {
        // Drawing logic for basket
        var path = Path()
        path.addArc(center: CGPoint(x: position.x + 125, y: position.y - 90),
                   radius: 95,
                   startAngle: .degrees(180),
                   endAngle: .degrees(0),
                   clockwise: false)
        context.stroke(path, with: .color(.blue), lineWidth: 10)
    }
}

class Egg {
    var position: CGPoint
    var size: CGFloat
    var color: Color
    
    init() {
        position = CGPoint(
            x: CGFloat.random(in: 0..<UIScreen.main.bounds.width),
            y: CGFloat.random(in: -800..<0)
        )
        size = CGFloat.random(in: 0.7...1.3)
        color = Color(
            red: Double.random(in: 193/255...1),
            green: Double.random(in: 205/255...249/255),
            blue: Double.random(in: 168/255...1),
            opacity: Double.random(in: 0.4...1.0)
        )
    }
    
    func move(speedFactor: CGFloat) {
        position.y += CGFloat.random(in: 1...5) * speedFactor
        if position.y > UIScreen.main.bounds.height {
            reset()
        }
    }
    
    func reset() {
        position = CGPoint(
            x: CGFloat.random(in: 0..<UIScreen.main.bounds.width),
            y: CGFloat.random(in: -800..<0)
        )
    }
    
    func draw(context: inout GraphicsContext) {
        let eggPath = Path(ellipseIn: CGRect(
            x: position.x - 35 * size,
            y: position.y - 50 * size,
            width: 70 * size,
            height: 100 * size
        ))
        context.fill(eggPath, with: .color(color))
    }
}

// Similar implementations for:
// - SpecialEgg, GoldenEgg, Bunny, Chicken, FloatingBunny, SecondBunny

// MARK: - Main Game View
struct EggGame: View {
    @StateObject private var gameState = GameState()
    private let timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Canvas { context, size in
            // Draw background
            context.fill(Path(CGRect(origin: .zero, size: size)),
                         with: .color(GameConstants.backgroundColor))
            
            // Draw entities
            gameState.basket.draw(context: &context)
            gameState.eggs.forEach { $0.draw(context: &context) }
            // Draw other entities...
            
            // Draw UI elements
            drawUI(context: &context, size: size)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    gameState.basket.setPosition(value.location)
                }
        )
        .onTapGesture {
            if !gameState.isGameActive {
                gameState.isGameActive = true
                gameState.isInstructions = false
            }
        }
        .onReceive(timer) { _ in
            if gameState.isGameActive {
                gameState.timeLeft -= 1
                gameState.updateEntities()
                
                if gameState.timeLeft <= 0 {
                    gameState.isGameOver = true
                    gameState.isGameActive = false
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    private func drawUI(context: inout GraphicsContext, size: CGSize) {
        // Score display
        let scoreText = Text("Score: \(gameState.score)")
            .font(.system(size: 32, weight: .bold))
        context.draw(scoreText, at: CGPoint(x: 20, y: 20))
        
        // Game over screen
        if gameState.isGameOver {
            let gameOverText = Text("Game Over")
                .font(.largeTitle)
            context.draw(gameOverText,
                         at: CGPoint(x: size.width/2, y: size.height/2))
        }
    }
}

// MARK: - Preview
struct EggGame_Previews: PreviewProvider {
    static var previews: some View {
        EggGame()
    }
}
