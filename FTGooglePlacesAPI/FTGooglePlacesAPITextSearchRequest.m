//
//  FTGooglePlacesAPITextSearchRequest.m
//
//  Created by Lukas Kukacka on 10/30/13.
//
//
//  The MIT License (MIT)
//
//  Copyright (c) 2013 Fuerte Int. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "FTGooglePlacesAPITextSearchRequest.h"

static const NSUInteger kMaxRadius = 50000;

@implementation FTGooglePlacesAPITextSearchRequest

#pragma Lifecycle

- (instancetype)initWithQuery:(NSString *)query
{
    self =  [super init];
    if(self)
    {
        //  Validate query
        if ([query length] == 0) {
            NSLog(@"WARNING: %s: Search query is empty, returning nil", __PRETTY_FUNCTION__);
            return nil;
        }
        
        _query = query;
        
        //  Default values
        _radius = kMaxRadius+1; // Indicate "no value" by overflowing max radius value
        _locationCoordinate = CLLocationCoordinate2DMake(10000, 10000); // Default is invalid value
        
        //  Try to determine default language as a currently active language
        //  from the NSUserDefaults
        //  See https://developer.apple.com/library/ios/documentation/MacOSX/Conceptual/BPInternational/Articles/ChoosingLocalizations.html
        //  Current language is cached so we have to always check agains NSUserDefaults
        //  Language should never change while the app is running, so it should be ok
        static NSString *CurrentAppLanguage = nil;
        if (!CurrentAppLanguage) {
            NSArray* languages = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"];
            if ([languages count] > 0) {
                CurrentAppLanguage = languages[0];
            }
        }
        
        _language = CurrentAppLanguage;
    }
    return self;
}

#pragma mark - Accessors

- (void)setRadius:(NSUInteger)radius
{
    [self willChangeValueForKey:@"radius"];
    
    //  Validate radius
    _radius = radius;
    if (_radius > kMaxRadius) {
        NSLog(@"WARNING: %s: Radius %dm is too big. Maximum radius is %dm, using maximum", __PRETTY_FUNCTION__, radius, kMaxRadius);
        _radius = kMaxRadius;
    }
    
    [self didChangeValueForKey:@"radius"];
}

#pragma mark - Superclass overrides

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p> %@", [self class], self, [self placesAPIRequestParams]];
}

#pragma mark - FTGooglePlacesAPIRequest protocol

- (NSString *)requestTypeUrlString
{
    return @"textsearch";
}

- (NSDictionary *)placesAPIRequestParams
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    if(_query) {
        params[@"query"] = _query;
    }
    
    //  Required parameters
    if (CLLocationCoordinate2DIsValid(_locationCoordinate)) {
        params[@"location"] = [NSString stringWithFormat:@"%.7f,%.7f", _locationCoordinate.latitude, _locationCoordinate.longitude];
    }
    
    //  Radius is optional for text search
    if (_radius <= kMaxRadius) {
        params[@"radius"] = [NSString stringWithFormat:@"%d", _radius];
    }
    
    //  Optional parameters
    if (_language) {
        params[@"language"] = _language;
    };
    
    if (_openNow) {
        params[@"opennow"] = [NSNull null];
    }
    
    if ([_types count] > 0) {
        params[@"types"] = [_types componentsJoinedByString:@"|"];
    }
    
    return [params copy];
}

@end