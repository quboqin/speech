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

#import "StickyNotesViewController.h"

#import "stickynote/Stickynote.pbobjc.h"
#import "stickynote/Stickynote.pbrpc.h"

#import <GRPCClient/GRPCCall.h>
#import <GRPCClient/GRPCCall+Tests.h> // this allows us to disable TLS
#import <RxLibrary/GRXBufferedPipe.h>

#import <ProtoRPC/ProtoRPC.h>

// [START host]
static NSString * const kHostAddress = @"localhost";
// [END host]
// = @"<IP Address>"; // GCE instance
// = @"<IP Address>"; // L4 load balancer

static BOOL useSSL = YES;

@interface StickyNotesViewController () <UITextFieldDelegate>
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet UITextField *textField;
@property (nonatomic, strong) IBOutlet UISwitch *streamSwitch;

@property (nonatomic, strong) NSString *addressWithPort;

@property (nonatomic, strong) StickyNote *client;
@property (nonatomic, strong) ProtoRPC *updateCall;
@property (nonatomic, strong) GRXBufferedPipe *writer;

@end

@implementation StickyNotesViewController

- (void) viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor darkGrayColor];

  [self configureNetworking];
}

- (void) configureNetworking {
  if (!useSSL) {
    _addressWithPort = [kHostAddress stringByAppendingString:@":8080"];
    // This tells the GRPC library to NOT use SSL.
    [GRPCCall useInsecureConnectionsForHost:_addressWithPort];
  } else {
    _addressWithPort = [kHostAddress stringByAppendingString:@":443"];
    // This tells the GRPC library to trust a certificate that it might not be able to validate.
    // Typically this would be used to trust a self-signed certificate.
    [GRPCCall useTestCertsPath:[[NSBundle mainBundle] pathForResource:@"ssl" ofType:@"crt"]
                      testName:@"example.com"
                       forHost:kHostAddress
     ];
  }
  _client = [[StickyNote alloc] initWithHost:_addressWithPort];
}

- (void) getStickynoteWithMessage:(NSString *) message {
  StickyNoteRequest *request = [StickyNoteRequest message];
  request.message = message;
  ProtoRPC *call = [_client RPCToGetWithRequest:request
                                       handler:
                    ^(StickyNoteResponse *response, NSError *error) {
                      [self handleStickynoteResponse:response andError:error];
                    }];
  [call start];
}

// [START openStreamingConnection]
- (void) openStreamingConnection {
  _writer = [[GRXBufferedPipe alloc] init];
  _updateCall = [_client RPCToUpdateWithRequestsWriter:_writer
                                          eventHandler:^(BOOL done, StickyNoteResponse *response, NSError *error) {
                                            [self handleStickynoteResponse:response andError:error];
                                          }];
  [_updateCall start];
}
// [END openStreamingConnection]

- (void) closeStreamingConnection {
  [_writer writesFinishedWithError:nil];
}

- (void) handleStickynoteResponse:(StickyNoteResponse *)response andError:(NSError *) error {
  if (error) {
    self.imageView.backgroundColor = [UIColor redColor];
    self.imageView.image = nil;
    NSLog(@"ERROR: %@", error);
  } else if (response.image) {
    NSData *imageData = response.image;
    UIImage *image = [UIImage imageWithData:imageData];
    self.imageView.image = image;
  }
}

- (IBAction) textFieldDidEndEditing:(UITextField *)textField
{
  [self getStickynoteWithMessage:textField.text];
}

// [START textDidChange]
- (IBAction)textDidChange:(UITextField *) sender {
  if ([_streamSwitch isOn]) {
    StickyNoteRequest *request = [StickyNoteRequest message];
    request.message = sender.text;
    [_writer writeValue:request];
  }
}
// [END textDidChange]

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  return NO;
}

- (IBAction) switchValueDidChange:(UISwitch *) sender {
  if ([sender isOn]) {
    [self openStreamingConnection];
  } else {
    [self closeStreamingConnection];
  }
}

- (UIStatusBarStyle) preferredStatusBarStyle {
  return UIStatusBarStyleLightContent;
}

@end
