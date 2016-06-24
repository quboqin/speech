// Copyright 2016 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import stickynote

let hostAddress = "localhost"
let useSSL = false

class StickyNotesViewController: UIViewController, UITextFieldDelegate {
  @IBOutlet weak var imageView: UIImageView?
  @IBOutlet weak var textField: UITextField?
  @IBOutlet weak var streamSwitch: UISwitch?
  var addressWithPort: String?
  var updateCall: ProtoRPC?
  var writer: GRXBufferedPipe?
  var client: StickyNote?

  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = UIColor.darkGray()
    self.configureNetworking()
  }

  func configureNetworking() {
    if (!useSSL) {
      self.addressWithPort = hostAddress + ":8080"
      // This tells the GRPC library to NOT use SSL.
      GRPCCall.useInsecureConnections(forHost: self.addressWithPort)
    } else {
      self.addressWithPort = hostAddress + ":443"
      // This tells the GRPC library to trust a certificate that it might not be able to validate.
      // Typically this would be used to trust a self-signed certificate.
      let certificateFilePath = Bundle.main().pathForResource("ssl", ofType: "crt")
      GRPCCall.useTestCertsPath(certificateFilePath, testName: "example.com", forHost: hostAddress)
    }
    self.client = StickyNote.init(host: self.addressWithPort!)
  }

  @IBAction func textFieldDidEndEditing(_ textField: UITextField) {
    self.getStickynote(message: textField.text!)
  }

  func handleStickynoteResponse(response: StickyNoteResponse!, error: NSError!) {
      if (error != nil) {
        self.imageView!.backgroundColor = UIColor.red()
        self.imageView!.image = nil;
      } else if (response != nil) {
        self.imageView!.image = UIImage(data: response!.image);
      }
  }

  func getStickynote(message: String) {
    let request = StickyNoteRequest.init()
    request.message = message
    let call = self.client?.rpcToGet(with: request, handler: { (response, error) in
      self.handleStickynoteResponse(response: response, error: error)
    })
    call!.start()
  }

  // [START openStreamingConnection]
  func openStreamingConnection() {
    self.writer = GRXBufferedPipe()
    self.updateCall = self.client?.rpcToUpdate(withRequestsWriter: self.writer!, eventHandler: { (done, response, error) in
      self.handleStickynoteResponse(response: response, error: error)
    })
    self.updateCall!.start()
  }
  // [END openStreamingConnection]

  func closeStreamingConnection() {
    self.writer!.writesFinishedWithError(nil)
  }

  // [START textDidChange]
  @IBAction func textDidChange(textField: UITextField) {
    if (self.streamSwitch!.isOn) {
      let request = StickyNoteRequest()
      request.message = textField.text
      self.writer!.writeValue(request)
    }
  }
  // [END textDidChange]

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return false
  }

  @IBAction func switchValueDidChange(`switch`: UISwitch) {
    if (`switch`.isOn) {
      self.openStreamingConnection()
    } else {
      self.closeStreamingConnection()
    }
  }

  override func preferredStatusBarStyle() -> UIStatusBarStyle {
   return .lightContent
  }
}
