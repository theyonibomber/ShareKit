//
//  SHKItem.h
//  ShareKit
//
//  Created by Nathan Weiner on 6/18/10.

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

#import <Foundation/Foundation.h>

extern NSString * const SHKAttachmentSaveDir;

typedef enum 
{
	SHKShareTypeUndefined,
	SHKShareTypeURL,
	SHKShareTypeText,
	SHKShareTypeImage,
	SHKShareTypeVideo,
	SHKShareTypeFile,
    SHKShareTypeUserInfo
} SHKShareType;

typedef enum 
{
    SHKURLContentTypeUndefined,
    SHKURLContentTypeWebpage,
    SHKURLContentTypeAudio,
    SHKURLContentTypeVideo,
    SHKURLContentTypeImage,
} SHKURLContentType;

@interface SHKItem : NSObject

@property (nonatomic) SHKShareType shareType;

@property (nonatomic, retain)	NSURL *URL;
@property (nonatomic) SHKURLContentType URLContentType;

@property (nonatomic, retain)	UIImage *image;

@property (nonatomic, retain)	NSString *title;
@property (nonatomic, retain)	NSString *text;
@property (nonatomic, retain)	NSArray *tags;

@property (nonatomic, retain)	NSData *data;
@property (nonatomic, retain)	NSString *mimeType;
@property (nonatomic, retain)	NSString *filename;

/*** creation methods ***/

/* always use these for SHKItem object creation, as they implicitly set appropriate SHKShareType. Items without SHKShareType will not be shared! */

+ (id)URL:(NSURL *)url title:(NSString *)title __attribute__((deprecated ("use URL:title:contentType: instead")));

//Some sharers might present audio and video urls in enhanced way - e.g with media player (see Tumblr sharer). Other sharers share same way they used to, regardless of what type is specified.
+ (id)URL:(NSURL *)url title:(NSString *)title contentType:(SHKURLContentType)type;
+ (id)image:(UIImage *)image title:(NSString *)title;
+ (id)video:(NSData *)videoData filename:(NSString *)filename title:(NSString *)title;
+ (id)text:(NSString *)text;
+ (id)file:(NSData *)data filename:(NSString *)filename mimeType:(NSString *)mimeType title:(NSString *)title;

/*** custom value methods ***/

/* these are for custom properties injection. Use them only if you are subclassing a sharer and need more properties. If you are creating a new sharer and builtin properties are insufficient, create sharer specific extension instead */

- (void)setCustomValue:(NSString *)value forKey:(NSString *)key;
- (NSString *)customValueForKey:(NSString *)key;
- (BOOL)customBoolForSwitchKey:(NSString *)key;

/*** archive methods ***/

/* used when ShareKit needs to save SHKItem to persistent storage. (e.g. offline queue or during facebook's SSO trip to different app  */

- (NSDictionary *)dictionaryRepresentation;
+ (id)itemFromDictionary:(NSDictionary *)dictionary;

/*** sharer specific extension properties ***/

/* sharers might be instructed to share the item in specific ways, e.g. SHKPrint's print quality, SHKMail's send to specified recipients etc. 
 Generally, YOU DO NOT NEED TO SET THESE, as sharers perfectly work with automatic default values. You can change default values in your app's 
 configurator, or individually during SHKItem creation. Example is in the demo app - ExampleShareLink.m - share method. More info about 
 particular setting is in DefaultSHKConfigurator.m
 */

/* SHKPrint */
@property (nonatomic) UIPrintInfoOutputType printOutputType;

/* SHKMail */
@property (nonatomic, retain) NSArray *mailToRecipients;
@property BOOL isMailHTML;
@property CGFloat mailJPGQuality; 
@property BOOL mailShareWithAppSignature; //default NO. Appends "Sent from <appName>"

/* SHKFacebook */
@property (nonatomic, retain) NSString *facebookURLSharePictureURI;
@property (nonatomic, retain) NSString *facebookURLShareDescription;

/* SHKTextMessage */
@property (nonatomic, retain) NSArray *textMessageToRecipients;
/* if you add new sharer specific properties, make sure to add them also to dictionaryRepresentation, itemWithDictionary and description methods in SHKItem.m */

/* put in for SHKInstagram, but could be useful in some other place. This is the rect in the coordinates of the view of the viewcontroller set with
 setRootViewController: where a popover should eminate from. If this isn't provided the popover will be presented from the top left. */
@property (nonatomic, assign) CGRect popOverSourceRect;

@end
