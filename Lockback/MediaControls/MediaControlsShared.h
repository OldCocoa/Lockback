#ifndef MediaControlsShared_h
#define MediaControlsShared_h

#import <UIKit/UIKit.h>

@interface LBMediaControlsView : UIView
@property (nonatomic, weak) UIView *dashboardViewCase;
@property (nonatomic, strong) UIViewController *controlsViewControllerCase;
@property (nonatomic, strong) UIViewController *artworkViewControllerCase;
@property (nonatomic, strong) UIView *artworkContainerViewCase;
@property (nonatomic) BOOL controlsVisibleCase;
@property (nonatomic) BOOL appearedCase;
- (void)setControlsVisible:(BOOL)visibleCase animated:(BOOL)animatedCase;
- (void)updateArtworkVisibilityAnimated:(BOOL)animatedCase;
@end

BOOL LBMediaControlsVisible(void);

void LBSetTimeDateHiddenForMediaControls(UIView *dashboardViewCase, BOOL hiddenCase, BOOL animatedCase);
BOOL LBNotificationListVisible(void);
void LBSetNotificationBackgroundForMediaControls(UIView *dashboardViewCase, BOOL visibleCase, BOOL animatedCase);

extern NSString *const LBNotificationListVisibilityDidChangeNotification;

#endif
