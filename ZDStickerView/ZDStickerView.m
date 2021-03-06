//
// ZDStickerView.m
//
// Created by Seonghyun Kim on 5/29/13.
// Copyright (c) 2013 scipi. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ZDStickerView.h"
#import "SPGripViewBorderView.h"


#define kSPUserResizableViewDefaultMinWidth 48.0



@interface ZDStickerView ()<UIGestureRecognizerDelegate>

@property (nonatomic, strong) SPGripViewBorderView *borderView;

@property (strong, nonatomic) UIImageView *resizingControl;
@property (strong, nonatomic) UIImageView *deleteControl;
@property (strong, nonatomic) UIImageView *customControl;

@property (nonatomic) BOOL preventsLayoutWhileResizing;

@property (nonatomic) CGFloat deltaAngle;
@property (nonatomic) CGPoint prevPoint;
@property (nonatomic) CGAffineTransform startTransform;

@property (nonatomic) CGPoint touchStart;

@end



@implementation ZDStickerView


#ifdef ZDSTICKERVIEW_LONGPRESS
- (void)longPress:(UIPanGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        if ([self.stickerViewDelegate respondsToSelector:@selector(stickerViewDidLongPressed:)])
        {
            [self.stickerViewDelegate stickerViewDidLongPressed:self];
        }
    }
}
#endif


- (void)singleTap:(UIPanGestureRecognizer *)recognizer
{
    if ([self.stickerViewDelegate respondsToSelector:@selector(stickerViewDidClose:)])
    {
        [self.stickerViewDelegate stickerViewDidClose:self];
    }

    if (NO == self.preventsDeleting)
    {
        UIView *close = (UIView *)[recognizer view];
        [close.superview removeFromSuperview];
    }
}



- (void)customTap:(UIPanGestureRecognizer *)recognizer
{
    if (NO == self.preventsCustomButton)
    {
        if ([self.stickerViewDelegate respondsToSelector:@selector(stickerViewDidCustomButtonTap:)])
        {
            [self.stickerViewDelegate stickerViewDidCustomButtonTap:self];
        }
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    BOOL right = [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]];
    BOOL left = [otherGestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] && [gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]];
    if (right || left) {
        return YES;
    } else {
        return NO;
    }
}

- (void)pinchTranslate:(UIPinchGestureRecognizer *)recognizer {
    if (self.preventsResizing) {
        return;
    }
    if (self.bounds.size.width < self.minWidth || self.bounds.size.height < self.minHeight)
    {
        self.bounds = CGRectMake(self.bounds.origin.x,
                                 self.bounds.origin.y,
                                 self.minWidth+1,
                                 self.minHeight+1);
        self.resizingControl.frame =CGRectMake(self.bounds.size.width-self.controlBtnSize.width,
                                               self.bounds.size.height-self.controlBtnSize.height,
                                               self.controlBtnSize.width,
                                               self.controlBtnSize.height);
        self.deleteControl.frame = CGRectMake(self.lt_controlInset.width, self.lt_controlInset.height,
                                              self.controlBtnSize.width, self.controlBtnSize.height);
        self.customControl.frame =CGRectMake(self.bounds.size.width-self.controlBtnSize.width,
                                             0,
                                             self.controlBtnSize.width,
                                             self.controlBtnSize.height);
        
    }
    // Resizing
    else
    {
        CGFloat scale = recognizer.scale;
        recognizer.scale = 1;
        
        float wChange = (scale - 1) * CGRectGetWidth(self.bounds);
        float hChange = (scale - 1) * CGRectGetHeight(self.bounds);
        
        
        if (ABS(wChange) > 50.0f || ABS(hChange) > 50.0f)
        {
            
            return;
        }
        
        self.bounds = CGRectMake(self.bounds.origin.x, self.bounds.origin.y,
                                 self.bounds.size.width + (wChange),
                                 self.bounds.size.height + (hChange));
        self.resizingControl.frame =CGRectMake(self.bounds.size.width-self.controlBtnSize.width,
                                               self.bounds.size.height-self.controlBtnSize.height,
                                               self.controlBtnSize.width, self.controlBtnSize.height);
        self.deleteControl.frame = CGRectMake(self.lt_controlInset.width, self.lt_controlInset.height,
                                              self.controlBtnSize.width, self.controlBtnSize.height);
        self.customControl.frame =CGRectMake(self.bounds.size.width-self.controlBtnSize.width,
                                             0,
                                             self.controlBtnSize.width,
                                             self.controlBtnSize.height);
        
        self.borderView.frame = CGRectInset(self.bounds, self.borderInset, self.borderInset);
        [self.borderView setNeedsDisplay];
        
        if ([self.stickerViewDelegate respondsToSelector:@selector(stickerView:didChangeSize:)]) {
            [self.stickerViewDelegate stickerView:self didChangeSize:CGSizeMake(wChange, hChange)];
        }
    }
    
}

- (void)panTranslate:(UIPanGestureRecognizer *)pan {
    if (self.preventsMoving) {
        return;
    }
    switch (pan.state) {
        case UIGestureRecognizerStateBegan: {
            
            self.touchStart = [pan locationInView:self.superview];
        }
            break;
        case UIGestureRecognizerStateChanged: {
            CGPoint touch = [pan locationInView:self.superview];
            
            [self translateUsingTouchLocation:touch];
            self.touchStart = touch;
        }
            break;
        case UIGestureRecognizerStateEnded:
            [self enableTransluceny:NO];
            
            // Notify the delegate we've ended our editing session.
            if ([self.stickerViewDelegate respondsToSelector:@selector(stickerViewDidEndEditing:)])
            {
                [self.stickerViewDelegate stickerViewDidEndEditing:self];
            }
            break;
        case UIGestureRecognizerStateCancelled:
            [self enableTransluceny:NO];
            
            // Notify the delegate we've ended our editing session.
            if ([self.stickerViewDelegate respondsToSelector:@selector(stickerViewDidCancelEditing:)])
            {
                [self.stickerViewDelegate stickerViewDidCancelEditing:self];
            }
            break;
        default:
            break;
    }
}

- (void)selectView:(UITapGestureRecognizer *)tap {
    
    [self enableTransluceny:YES];
    if ([self.stickerViewDelegate respondsToSelector:@selector(stickerViewDidBeginEditing:)])
    {
        [self.stickerViewDelegate stickerViewDidBeginEditing:self];
    }
}

- (void)resizeTranslate:(UIPanGestureRecognizer *)recognizer
{
    if ([recognizer state] == UIGestureRecognizerStateBegan)
    {
        [self enableTransluceny:YES];
        self.prevPoint = [recognizer locationInView:self];
        [self setNeedsDisplay];
    }
    else if ([recognizer state] == UIGestureRecognizerStateChanged)
    {
        [self enableTransluceny:YES];
        
        // preventing from the picture being shrinked too far by resizing
        if (self.bounds.size.width < self.minWidth || self.bounds.size.height < self.minHeight)
        {
            self.bounds = CGRectMake(self.bounds.origin.x,
                                     self.bounds.origin.y,
                                     self.minWidth+1,
                                     self.minHeight+1);
            self.resizingControl.frame =CGRectMake(self.bounds.size.width-self.controlBtnSize.width,
                                                   self.bounds.size.height-self.controlBtnSize.height,
                                                   self.controlBtnSize.width,
                                                   self.controlBtnSize.height);
            self.deleteControl.frame = CGRectMake(self.lt_controlInset.width, self.lt_controlInset.height,
                                                  self.controlBtnSize.width, self.controlBtnSize.height);
            self.customControl.frame =CGRectMake(self.bounds.size.width-self.controlBtnSize.width,
                                                 0,
                                                 self.controlBtnSize.width,
                                                 self.controlBtnSize.height);
            self.prevPoint = [recognizer locationInView:self];
        }
        // Resizing
        else
        {
            CGPoint point = [recognizer locationInView:self];
            float wChange = 0.0, hChange = 0.0;

            wChange = (point.x - self.prevPoint.x);
            float wRatioChange = (wChange/(float)self.bounds.size.width);

            hChange = wRatioChange * self.bounds.size.height;

            if (ABS(wChange) > 50.0f || ABS(hChange) > 50.0f)
            {
                self.prevPoint = [recognizer locationOfTouch:0 inView:self];
                return;
            }

            self.bounds = CGRectMake(self.bounds.origin.x, self.bounds.origin.y,
                                     self.bounds.size.width + (wChange),
                                     self.bounds.size.height + (hChange));
            self.resizingControl.frame =CGRectMake(self.bounds.size.width-self.controlBtnSize.width,
                                                   self.bounds.size.height-self.controlBtnSize.height,
                                                   self.controlBtnSize.width, self.controlBtnSize.height);
            self.deleteControl.frame = CGRectMake(self.lt_controlInset.width, self.lt_controlInset.height,
                                                  self.controlBtnSize.width, self.controlBtnSize.height);
            self.customControl.frame =CGRectMake(self.bounds.size.width-self.controlBtnSize.width,
                                                 0,
                                                 self.controlBtnSize.width,
                                                 self.controlBtnSize.height);
            
            self.prevPoint = [recognizer locationOfTouch:0 inView:self];
            
            if ([self.stickerViewDelegate respondsToSelector:@selector(stickerView:didChangeSize:)]) {
                [self.stickerViewDelegate stickerView:self didChangeSize:CGSizeMake(wChange, hChange)];
            }
        }

        /* Rotation */
        float ang = atan2([recognizer locationInView:self.superview].y - self.center.y,
                          [recognizer locationInView:self.superview].x - self.center.x);

        float angleDiff = self.deltaAngle - ang;

        NSLog(@"aaaaaaaaaaa  %f", angleDiff);
        if (NO == self.preventsResizing)
        {
            self.transform = CGAffineTransformMakeRotation(-angleDiff);
            if ([self.stickerViewDelegate respondsToSelector:@selector(stickerView:didChangeToRadian:)]) {
                [self.stickerViewDelegate stickerView:self didChangeToRadian:-angleDiff];
            }
        }

        self.borderView.frame = CGRectInset(self.bounds, self.borderInset, self.borderInset);
        [self.borderView setNeedsDisplay];

        [self setNeedsDisplay];
    }
    else if ([recognizer state] == UIGestureRecognizerStateEnded)
    {
        [self enableTransluceny:NO];
        self.prevPoint = [recognizer locationInView:self];
        [self setNeedsDisplay];
    }
}

- (void)setBorderColor:(UIColor *)borderColor {
    _borderColor = borderColor;
    
    self.borderView.borderColor = borderColor;
}

- (void)setBorderInset:(CGFloat)borderInset {
    _borderInset = borderInset;
    
    self.borderView.frame = CGRectInset(self.bounds, self.borderInset, self.borderInset);
    [self setNeedsDisplay];
}

- (void)setLt_controlInset:(CGSize)lt_controlInset {
    _lt_controlInset = lt_controlInset;
    
    self.deleteControl.frame = CGRectMake(_lt_controlInset.width, _lt_controlInset.height,
                                          self.controlBtnSize.width, self.controlBtnSize.height);
    [self setNeedsDisplay];
}

- (void)setupDefaultAttributes
{
    self.controlBtnSize = CGSizeMake(23, 23);
    self.borderInset = 10.5;
    self.contentInset = 5;
    self.lt_controlInset = CGSizeZero;
    
    self.borderView = [[SPGripViewBorderView alloc] initWithFrame:CGRectInset(self.bounds, self.borderInset, self.borderInset)];
//    self.borderView.backgroundColor = [UIColor redColor];
    self.borderView.borderColor = [UIColor whiteColor];
    [self.borderView setHidden:YES];
    [self addSubview:self.borderView];

    if (kSPUserResizableViewDefaultMinWidth > self.bounds.size.width*0.5)
    {
        self.minWidth = kSPUserResizableViewDefaultMinWidth;
        self.minHeight = self.bounds.size.height * (kSPUserResizableViewDefaultMinWidth/self.bounds.size.width);
    }
    else
    {
        self.minWidth = self.bounds.size.width*0.5;
        self.minHeight = self.bounds.size.height*0.5;
    }

    self.preventsPositionOutsideSuperview = YES;
    self.preventsLayoutWhileResizing = YES;
    self.preventsResizing = NO;
    self.preventsDeleting = NO;
    self.preventsCustomButton = YES;
    self.translucencySticker = YES;

#ifdef ZDSTICKERVIEW_LONGPRESS
    UILongPressGestureRecognizer*longpress = [[UILongPressGestureRecognizer alloc]
                                              initWithTarget:self
                                                      action:@selector(longPress:)];
    [self addGestureRecognizer:longpress];
#endif

    self.deleteControl = [[UIImageView alloc]initWithFrame:CGRectMake(self.lt_controlInset.width, self.lt_controlInset.height,
                                                                      self.controlBtnSize.width, self.controlBtnSize.height)];
    self.deleteControl.backgroundColor = [UIColor clearColor];
    self.deleteControl.image = [UIImage imageNamed:@"ZDStickerView.bundle/ZDBtn3.png"];
    self.deleteControl.userInteractionEnabled = YES;
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc]
                                         initWithTarget:self
                                                 action:@selector(singleTap:)];
    [self.deleteControl addGestureRecognizer:singleTap];
    [self addSubview:self.deleteControl];

    self.resizingControl = [[UIImageView alloc]initWithFrame:CGRectMake(self.frame.size.width-self.controlBtnSize.width,
                                                                        self.frame.size.height-self.controlBtnSize.height,
                                                                        self.controlBtnSize.width, self.controlBtnSize.height)];
    self.resizingControl.backgroundColor = [UIColor clearColor];
    self.resizingControl.userInteractionEnabled = YES;
    self.resizingControl.image = [UIImage imageNamed:@"ZDStickerView.bundle/ZDBtn2.png.png"];
    UIPanGestureRecognizer*panResizeGesture = [[UIPanGestureRecognizer alloc]
                                               initWithTarget:self
                                                       action:@selector(resizeTranslate:)];
    [self.resizingControl addGestureRecognizer:panResizeGesture];
    [self addSubview:self.resizingControl];

    self.customControl = [[UIImageView alloc]initWithFrame:CGRectMake(self.frame.size.width-self.controlBtnSize.width,
                                                                      0,
                                                                      self.controlBtnSize.width, self.controlBtnSize.height)];
    self.customControl.backgroundColor = [UIColor clearColor];
    self.customControl.userInteractionEnabled = YES;
    self.customControl.image = nil;
    
    
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc]
                                              initWithTarget:self
                                              action:@selector(pinchTranslate:)];
    pinchGesture.delegate = self;
    [self addGestureRecognizer:pinchGesture];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panTranslate:)];
    panGesture.delegate = self;
    [self addGestureRecognizer:panGesture];
    
    UITapGestureRecognizer *selectGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectView:)];
    [self addGestureRecognizer:selectGesture];
    
    UITapGestureRecognizer *customTapGesture = [[UITapGestureRecognizer alloc]
                                                initWithTarget:self
                                                        action:@selector(customTap:)];
    [self.customControl addGestureRecognizer:customTapGesture];
    [self addSubview:self.customControl];

    self.deltaAngle = atan2(self.frame.origin.y+self.frame.size.height - self.center.y,
                            self.frame.origin.x+self.frame.size.width - self.center.x);
}



- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        [self setupDefaultAttributes];
    }

    return self;
}



- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        [self setupDefaultAttributes];
    }

    return self;
}



- (void)setContentView:(UIView *)newContentView
{
    [self.contentView removeFromSuperview];
    _contentView = newContentView;

    self.contentView.frame = CGRectInset(self.bounds,
                                         self.contentInset + self.borderInset,
                                         self.contentInset + self.borderInset);

    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [self addSubview:self.contentView];

    for (UIView *subview in [self.contentView subviews])
    {
        [subview setFrame:CGRectMake(0, 0,
                                     self.contentView.frame.size.width,
                                     self.contentView.frame.size.height)];

        subview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }

    [self bringSubviewToFront:self.borderView];
    [self bringSubviewToFront:self.resizingControl];
    [self bringSubviewToFront:self.deleteControl];
    [self bringSubviewToFront:self.customControl];
}



- (void)setFrame:(CGRect)newFrame
{
    [super setFrame:newFrame];
    self.contentView.frame = CGRectInset(self.bounds,
                                         self.contentInset + self.borderInset,
                                         self.contentInset + self.borderInset);

    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    for (UIView *subview in [self.contentView subviews])
    {
        [subview setFrame:CGRectMake(0, 0,
                                     self.contentView.frame.size.width,
                                     self.contentView.frame.size.height)];

        subview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }

    self.borderView.frame = CGRectInset(self.bounds,
                                        self.borderInset,
                                        self.borderInset);

    self.resizingControl.frame =CGRectMake(self.bounds.size.width-self.controlBtnSize.width,
                                           self.bounds.size.height-self.controlBtnSize.height,
                                           self.controlBtnSize.width,
                                           self.controlBtnSize.height);

    self.deleteControl.frame = CGRectMake(self.lt_controlInset.width, self.lt_controlInset.height,
                                          self.controlBtnSize.width, self.controlBtnSize.height);

    self.customControl.frame =CGRectMake(self.bounds.size.width-self.controlBtnSize.width,
                                         0,
                                         self.controlBtnSize.width,
                                         self.controlBtnSize.height);

    [self.borderView setNeedsDisplay];
}



- (void)translateUsingTouchLocation:(CGPoint)touchPoint
{
    CGPoint newCenter = CGPointMake(self.center.x + touchPoint.x - self.touchStart.x,
                                    self.center.y + touchPoint.y - self.touchStart.y);

    if (self.preventsPositionOutsideSuperview)
    {
        // Ensure the translation won't cause the view to move offscreen.
        CGFloat midPointX = CGRectGetMidX(self.bounds);
        if (newCenter.x > self.superview.bounds.size.width - midPointX)
        {
            newCenter.x = self.superview.bounds.size.width - midPointX;
        }

        if (newCenter.x < midPointX)
        {
            newCenter.x = midPointX;
        }

        CGFloat midPointY = CGRectGetMidY(self.bounds);
        if (newCenter.y > self.superview.bounds.size.height - midPointY)
        {
            newCenter.y = self.superview.bounds.size.height - midPointY;
        }

        if (newCenter.y < midPointY)
        {
            newCenter.y = midPointY;
        }
    }

    self.center = newCenter;
    if ([self.stickerViewDelegate respondsToSelector:@selector(stickerView:didTranslateToCenter:)]) {
        [self.stickerViewDelegate stickerView:self didTranslateToCenter:self.center];
    }
}

- (void)hideDelHandle
{
    self.deleteControl.hidden = YES;
}

- (void)showDelHandle
{
    self.deleteControl.hidden = NO;
}



- (void)hideEditingHandles
{
    self.resizingControl.hidden = YES;
    self.deleteControl.hidden = YES;
    self.customControl.hidden = YES;
    [self.borderView setHidden:YES];
}



- (void)showEditingHandles
{
    if (NO == self.preventsCustomButton)
    {
        self.customControl.hidden = NO;
    }
    else
    {
        self.customControl.hidden = YES;
    }

    if (NO == self.preventsDeleting)
    {
        self.deleteControl.hidden = NO;
    }
    else
    {
        self.deleteControl.hidden = YES;
    }

    if (NO == self.preventsResizing)
    {
        self.resizingControl.hidden = NO;
    }
    else
    {
        self.resizingControl.hidden = YES;
    }

    [self.borderView setHidden:NO];
}



- (void)showCustomHandle
{
    self.customControl.hidden = NO;
}



- (void)hideCustomHandle
{
    self.customControl.hidden = YES;
}



- (void)setButton:(ZDSTICKERVIEW_BUTTONS)type image:(UIImage*)image
{
    switch (type)
    {
        case ZDSTICKERVIEW_BUTTON_RESIZE:
            self.resizingControl.image = image;
            break;
        case ZDSTICKERVIEW_BUTTON_DEL:
            self.deleteControl.image = image;
            break;
        case ZDSTICKERVIEW_BUTTON_CUSTOM:
            self.customControl.image = image;
            break;

        default:
            break;
    }
}



- (BOOL)isEditingHandlesHidden
{
    return self.borderView.hidden;
}



- (void)enableTransluceny:(BOOL)state
{
    if (self.translucencySticker == YES)
    {
        if (state == YES)
        {
            self.alpha = 0.65;
        }
        else
        {
            self.alpha = 1.0;
        }
    }
}



@end
