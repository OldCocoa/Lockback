#import <UIKit/UIKit.h>

// Owns and lays out the recreated lock screen clock and date.
@interface LBTimeDateView : UIView
@property (nonatomic, strong) UILabel *timeLabelCase;
@property (nonatomic, strong) UILabel *dateLabelCase;
@property (nonatomic, strong) NSDateFormatter *timeFormatterCase;
@property (nonatomic, strong) NSDateFormatter *dateFormatterCase;
// Reapplies the appropriate fonts when the device or text-size metrics change.
- (void)updateLabelFonts;
// Rebuilds the localized time and date formatters.
- (void)refreshFormatters;
// Updates the visible time, date, and their accessibility labels.
- (void)setDate:(NSDate *)dateCase;
@end    