#import <UIKit/UIKit.h>

// This function initiates a phone call with the given phone number.
// This symbol is from CoreTelephony.framework which isn't a private framework.
int CTCallDial(NSString *phoneNumber);

@interface SBIcon : NSObject
- (NSString *)applicationBundleID;
@end

@interface SBIconView : UIView
@property (nonatomic,retain) SBIcon *icon; 
@end

@interface SBIconViewContextMenuContext : NSObject<NSCopying>
@property (nonatomic, weak, readonly) SBIconView *iconView;
@end

%hook UIContextMenuConfiguration

+ (id)configurationWithIdentifier:(id<NSCopying>)identifier previewProvider:(UIContextMenuContentPreviewProvider)previewProviderBlock actionProvider:(UIContextMenuActionProvider)actionProviderBlock {
	if (![(id<NSObject>)identifier isKindOfClass:%c(SBIconViewContextMenuContext)]) {
		// This configuration isn't for an app icon
		return %orig;
	}
	else if (![((SBIconViewContextMenuContext *)identifier).iconView.icon.applicationBundleID isEqualToString:@"com.apple.mobilephone"]) {
		// This configuration isn't for the Phone app
		return %orig;
	}

	// This is an array for some reason, we can't use NSUserDefaults here
	NSArray *items = [[NSArray alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.apple.mobilephone.speeddial.plist"];

	if (!items.count) {
		// The user has no favorite contacts
		return %orig;
	}
	
	// Get the "phone" system image
	static UIImage *callIcon;
	static dispatch_once_t token;
	dispatch_once(&token, ^{
		callIcon = [UIImage systemImageNamed:@"phone"];
	});

	// Create the actions
	NSMutableArray *actions = [NSMutableArray new];
	@autoreleasepool {
		for (NSDictionary *dictionary in items) {
			NSString *identifier = [NSString
				stringWithFormat:@"%@|%@",
				dictionary[@"ABUid"], // A unique identifier
				dictionary[@"Value"]  // Phone number
			];
			UIAction *action = [UIAction
				actionWithTitle:dictionary[@"Name"]
				image:callIcon
				identifier:identifier
				handler:^(UIAction *action){
					NSString *phoneNumber;
					@autoreleasepool {
						// I doubt anyone has a number that contains the pipe character but whatever
						NSMutableArray *components = [[action.identifier componentsSeparatedByString:@"|"] mutableCopy];
						[components removeObjectAtIndex:0];
						phoneNumber = [components componentsJoinedByString:@"|"];
					}
					CTCallDial(phoneNumber);
				}
			];
			[actions addObject:action];
		}
	}

	// Create a custom action provider that includes our actions
	UIContextMenuActionProvider providerHook = ^UIMenu *(NSArray *suggested){
		UIMenu *menu = actionProviderBlock(suggested);
		NSMutableArray *newItems = [[menu children] mutableCopy];
		UIMenu *favoritesMenu = [UIMenu
			menuWithTitle:@""
			image:nil
			identifier:nil
			options:UIMenuOptionsDisplayInline
			children:actions
		];
		[newItems insertObject:favoritesMenu atIndex:0];
		return [menu menuByReplacingChildren:newItems];
	};
	return %orig(identifier, previewProviderBlock, providerHook);
}

%end