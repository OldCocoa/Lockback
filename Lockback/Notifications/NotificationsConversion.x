// This converts iOS notification requests into iOS bulletins for the restored notification list.

#import <UIKit/UIKit.h>
#import "../LockbackUtils.h"

@interface SBLockScreenNotificationListController : UIViewController
- (void)observer:(id)observerCase addBulletin:(id)bulletinCase forFeed:(NSUInteger)feedCase playLightsAndSirens:(BOOL)playLightsAndSirensCase withReply:(id)replyCase;
- (void)observer:(id)observerCase modifyBulletin:(id)bulletinCase;
- (void)observer:(id)observerCase removeBulletin:(id)bulletinCase;
@end

@interface SBNotificationCenterDestination : NSObject
- (id)notificationListViewController;
@end

@interface NSObject (LBNotificationsConversionPrivateMethodsCase)
- (id)bulletin;
- (id)bulletinID;
- (id)defaultAction;
- (id)notificationRequest;
- (id)notificationRequestsPassingTest:(BOOL (^)(id notificationRequestCase))testCase;
- (void)notificationListViewController:(id)listViewControllerCase requestPermissionToExecuteAction:(id)actionCase forNotificationRequest:(id)notificationRequestCase withParameters:(id)parametersCase completion:(void (^)(BOOL permittedCase))completionCase;
- (void)notificationListViewController:(id)listViewControllerCase requestsExecuteAction:(id)actionCase forNotificationRequest:(id)notificationRequestCase withParameters:(id)parametersCase completion:(void (^)(BOOL successCase))completionCase;
@end

// Stores the iOS requests and forwards their iOS bulletins to the restored notification controller.
@interface LBNotificationRequestBridgeCase : NSObject
@property (nonatomic, strong) NSMutableDictionary *notificationRequestsByIdentifierCase;
@property (nonatomic, weak) SBLockScreenNotificationListController *notificationControllerCase;
@property (nonatomic, weak) id dashboardNotificationControllerCase;
@property (nonatomic, weak) SBNotificationCenterDestination *notificationCenterDestinationCase;
+ (instancetype)sharedBridgeCase;
- (void)attachNotificationControllerCase:(SBLockScreenNotificationListController *)notificationControllerCase;
- (void)detachNotificationControllerCase:(SBLockScreenNotificationListController *)notificationControllerCase;
- (void)postNotificationRequestCase:(id)notificationRequestCase;
- (void)updateNotificationRequestCase:(id)notificationRequestCase;
- (void)withdrawNotificationRequestCase:(id)notificationRequestCase;
- (void)synchronizeNotificationRequestsFromDashboardControllerCase:(id)dashboardNotificationControllerCase;
- (void)synchronizeNotificationRequestsFromNotificationCenterDestinationCase:(SBNotificationCenterDestination *)notificationCenterDestinationCase;
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

// Gets the native iOS notification list that owns the requests currently shown by the dashboard.
static id lbDashboardNotificationListCase(id dashboardNotificationControllerCase) {
    if (!dashboardNotificationControllerCase) { return nil; }

    Ivar listViewControllerIvarCase = class_getInstanceVariable([dashboardNotificationControllerCase class], "_listViewController");
    return listViewControllerIvarCase ? object_getIvar(dashboardNotificationControllerCase, listViewControllerIvarCase) : nil;
}

// Resolves a native list object back to its notification request when necessary.
static id lbNotificationRequestFromListObjectCase(id notificationListObjectCase) {
    if (lbBulletinForNotificationRequestCase(notificationListObjectCase)) { return notificationListObjectCase; }
    return [notificationListObjectCase respondsToSelector:@selector(notificationRequest)] ? [notificationListObjectCase notificationRequest] : nil;
}

// Gets all notification requests currently owned by a native iOS notification list.
static NSArray *lbNotificationRequestsFromListCase(id notificationListCase) {
    if (![notificationListCase respondsToSelector:@selector(notificationRequestsPassingTest:)]) { return nil; }

    id notificationListObjectsCase = [notificationListCase notificationRequestsPassingTest:^BOOL(id notificationRequestCase) { return notificationRequestCase != nil; }];
    if (![notificationListObjectsCase conformsToProtocol:@protocol(NSFastEnumeration)]) { return nil; }

    NSMutableArray *notificationRequestsCase = [NSMutableArray array];
    for (id notificationListObjectCase in notificationListObjectsCase) {
        id notificationRequestCase = lbNotificationRequestFromListObjectCase(notificationListObjectCase);
        if (notificationRequestCase) { [notificationRequestsCase addObject:notificationRequestCase]; }
    }

    return notificationRequestsCase;
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

    if (LBNotificationCenterMirroringEnabled()) { [self synchronizeNotificationRequestsFromNotificationCenterDestinationCase:self.notificationCenterDestinationCase]; }
    else { [self synchronizeNotificationRequestsFromDashboardControllerCase:self.dashboardNotificationControllerCase]; }
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

// Replays the requests already owned by iOS into the restored list when the lock screen is rebuilt.
- (void)synchronizeNotificationRequestsFromDashboardControllerCase:(id)dashboardNotificationControllerCase {
    if (!dashboardNotificationControllerCase || LBNotificationCenterMirroringEnabled()) { return; }

    self.dashboardNotificationControllerCase = dashboardNotificationControllerCase;

    NSArray *notificationRequestsCase = lbNotificationRequestsFromListCase(lbDashboardNotificationListCase(dashboardNotificationControllerCase));
    for (NSUInteger requestIndexCase = 0; requestIndexCase < notificationRequestsCase.count; requestIndexCase++) { [self updateNotificationRequestCase:notificationRequestsCase[requestIndexCase]]; }
}

// Rebuilds the restored list from Notification Center and removes requests that Notification Center no longer owns.
- (void)synchronizeNotificationRequestsFromNotificationCenterDestinationCase:(SBNotificationCenterDestination *)notificationCenterDestinationCase {
    if (!notificationCenterDestinationCase || !LBNotificationCenterMirroringEnabled()) { return; }

    self.notificationCenterDestinationCase = notificationCenterDestinationCase;

    NSArray *notificationRequestsCase = lbNotificationRequestsFromListCase([notificationCenterDestinationCase notificationListViewController]);
    if (!notificationRequestsCase) { return; }

    NSMutableSet *notificationIdentifiersCase = [NSMutableSet set];
    for (NSUInteger requestIndexCase = 0; requestIndexCase < notificationRequestsCase.count; requestIndexCase++) {
        id notificationRequestCase = notificationRequestsCase[requestIndexCase];
        
        NSString *notificationIdentifierCase = lbNotificationRequestIdentifierCase(notificationRequestCase);
        if (notificationIdentifierCase) { [notificationIdentifiersCase addObject:notificationIdentifierCase]; }

        [self updateNotificationRequestCase:notificationRequestCase];
    }

    NSArray *storedNotificationIdentifiersCase = self.notificationRequestsByIdentifierCase.allKeys;
    for (NSUInteger identifierIndexCase = 0; identifierIndexCase < storedNotificationIdentifiersCase.count; identifierIndexCase++) {
        NSString *notificationIdentifierCase = storedNotificationIdentifiersCase[identifierIndexCase];
        if ([notificationIdentifiersCase containsObject:notificationIdentifierCase]) { continue; }

        id notificationRequestCase = self.notificationRequestsByIdentifierCase[notificationIdentifierCase];
        [self withdrawNotificationRequestCase:notificationRequestCase];
    }
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

%hook SBNotificationCenterDestination

- (id)init {
    id notificationCenterDestinationCase = %orig;
    [LBNotificationRequestBridgeCase sharedBridgeCase].notificationCenterDestinationCase = notificationCenterDestinationCase;
    return notificationCenterDestinationCase;
}

- (void)postNotificationRequest:(id)notificationRequestCase forCoalescedNotification:(id)coalescedNotificationCase {
    %orig;
    [LBNotificationRequestBridgeCase sharedBridgeCase].notificationCenterDestinationCase = (SBNotificationCenterDestination *)self;
    if (LBLockbackEnabled() && LBNotificationCenterMirroringEnabled()) { [[LBNotificationRequestBridgeCase sharedBridgeCase] postNotificationRequestCase:notificationRequestCase]; }
}

- (void)modifyNotificationRequest:(id)notificationRequestCase forCoalescedNotification:(id)coalescedNotificationCase {
    %orig;
    [LBNotificationRequestBridgeCase sharedBridgeCase].notificationCenterDestinationCase = (SBNotificationCenterDestination *)self;
    if (LBLockbackEnabled() && LBNotificationCenterMirroringEnabled()) { [[LBNotificationRequestBridgeCase sharedBridgeCase] updateNotificationRequestCase:notificationRequestCase]; }
}

- (void)withdrawNotificationRequest:(id)notificationRequestCase forCoalescedNotification:(id)coalescedNotificationCase {
    %orig;
    [LBNotificationRequestBridgeCase sharedBridgeCase].notificationCenterDestinationCase = (SBNotificationCenterDestination *)self;
    if (LBLockbackEnabled() && LBNotificationCenterMirroringEnabled()) { [[LBNotificationRequestBridgeCase sharedBridgeCase] withdrawNotificationRequestCase:notificationRequestCase]; }
}

- (void)setNotificationListViewController:(id)notificationListViewControllerCase {
    %orig;
    [LBNotificationRequestBridgeCase sharedBridgeCase].notificationCenterDestinationCase = (SBNotificationCenterDestination *)self;
    if (LBLockbackEnabled() && LBNotificationCenterMirroringEnabled()) { [[LBNotificationRequestBridgeCase sharedBridgeCase] synchronizeNotificationRequestsFromNotificationCenterDestinationCase:(SBNotificationCenterDestination *)self]; }
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
    if (LBLockbackEnabled() && !LBNotificationCenterMirroringEnabled()) { [[LBNotificationRequestBridgeCase sharedBridgeCase] postNotificationRequestCase:notificationRequestCase]; }
}

- (void)updateNotificationRequest:(id)notificationRequestCase forCoalescedNotification:(id)coalescedNotificationCase {
    %orig;
    [LBNotificationRequestBridgeCase sharedBridgeCase].dashboardNotificationControllerCase = self;
    if (LBLockbackEnabled() && !LBNotificationCenterMirroringEnabled()) { [[LBNotificationRequestBridgeCase sharedBridgeCase] updateNotificationRequestCase:notificationRequestCase]; }
}

- (void)withdrawNotificationRequest:(id)notificationRequestCase forCoalescedNotification:(id)coalescedNotificationCase {
    %orig;
    [LBNotificationRequestBridgeCase sharedBridgeCase].dashboardNotificationControllerCase = self;
    if (LBLockbackEnabled() && !LBNotificationCenterMirroringEnabled()) { [[LBNotificationRequestBridgeCase sharedBridgeCase] withdrawNotificationRequestCase:notificationRequestCase]; }
}

- (void)viewDidAppear:(BOOL)animatedCase {
    %orig;
    if (LBLockbackEnabled()) { [[LBNotificationRequestBridgeCase sharedBridgeCase] synchronizeNotificationRequestsFromDashboardControllerCase:self]; }
}

- (void)rebuildEverythingForReason:(id)reasonCase {
    %orig;
    if (LBLockbackEnabled()) { [[LBNotificationRequestBridgeCase sharedBridgeCase] synchronizeNotificationRequestsFromDashboardControllerCase:self]; }
}

%end

%end

void lbInitializeNotificationsConversionCase(void) { %init(LBNotificationsConversionCase); }