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

#import <GRPCClient/GRPCCall.h>
#import <RxLibrary/GRXBufferedPipe.h>
#import <ProtoRPC/ProtoRPC.h>

#define API_KEY @"YOUR_API_KEY"
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
    instance.sampleRate = 16000.0; // default value
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
                                           completion(response, error);
                                         }];
    _call.requestHeaders[@"X-Goog-Api-Key"] = API_KEY;
    NSLog(@"HEADERS: %@", _call.requestHeaders);
    [_call start];

    _streaming = YES;

    InitialRecognizeRequest *initialRecognizeRequest = [InitialRecognizeRequest message];
    initialRecognizeRequest.encoding = InitialRecognizeRequest_AudioEncoding_Linear16;
    initialRecognizeRequest.sampleRate = self.sampleRate;
    initialRecognizeRequest.languageCode = @"en-US";
    initialRecognizeRequest.maxAlternatives = 30;
    initialRecognizeRequest.continuous = YES;
    initialRecognizeRequest.interimResults = YES;
    initialRecognizeRequest.enableEndpointerEvents = YES;
    request.initialRequest = initialRecognizeRequest;
  }

  AudioRequest *audioRequest = [AudioRequest message];
  audioRequest.content = audioData;
  request.audioRequest = audioRequest;

  [_writer writeValue:request];
}

- (void) stopStreaming {
  if (!_streaming) {
    return;
  }
  [_writer finishWithError:nil];
  _streaming = NO;
}

- (BOOL) isStreaming {
  return _streaming;
}

@end
