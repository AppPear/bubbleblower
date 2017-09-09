//
//  ViewController.swift
//  soapBubble
//
//  Created by Samu András on 2017. 09. 03..
//  Copyright © 2017. Samu András. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import CoreAudio
import AVFoundation

class ViewController: UIViewController, ARSCNViewDelegate {
    var imageView:UIImageView!
    @IBOutlet var sceneView: ARSCNView!
    let soapBubble = Bubble()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        // Create a new scene
        let scene = SCNScene()
        
        
        // Set the scene to the view
        sceneView.scene = scene
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        
        imageView = UIImageView(frame: CGRect(x: 0, y:  self.view.frame.size.height*0.5, width: self.view.frame.size.width, height: self.view.frame.size.height*0.5))
        imageView.contentMode = .scaleAspectFit
        imageView.image = #imageLiteral(resourceName: "bubble_blower")
        imageView.alpha = 0.8
        //self.sceneView.addSubview(imageView)
        
        initMicrophone()
    }
    
    func initMicrophone(){
        var recorder: AVAudioRecorder
        let audioSession: AVAudioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try audioSession.setActive(true)
        } catch  {}
        
        let url = URL(fileURLWithPath:"/dev/null")
        
        var settings = Dictionary<String, NSNumber>()
        settings[AVSampleRateKey] = 44100.0
        settings[AVFormatIDKey] = kAudioFormatAppleLossless as NSNumber
        settings[AVNumberOfChannelsKey] = 1
        settings[AVEncoderAudioQualityKey] = 0x7F //max quality hex
        
        do {
            try recorder = AVAudioRecorder(url: url, settings: settings)
            recorder.prepareToRecord()
            recorder.isMeteringEnabled = true
            recorder.record()
            _ = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(timerCallBack(timer:)), userInfo: recorder, repeats: true)
        } catch  {}
    }
    
    @objc func timerCallBack(timer:Timer){
        let recorder: AVAudioRecorder = timer.userInfo as! AVAudioRecorder
        recorder.updateMeters()
        let avgPower: Float = 160+recorder.averagePower(forChannel: 0)
        if avgPower > 150 && avgPower < 155 {
            newBubble()
            Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false, block: { (timer) in
                self.newBubble()
            })
        }else if avgPower >= 155 && avgPower < 165{
            newBubble()
            Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: { (timer) in
                self.newBubble()
            })
            Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false, block: { (timer) in
                self.newBubble()
            })
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false, block: { (timer) in
                self.newBubble()
            })
        }else if avgPower >= 165{
            newBubble()
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { (timer) in
                self.newBubble()
            })
            Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false, block: { (timer) in
                self.newBubble()
            })
            Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false, block: { (timer) in
                self.newBubble()
            })
            Timer.scheduledTimer(withTimeInterval: 0.35, repeats: false, block: { (timer) in
                self.newBubble()
            })
            Timer.scheduledTimer(withTimeInterval: 0.45, repeats: false, block: { (timer) in
                self.newBubble()
            })
        }
    }
    
    @objc func handleTap(_ recgnizer:UITapGestureRecognizer){
        newBubble()
        //        AudioServicesPlaySystemSound(1519)
    }
    func newBubble(){
        guard let frame = self.sceneView.session.currentFrame else {
            return
        }
        let mat = SCNMatrix4(frame.camera.transform) // 4x4 transform matrix describing camera in world space
        let dir = SCNVector3(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33) // orientation of camera in world space
        
        let position = getNewPosition()
        let newBubble = soapBubble.clone()
        newBubble.position = position
        newBubble.scale = SCNVector3(1,1,1) * floatBetween(0.4, and: 1)
        newBubble.runAction(SCNAction.move(by: dir + SCNVector3(floatBetween(-0.5, and:0.5 ),floatBetween(0, and: 1.5),0), duration: TimeInterval(floatBetween(6, and: 9)))) {
            newBubble.runAction(SCNAction.fadeOut(duration: 0), completionHandler: {
                DispatchQueue.main.async {
                    playSoftImpact()
                }
                newBubble.removeFromParentNode()
            })
        }
        sceneView.scene.rootNode.addChildNode(newBubble)
    }
    
    func getNewPosition() -> (SCNVector3) { // (direction, position)
        if let frame = self.sceneView.session.currentFrame {
            let mat = SCNMatrix4(frame.camera.transform) // 4x4 transform matrix describing camera in world space
            let dir = SCNVector3(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33) // orientation of camera in world space
            let pos = SCNVector3(mat.m41, mat.m42, mat.m43) // location of camera in world space
            return pos + SCNVector3(0,-0.07,0) + dir.normalized() * 0.5
        }
        return SCNVector3(0, 0, -1)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let frame = self.sceneView.session.currentFrame else {
            return
        }
        let mat = SCNMatrix4(frame.camera.transform) // 4x4 transform matrix describing camera in world space
        let pos = SCNVector3(mat.m41, mat.m42, mat.m43) // location of camera in world space
        
        
        for node in sceneView.scene.rootNode.childNodes {
            node.look(at: pos)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    // MARK: - ARSCNViewDelegate
    
    /*
     // Override to create and configure nodes for anchors added to the view's session.
     func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
     let node = SCNNode()
     
     return node
     }
     */
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}

private func floatBetween(_ first: Float,  and second: Float) -> Float {
    // random float between upper and lower bound (inclusive)
    return (Float(arc4random()) / Float(UInt32.max)) * (first - second) + second
}

extension SCNVector3 {
    func length() -> Float {
        return sqrtf(x * x + y * y + z * z)
    }
    
    func normalized() -> SCNVector3 {
        if self.length() == 0 {
            return self
        }
        
        return self / self.length()
    }
}
func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

func * (left: SCNVector3, right: Float) -> SCNVector3 {
    return SCNVector3Make(left.x * right, left.y * right, left.z * right)
}

func / (left: SCNVector3, right: Float) -> SCNVector3 {
    return SCNVector3Make(left.x / right, left.y / right, left.z / right)
}

func playHapticSuccess() {
    if #available(iOS 10.0, *) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
}

func playHapticImpact() {
    if #available(iOS 10.0, *) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
}

func playSoftImpact() {
    if #available(iOS 10.0, *) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
}

