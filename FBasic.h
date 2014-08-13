//
//  FacebookService.h
//  fb_bi
//
//  Created by paul on 8/13/14.
//  Copyright (c) 2014 paul. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ACAccount;

static NSString *kIDKey             = @"id";
static NSString *kEmailKey          = @"email";
static NSString *kNameKey           = @"name";
static NSString *kFirstNameKey      = @"first_name";
static NSString *kLastNameKey       = @"last_name";
static NSString *kGenderKey         = @"gender";
static NSString *kLinkKey           = @"link";
static NSString *kLocaleKey         = @"locale";
static NSString *kTimezoneKey       = @"timezone";
static NSString *kUpdatedTimeKey    = @"updated_time";
static NSString *kVerifiedKey       = @"verified";

@interface FBasic : NSObject
+ (void)requestProfile:(void (^)(NSArray *accounts, void (^pickedAccount)(ACAccount *)))accountPick success:(void (^)(NSDictionary *))success failure:(void (^)(NSString *))failure;
+ (void)shareImage:(UIImage *)image URL:(NSURL *)url text:(NSString *)text success:(void (^)())success failure:(void (^)(NSString *))failure;
@end
