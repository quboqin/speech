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
//

#import "SpeechRecognitionService.h"

#import "google/cloud/speech/v1/CloudSpeech.pbrpc.h"
#import <GRPCClient/GRPCCall.h>
#import <RxLibrary/GRXBufferedPipe.h>
#import <ProtoRPC/ProtoRPC.h>

#define APIKEY @"AIzaSyAagYqOIxz8X-hkodBKb7DSZFa3ol47P_8"
#define APICLIENT @"com.google.talk-200"
#define HOST @"speech.googleapis.com"

@interface SpeechRecognitionService ()

@property (nonatomic, assign) BOOL streaming;
@property (nonatomic, strong) Speech *client;
@property (nonatomic, strong) GRXBufferedPipe *writer;
@property (nonatomic, strong) ProtoRPC *call;

@end

@implementation SpeechRecognitionService

+ (instancetype) sharedInstance {
  static SpeechRecognitionService *instance = nil;
  if (!instance) {
    instance = [[self alloc] init];
  }
  return instance;
}

- (void) streamAudioData:(NSData *) audioData
          withCompletion:(SpeechRecognitionCompletionHandler)completion {

  RecognizeRequest *request = [RecognizeRequest message];

  if (!_streaming) {
    _client = [[Speech alloc] initWithHost:HOST];
    _writer = [[GRXBufferedPipe alloc] init];
    _call = [_client RPCToRecognizeWithRequestsWriter:_writer
                                         eventHandler:^(BOOL done, RecognizeResponse *response, NSError *error) {
                                           NSLog(@"RESPONSE RECEIVED");
                                           if (error) {
                                             NSLog(@"ERROR: %@", error);
                                           } else {
                                             NSLog(@"RESPONSE");
                                             for (SpeechRecognitionResult *result in response.resultsArray) {
                                               NSLog(@"RESULT");
                                               for (SpeechRecognitionAlternative *alternative in result.alternativesArray) {
                                                 NSLog(@"ALTERNATIVE %0.4f %@",
                                                       alternative.confidence,
                                                       alternative.transcript);
                                               }
                                             }
                                             completion(response);
                                           }
                                         }];
    _call.requestHeaders[@"X-Goog-Api-Key"] = APIKEY;
    NSLog(@"HEADERS: %@", _call.requestHeaders);
    [_call start];

    _streaming = YES;

    InitialRecognizeRequest *initialRecognizeRequest = [InitialRecognizeRequest message];
    initialRecognizeRequest.encoding = InitialRecognizeRequest_AudioEncoding_Linear16;
    initialRecognizeRequest.sampleRate = 8000;
    initialRecognizeRequest.languageCode = @"en-US";
    initialRecognizeRequest.maxAlternatives = 30;
    request.initialRequest = initialRecognizeRequest;
  }

  AudioRequest *audioRequest = [AudioRequest message];
  audioRequest.content = audioData;
  request.audioRequest = audioRequest;

  [_writer writeValue:request];
}

- (void) stopStreamingWithCompletion:(SpeechRecognitionCompletionHandler)completion {
  [_writer finishWithError:nil];
  _streaming = NO;
  completion(nil);
}

- (BOOL) isStreaming {
  return _streaming;
}

@end
