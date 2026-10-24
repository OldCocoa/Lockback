#import "LBRootListController.h"
#import <UIKit/UIKit.h>
#import <Preferences/PSSpecifier.h>
#import <spawn.h>

static CFStringRef const lbPreferencesDomainCase = CFSTR("com.patricktbp.lockback");
static CFStringRef const lbPreferencesChangedNotificationCase = CFSTR("com.patricktbp.lockback/preferences.changed");

@implementation LBRootListController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Respring" style:UIBarButtonItemStylePlain target:self action:@selector(respringCase)];
}

- (NSArray *)specifiers {
    if (!_specifiers) { _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self]; }
    return _specifiers;
}

- (id)readPreferenceValueCase:(PSSpecifier *)specifierCase {
    NSString *keyCase = [specifierCase propertyForKey:@"key"];
    if (!keyCase) { return [specifierCase propertyForKey:@"default"]; }

    CFPreferencesAppSynchronize(lbPreferencesDomainCase);
    CFPropertyListRef valueCase = CFPreferencesCopyAppValue((__bridge CFStringRef)keyCase, lbPreferencesDomainCase);
    return valueCase ? CFBridgingRelease(valueCase) : [specifierCase propertyForKey:@"default"];
}

- (void)setPreferenceValueCase:(id)valueCase specifier:(PSSpecifier *)specifierCase {
    NSString *keyCase = [specifierCase propertyForKey:@"key"];
    if (!keyCase) { return; }

    CFPreferencesSetAppValue((__bridge CFStringRef)keyCase, (__bridge CFPropertyListRef)valueCase, lbPreferencesDomainCase);
    CFPreferencesAppSynchronize(lbPreferencesDomainCase);

    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        lbPreferencesChangedNotificationCase,
        NULL,
        NULL,
        YES
    );
}

// Resprings the operating system, useful when enabling/disabling Lockback
- (void)respringCase {
    pid_t processCase;
    const char *argumentsCase[] = { "killall", "-9", "SpringBoard", NULL };
    extern char **environ;

    posix_spawn(&processCase, "/usr/bin/killall", NULL, NULL, (char *const *)argumentsCase, environ);
}

@end