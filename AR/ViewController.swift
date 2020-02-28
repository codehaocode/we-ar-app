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
    var playAction = false
    var hoopAdded = false
    
    
    @IBOutlet var mapButton: UIButton!
    @IBOutlet var playButton: UIButton!
    
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
            
//            let rotate = simd_float4x4(SCNMatrix4MakeRotation(sceneView.session.currentFrame!.camera.eulerAngles.y, 0, 1, 0))
            guard let frame = self.sceneView.session.currentFrame else { return }
            

            print("Show Map")
            node.eulerAngles.y = frame.camera.eulerAngles.y
            sceneView.scene.rootNode.addChildNode(node)
            
        } else {
            
            sceneView.scene.rootNode.enumerateChildNodes { (node, _) in node.removeFromParentNode() }
            print("Hide Map")
            
        }
    }
    
    @IBAction func playMode(_ sender: Any) {
        
        playAction = !playAction
        
        if playAction {
            print("It's time to play")
        } else {
            sceneView.scene.rootNode.enumerateChildNodes { (node, _) in node.removeFromParentNode() }
            hoopAdded = false
            print("Game Over")
            
            
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
        
        configuration.planeDetection = [.horizontal, .vertical]
        sceneView.session.run(configuration)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    
    
    @IBAction func screenTapped(_ sender: UITapGestureRecognizer) {
        
        if mapAction {
            
            let touchLocation = sender.location(in: sceneView)
            let hitTestResult = sceneView.hitTest(touchLocation)
            if let result = hitTestResult.first {
                //            addTouchEffect(result: <#T##ARHitTestResult#>, anchor: <#T##ARAnchor#>)
                print(result)
                startNavigation()
            }
        }
        
        guard playAction else {return}
        
        if !hoopAdded {
            let touchLocation = sender.location(in: sceneView)
            let hitTestResult = sceneView.hitTest(touchLocation, types: [.existingPlaneUsingExtent])
            if let result = hitTestResult.first, let planeAnchor = result.anchor as? ARPlaneAnchor {
                addHoop(result: result, planeAnchor: planeAnchor)
                hoopAdded = true
            }
        }
        else { createBasketball()
            
        }
        
        
        
    }
    func createBasketball() {
        
        guard let currentFrame = sceneView.session.currentFrame else { return }
        
        let ball  = SCNNode(geometry: SCNSphere(radius: 0.25))
        ball.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "art.scnassets/Basketball.jpg")
        
        let cameraTransform = SCNMatrix4(currentFrame.camera.transform)
        ball.transform = cameraTransform
        
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ball, options: [SCNPhysicsShape.Option.collisionMargin : 0.01]))
        ball.physicsBody = physicsBody
        
        let power = Float(10.0)
        let force = SCNVector3(-cameraTransform.m31*power, -cameraTransform.m32*power, -cameraTransform.m33*power)
        
        ball.physicsBody?.applyForce(force, asImpulse: true)
        
        sceneView.scene.rootNode.addChildNode(ball)
    }
    
    
    
    
    func addTouchEffect(result:ARHitTestResult, anchor: ARAnchor) {
        print("Touch Effect")
    }
    
    func startNavigation() {
        print("start navigation")
    }
    
    
    func createWall(planeAnchor: ARPlaneAnchor) -> SCNNode{
        let node = SCNNode()
        
        let geometry = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        
        node.geometry = geometry
        
        node.eulerAngles.x = -.pi/2
        node.opacity = 0.25
        print("find wall")
        
        return node
    }
    
    
    
    
    func addHoop(result: ARHitTestResult, planeAnchor: ARPlaneAnchor) {
        let hoopScene = SCNScene(named: "art.scnassets/hoop.scn")
        
        guard let hoopNode = hoopScene?.rootNode.childNode(withName: "Hoop", recursively: false) else {
            return
        }
        
        let planePosition = result.worldTransform.columns.3
        hoopNode.position = SCNVector3(planePosition.x, planePosition.y, planePosition.z)
        
        guard let anchoredNode = sceneView.node(for: planeAnchor) else {return}
        let anchorNodeOrientation = anchoredNode.worldOrientation
        hoopNode.eulerAngles.y = .pi * anchorNodeOrientation.y
        
        hoopNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: hoopNode, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
        
        sceneView.scene.rootNode.addChildNode(hoopNode)

    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard playAction, !hoopAdded else {return}
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            return
        }
        
        let wall = createWall(planeAnchor: planeAnchor)
        node.addChildNode(wall)
        wall.runAction(waitRemoveAction)
        
        print("find Wall")
        
    }
    
    var waitRemoveAction: SCNAction {
        return .sequence([.wait(duration: 2.0), .fadeOut(duration: 2.0), .removeFromParentNode()])
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard playAction else { return }
        guard let planeAnchor = anchor as? ARPlaneAnchor, let planeNode = node.childNodes.first, let plane = planeNode.geometry as? SCNPlane else {return}
        
        planeNode.position = SCNVector3(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z)
        plane.width = CGFloat(planeAnchor.extent.x)
        plane.height = CGFloat(planeAnchor.extent.z)
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
