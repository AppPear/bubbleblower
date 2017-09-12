//
//  soapBubble.swift
//  soapBubble
//
//  Created by Samu András on 2017. 09. 03..
//  Copyright © 2017. Samu András. All rights reserved.
//

import Foundation
import ARKit

class Bubble: SCNNode {
    
    override init() {
        super.init()
        let bubble = SCNPlane(width: 0.25, height: 0.25)
        let material = SCNMaterial()
        material.diffuse.contents = #imageLiteral(resourceName: "bubbleText")
        material.isDoubleSided = true
        material.blendMode = .screen
        bubble.materials = [material]
        self.geometry = bubble
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
