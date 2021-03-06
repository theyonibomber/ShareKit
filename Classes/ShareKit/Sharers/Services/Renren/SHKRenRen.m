//
//  SHKRenRen.m
//  ShareKit
//
//  Created by icyleaf on 11-11-15.
//  Copyright (c) 2011 icyleaf.com. All rights reserved.
//

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
//
//

#import "SHKRenRen.h"
#import "SHKConfiguration.h"
#import "NSMutableDictionary+NSNullsToEmptyStrings.h"

static NSString *const kSHKRenRenUserInfo = @"kSHKRenRenUserInfo";

@implementation SHKRenRen
@synthesize renren = _renren;


static SHKRenRen *sharedRenRen = nil;

+ (SHKRenRen *)sharedSHKRenren 
{
    if ( ! sharedRenRen) 
    {
        sharedRenRen = [[SHKRenRen alloc] init];
    }
    
    return sharedRenRen;
}

- (id)init
{
	if ((self = [super init]))
	{		
        _renren = [Renren sharedRenren];
	}
    
	return self;
}


#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return @"人人网";
}

+ (BOOL)canShareURL
{
	return YES;
}

+ (BOOL)canShareText
{
	return YES;
}

+ (BOOL)canShareImage
{
	return YES;
}

+ (BOOL)canGetUserInfo
{
    return YES;
}


#pragma mark -
#pragma mark Configuration : Dynamic Enable

- (BOOL)shouldAutoShare
{
	return self.item.shareType == SHKShareTypeUserInfo;
}


#pragma mark -
#pragma mark Authentication

- (BOOL)isAuthorized
{	
	return [_renren isSessionValid];
}

- (void)promptAuthorization
{
    NSArray *permissions = [NSArray arrayWithObjects:@"status_update", @"photo_upload", nil];
    [_renren authorizationWithPermisson:permissions andDelegate:self];
}

+ (void)logout
{
    [[Renren sharedRenren] logout:[SHKRenRen sharedSHKRenren]];
}

#pragma mark -
#pragma mark UI Implementation

- (void)show
{
    if (self.item.shareType == SHKShareTypeURL)
	{
        [self.item setCustomValue:[self.item.URL.absoluteString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                      forKey:@"status"];
        
		[self showRenRenForm];
	}
    
    else if (self.item.shareType == SHKShareTypeImage)
	{
		[self showRenRenPublishPhotoDialog];
	}
	
	else if (self.item.shareType == SHKShareTypeText)
	{
        [self.item setCustomValue:self.item.text forKey:@"status"];
		[self showRenRenForm];
	}
}

- (void)showRenRenForm
{
	SHKFormControllerLargeTextField *rootView = [[SHKFormControllerLargeTextField alloc] initWithNibName:nil 
                                                                                                  bundle:nil 
                                                                                                delegate:self];	
	
	rootView.text = [self.item customValueForKey:@"status"];
	rootView.maxTextLength = 140;
	rootView.image = self.item.image;
	rootView.imageTextLength = 25;
	
	self.navigationBar.tintColor = SHKCONFIG_WITH_ARGUMENT(barTintForView:,self);
	
	[self pushViewController:rootView animated:NO];
	[rootView release];
	
	[[SHK currentHelper] showViewController:self];	
}

- (void)sendForm:(SHKFormControllerLargeTextField *)form
{	
	[self.item setCustomValue:form.textView.text forKey:@"status"];
	[self tryToSend];
}

- (void)showRenRenPublishPhotoDialog
{
    [_renren publishPhotoSimplyWithImage:self.item.image
                                     caption:self.item.title];
}


#pragma mark -
#pragma mark Share API Methods

- (BOOL)validateItem
{
	if (self.item.shareType == SHKShareTypeUserInfo) {
		return YES;
	}
	
	NSString *status = [self.item customValueForKey:@"status"];
	return status != nil;
}

- (BOOL)validateItemAfterUserEdit 
{
	BOOL result = NO;
	
	BOOL isValid = [self validateItem];    
	NSString *status = [self.item customValueForKey:@"status"];
	
	if (isValid && status.length <= 140) {
		result = YES;
	}
	
    return result;
}	

- (BOOL)send
{
	if ( ! [self validateItemAfterUserEdit])
		return NO;
	
	else
	{	
		if (self.item.shareType == SHKShareTypeImage)
        {
			[self showRenRenPublishPhotoDialog];
		}
        else if (self.item.shareType == SHKShareTypeUserInfo)
        {
            ROUserInfoRequestParam *param = [[ROUserInfoRequestParam alloc] init];
            [_renren getUsersInfo:param andDelegate:self];

            // make sure we don't die before response arrives
            [self retain];

            [param release];
        }
        else 
        {
			NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:10];
            [params setObject:@"status.set" forKey:@"method"];
            [params setObject:[self.item customValueForKey:@"status"] forKey:@"status"];
            [_renren requestWithParams:params andDelegate:self];
		}
		
		// Notify delegate
		[self sendDidStart];	
		
		return YES;
	}
}

#pragma mark - RenrenDelegate methods

-(void)renrenDidLogin:(Renren *)renren
{
    [self authDidFinish:YES];
    [self show];
}

- (void)renren:(Renren *)renren loginFailWithError:(ROError*)error
{
    [self authDidFinish:NO];
}

- (void)renren:(Renren *)renren requestDidReturnResponse:(ROResponse*)response
{
    // user info
    if ([response.rootObject isKindOfClass:[NSArray class]])
    {
        if ([(NSArray *)response.rootObject count] == 0)
        {
            [self sendDidFailWithError:nil];
            return;
        }
        ROUserResponseItem *responseItem = [(NSArray *)response.rootObject objectAtIndex:0];
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[responseItem responseDictionary]];
        [userInfo convertNSNullsToEmptyStrings];

        [[NSUserDefaults standardUserDefaults] setObject:userInfo forKey:kSHKRenRenUserInfo];
        [self sendDidFinish];

        // see [self send]
        [self release];
    }
    else
    {
        NSDictionary* params = (NSDictionary *)response.rootObject;
        if (params != nil && [params objectForKey:@"result"] != nil && [[params objectForKey:@"result"] intValue] == 1)
        {
            [self sendDidFinish];
        }
        else
        {
            [self sendDidFailWithError:[SHK error:SHKLocalizedString([params objectForKey:@"error_msg"])]];
        }
    }
}

- (void)renren:(Renren *)renren requestFailWithError:(ROError*)error
{ 
    [self sendDidFailWithError:[SHK error:SHKLocalizedString([error localizedDescription])]];
}

@end
