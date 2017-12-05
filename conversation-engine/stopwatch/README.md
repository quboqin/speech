# Dialogflow Sample

This app demonstrates how to make streaming gRPC connections to the [Dialogflow API](https://cloud.google.com/dialogflow-enterprise/) to recognize commands in recorded audio.

## Prerequisites
- Credentials for calling the Dialogflow API
- An OSX machine or emulator
- [Xcode 9.1][xcode] or later
- [Cocoapods][cocoapods] version 1.0 or later

## Prepare your Google Cloud account
As with all Google Cloud APIs, every call to the Dialogflow API must be associated
  with a project within the [Google Cloud Console][cloud-console] that has the
  API enabled. In brief:
  - Create a project (or use an existing one) in the [Cloud Console][cloud-console]
  - [Enable billing][billing].

## Enable Dialogflow
If you have not already done so, [enable Dialogflow for your project](https://cloud.google.com/dialogflow-enterprise/docs/quickstart). Scripts related to the quickstart are in the SETUP-SERVICE directory.

## Running the app
- In the [Google Cloud Console](https://console.cloud.google.com), use the APIs&Services->Library menu item to find and enable the Dialogflow API.
- Also using the Credentials item in the Google Cloud Console, create a Service Account key. Use the popup to create a key for a "New service account", name it "stopwatch" (this is arbitrary), and give it the role of `Dialogflow API Admin`. Choose a key type of "JSON" and press the "Create" button to download a key file. As a convenience, rename this file to `credentials.json`.
- Clone this repository and `cd` into this directory.
- Copy your `credentials.json` over the skeletal version in this directory. It is used by the scripts in `SETUP_SERVICE` and by the sample application. 
- Be sure that you have gone through the steps in the [Dialogflow quickstart](https://cloud.google.com/dialogflow-enterprise/docs/quickstart) to create and configure your stopwatch agent. Helper scripts for this are in the `SETUP_SERVICE` directory.
- Run ./INSTALL-COCOAPODS to install app dependencies. When it finishes, it will open the Stopwatch workspace in Xcode. Since we are using Cocoapods, be sure to open the workspace and not Stopwatch.xcodeproj.
- Replace `your-project-identifier` in `StopwatchService.swift` with the identifier of your Google Cloud project.
- You are now ready to build and run the project. In Xcode you can do this by clicking the 'Play' button in the top left. This will launch the app on the simulator or on the device you've selected. Be sure that the 'Stopwatch' target is selected in the popup near the top left of the Xcode window. 
- Tap the `Start Listening` button. This uses a custom AudioController class to capture audio in an in-memory instance of NSMutableData. When this data reaches a certain size, it is sent to the StopwatchService class, which streams it to the Dialogflow API. Packets are streamed as instances of the DFStreamingDetectIntentRequest object. The first DFStreamingDetectIntentRequest object sent includes configuration information and subsequent DFStreamingDetectIntentRequest objects contain audio packets. 
- Say a few words and wait for the display to update when your speech is recognized.
- Tap the button to stop capturing audio, or if audio capture has stopped because your speech was recognized, tap it again to start a new listening session.

[cloud-console]: https://console.cloud.google.com
[git]: https://git-scm.com/
[xcode]: https://developer.apple.com/xcode/
[billing]: https://console.cloud.google.com/billing?project=_
[cocoapods]: https://cocoapods.org/

