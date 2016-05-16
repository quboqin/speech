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

@implementation NSString (NSString_Extended)

- (NSString *)urlencode {
  NSMutableString *output = [NSMutableString string];
  const unsigned char *source = (const unsigned char *)[self UTF8String];
  NSInteger sourceLen = strlen((const char *)source);
  for (int i = 0; i < sourceLen; ++i) {
    const unsigned char thisChar = source[i];
    if (thisChar == ' '){
      [output appendString:@"+"];
    } else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' ||
               (thisChar >= 'a' && thisChar <= 'z') ||
               (thisChar >= 'A' && thisChar <= 'Z') ||
               (thisChar >= '0' && thisChar <= '9')) {
      [output appendFormat:@"%c", thisChar];
    } else {
      [output appendFormat:@"%%%02X", thisChar];
    }
  }
  return output;
}

@end

// [START host]
static NSString * const kHostAddress = @"localhost:8080";
// [END host]

@interface StickyNotesViewController () <UITextFieldDelegate>
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet UITextField *textField;

@property (nonatomic, strong) NSMutableURLRequest *request;
@property (nonatomic, strong) NSURLSessionDataTask *task;
@end

@implementation StickyNotesViewController

// [START textFieldDidEndEditing]
- (IBAction) textFieldDidEndEditing:(UITextField *)textField
{
  NSString *queryString = [NSString stringWithFormat:@"http://%@/stickynote?message=%@",
                           kHostAddress,
                           [textField.text urlencode]];
  NSURL *URL = [NSURL URLWithString:queryString];
  _request = [NSMutableURLRequest requestWithURL:URL];

  NSURLSession *session = [NSURLSession sharedSession];
  _task = [session dataTaskWithRequest:_request
                     completionHandler:
           ^(NSData *data, NSURLResponse *response, NSError *error) {
             UIImage *image = [UIImage imageWithData:data];
             dispatch_async(dispatch_get_main_queue(), ^{
                              self.imageView.image = image;
                            });
           }];
  [_task resume];
}
// [END textFieldDidEndEditing]

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  return NO;
}

- (UIStatusBarStyle) preferredStatusBarStyle {
  return UIStatusBarStyleLightContent;
}

@end
