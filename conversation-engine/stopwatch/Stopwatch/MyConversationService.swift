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
import Foundation
import googleapis

let Host = "conversation.googleapis.com"
let ProjectName = "hello-86"
let AgentName = "hello-86"
let SessionID = "001"
let TokenProviderURL = "http://localhost:8080"
let SampleRate = 16000

typealias MyConversationCompletionHandler =
  (StreamingDetectIntentResponse?, NSError?) -> (Void)

class MyConversationService {
  var sampleRate: Int = SampleRate
  private var streaming = false

  private var client : ConversationService!
  private var writer : GRXBufferedPipe!
  private var call : GRPCProtoCall!

  private var token : String!

  static let sharedInstance = MyConversationService()

  func authorization() -> String {
    if let token = self.token {
      return "Bearer " + self.token
    } else {
      return "No token was "
    }
  }
  
  func fetchToken(_ completion:@escaping ()->()) {
    let request : URLRequest = URLRequest(url:URL(string:TokenProviderURL)!)
    let task = URLSession.shared.dataTask(with:request) {
      (data, response, error) in
      if let data = data {
        let values = try! JSONSerialization.jsonObject(with: data) as! [String:Any]
        let token = values["access_token"] as! String
        self.token = token
        completion()
      } else {
        completion()
      }
    }
    task.resume()
  }

  func streamAudioData(_ audioData: NSData, completion: @escaping MyConversationCompletionHandler) {
    if (!streaming) {
      // if we aren't already streaming, set up a gRPC connection
      client = ConversationService(host:Host)
      writer = GRXBufferedPipe()
      call = client.rpcToStreamingDetectIntent(
        withRequestsWriter: writer,
        eventHandler: { (done, response, error) in
          completion(response, error as? NSError)
      })
      // authenticate using an authorization token (obtained using OAuth)
      call.requestHeaders.setObject(NSString(string:self.authorization()),
                                    forKey:NSString(string:"Authorization"))
      call.start()
      streaming = true

      // send an initial request message to configure the service
      let queryParams = StreamingQueryParameters()
      queryParams.session = "projects/" + ProjectName +
        "/agents/" + AgentName +
        "/sessions/" + SessionID

      let queryInput = StreamingQueryInput()
      let audioConfig = StreamingInputAudioConfig()
      let inputAudioConfig = InputAudioConfig()
      inputAudioConfig.audioEncoding = AudioEncoding(rawValue:1)!
      inputAudioConfig.languageCode = "en-US"
      inputAudioConfig.sampleRateHertz = Int32(sampleRate)
      audioConfig.config = inputAudioConfig
      audioConfig.singleUtterance = true
      queryInput.audioConfig = audioConfig

      let streamingRecognizeRequest = StreamingDetectIntentRequest()
      streamingRecognizeRequest.queryParams = queryParams
      streamingRecognizeRequest.queryInput = queryInput
      writer.writeValue(streamingRecognizeRequest)
    }

    // send a request message containing the audio data
    let streamingRecognizeRequest = StreamingDetectIntentRequest()
    streamingRecognizeRequest.inputAudio = audioData as Data
    writer.writeValue(streamingRecognizeRequest)
  }

  func stopStreaming() {
    if (!streaming) {
      return
    }
    writer.finishWithError(nil)
    streaming = false
  }
  
  func isStreaming() -> Bool {
    return streaming
  }
}

