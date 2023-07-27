//
//  ViewController.swift
//  VideoPlayer
//
//  Created by Krishna Mangalarapu on 7/23/23.
//

import UIKit
import RealityKit
import AVKit
import ARKit

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // start plane detection on load.
        startPlaneDetection()
        
        // tap recognize on screen
        arView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:  ))))

    }
    
    @objc
    func handleTap(recognizer: UITapGestureRecognizer) {
        let tapLocation = recognizer.location(in: arView)
        
        // rayCast -> from 2d coordinate to get corresponding 3d point in real world.
        let results = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal)
        
        if let firstResult = results.first {
            // 3d x, y, z coords.
            let worldPosition = firstResult.worldTransform.columns.3
            let position3D = SIMD3<Float>(worldPosition.x, worldPosition.y, worldPosition.z)
    
            // place screen
            let videoScreen =  createVideoScreen(width: 0.4, height: 0.2)
            videoScreen.setPosition(SIMD3(x: 0, y: 0.2/2, z: 0), relativeTo: videoScreen)
            placeScreen(screen: videoScreen, worldPosition: position3D)
            
            // enable gestures
            installGestures(on: videoScreen)
        }
        
    }
    
    func placeScreen(screen: ModelEntity, worldPosition: SIMD3<Float>) {
        // Anchor
        let anchorEntity = AnchorEntity(world: worldPosition)
    
        // Tie Model to Anchor
        anchorEntity.addChild(screen)
        
        // Anchor to scene
        arView.scene.addAnchor(anchorEntity)
    }
    
    func startPlaneDetection() {
        arView.automaticallyConfigureSession = true
        let configuration = ARWorldTrackingConfiguration()
        
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        
        arView.session.run(configuration)
        
    }
    
    func createVideoScreen(width: Float, height: Float) -> ModelEntity {
        // Mesh
        let screenMesh = MeshResource.generatePlane(width: width, height: height)
        
        // URL and Video Item
        let url = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4"
        let videoItem = createVideoItem(with: url)
        
        // Video Material
        let player = AVPlayer()
        let videoMaterial = VideoMaterial(avPlayer: player)
        player.replaceCurrentItem(with: videoItem!)
        player.play()
        
        // VideoMaterial Entity
        let videoMaterialEntity = ModelEntity(mesh: screenMesh, materials: [videoMaterial])
        return videoMaterialEntity
    }
    
    func createVideoItem(with urlString: String) -> AVPlayerItem? {
        guard let url = URL(string: urlString) else {return nil}
        
        // video item
        let asset = AVAsset(url: url)
        let videoItem = AVPlayerItem(asset: asset)
        
        return videoItem
    }
    
    func installGestures(on model: ModelEntity) {
        model.generateCollisionShapes(recursive: true)
        arView.installGestures([.rotation, .scale], for: model)
    }
}
