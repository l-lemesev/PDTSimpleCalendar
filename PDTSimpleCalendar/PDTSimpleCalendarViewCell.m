//
//  PDTSimpleCalendarViewCell.m
//  PDTSimpleCalendar
//
//  Created by Jerome Miglino on 10/7/13.
//  Copyright (c) 2013 Producteev. All rights reserved.
//

#import "PDTSimpleCalendarViewCell.h"

const CGFloat PDTSimpleCalendarCircleSize = 32.0f;

CGFloat const radiusCircle = 12.0f;
CGFloat const offsetCircle = 2.0f;

CGFloat const lineWidth = 1.0f;
CGFloat const startRadius = PDTSimpleCalendarCircleSize / 2 + 2;
CGFloat const stepRadius = 1.0f;
CGFloat const radiusSpacing = 1.0f;

CGFloat const startAngle = 270.0f; // Angle we start our calculations from.
CGFloat const firstArcStartAngle = startAngle - 15.0f;
CGFloat const firstArcEndAngle = startAngle + 90.0f;

CGFloat const secondArcStartAngle = startAngle;
CGFloat const secondArcEndAngle = startAngle + 75.0f;

CGFloat const thirdArcStartAngle = startAngle + 15.0f;
CGFloat const thirdArcEndAngle = startAngle + 60;


@interface PDTSimpleCalendarViewCell ()

@property (nonatomic, strong) UILabel *dayLabel;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) CAShapeLayer *firstArcLayer;
@property (nonatomic, strong) CAShapeLayer *secondArcLayer;
@property (nonatomic, strong) CAShapeLayer *thirdArcLayer;

@end

@implementation PDTSimpleCalendarViewCell

#pragma mark - Class Methods

+ (NSString *)formatDate:(NSDate *)date withCalendar:(NSCalendar *)calendar
{
    NSDateFormatter *dateFormatter = [self dateFormatter];
    return [PDTSimpleCalendarViewCell stringFromDate:date withDateFormatter:dateFormatter withCalendar:calendar];
}

+ (NSString *)formatAccessibilityDate:(NSDate *)date withCalendar:(NSCalendar *)calendar
{
    NSDateFormatter *dateFormatter = [self accessibilityDateFormatter];
    return [PDTSimpleCalendarViewCell stringFromDate:date withDateFormatter:dateFormatter withCalendar:calendar];
}


+ (NSDateFormatter *)dateFormatter {
    static NSDateFormatter *dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"d";
    });
    return dateFormatter;
}

+ (NSDateFormatter *)accessibilityDateFormatter {
    static NSDateFormatter *dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterLongStyle];
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        
    });
    return dateFormatter;
}

+ (NSString *)stringFromDate:(NSDate *)date withDateFormatter:(NSDateFormatter *)dateFormatter withCalendar:(NSCalendar *)calendar {
    //Test if the calendar is different than the current dateFormatter calendar property
    if (![dateFormatter.calendar isEqual:calendar]) {
        dateFormatter.calendar = calendar;
    }
    return [dateFormatter stringFromDate:date];
}

#pragma mark - Instance Methods

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _date = nil;
        _isToday = NO;
        _dayLabel = [[UILabel alloc] init];
        [self.dayLabel setFont:[self textDefaultFont]];
        [self.dayLabel setTextAlignment:NSTextAlignmentCenter];
        [self.contentView addSubview:self.dayLabel];

        //Add the Constraints
        [self.dayLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.dayLabel setBackgroundColor:[UIColor clearColor]];
        self.dayLabel.layer.cornerRadius = PDTSimpleCalendarCircleSize/2;
        self.dayLabel.layer.masksToBounds = YES;

        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.dayLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.dayLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.dayLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:PDTSimpleCalendarCircleSize]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.dayLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:PDTSimpleCalendarCircleSize]];

        [self setCircleColor:NO selected:NO];
    }

    return self;
}

- (void)setDate:(NSDate *)date calendar:(NSCalendar *)calendar
{
    NSString* day = @"";
    NSString* accessibilityDay = @"";
    if (date && calendar) {
        _date = date;
        day = [PDTSimpleCalendarViewCell formatDate:date withCalendar:calendar];
        accessibilityDay = [PDTSimpleCalendarViewCell formatAccessibilityDate:date withCalendar:calendar];
    }
    self.dayLabel.text = day;
    self.dayLabel.accessibilityLabel = accessibilityDay;
}

- (void)setIsToday:(BOOL)isToday
{
    _isToday = isToday;
    [self setCircleColor:isToday selected:self.selected];
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self setCircleColor:self.isToday selected:selected];
    if (!selected) {
        [self.firstArcLayer removeFromSuperlayer];
        [self.secondArcLayer removeFromSuperlayer];
        [self.thirdArcLayer removeFromSuperlayer];
    }
}


- (void)setCircleColor:(BOOL)today selected:(BOOL)selected
{
    UIColor *circleColor = (today) ? [self circleTodayColor] : [self circleDefaultColor];
    UIColor *labelColor = (today) ? [self textTodayColor] : [self textDefaultColor];

    if (self.date && self.delegate) {
        if ([self.delegate respondsToSelector:@selector(simpleCalendarViewCell:shouldUseCustomColorsForDate:)] && [self.delegate simpleCalendarViewCell:self shouldUseCustomColorsForDate:self.date]) {

            if ([self.delegate respondsToSelector:@selector(simpleCalendarViewCell:textColorForDate:)] && [self.delegate simpleCalendarViewCell:self textColorForDate:self.date]) {
                labelColor = [self.delegate simpleCalendarViewCell:self textColorForDate:self.date];
            }

            if ([self.delegate respondsToSelector:@selector(simpleCalendarViewCell:circleColorForDate:)] && [self.delegate simpleCalendarViewCell:self circleColorForDate:self.date]) {
                circleColor = [self.delegate simpleCalendarViewCell:self circleColorForDate:self.date];
            }
        }
    }
    
    if (selected) {
        circleColor = [self circleSelectedColor];
        labelColor = [self textSelectedColor];
    }

    [self.dayLabel setBackgroundColor:circleColor];
    [self.dayLabel setTextColor:labelColor];
}


- (void)refreshCellColors
{
    [self setCircleColor:self.isToday selected:self.isSelected];
}

- (void)setNumberOfItems:(NSInteger)numberOfItems {
    if (numberOfItems > 0 && self.date) {
        self.selected = YES;
        if (numberOfItems == 2) {
            [self drawFirstArc];
        } else if (numberOfItems == 3) {
            [self drawFirstArc];
            [self drawSecondArc];
        } else if (numberOfItems > 3) {
            [self drawFirstArc];
            [self drawSecondArc];
            [self drawThirdArc];
        }
    } else {
        [self.firstArcLayer removeFromSuperlayer];
        [self.secondArcLayer removeFromSuperlayer];
        [self.thirdArcLayer removeFromSuperlayer];
    }
}

#pragma mark - Prepare for Reuse

- (void)prepareForReuse
{
    [super prepareForReuse];
    _date = nil;
    _isToday = NO;
    [self.dayLabel setText:@""];
    [self.dayLabel setBackgroundColor:[self circleDefaultColor]];
    [self.dayLabel setTextColor:[self textDefaultColor]];
}

#pragma mark - Circle Color Customization Methods

- (UIColor *)circleDefaultColor
{
    if(_circleDefaultColor == nil) {
        _circleDefaultColor = [[[self class] appearance] circleDefaultColor];
    }

    if(_circleDefaultColor != nil) {
        return _circleDefaultColor;
    }

    return [UIColor whiteColor];
}

- (UIColor *)circleTodayColor
{
    if(_circleTodayColor == nil) {
        _circleTodayColor = [[[self class] appearance] circleTodayColor];
    }

    if(_circleTodayColor != nil) {
        return _circleTodayColor;
    }

    return [UIColor grayColor];
}

- (UIColor *)circleSelectedColor
{
    if(_circleSelectedColor == nil) {
        _circleSelectedColor = [[[self class] appearance] circleSelectedColor];
    }

    if(_circleSelectedColor != nil) {
        return _circleSelectedColor;
    }

    return [UIColor redColor];
}

#pragma mark - Text Label Customizations Color

- (UIColor *)textDefaultColor
{
    if(_textDefaultColor == nil) {
        _textDefaultColor = [[[self class] appearance] textDefaultColor];
    }

    if(_textDefaultColor != nil) {
        return _textDefaultColor;
    }

    return [UIColor blackColor];
}

- (UIColor *)textTodayColor
{
    if(_textTodayColor == nil) {
        _textTodayColor = [[[self class] appearance] textTodayColor];
    }

    if(_textTodayColor != nil) {
        return _textTodayColor;
    }

    return [UIColor whiteColor];
}

- (UIColor *)textSelectedColor
{
    if(_textSelectedColor == nil) {
        _textSelectedColor = [[[self class] appearance] textSelectedColor];
    }

    if(_textSelectedColor != nil) {
        return _textSelectedColor;
    }

    return [UIColor whiteColor];
}

- (UIColor *)textDisabledColor
{
    if(_textDisabledColor == nil) {
        _textDisabledColor = [[[self class] appearance] textDisabledColor];
    }

    if(_textDisabledColor != nil) {
        return _textDisabledColor;
    }

    return [UIColor lightGrayColor];
}

- (UIColor *)itemSelectionColor {
    if (_itemSelectionColor == nil) {
        _itemSelectionColor = [[[self class] appearance] itemSelectionColor];
    }
    
    if (_itemSelectionColor != nil) {
        return _itemSelectionColor;
    }
    
    return [UIColor whiteColor];
}

#pragma mark - Text Label Customizations Font

- (UIFont *)textDefaultFont
{
    if(_textDefaultFont == nil) {
        _textDefaultFont = [[[self class] appearance] textDefaultFont];
    }

    if (_textDefaultFont != nil) {
        return _textDefaultFont;
    }

    // default system font
    return [UIFont systemFontOfSize:17.0];
}

#pragma mark - Items selection 

- (void)drawFirstArc {
    self.firstArcLayer = [self addArcWithRadius:startRadius startAngle:firstArcStartAngle endAngle:firstArcEndAngle];
}

- (void)drawSecondArc {
    self.secondArcLayer = [self addArcWithRadius:startRadius + stepRadius + radiusSpacing startAngle:secondArcStartAngle endAngle:secondArcEndAngle];
}

- (void)drawThirdArc {
    self.thirdArcLayer = [self addArcWithRadius:startRadius + stepRadius * 2 + radiusSpacing * 2 startAngle:thirdArcStartAngle endAngle:thirdArcEndAngle];
}

- (CAShapeLayer *)addArcWithRadius:(CGFloat)radius startAngle:(CGFloat)startAngle endAngle:(CGFloat)endAngle {
    CAShapeLayer *circle = [CAShapeLayer layer];
    CGPoint center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:radians(startAngle) endAngle:radians(endAngle) clockwise:YES];
    
    circle.path = [path CGPath];
    circle.fillColor = [UIColor clearColor].CGColor;
    circle.lineCap = kCALineCapRound;
    
    UIColor *strokeColor = self.circleSelectedColor;
    circle.strokeColor = strokeColor.CGColor;
    circle.lineWidth = lineWidth;
    [self.layer addSublayer:circle];
    return circle;
}

static inline double radians(double degrees) {
    return degrees * M_PI / 180;
}

@end
