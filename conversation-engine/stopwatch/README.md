# Cloud Conversation Engine Sample

This app demonstrates how to make streaming gRPC connections to the [Cloud Conversation Engine](https://cloud.google.com/cce/) to recognize speech in recorded audio.

## Prerequisites
- Credentials for calling the Cloud Conversation Engine API
- An OSX machine or emulator
- [Xcode 8][xcode] or later
- [Cocoapods][cocoapods] version 1.0 or later
- A local [Go][golang] installation.

## Prepare your Google Cloud account
As with all Google Cloud APIs, every call to the Cloud Conversation Engine API must be associated
  with a project within the [Google Cloud Console][cloud-console] that has the
  API enabled. In brief:
  - Create a project (or use an existing one) in the [Cloud Console][cloud-console]
  - [Enable billing][billing].

## Enable Cloud Conversation Engine
If you have not already done so, [enable Cloud Conversation Engine for your project](https://cloud.google.com/conversation/docs/quickstart). Scripts related to the quickstart are in the SETUP-SERVICE directory.

## Running the app
- In the [Google Cloud Console](https://console.cloud.google.com), use the APIs&Services->Library menu item to find and enable the Cloud Conversation Engine API.
- Also using the Credentials item in the Google Cloud Console, create a Service Account key. Use the popup to create a key for a "New service account", name it "conversations" (this is arbitrary), and give it the role of Project Owner. Choose a key type of "JSON" and press the "Create" button to download a key file. As a convenience, rename this file to `credentials.json`.
- Clone this repo and `cd` into this directory.
- Copy your credentials.json file into the token-provider directory and build and run token-provider (This step requires Go). After entering the directory, run `go run main.go -serve &`. This will start a lightweight server on your Mac that will obtain and serve OAuth tokens to the sample app using your Service Account key.
- Run ./INSTALL-COCOAPODS to install app dependencies. When it finishes, it will open the Stopwatch workspace in Xcode. Since we are using Cocoapods, be sure to open the workspace and not Stopwatch.xcodeproj.
- You are now ready to build and run the project. In Xcode you can do this by clicking the 'Play' button in the top left. This will launch the app on the simulator or on the device you've selected. Be sure that the 'Stopwatch' target is selected in the popup near the top left of the Xcode window. 
- Tap the `Start Listening` button. This uses a custom AudioController class to capture audio in an in-memory instance of NSMutableData. When this data reaches a certain size, it is sent to the SpeechRecognitionService class, which streams it to the conversation service. Packets are streamed as instances of the RecognizeRequest object, and the first RecognizeRequest object sent also includes configuration information in an instance of InitialRecognizeRequest. 
- Say a few words and wait for the display to update when your speech is recognized.
- Tap the button to stop capturing audio, or if audio capture has stopped because your speech was recognized, tap it again to start a new listening session.

[cloud-console]: https://console.cloud.google.com
[git]: https://git-scm.com/
[xcode]: https://developer.apple.com/xcode/
[billing]: https://console.cloud.google.com/billing?project=_
[cocoapods]: https://cocoapods.org/
[gRPC Objective-C setup]: https://github.com/grpc/grpc/tree/master/src/objective-c
[golang]: https://golang.org

