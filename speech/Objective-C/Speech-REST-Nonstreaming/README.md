# Cloud Speech Nonstreaming REST Objective-C Sample

This app demonstrates how to make nonstreaming REST connections to the [Cloud Speech API](https://cloud.google.com/speech/) to recognize speech in recorded audio.

## Prerequisites
- An iOS API key for the Cloud Speech API (See
  [the docs][getting-started] to learn more)
- An OSX machine or emulator
- [Xcode 8][xcode]

## Quickstart
- Clone this repo and `cd` into this directory.
- In `Speech/ViewController.m`, replace `YOUR_API_KEY` with the API key obtained above.
- Open the project by running `open Speech.xcodeproj`.
- Build and run the app.


## Running the app

- As with all Google Cloud APIs, every call to the Speech API must be associated
  with a project within the [Google Cloud Console][cloud-console] that has the
  Speech API enabled. This is described in more detail in the [getting started
  doc][getting-started], but in brief:
  - Create a project (or use an existing one) in the [Cloud
    Console][cloud-console]
  - [Enable billing][billing] and the [Speech API][enable-speech].
  - Create an iOS [API key][api-key], and save this for later.

- Clone this repository on GitHub. If you have [`git`][git] installed, you can do this by executing the following command:

        $ git clone https://github.com/GoogleCloudPlatform/ios-docs-samples.git

    This will download the repository of samples into the directory
    `ios-docs-samples`.

- `cd` into this directory in the repository you just cloned, and run the command `open Speech.xcodeproj` to open this project in Xcode.

- In Xcode's Project Navigator, open the `ViewController.m` file within the `Speech` directory.

- Find the line where the `API_KEY` is set. Replace the string value with the iOS API key obtained from the Cloud console above. This key is the credential used to authenticate all requests to the Speech API. Calls to the API are thus associated with the project you created above, for access and billing purposes.

- You are now ready to build and run the project. In Xcode you can do this by clicking the 'Play' button in the top left. This will launch the app on the simulator or on the device you've selected.

- Click the `Begin Recording` button. This uses an AVAudioRecorder instance to record audio to a file in the app's Documents directory.

- Say a few words, and then tap the `Stop Recording/Playing` button. If you'd like to hear the audio you just recorded, tap the button labeled `Play Recorded Audio`.

- Press the `Process Recorded Audio` button. This causes the `processAudio:` method to construct an HTTP request which it sends to the Speech API endpoint. Notice the options passed as query parameters and in the Content-Type header. When the API call returns, the results are displayed in the scrollable text area at the bottom of the screen.

[getting-started]: https://cloud.google.com/speech/docs/getting-started
[cloud-console]: https://console.cloud.google.com
[git]: https://git-scm.com/
[xcode]: https://developer.apple.com/xcode/
[billing]: https://console.cloud.google.com/billing?project=_
[enable-speech]: https://console.cloud.google.com/apis/api/speech.googleapis.com/overview?project=_
[api-key]: https://console.cloud.google.com/apis/credentials?project=_

