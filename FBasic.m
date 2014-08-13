//
//  FacebookService.m
//  fb_bi
//
//  Created by paul on 8/13/14.
//  Copyright (c) 2014 paul. All rights reserved.
//
#import <Accounts/Accounts.h>
#import <Social/Social.h>

#import "FBasic.h"

static NSString *kErrorServiceNotAvailable     = @"Facebook service is not available";
static NSString *kErrorSetupAccount            = @"Please setup Facebook account in Settings > Facebook";
static NSString *kErrorRenewalFailed           = @"Facebook auth renewal failed";
static NSString *kErrorNoAccountSpecified      = @"No account were specified";
static NSString *kErrorPostCancelled           = @"Post Canceled";

@interface FBasic ()
{
    ACAccountStore *_accountStore;
}
@end

@implementation FBasic

+ (FBasic *)defaultFacebookService
{
    static FBasic *_defaultFacebookService = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultFacebookService = [[FBasic alloc] init];
    });
    return _defaultFacebookService;
}

- (ACAccountStore *)accountStore
{
    if(!_accountStore){
        _accountStore = [[ACAccountStore alloc] init];
    };
    return _accountStore;
}

+ (void)requestProfile:(void (^)(NSArray *accounts, void (^pickedAccount)(ACAccount *)))accountPick success:(void (^)(NSDictionary *))success failure:(void (^)(NSString *))failure {

    if (![SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
        if (failure) {
            failure(kErrorServiceNotAvailable);
        }
        return;
    }
    
    ACAccountStore *accountStore = [self defaultFacebookService].accountStore;
    
    ACAccountType *facebookAccountType = [accountStore
                                          accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *appID = [infoDict objectForKey:@"FacebookAppID"];
    assert(appID);
    
    NSDictionary *options = @{
                              ACFacebookAppIdKey: appID,
                              ACFacebookPermissionsKey: @[@"email"],
                              ACFacebookAudienceKey: ACFacebookAudienceEveryone
                              };
    [accountStore requestAccessToAccountsWithType:facebookAccountType
                                          options:options completion:^(BOOL granted, NSError *e) {

                                              if (granted) {
                                                  NSArray *accounts = [accountStore
                                                                       accountsWithAccountType:facebookAccountType];
                                                  if (accountPick && accounts.count > 1) {
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          accountPick(accounts, ^(ACAccount *pickedAccount){
                                                              [self requestProfileDetailsForAccount:pickedAccount success:success failure:failure];
                                                          });
                                                      });
                                                  } else {
                                                      ACAccount *pickedAccount = [accounts firstObject];
                                                      [self requestProfileDetailsForAccount:pickedAccount success:success failure:failure];
                                                  }
                                                  
                                              } else {
                                                  if (failure) {
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          failure(kErrorSetupAccount);
                                                      });
                                                  }
                                                  return;
                                              }
                                          }];
}

+ (void)renewAccount:(ACAccount *)account success:(void (^)())success failure:(void (^)(NSString *))failure
{
    [[[self defaultFacebookService] accountStore] renewCredentialsForAccount:account completion:^(ACAccountCredentialRenewResult renewResult, NSError *error) {
        if (ACAccountCredentialRenewResultRenewed == renewResult) {
            if (success) {
                    success();
            }
        } else {
            if (failure) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failure(error.localizedDescription ? : kErrorRenewalFailed);
                });
            }
        }
    }];
}

+ (void)requestProfileDetailsForAccount:(ACAccount *)account success:(void (^)(NSDictionary *))success failure:(void (^)(NSString *))failure;
{
    if (!account) {
        if (failure) {
            failure(kErrorNoAccountSpecified);
        }
        return;
    }
    NSURL *profileURL = [NSURL URLWithString:@"https://graph.facebook.com/me"];
    
    SLRequest *profileRequest = [SLRequest
                                 requestForServiceType:SLServiceTypeFacebook
                                 requestMethod:SLRequestMethodGET
                                 URL:profileURL
                                 parameters:nil];
    
    profileRequest.account = account;
    
    [profileRequest performRequestWithHandler:^(NSData *responseData,
                                                NSHTTPURLResponse *urlResponse, NSError *error) {
        NSError *parsingError = nil;
        NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&parsingError];
        
        NSDictionary *errorDict = jsonObject[@"error"];
        
        if (parsingError || errorDict) {
            int errorCode = [[errorDict valueForKey:@"code"] intValue];
            if (190 == errorCode) {
                //190 is code that you need to renew credentials.  this is when tokens expire.  so, if it happens, it goes to renew code (not included in this question as it is working fine)
                [self renewAccount:account success:^{
                    [self requestProfileDetailsForAccount:account success:success failure:failure];
                } failure:failure];
            } else if (failure) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failure(errorDict[@"message"] ? : parsingError.localizedDescription);
                });
                return;
            }
        }
        if (success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                success(jsonObject);
            });
        }
    }];
}

+ (void)shareImage:(UIImage *)image URL:(NSURL *)url text:(NSString *)text success:(void (^)())success failure:(void (^)(NSString *))failure
{
    if (![SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
        if (failure) {
            failure(kErrorServiceNotAvailable);
        }
        return;
    }
    
    SLComposeViewController *mySLComposerSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
    
    if (text) [mySLComposerSheet setInitialText:text];
    if (image) [mySLComposerSheet addImage:image];
    if (url) [mySLComposerSheet addURL:url];
    
    [mySLComposerSheet setCompletionHandler:^(SLComposeViewControllerResult result) {
        switch (result) {
            case SLComposeViewControllerResultCancelled:
                if (failure) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        failure(kErrorPostCancelled);
                    });
                }
                break;
            case SLComposeViewControllerResultDone:
                if (success) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        success();
                    });
                }
                break;
        }
    }];
    
    [[self topMostController] presentViewController:mySLComposerSheet animated:YES completion:nil];

}

+ (UIViewController *)topMostController
{
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}

@end
