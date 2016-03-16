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

#import "GCPNSObject+HTTPHelpers.h"

#import <wctype.h>

static char int_to_char[] = "0123456789ABCDEF";

@implementation NSString (GCP_HTTPHelpers)

- (NSString *) gcp_URLEncodedString
{
    NSMutableString *result = [NSMutableString string];
    int i = 0;
    const char *source = [self cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned long max = strlen(source);
    while (i < max) {
        unsigned char c = source[i++];
        if (c == ' ') {
            [result appendString:@"%20"];
        }
        else if (iswalpha(c) || iswdigit(c) || (c == '-') || (c == '.') || (c == '_') || (c == '~')) {
            [result appendFormat:@"%c", c];
        }
        else {
            [result appendString:[NSString stringWithFormat:@"%%%c%c", int_to_char[(c/16)%16], int_to_char[c%16]]];
        }
    }
    return result;
}

@end

@implementation NSDictionary (GCP_HTTPHelpers)

- (NSString *) gcp_URLQueryString
{
    NSMutableString *result = [NSMutableString string];
    NSEnumerator *keyEnumerator = [[[self allKeys] sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];
    id key;
    while ((key = [keyEnumerator nextObject])) {
        id value = [self objectForKey:key];
        if (![value isKindOfClass:[NSString class]]) {
            if ([value respondsToSelector:@selector(stringValue)]) {
                value = [value stringValue];
            }
        }
        if ([value isKindOfClass:[NSString class]]) {
            if ([result length] > 0) [result appendString:@"&"];
            [result appendString:[NSString stringWithFormat:@"%@=%@",
                                  [key gcp_URLEncodedString],
                                  [value gcp_URLEncodedString]]];
        }
    }
    return [NSString stringWithString:result];
}

@end

