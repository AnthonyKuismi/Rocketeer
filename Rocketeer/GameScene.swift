//
//  GameScene.swift
//  Rocketeer
//
//  Created by 90308589 on 9/5/20.
//  Copyright © 2020 Anthony Kuismi. All rights reserved.
//

import SpriteKit
import GameplayKit
import AVFoundation
extension SKSpriteNode {
       func addGlow(radius: Float) {
           let effectNode = SKEffectNode()
           effectNode.shouldRasterize = true
           addChild(effectNode)
           effectNode.addChild(SKSpriteNode(texture: texture))
           effectNode.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius":radius])
       }
}
class GameScene: SKScene,SKPhysicsContactDelegate {
    
    var scoreLabel = SKLabelNode()
    var highScoreLabel = SKLabelNode()
    
    let reducedPower: CGFloat = 10
    let circlePower: CGFloat = 30
    
    var score = 0
    var highscore = 0
    
    var audioPlayerExplosion: AVAudioPlayer?
    var audioPlayerBoost: AVAudioPlayer?
    
    var gameState:String = "home"
    
    var dead = false
    var isTouch = false
    var justRealesed = false
    
    var player = SKSpriteNode()
    var rightSide = SKSpriteNode()
    var leftSide = SKSpriteNode()
    var obstacle = SKSpriteNode()
    var theCamera = SKCameraNode()
    var playButton = SKSpriteNode()
    var restartButton = SKSpriteNode()
    //var homeButton = SKSpriteNode(imageNamed: "homeButton")
    
    override func didMove(to view: SKView) {
        setup()
        setupHomeScreen()
    }
    
    func set_filtering_mode(fileNamed: String,node: SKSpriteNode){
        let texture = SKTexture(imageNamed: fileNamed)
        texture.filteringMode = SKTextureFilteringMode.nearest
        node.texture = texture
    }
    
    func setup(){
        loadVars()
        setupNodes()
        setupNames()
        setupPhysics()
        setupSounds()
    }
    
    func setupNames(){
        playButton.name = "playButton"
        restartButton.name = "restartButton"
        //homeButton.name = "homeButton"
    }
    
    func loadVars(){
        highscore = getHighScore()
    }

    func setupHomeScreen(){
        self.removeAllChildren()
        addChild(playButton)
    }
    
    func setupRestartScreen(){
        player.removeFromParent()
        restartButton.position.x = 0
        restartButton.position.y = (camera?.position.y)! - 200
        addChild(restartButton)
    }
    
    func setupGame(){
        self.removeAllChildren()
        addChild(scoreLabel)
        addChild(highScoreLabel)
        addChild(player)
        addChild(obstacle)
        addChild(rightSide)
        addChild(leftSide)
        self.camera = theCamera
        scoreLabel.text = "\(score)"
        highScoreLabel.text = "Highscore: \(highscore)"
    }
    
    func restartGame(){
        score = 0
        dead = false
        player.position = CGPoint.zero
        player.zRotation = 0
        gameState = "game"
        obstacle.position = CGPoint(x: 300, y: 700)
        self.removeAllChildren()
        setupGame()
    }
    func setupSounds(){
        do{
            var path = Bundle.main.path(forResource: "Explosion", ofType: "wav")!
            var url = URL(fileURLWithPath: path)
            audioPlayerExplosion = try AVAudioPlayer(contentsOf: url)
            path = Bundle.main.path(forResource: "RocketBoost", ofType: "wav")!
            url = URL(fileURLWithPath: path)
            audioPlayerBoost = try AVAudioPlayer(contentsOf: url)
            audioPlayerBoost?.volume = 0.01
            } catch {}
    }
    
    func setupNodes(){
        highScoreLabel = self.childNode(withName: "highScoreLabel") as! SKLabelNode
        scoreLabel = self.childNode(withName: "scoreLabel") as! SKLabelNode
        player = self.childNode(withName: "firework") as! SKSpriteNode
        obstacle = self.childNode(withName: "obstacle") as! SKSpriteNode
        rightSide = self.childNode(withName: "rightSide") as! SKSpriteNode
        leftSide = self.childNode(withName: "leftSide") as! SKSpriteNode
        
        let buttonSize = CGSize(width: 256 , height: 256)
        set_filtering_mode(fileNamed: "playButton0", node: playButton)
        set_filtering_mode(fileNamed: "retryButton", node: restartButton)
        set_filtering_mode(fileNamed: "firework", node: player)
        playButton.size = buttonSize
        restartButton.size = buttonSize
        //homeButton.size = buttonSize
        playButton.position = CGPoint.zero
        player.addGlow(radius: 60)
        self.camera = theCamera
    }
    
    func setupPhysics(){
        physicsWorld.contactDelegate = self
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameState == "game"{
            isTouch = true
        }else if gameState == "home"{
            buttonPress(touch: touches.first!)
            
        } else if gameState == "dead"{
            buttonPress(touch: touches.first!)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameState == "game"{
            isTouch = false
            justRealesed = true
        }else if gameState == "home"{
            
        }
    }
    
    func buttonPress(touch: UITouch){
        enumerateChildNodes(withName: "//*") { (node, stop) in
            let location = touch.location(in: self)
            if node.name == "playButton"{
                if (self.playButton.contains(location)){
                    self.gameState = "game"
                    self.setupGame()
                }
            } else if node.name == "restartButton"{
                if (self.restartButton.contains(location)){
                    self.gameState = "game"
                    self.restartGame()
                }
            } else if node.name == "homeButton" {
               // if (self.homeButton.contains(location)){
                 //   self.setupHomeScreen()
                //}
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if gameState == "game"{
            if isTouch{
                let force = calcCircleMovement()
                player.physicsBody?.applyImpulse(force)
            }else{
                if justRealesed{
                    let force = calcStraightMovement()
                    player.physicsBody?.applyImpulse(force)
                    justRealesed = false
                }
            }
            if !dead{
                audioPlayerBoost?.play()
                addEmiter(loc: player.position, file: "rocketBooster")
            }
            let currentY = player.position.y
            theCamera.position.y = currentY
            rightSide.position.y = currentY
            leftSide.position.y = currentY
            scoreLabel.position.y = currentY + 480
            highScoreLabel.position.y = currentY + 400
            if theCamera.position.y - obstacle.position.y > 600{
                score = score + 1
                scoreLabel.text = "\(score)"
                let number = Int.random(in: 0...6)
                obstacle.position.y = theCamera.position.y + 600
                obstacle.position.x = CGFloat(number * 100 - 315)
            }
            if score > highscore{
                print("tom")
                highscore = score
                highScoreLabel.text = "Highscore: \(highscore)"
                setHighScore()
            }
        }
        
    }
    
    func calcCircleMovement() -> CGVector{
        player.physicsBody?.velocity = CGVector.zero
        player.zRotation = player.zRotation + CGFloat(Double.pi)/20
        let dx = cos(player.zRotation + CGFloat(Double.pi)/2)*circlePower
        let dy = sin(player.zRotation + CGFloat(Double.pi)/2)*circlePower
        return CGVector(dx: dx, dy: dy)
    }
    
    func calcStraightMovement() -> CGVector{
        let dx = -cos(player.zRotation + CGFloat(Double.pi)/2)*reducedPower
        let dy = -sin(player.zRotation + CGFloat(Double.pi)/2)*reducedPower
        return CGVector(dx: dx, dy: dy)
    }
    
    func addEmiter(loc: CGPoint,file:String){
        let emitter = SKEmitterNode(fileNamed: file)
        emitter?.name = "emitter"
        emitter?.zPosition = 2;
        emitter?.position = CGPoint(x: loc.x, y: loc.y )
        addChild(emitter!)
        
        emitter?.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),SKAction.removeFromParent()]))
    }
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }
        if nodeA.name == "firework"{
            lose()
        } else if nodeB.name == "firework"{
            lose()
        }
    }
    
    func lose(){
        gameState = "dead"
        audioPlayerBoost?.stop()
        audioPlayerExplosion?.play()
        dead = true
        addEmiter(loc: player.position, file: "smokeHouse")
        setupRestartScreen()
    }
    
    func getHighScore()-> Int{
        return UserDefaults.standard.integer(forKey: "highscore")
    }
    
    func setHighScore(){
        UserDefaults.standard.set(highscore, forKey: "highscore")
    }

}
