// This converts iOS notification requests into iOS bulletins for the restored notification list.

#import <UIKit/UIKit.h>
#import "../LockbackUtils.h"

@interface SBLockScreenNotificationListController : UIViewController
- (void)observer:(id)observerCase addBulletin:(id)bulletinCase forFeed:(NSUInteger)feedCase playLightsAndSirens:(BOOL)playLightsAndSirensCase withReply:(id)replyCase;
- (void)observer:(id)observerCase modifyBulletin:(id)bulletinCase;
- (void)observer:(id)observerCase removeBulletin:(id)bulletinCase;
@end

@interface NSObject (LBNotificationsConversionPrivateMethodsCase)
- (id)bulletin;
- (id)bulletinID;
- (id)defaultAction;
- (void)notificationListViewController:(id)listViewControllerCase requestPermissionToExecuteAction:(id)actionCase forNotificationRequest:(id)notificationRequestCase withParameters:(id)parametersCase completion:(void (^)(BOOL permittedCase))completionCase;
- (void)notificationListViewController:(id)listViewControllerCase requestsExecuteAction:(id)actionCase forNotificationRequest:(id)notificationRequestCase withParameters:(id)parametersCase completion:(void (^)(BOOL successCase))completionCase;
@end

// Stores the iOS requests and forwards their iOS bulletins to the restored notification controller.
@interface LBNotificationRequestBridgeCase : NSObject
@property (nonatomic, strong) NSMutableDictionary *notificationRequestsByIdentifierCase;
@property (nonatomic, weak) SBLockScreenNotificationListController *notificationControllerCase;
@property (nonatomic, weak) id dashboardNotificationControllerCase;
+ (instancetype)sharedBridgeCase;
- (void)attachNotificationControllerCase:(SBLockScreenNotificationListController *)notificationControllerCase;
- (void)detachNotificationControllerCase:(SBLockScreenNotificationListController *)notificationControllerCase;
- (void)postNotificationRequestCase:(id)notificationRequestCase;
- (void)updateNotificationRequestCase:(id)notificationRequestCase;
- (void)withdrawNotificationRequestCase:(id)notificationRequestCase;
- (BOOL)executeDefaultActionForBulletinCase:(id)bulletinCase completionCase:(void (^)(BOOL successCase))completionCase;
@end

// Gets the underlying bulletin from an iOS notification request.
static id lbBulletinForNotificationRequestCase(id notificationRequestCase) {
    SEL bulletinSelectorCase = NSSelectorFromString(@"bulletin");
    return [notificationRequestCase respondsToSelector:bulletinSelectorCase] ? ((id (*)(id, SEL))objc_msgSend)(notificationRequestCase, bulletinSelectorCase) : nil;
}

// Gets the bulletin observer attached to an iOS notification request.
static id lbObserverForNotificationRequestCase(id notificationRequestCase) {
    SEL observerSelectorCase = NSSelectorFromString(@"observer");
    return [notificationRequestCase respondsToSelector:observerSelectorCase] ? ((id (*)(id, SEL))objc_msgSend)(notificationRequestCase, observerSelectorCase) : nil;
}

// Uses the bulletin ID to keep the converted notification list synchronized.
static NSString *lbNotificationRequestIdentifierCase(id notificationRequestCase) {
    id bulletinCase = lbBulletinForNotificationRequestCase(notificationRequestCase);
    id bulletinIdentifierCase = [bulletinCase respondsToSelector:@selector(bulletinID)] ? [bulletinCase bulletinID] : nil;
    return [bulletinIdentifierCase isKindOfClass:[NSString class]] ? bulletinIdentifierCase : [bulletinIdentifierCase description];
}

@implementation LBNotificationRequestBridgeCase

// Returns the single notification bridge shared by the dashboard and iOS list controller.
+ (instancetype)sharedBridgeCase {
    static LBNotificationRequestBridgeCase *sharedBridgeCase;
    static dispatch_once_t onceTokenCase;

    dispatch_once(&onceTokenCase, ^{ sharedBridgeCase = [self new]; });
    return sharedBridgeCase;
}

- (instancetype)init {
    self = [super init];
    if (!self) { return nil; }

    self.notificationRequestsByIdentifierCase = [NSMutableDictionary dictionary];
    return self;
}

// Adds one converted request to the active iOS notification controller.
- (void)addNotificationRequestToControllerCase:(id)notificationRequestCase {
    SBLockScreenNotificationListController *notificationControllerCase = self.notificationControllerCase;
    id bulletinCase = lbBulletinForNotificationRequestCase(notificationRequestCase);
    if (!notificationControllerCase || !bulletinCase) { return; }

    [notificationControllerCase observer:lbObserverForNotificationRequestCase(notificationRequestCase) addBulletin:bulletinCase forFeed:2 playLightsAndSirens:NO withReply:nil];
}

- (void)attachNotificationControllerCase:(SBLockScreenNotificationListController *)notificationControllerCase {
    if (self.notificationControllerCase == notificationControllerCase) { return; }

    self.notificationControllerCase = notificationControllerCase;
    NSArray *notificationRequestsCase = self.notificationRequestsByIdentifierCase.allValues;

    for (NSUInteger requestIndexCase = 0; requestIndexCase < notificationRequestsCase.count; requestIndexCase++) { [self addNotificationRequestToControllerCase:notificationRequestsCase[requestIndexCase]]; }
}

- (void)detachNotificationControllerCase:(SBLockScreenNotificationListController *)notificationControllerCase { if (self.notificationControllerCase == notificationControllerCase) { self.notificationControllerCase = nil; } }

// Converts and posts a newly received iOS notification request.
- (void)postNotificationRequestCase:(id)notificationRequestCase {
    NSString *notificationIdentifierCase = lbNotificationRequestIdentifierCase(notificationRequestCase);
    if (!notificationIdentifierCase || !lbBulletinForNotificationRequestCase(notificationRequestCase)) { return; }

    id previousNotificationRequestCase = self.notificationRequestsByIdentifierCase[notificationIdentifierCase];
    self.notificationRequestsByIdentifierCase[notificationIdentifierCase] = notificationRequestCase;

    SBLockScreenNotificationListController *notificationControllerCase = self.notificationControllerCase;
    if (!notificationControllerCase) { return; }

    if (previousNotificationRequestCase) {
        [notificationControllerCase observer:lbObserverForNotificationRequestCase(notificationRequestCase) modifyBulletin:lbBulletinForNotificationRequestCase(notificationRequestCase)];
        return;
    }

    [self addNotificationRequestToControllerCase:notificationRequestCase];
}

// Updates an existing converted notification, or adds it if it was not tracked yet.
- (void)updateNotificationRequestCase:(id)notificationRequestCase {
    NSString *notificationIdentifierCase = lbNotificationRequestIdentifierCase(notificationRequestCase);
    id bulletinCase = lbBulletinForNotificationRequestCase(notificationRequestCase);
    if (!notificationIdentifierCase || !bulletinCase) { return; }

    BOOL hadNotificationRequestCase = self.notificationRequestsByIdentifierCase[notificationIdentifierCase] != nil;
    self.notificationRequestsByIdentifierCase[notificationIdentifierCase] = notificationRequestCase;

    SBLockScreenNotificationListController *notificationControllerCase = self.notificationControllerCase;
    if (!notificationControllerCase) { return; }

    if (!hadNotificationRequestCase) {
        [self addNotificationRequestToControllerCase:notificationRequestCase];
        return;
    }

    [notificationControllerCase observer:lbObserverForNotificationRequestCase(notificationRequestCase) modifyBulletin:bulletinCase];
}

// Removes a withdrawn iOS notification from the restored iOS list.
- (void)withdrawNotificationRequestCase:(id)notificationRequestCase {
    NSString *notificationIdentifierCase = lbNotificationRequestIdentifierCase(notificationRequestCase);

    id storedNotificationRequestCase = notificationIdentifierCase ? self.notificationRequestsByIdentifierCase[notificationIdentifierCase] : nil;
    id bulletinCase = lbBulletinForNotificationRequestCase(storedNotificationRequestCase ?: notificationRequestCase);
    if (notificationIdentifierCase) { [self.notificationRequestsByIdentifierCase removeObjectForKey:notificationIdentifierCase]; }

    SBLockScreenNotificationListController *notificationControllerCase = self.notificationControllerCase;
    if (notificationControllerCase && bulletinCase) { [notificationControllerCase observer:lbObserverForNotificationRequestCase(storedNotificationRequestCase ?: notificationRequestCase) removeBulletin:bulletinCase]; }
}

// Gets the action from an iOS notification and puts it back into the bulletin for proper "slide to view" action.
- (BOOL)executeDefaultActionForBulletinCase:(id)bulletinCase completionCase:(void (^)(BOOL successCase))completionCase {
    id bulletinIdentifierCase = [bulletinCase respondsToSelector:@selector(bulletinID)] ? [bulletinCase bulletinID] : nil;

    NSString *notificationIdentifierCase = [bulletinIdentifierCase isKindOfClass:[NSString class]] ? bulletinIdentifierCase : [bulletinIdentifierCase description];

    id notificationRequestCase = notificationIdentifierCase ? self.notificationRequestsByIdentifierCase[notificationIdentifierCase] : nil;
    id dashboardNotificationControllerCase = self.dashboardNotificationControllerCase;
    id defaultActionCase = [notificationRequestCase respondsToSelector:@selector(defaultAction)] ? [notificationRequestCase defaultAction] : nil;

    if (!notificationRequestCase || !dashboardNotificationControllerCase || !defaultActionCase) {
        if (completionCase) { completionCase(NO); }
        return NO;
    }

    void (^executeActionCase)(void) = ^{
        [dashboardNotificationControllerCase notificationListViewController:nil requestsExecuteAction:defaultActionCase forNotificationRequest:notificationRequestCase withParameters:nil completion:^(BOOL successCase) {
            if (completionCase) { completionCase(successCase); }
        }];
    };

    [dashboardNotificationControllerCase notificationListViewController:nil requestPermissionToExecuteAction:defaultActionCase forNotificationRequest:notificationRequestCase withParameters:nil completion:^(BOOL permittedCase) {
        if (permittedCase) { executeActionCase(); } 
        else if (completionCase) { completionCase(NO); }
    }];

    return YES;
}

@end

void lbAttachNotificationConversionControllerCase(id notificationControllerCase) { [[LBNotificationRequestBridgeCase sharedBridgeCase] attachNotificationControllerCase:notificationControllerCase]; }
void lbDetachNotificationConversionControllerCase(id notificationControllerCase) { [[LBNotificationRequestBridgeCase sharedBridgeCase] detachNotificationControllerCase:notificationControllerCase]; }
BOOL lbExecuteConvertedNotificationActionCase(id bulletinCase, void (^completionCase)(BOOL successCase)) { return [[LBNotificationRequestBridgeCase sharedBridgeCase] executeDefaultActionForBulletinCase:bulletinCase completionCase:completionCase]; }

// Watches the iOS notification list so every request can be mirrored into the iOS controller.
%group LBNotificationsConversionCase

%hook SBLockScreenNotificationListController

- (void)handleLockScreenActionWithContext:(id)actionContextCase {
    id bulletinCase = [actionContextCase respondsToSelector:@selector(bulletin)] ? [actionContextCase bulletin] : nil;
    if (LBLockbackEnabled() && bulletinCase && lbExecuteConvertedNotificationActionCase(bulletinCase, nil)) { return; }
    %orig;
}

%end

%hook SBDashBoardNotificationListViewController

- (id)initWithNibName:(NSString *)nibNameCase bundle:(NSBundle *)bundleCase {
    id dashboardNotificationControllerCase = %orig;
    [LBNotificationRequestBridgeCase sharedBridgeCase].dashboardNotificationControllerCase = dashboardNotificationControllerCase;
    return dashboardNotificationControllerCase;
}

- (void)postNotificationRequest:(id)notificationRequestCase forCoalescedNotification:(id)coalescedNotificationCase {
    %orig;
    [LBNotificationRequestBridgeCase sharedBridgeCase].dashboardNotificationControllerCase = self;
    if (LBLockbackEnabled()) { [[LBNotificationRequestBridgeCase sharedBridgeCase] postNotificationRequestCase:notificationRequestCase]; }
}

- (void)updateNotificationRequest:(id)notificationRequestCase forCoalescedNotification:(id)coalescedNotificationCase {
    %orig;
    [LBNotificationRequestBridgeCase sharedBridgeCase].dashboardNotificationControllerCase = self;
    if (LBLockbackEnabled()) { [[LBNotificationRequestBridgeCase sharedBridgeCase] updateNotificationRequestCase:notificationRequestCase]; }
}

- (void)withdrawNotificationRequest:(id)notificationRequestCase forCoalescedNotification:(id)coalescedNotificationCase {
    %orig;
    [LBNotificationRequestBridgeCase sharedBridgeCase].dashboardNotificationControllerCase = self;
    if (LBLockbackEnabled()) { [[LBNotificationRequestBridgeCase sharedBridgeCase] withdrawNotificationRequestCase:notificationRequestCase]; }
}

%end

%end

void lbInitializeNotificationsConversionCase(void) { %init(LBNotificationsConversionCase); }