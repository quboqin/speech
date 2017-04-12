//
// Copyright 2016 Google Inc. All Rights Reserved.
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

#import <AVFoundation/AVFoundation.h>

#import "ViewController.h"

#define API_KEY @"YOUR_API_KEY"

#define SAMPLE_RATE 16000

@interface ViewController () <AVAudioRecorderDelegate, AVAudioPlayerDelegate>

@property (nonatomic, strong) IBOutlet UITextView *textView;

@property (strong, nonatomic) AVAudioRecorder *audioRecorder;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;

@end

@implementation ViewController

- (NSString *) soundFilePath {
  NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *docsDir = dirPaths[0];
  return [docsDir stringByAppendingPathComponent:@"sound.caf"];
}

- (void)viewDidLoad {
  [super viewDidLoad];

  NSURL *soundFileURL = [NSURL fileURLWithPath:[self soundFilePath]];
  NSDictionary *recordSettings = @{AVEncoderAudioQualityKey:@(AVAudioQualityMax),
                                   AVEncoderBitRateKey: @16,
                                   AVNumberOfChannelsKey: @1,
                                   AVSampleRateKey: @(SAMPLE_RATE)};
  NSError *error;
  _audioRecorder = [[AVAudioRecorder alloc]
                    initWithURL:soundFileURL
                    settings:recordSettings
                    error:&error];
  if (error) {
    NSLog(@"error: %@", error.localizedDescription);
  }
}

- (IBAction)recordAudio:(id)sender {
  [self stopAudio:sender];
  AVAudioSession *audioSession = [AVAudioSession sharedInstance];
  [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
  [_audioRecorder record];
}

- (IBAction)playAudio:(id)sender {
  [self stopAudio:sender];
  AVAudioSession *audioSession = [AVAudioSession sharedInstance];
  [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
  NSError *error;
  _audioPlayer = [[AVAudioPlayer alloc]
                  initWithContentsOfURL:_audioRecorder.url
                  error:&error];
  _audioPlayer.delegate = self;
  _audioPlayer.volume = 1.0;
  if (error)
    NSLog(@"Error: %@",
          error.localizedDescription);
  else
    [_audioPlayer play];
}

- (IBAction)stopAudio:(id)sender {
  if (_audioRecorder.recording) {
    [_audioRecorder stop];
  } else if (_audioPlayer.playing) {
    [_audioPlayer stop];
  }
}

- (IBAction) processAudio:(id) sender {
  [self stopAudio:sender];

  NSString *service = @"https://speech.googleapis.com/v1/speech:recognize";
  service = [service stringByAppendingString:@"?key="];
  service = [service stringByAppendingString:API_KEY];

  NSData *audioData = [NSData dataWithContentsOfFile:[self soundFilePath]];
  NSDictionary *configRequest = @{@"encoding":@"LINEAR16",
                                  @"sampleRateHertz":@(SAMPLE_RATE),
                                  @"languageCode":@"en-US",
                                  @"maxAlternatives":@30};
  NSDictionary *audioRequest = @{@"content":[audioData base64EncodedStringWithOptions:0]};
  NSDictionary *requestDictionary = @{@"config":configRequest,
                                      @"audio":audioRequest};
  NSError *error;
  NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestDictionary
                                                        options:0
                                                          error:&error];

  NSString *path = service;
  NSURL *URL = [NSURL URLWithString:path];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
  // if your API key has a bundle ID restriction, specify the bundle ID like this:
  [request addValue:[[NSBundle mainBundle] bundleIdentifier] forHTTPHeaderField:@"X-Ios-Bundle-Identifier"];
  NSString *contentType = @"application/json";
  [request addValue:contentType forHTTPHeaderField:@"Content-Type"];
  [request setHTTPBody:requestData];
  [request setHTTPMethod:@"POST"];

  NSURLSessionTask *task =
  [[NSURLSession sharedSession]
   dataTaskWithRequest:request
   completionHandler:
   ^(NSData *data, NSURLResponse *response, NSError *error) {
     dispatch_async(dispatch_get_main_queue(),
                    ^{
                      NSString *stringResult = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                      _textView.text = stringResult;
                      NSLog(@"RESULT: %@", stringResult);
                    });
   }];
  [task resume];
}

@end
