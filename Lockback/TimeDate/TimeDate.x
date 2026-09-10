// This restores the time and date on the lock screen.

#import <UIKit/UIKit.h>
#import <math.h>
#import "../LockbackUtils.h"
#import "TimeDateShared.h"

static const void *lbTimeDateViewAssociationKeyCase = &lbTimeDateViewAssociationKeyCase;

// Keeps all active lock screen time/date views synchronized with the system clock, locale, and time zone.
@interface LBTimeDateUpdater : NSObject
@property (nonatomic, strong) NSHashTable *dateViewsCase;
@property (nonatomic, strong) NSTimer *minuteUpdateTimerCase;
// Returns the single updater shared by every dashboard instance.
+ (instancetype)sharedUpdater;
- (void)addDateView:(LBTimeDateView *)dateViewCase;
- (void)updateDateViewsWithDate:(NSDate *)dateCase refreshingFormatters:(BOOL)refreshFormattersCase;
- (void)updateDateViewsRefreshingFormatters:(BOOL)refreshFormattersCase;
// Schedules the next refresh exactly on the next minute boundary.
- (void)scheduleMinuteUpdate;
@end

@implementation LBTimeDateUpdater

+ (instancetype)sharedUpdater {
    static LBTimeDateUpdater *sharedUpdaterCase;
    static dispatch_once_t onceTokenCase;

    dispatch_once(&onceTokenCase, ^{ sharedUpdaterCase = [self new]; });
    return sharedUpdaterCase;
}

- (instancetype)init {
    self = [super init];
    if (!self) { return nil; }

    self.dateViewsCase = [NSHashTable weakObjectsHashTable];

    NSNotificationCenter *notificationCenterCase = [NSNotificationCenter defaultCenter];
    NSArray *notificationsCase = @[
        NSSystemClockDidChangeNotification,
        NSSystemTimeZoneDidChangeNotification,
        NSCurrentLocaleDidChangeNotification,
        UIApplicationSignificantTimeChangeNotification,
    ];

    for (NSUInteger notificationIndexCase = 0; notificationIndexCase < notificationsCase.count; notificationIndexCase++) {
        [notificationCenterCase addObserver:self selector:@selector(environmentDidChange:) name:notificationsCase[notificationIndexCase] object:nil];
    }

    [self scheduleMinuteUpdate];
    return self;
}

- (void)addDateView:(LBTimeDateView *)dateViewCase {
    if (!dateViewCase) { return; }

    [self.dateViewsCase addObject:dateViewCase];
    [dateViewCase setDate:[NSDate date]];
}

- (void)updateDateViewsWithDate:(NSDate *)dateCase refreshingFormatters:(BOOL)refreshFormattersCase {
    if (!dateCase) { dateCase = [NSDate date]; }

    NSArray *dateViewsCase = self.dateViewsCase.allObjects;

    for (NSUInteger dateViewIndexCase = 0; dateViewIndexCase < dateViewsCase.count; dateViewIndexCase++) {
        LBTimeDateView *dateViewCase = dateViewsCase[dateViewIndexCase];
        if (refreshFormattersCase) { [dateViewCase refreshFormatters]; }

        [dateViewCase setDate:dateCase];
    }
}

- (void)updateDateViewsRefreshingFormatters:(BOOL)refreshFormattersCase { [self updateDateViewsWithDate:[NSDate date] refreshingFormatters:refreshFormattersCase]; }

- (void)scheduleMinuteUpdate {
    [self.minuteUpdateTimerCase invalidate];

    NSTimeInterval referenceTimeCase = [[NSDate date] timeIntervalSinceReferenceDate];
    NSTimeInterval nextMinuteReferenceTimeCase = (floor(referenceTimeCase / 60.0) + 1.0) * 60.0;

    NSDate *nextMinuteDateCase = [NSDate dateWithTimeIntervalSinceReferenceDate: nextMinuteReferenceTimeCase];

    self.minuteUpdateTimerCase = [[NSTimer alloc] initWithFireDate:nextMinuteDateCase interval:60.0 target:self selector:@selector(minuteDidChange:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.minuteUpdateTimerCase forMode:NSRunLoopCommonModes];
}

- (void)minuteDidChange:(NSTimer *)timerCase { [self updateDateViewsRefreshingFormatters:NO]; }

- (void)environmentDidChange:(NSNotification *)notificationCase {
    [self updateDateViewsRefreshingFormatters:YES];
    [self scheduleMinuteUpdate];
}

@end

// Returns the Lockback time/date view associated with this dashboard.
static LBTimeDateView *LBTimeDateViewForDashboard(UIView *dashboardViewCase) {
    return (LBTimeDateView *)LBLockScreenViewForDashboard(dashboardViewCase, lbTimeDateViewAssociationKeyCase, [LBTimeDateView class]);
}

// Creates and attaches the recreated time/date view to the active lock screen dashboard.
static void LBInstallTimeDateView(UIView *dashboardViewCase) {
    if (!dashboardViewCase.window) { return; }

    LBTimeDateView *timeDateViewCase = LBTimeDateViewForDashboard(dashboardViewCase);
    if (!timeDateViewCase) {
        timeDateViewCase = [[LBTimeDateView alloc] initWithFrame:dashboardViewCase.bounds];
        timeDateViewCase.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        [[LBTimeDateUpdater sharedUpdater] addDateView:timeDateViewCase];
    }

    [timeDateViewCase setDate:[NSDate date]];
    LBAttachLockScreenView(timeDateViewCase, dashboardViewCase, lbTimeDateViewAssociationKeyCase);
}

%group LBTimeDate

%hook SBFLockScreenDateView

- (void)setDate:(NSDate *)dateCase {
    %orig(dateCase);
    if (LBLockbackEnabled() && dateCase) { [[LBTimeDateUpdater sharedUpdater] updateDateViewsWithDate:dateCase refreshingFormatters:NO]; }
}

%end

%hook SBDashBoardView

- (void)didMoveToWindow {
    %orig;
    LBUpdateLockScreenFeature((UIView *)self, lbTimeDateViewAssociationKeyCase, YES, LBInstallTimeDateView);
}

- (void)layoutSubviews {
    %orig;
    LBUpdateLockScreenFeature((UIView *)self, lbTimeDateViewAssociationKeyCase, NO, LBInstallTimeDateView);
}

%end

%end

void LBInitializeTimeDate(void) { %init(LBTimeDate); }