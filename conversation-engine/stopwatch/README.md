# Cloud Conversation Engine Sample

This app demonstrates how to make streaming gRPC connections to the [Cloud Conversation Engine](https://cloud.google.com/cce/) to recognize speech in recorded audio.

## Prerequisites
- An API key for the Cloud Conversation Engine API (See
  [the docs][getting-started] to learn more)
- An OSX machine or emulator
- [Xcode 8][xcode] or later
- [Cocoapods][cocoapods] version 1.0 or later

## Quickstart
- Clone this repo and `cd` into this directory.
- Set up your Cloud Conversation Agent using the instructions in the SETUP-SERVICE directory.
- Run `./INSTALL-COCOAPODS`
- Build and run the token provider in ../token-provider.
- Build and run the app.

## Running the app

- As with all Google Cloud APIs, every call to the Cloud Conversation Engine API must be associated
  with a project within the [Google Cloud Console][cloud-console] that has the
  API enabled. This is described in more detail in the [getting started
  doc][getting-started], but in brief:
  - Create a project (or use an existing one) in the [Cloud
    Console][cloud-console]
  - [Enable billing][billing] and the Cloud Conversation API.

- Clone this repository on GitHub. If you have [`git`][git] installed, you can do this by executing the following command:

        $ git clone https://github.com/GoogleCloudPlatform/ios-docs-samples.git

    This will download the repository of samples into the directory
    `ios-docs-samples`.

- `cd` into this directory in the repository you just cloned, and run the command `pod install` to prepare all Cocoapods-related dependencies.

- `open Stopwatch.xcworkspace` to open this project in Xcode. Since we are using Cocoapods, be sure to open the workspace and not Stopwatch.xcodeproj.

- You are now ready to build and run the project. In Xcode you can do this by clicking the 'Play' button in the top left. This will launch the app on the simulator or on the device you've selected. Be sure that the 'Speech' target is selected in the popup near the top left of the Xcode window. 

- Tap the `Start Listening` button. This uses a custom AudioController class to capture audio in an in-memory instance of NSMutableData. When this data reaches a certain size, it is sent to the SpeechRecognitionService class, which streams it to the conversation service. Packets are streamed as instances of the RecognizeRequest object, and the first RecognizeRequest object sent also includes configuration information in an instance of InitialRecognizeRequest. As it runs, the AudioController logs the number of samples and average sample magnitude for each packet that it captures.

- Say a few words and wait for the display to update when your speech is recognized.

- Tap the button to stop capturing audio and close your gRPC connection.

[cloud-console]: https://console.cloud.google.com
[git]: https://git-scm.com/
[xcode]: https://developer.apple.com/xcode/
[billing]: https://console.cloud.google.com/billing?project=_
[cocoapods]: https://cocoapods.org/
[gRPC Objective-C setup]: https://github.com/grpc/grpc/tree/master/src/objective-c

