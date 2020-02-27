//
//  ViewController.swift
//  AR
//
//  Created by Yuhao Zhong on 27.02.20.
//  Copyright © 2020 Yuhao Zhong. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var mapAction = false
    
    @IBOutlet var mapButton: UIButton!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        sceneView.delegate = self
        
        sceneView.autoenablesDefaultLighting = true
        
    }
    
    @IBAction func showMap(_ sender: Any) {
        
        mapAction = !mapAction
        
        let scene = SCNScene(named: "art.scnassets/map.scn")
                    
        guard let node = scene?.rootNode.childNode(withName: "map", recursively: false) else { return }
        
        if mapAction {
        
            sceneView.scene.rootNode.addChildNode(node)
                        
        } else {
            
            sceneView.scene.rootNode.enumerateChildNodes { (node, _) in node.removeFromParentNode() }
        }
    }
    
        
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Confirm the device support AR feature
        guard ARWorldTrackingConfiguration.isSupported else {
            return
            // Inform the user that the device is not supported for AR expierence
        }
        
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
    
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
