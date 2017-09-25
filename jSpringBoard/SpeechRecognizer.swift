//
//  SpeechRecognizer.swift
//  jSpringBoard
//
//  Created by Jota Melo on 20/08/17.
//  Copyright © 2017 jota. All rights reserved.
//

import Foundation
import Speech

class SpeechRecognizer {
    static let shared = SpeechRecognizer()
    
    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer()
    private let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
    private var speechRecognitionTask: SFSpeechRecognitionTask?
    
    func authorize(callback: @escaping () -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            if status == .authorized {
                DispatchQueue.main.async {
                    callback()
                }
            }
        }
    }
    
    func startRecognition(callback: @escaping (String) -> Void) {
        self.audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: self.audioEngine.inputNode.outputFormat(forBus: 0)) { buffer, time in
            self.recognitionRequest.append(buffer)
        }
        self.audioEngine.prepare()
        try? self.audioEngine.start()
        
        self.speechRecognitionTask = self.speechRecognizer?.recognitionTask(with: self.recognitionRequest, resultHandler: { result, error in
            guard let result = result else { return }
            DispatchQueue.main.async {
                callback(result.bestTranscription.formattedString)
            }
        })
    }
    
    func stopRecognition() {
        self.audioEngine.stop()
        self.audioEngine.inputNode.removeTap(onBus: 0)
        self.speechRecognitionTask?.cancel()
        self.speechRecognitionTask = nil
    }
}
