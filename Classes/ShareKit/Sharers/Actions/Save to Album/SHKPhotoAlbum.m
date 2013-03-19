//
//  SHKPhotoAlbum.m
//  ShareKit
//
//  Created by Richard Johnson on 7/22/10.

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

#import "SHKPhotoAlbum.h"


@implementation SHKPhotoAlbum

#pragma mark -
#pragma mark Configuration : Service Definition

+ (NSString *)sharerTitle
{
	return SHKLocalizedString(@"Save to Photo Album");
}

+ (BOOL)canShareImage
{
	return YES;
}

+ (BOOL)canShareVideo
{
	NSString *tempPath = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"sharekit_temp_video.m4v"];
	if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(tempPath)) {
		return YES;
	}

	return NO;
}

+ (BOOL)shareRequiresInternetConnection
{
	return NO;
}

+ (BOOL)requiresAuthentication
{
	return NO;
}


#pragma mark -
#pragma mark Configuration : Dynamic Enable

- (BOOL)shouldAutoShare
{
	return YES;
}


#pragma mark -
#pragma mark Share API Methods

- (void)sendCompleted
{
	// Notify delegate, but quietly
	self.quiet = YES;
	[self sendDidFinish];
}

- (BOOL)send
{	
	if (self.item.shareType == SHKShareTypeImage)
		[self writeImageToAlbum];
	else if (self.item.shareType == SHKShareTypeVideo) {
		[self writeVideoToAlbum];
	}
    // Notify user
    [[SHKActivityIndicator currentIndicator] displayCompleted:SHKLocalizedString(@"Saved!")];

    // Notify delegate, but quietly
    self.quiet = YES;
    [self sendDidFinish];

    return YES;
}

- (void) writeImageToAlbum
{
	UIImageWriteToSavedPhotosAlbum(self.item.image, nil, nil, nil);
}

- (void) writeVideoToAlbum
{
	NSString *tempPath = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"sharekit_temp_video.m4v"];
	if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(tempPath)) {
		UISaveVideoAtPathToSavedPhotosAlbum (tempPath, nil, nil, nil);
	}
}


@end
