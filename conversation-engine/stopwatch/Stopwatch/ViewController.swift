//
// Copyright 2017 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
import UIKit
import AVFoundation
import googleapis

class ViewController : UIViewController, AudioControllerDelegate {
  @IBOutlet weak var textView: UITextView!
  @IBOutlet weak var button: UIButton!
  var audioData: NSMutableData!
  var listening: Bool = false

  override func viewDidLoad() {
    super.viewDidLoad()
    self.button.isEnabled = false
    AudioController.sharedInstance.delegate = self
    MyConversationService.sharedInstance.fetchToken {
      DispatchQueue.main.async { [unowned self] in
        self.button.isEnabled = true
      }
    }
  }

  @IBAction func buttonPressed(_ sender: NSObject) {
    if !listening {
      self.startListening()
    } else {
      self.stopListening()
    }
  }

  @IBAction func startListening() {
    listening = true
    button.setTitle("Listening... (Stop)", for: .normal)
    let audioSession = AVAudioSession.sharedInstance()
    do {
      try audioSession.setCategory(AVAudioSessionCategoryRecord)
    } catch {

    }
    audioData = NSMutableData()
    _ = AudioController.sharedInstance.prepare(specifiedSampleRate: SampleRate)

    MyConversationService.sharedInstance.sampleRate = SampleRate
    _ = AudioController.sharedInstance.start()
  }

  func stopListening() {
    _ = AudioController.sharedInstance.stop()
    MyConversationService.sharedInstance.stopStreaming()
    button.setTitle("Start Listening", for: .normal)
    listening = false
  }

  func processSampleData(_ data: Data) -> Void {
    audioData.append(data)

    // We recommend sending samples in 100ms chunks
    let chunkSize : Int /* bytes/chunk */ =
      Int(0.1 /* seconds/chunk */
        * Double(SampleRate) /* samples/second */
        * 2 /* bytes/sample */);

    if (audioData.length > chunkSize) {
      MyConversationService.sharedInstance.streamAudioData(
        audioData,
        completion: { [weak self] (response, error) in
          guard let strongSelf = self else {
            return
          }
          if let error = error {
            strongSelf.textView.text = error.localizedDescription
          } else if let response = response {
            print(response)
            if let recognitionResult = response.recognitionResult {
              if recognitionResult.isFinal {
                strongSelf.stopListening()
              }
            }
            strongSelf.textView.text = "\(response)"
          }
      })
      self.audioData = NSMutableData()
    }
  }
}
