//
//  arCalibration.swift
//  ar_animation
//
//  Created by Samu András on 2017. 09. 01..
//  Copyright © 2017. Samu András. All rights reserved.
//

import Foundation
import UIKit
import CoreMotion
import AVFoundation

enum AnimStages {
    case none
    case holdVertical
    case moveLeft
    case moveRight
    case doneCalibration
}

class arCalibration: UIView{
    
    var containerView:UIView?
    var phoneImage:UIImageView?
    var guideImage:UIImageView?
    var heading:UILabel?
    var subHeading:UILabel?
    var imageViewsFrame:CGRect?
    var calibrationDone: ((Bool) -> Void)?
    var isHorizontal:Bool = false
    var isTrackingReady:Bool = false
    
    
    public var stages:AnimStages = .none {
        didSet{
            guard oldValue != stages else { return }
            switch stages {
            case .none: ()
            
            case .holdVertical:
                phoneImage!.image = #imageLiteral(resourceName: "phone_bare")
                rotateViewVertical(view: self.phoneImage!, angle:50)
                guideImage!.image = #imageLiteral(resourceName: "arrow")
                heading?.text = "CALIBRATION"
                subHeading?.text = "Please move your phone to vertical position!"
                //playSoundEffect(name: "effect-new-word")
                UIView.animate(withDuration: 0.25, delay: 1, options: .curveEaseIn, animations: {
                    self.guideImage?.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                }, completion: { (finished) in
                    if finished {
                        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn, animations: {
                            self.guideImage?.transform = .identity
                        })
                    }
                })
                
                let motionManager = CMMotionManager()
                motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
                if motionManager.isDeviceMotionAvailable {
                    motionManager.startDeviceMotionUpdates(using: CMAttitudeReferenceFrame.xArbitraryZVertical, to: OperationQueue.main, withHandler: { (devMotion, error) -> Void in
                        let degree = min(max((motionManager.deviceMotion?.attitude.pitch)! * 180 / Double.pi, 40),90)
                        rotateViewVertical(view: self.phoneImage!, angle: 90-CGFloat(degree))
                        if degree > 70 {
                            print("vertical")
                            motionManager.stopDeviceMotionUpdates()
                            rotateViewVertical(view: self.phoneImage!, angle:0)
                            self.isHorizontal = true
                            if self.isHorizontal && self.isTrackingReady {
                                self.stages = .moveLeft
                            }
                        }
                })}
                
            case .moveLeft:
                self.phoneImage?.image = #imageLiteral(resourceName: "phone")
                self.guideImage?.image = #imageLiteral(resourceName: "left")
                self.phoneImage?.backgroundColor = UIColor(white: 0, alpha: 0)
                self.guideImage?.layer.mask?.contents = (self.phoneImage?.backgroundColor)!
                subHeading?.changeTextAnimated(text: "Please pan with your phone to the left")
                //playSoundEffect(name: "effect-interaction-success")
                playHapticImpact()
                let motionManager = CMMotionManager()
                motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
                if motionManager.isDeviceMotionAvailable {
                    motionManager.startDeviceMotionUpdates(using: CMAttitudeReferenceFrame.xArbitraryZVertical, to: OperationQueue.main, withHandler: { (devMotion, error) -> Void in
                        let degree = min(max(-60, (motionManager.deviceMotion?.attitude.yaw)!  * 180 / Double.pi),60)
                        rotateViewHorizontal(view: self.phoneImage!, angle: CGFloat(degree))
                        self.phoneImage?.frame = CGRect(origin: CGPoint(x:(self.imageViewsFrame?.origin.x)!+(-1.6)*CGFloat(degree),y:(self.imageViewsFrame?.origin.y)!), size: (self.imageViewsFrame?.size)!)
                        if degree > 45 {
                            self.stages = .moveRight
                        }
                        if degree < -45 && self.stages == .moveRight{
                            //done
                            motionManager.stopDeviceMotionUpdates()
                            self.stages = .doneCalibration
                        }
                        
                    })}

            case .moveRight:()
            playHapticImpact()
                //playSoundEffect(name: "effect-interaction-success")
                self.guideImage?.image = #imageLiteral(resourceName: "right")
                subHeading?.changeTextAnimated(text: "Now to the right")

            case .doneCalibration:()
                playHapticSuccess()
                //playSoundEffect(name: "effect-reward-answer-correct")
                heading?.changeTextAnimated(text: "DONE")
                subHeading?.text = ""
                guideImage?.changeImageAnimated(image: #imageLiteral(resourceName: "done"))
                phoneImage?.image = nil
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapHandle(_:)))
                self.addGestureRecognizer(tapGesture)
                Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(removeSelfAnimated), userInfo: nil, repeats: false)
            }
        }
    }
    
    @objc func tapHandle(_ recognizer:UITapGestureRecognizer){
       removeSelfAnimated()
    }
    
    @objc func removeSelfAnimated(){
        UIView.setAnimationCurve(.easeIn)
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 0
            self.containerView?.transform = CGAffineTransform(scaleX: 0.4, y: 0.8)
        }) { (finished) in
            if finished {
                self.removeFromSuperview()
                self.calibrationDone?(true)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        containerView = UIView(frame: CGRect(x:0,y:self.frame.size.height/4,width:self.frame.size.width,height:self.frame.size.width*0.66))
        self.addSubview(containerView!)
        self.backgroundColor = UIColor(white: 0, alpha: 0.5)
        imageViewsFrame = CGRect(x:0,y:0,width:self.frame.size.width, height:(containerView?.frame.size.height)!*0.66)
        guideImage = UIImageView(frame: imageViewsFrame!)
        phoneImage = UIImageView(frame:imageViewsFrame!)
        phoneImage?.contentMode = .scaleAspectFit
        guideImage?.contentMode = .scaleAspectFit
        
        containerView?.addSubview(guideImage!)
        containerView?.addSubview(phoneImage!)
        
        heading = UILabel(frame: CGRect(x: 0, y: (containerView?.frame.size.height)!*0.66, width: self.frame.size.width, height: (containerView?.frame.size.height)!*0.33/2))
        heading?.textAlignment = .center
        heading?.textColor = UIColor.white
        heading?.font = UIFont(name: "Montserrat-Bold", size: 20)
        containerView?.addSubview(heading!)
        
        subHeading = UILabel(frame: CGRect(x: self.center.x-self.frame.size.width*0.33, y: (containerView?.frame.size.height)!*0.66+((containerView?.frame.size.height)!*0.33/2), width: self.frame.size.width*0.66, height: (containerView?.frame.size.height)!*0.33/2))
        subHeading?.textAlignment = .center
        subHeading?.textColor = UIColor.white
        subHeading?.font = UIFont(name: "Montserrat-Regular", size: 16)
        subHeading?.numberOfLines = 2
        containerView?.addSubview(subHeading!)
        
        NotificationCenter.default.addObserver(self, selector: #selector(arTracking(_:)), name: NSNotification.Name(rawValue: "arTrackingReady"), object: nil)
        
        startAnimation()
    }
    
    @objc func arTracking(_ notification:NSNotification){
        isTrackingReady = true
        if isTrackingReady && isHorizontal {
            stages = .moveLeft
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func startAnimation(){
        stages = .holdVertical
    }
   
}

private func rotateViewHorizontal(view:UIView, angle:CGFloat)  {
    let layer = view.layer
    var rotationAndPerspectiveTransform = CATransform3DIdentity
    rotationAndPerspectiveTransform.m34 = 1.0 / -500;
    rotationAndPerspectiveTransform = CATransform3DRotate(rotationAndPerspectiveTransform, angle * CGFloat.pi / 180.0, 0.0, 1.0, 0.0);
    layer.transform = rotationAndPerspectiveTransform;
}

private func rotateViewVertical(view:UIView, angle:CGFloat)  {
    let layer = view.layer
    var rotationAndPerspectiveTransform = CATransform3DIdentity
    rotationAndPerspectiveTransform.m34 = 1.0 / -500;
    rotationAndPerspectiveTransform = CATransform3DRotate(rotationAndPerspectiveTransform, angle * CGFloat.pi / 180.0, 1.0, 0.0, 0.0);
    layer.transform = rotationAndPerspectiveTransform;
}



extension UILabel {
    func changeTextAnimated(text:String){
        UIView.setAnimationCurve(.easeIn)
        UIView.animate(withDuration: 0.2, animations: {
            self.transform = CGAffineTransform(scaleX: 0.4, y: 0.8)
            self.alpha = 0.5
            
        }) { (finished) in
            if finished {
                self.text = text
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
                    self.alpha = 1
                    self.transform = .identity
                }, completion:nil)
            }
        }
    }
}

extension UIImageView {
    func changeImageAnimated(image:UIImage){
        UIView.setAnimationCurve(.easeIn)
        UIView.animate(withDuration: 0.2, animations: {
            self.transform = CGAffineTransform(scaleX: 0.4, y: 0.8)
            self.alpha = 0.5
            
        }) { (finished) in
            if finished {
                self.image = image
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
                    self.alpha = 1
                    self.transform = .identity
                }, completion:nil)
            }
        }
    }
}
