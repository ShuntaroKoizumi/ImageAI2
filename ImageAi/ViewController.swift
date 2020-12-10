//
//  ViewController.swift
//  ImageAi
//
//  Created by 小泉竣太郎 on 2020/06/27.
//  Copyright © 2020 shuntaro. All rights reserved.
//

import UIKit
import NYXImagesKit
import CoreML
import Vision
import AVFoundation

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    @IBOutlet var photoDisplayImageView: UIImageView!
    @IBOutlet var infoTextView: UITextView!
    
    var imagePicker: UIImagePickerController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
    }

    @IBAction func readPhoto() {
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    @IBAction func takePhoto() {
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let resizedImage = (info[.originalImage] as? UIImage)?.scale(byFactor: 0.1)
        
        photoDisplayImageView.image = resizedImage
        picker.dismiss(animated: true, completion: nil)
        imageInference(image: resizedImage!)
    }
    
    //画像推定
    func imageInference(image: UIImage) {
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else {
            fatalError("モデルをロードできません")
        }
        let request = VNCoreMLRequest(model: model) {
            [weak self] request, error in
            guard let results = request.results as? [VNClassificationObservation], let firstResult = results.first else {
                fatalError("判定をできません")
            }
            
            DispatchQueue.main.async {
                self!.infoTextView.text = "Accuracy = \(Int(firstResult.confidence * 100))%, \n\n Detail: \(firstResult.identifier)"
                
                //音声読み上げ
                let utterWords = AVSpeechUtterance(string: (self?.infoTextView.text)!)
                utterWords.voice = AVSpeechSynthesisVoice(language: "en-us")
                let synthesizer = AVSpeechSynthesizer()
                synthesizer.speak(utterWords)
            }
        }
        
        guard let ciImage = CIImage(image: image) else {
            fatalError("画像を変換できません")
        }
        
        let imageHandler = VNImageRequestHandler(ciImage: ciImage)
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try imageHandler.perform([request])
            } catch {
                print("error\(error)")
            }
        }
    }
}

