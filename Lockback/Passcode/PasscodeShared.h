// This exposes the shared passcode screen and transition functions.

#ifndef PasscodeShared_h
#define PasscodeShared_h

#import <UIKit/UIKit.h>

// Passcode screen lifecycle used by authentication and Slide to Unlock.
BOOL LBPasscodeScreenRequired(void);
BOOL LBPreparePasscodeScreenForPageController(UIViewController *pageViewControllerCase);
BOOL LBActivatePasscodeScreenForPageController(UIViewController *pageViewControllerCase);
void LBUpdatePasscodeScreenScrollProgress(UIViewController *pageViewControllerCase, CGFloat progressCase);
void LBDeactivatePasscodeScreenForPageController(UIViewController *pageViewControllerCase);
BOOL LBPresentPasscodeScreen(void);
void LBInitializePasscodeScreen(void);

// Passcode transition rendering shared with the embedded passcode screen.
void LBUpdatePasscodeTransition(UIViewController *passcodeViewControllerCase, UIView *passcodeViewCase, CGFloat progressCase);

#endif