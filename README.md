FBasic
==============

System Requirements
--------------
iOS 6+

Installation
--------------
Add Social.framework.  
Drag FBasic.h and .m to your project.  
Add in project settings > Info your FacebookAppID.  

Usage
--------------

```objective-c
#import "FBasic.h"
#import <Accounts/Accounts.h>

[FBasic requestProfile:^(NSArray *accounts, void (^pickedAccount)(ACAccount *)) {
        pickedAccount([accounts lastObject]);
} success:^(NSDictionary *profile) {
	NSLog(@"%@", profile[kNameKey]);
} failure:^(NSString *error) {
	
}];
    
[FBasic shareImage:nil URL:nil text:@"Добро побеждает зло." success:^{
	
} failure:^(NSString *e) {
	
}];
```