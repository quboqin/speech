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

#import "google/cloud/speech/v1beta1/CloudSpeech.pbrpc.h"
#import <GRPCClient/GRPCCall.h>
#import <ProtoRPC/ProtoRPC.h>

#define API_KEY @"YOUR_API_KEY"

@implementation SpeechRecognitionService

+ (instancetype) sharedInstance {
  static SpeechRecognitionService *instance = nil;
  if (!instance) {
    instance = [[self alloc] init];
  }
  return instance;
}

- (void) processAudioData:(NSData *) audioData
           withCompletion:(SpeechRecognitionCompletionHandler)completion {

  static NSString * const kHostAddress = @"speech.googleapis.com";

  RecognitionConfig *recognitionConfig = [RecognitionConfig message];
  recognitionConfig.encoding = RecognitionConfig_AudioEncoding_Linear16;
  recognitionConfig.sampleRate = 16000;
  recognitionConfig.languageCode = @"en-US";
  recognitionConfig.maxAlternatives = 30;

  RecognitionAudio *recognitionAudio = [RecognitionAudio message];
  recognitionAudio.content = audioData;

  SyncRecognizeRequest *request = [SyncRecognizeRequest message];
  request.config = recognitionConfig;
  request.audio = recognitionAudio;

  Speech *client = [[Speech alloc] initWithHost:kHostAddress];

  GRPCProtoCall *call = [client RPCToSyncRecognizeWithRequest:request
                                                         handler:
                    ^(SyncRecognizeResponse *response, NSError *error) {
                      NSLog(@"RESPONSE RECEIVED %@", response);
                      if (error) {
                        NSLog(@"ERROR: %@", error);
                        completion([error description]);
                      } else {
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

  call.requestHeaders[@"X-Goog-Api-Key"] = API_KEY;
  NSLog(@"HEADERS: %@", call.requestHeaders);
  [call start];
}

@end
