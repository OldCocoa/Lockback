#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface NSObject (LBSlideToUnlockAnimationPrivateMethods)
- (void)setHighlight:(BOOL)highlightCase;
- (void)setChevronStyle:(NSInteger)chevronStyleCase;
- (void)startAnimating;
- (void)stopAnimating;
- (void)show;
- (void)fadeOut;
- (void)fadeIn;
@end

@interface LBSlideToUnlockView : UIView <CAAnimationDelegate>
@property (nonatomic, strong) UIView *parentSpringViewCase;
@property (nonatomic, strong) UIView *springViewCase;
@property (nonatomic, strong) UIView *glintyStringViewCase;
@property (nonatomic, assign) BOOL shakingSlideTextCase;
- (void)updateSlideAppearance;
- (void)setCustomSlideToUnlockText:(NSString *)customTextCase;
@end

@interface LBSlideToUnlockView (Animation)
- (void)startSlideAnimation;
- (void)stopSlideAnimation;
- (void)shakeSlideToUnlockTextWithCustomText:(NSString *)customTextCase;
@end

@implementation LBSlideToUnlockView (Animation)

// Starts the original glint animation when the lock screen is visible.
- (void)startSlideAnimation {
    if (self.shakingSlideTextCase) { return; }
    if ([(id)self.glintyStringViewCase respondsToSelector:@selector(startAnimating)]) { [(id)self.glintyStringViewCase startAnimating]; }
}

// Stops the glint and spring animations when the lock screen leaves the screen.
- (void)stopSlideAnimation {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self.springViewCase.layer removeAllAnimations];
    [self.parentSpringViewCase.layer removeAllAnimations];

    if ([(id)self.glintyStringViewCase respondsToSelector:@selector(stopAnimating)]) { [(id)self.glintyStringViewCase stopAnimating]; }
}

- (void)restoreSlideToUnlockText {
    UIView *glintyStringViewCase = self.glintyStringViewCase;

    if ([glintyStringViewCase respondsToSelector:@selector(setHighlight:)]) { [(id)glintyStringViewCase setHighlight:NO]; }
    if ([glintyStringViewCase respondsToSelector:@selector(setChevronStyle:)]) { [(id)glintyStringViewCase setChevronStyle:1]; }

    [self setCustomSlideToUnlockText:nil];
    self.shakingSlideTextCase = NO;
    [self performSelector:@selector(fadeInSlideToUnlockText) withObject:nil afterDelay:2.0];
}

- (void)fadeInSlideToUnlockText {
    UIView *glintyStringViewCase = self.glintyStringViewCase;
    if (!self.window || !glintyStringViewCase) { return; }

    [self updateSlideAppearance];

    if ([glintyStringViewCase respondsToSelector:@selector(fadeIn)]) {
        [(id)glintyStringViewCase fadeIn];
        return;
    }

    [self startSlideAnimation];
}

- (void)finishSlideFailureAnimation {
    if (!self.shakingSlideTextCase) { return; }

    if ([(id)self.glintyStringViewCase respondsToSelector:@selector(fadeOut)]) {
        [(id)self.glintyStringViewCase fadeOut];
        return;
    }

    [self restoreSlideToUnlockText];
}

- (void)shakeSlideToUnlockTextWithCustomText:(NSString *)customTextCase {
    if (!customTextCase.length || !self.window) { return; }

    [self stopSlideAnimation];
    self.shakingSlideTextCase = YES;

    UIView *glintyStringViewCase = self.glintyStringViewCase;
    if ([glintyStringViewCase respondsToSelector:@selector(setHighlight:)]) { [(id)glintyStringViewCase setHighlight:YES]; }
    if ([glintyStringViewCase respondsToSelector:@selector(setChevronStyle:)]) { [(id)glintyStringViewCase setChevronStyle:0]; }

    [self setCustomSlideToUnlockText:customTextCase];
    if ([glintyStringViewCase respondsToSelector:@selector(show)]) { [(id)glintyStringViewCase show]; }

    CASpringAnimation *springAnimationCase = [CASpringAnimation animationWithKeyPath:@"position.x"];
    springAnimationCase.mass = 1.2;
    springAnimationCase.stiffness = 1200.0;
    springAnimationCase.damping = 12.0;
    springAnimationCase.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.0498f :0.0020f :0.6638f :1.0f];
    springAnimationCase.duration = 0.86;
    springAnimationCase.fillMode = kCAFillModeBackwards;
    springAnimationCase.delegate = self;
    springAnimationCase.fromValue = @(self.springViewCase.layer.position.x + 75.0);
    [self.springViewCase.layer addAnimation:springAnimationCase forKey:@"position"];

    CABasicAnimation *forceAnimationCase = [CABasicAnimation animationWithKeyPath:@"position.x"];
    forceAnimationCase.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.25f :0.1f :0.25f :1.0f];
    forceAnimationCase.duration = 0.07;
    forceAnimationCase.fillMode = kCAFillModeBackwards;
    forceAnimationCase.fromValue = @(self.parentSpringViewCase.layer.position.x - 75.0);
    [self.parentSpringViewCase.layer addAnimation:forceAnimationCase forKey:@"force"];
}

- (void)animationDidStop:(CAAnimation *)animationCase finished:(BOOL)finishedCase {
    if (!finishedCase || !self.shakingSlideTextCase) { return; }
    [self performSelector:@selector(finishSlideFailureAnimation) withObject:nil afterDelay:1.5];
}

// These empty callbacks satisfy the private glinty view delegate used by SpringBoard.
- (void)glintyFadeOutAnimationDidStop { if (self.shakingSlideTextCase) { [self restoreSlideToUnlockText]; } }
- (void)glintyFadeInAnimationDidStop {}
- (void)glintyAnimationDidStart {}
- (void)glintyAnimationDidStop {}

@end