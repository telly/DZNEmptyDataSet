//
//  UIScrollView+EmptyDataSet.m
//  DZNEmptyDataSet
//  https://github.com/dzenbot/DZNEmptyDataSet
//
//  Created by Ignacio Romero Zurbuchen on 6/20/14.
//  Copyright (c) 2014 DZN Labs. All rights reserved.
//  Licence: MIT-Licence
//

#import "UIScrollView+EmptyDataSet.h"
#import <objc/runtime.h>

@interface DZNEmptyDataSetView : UIView

@property (nonatomic, readonly) UIView *contentView;
@property (nonatomic, readonly) UILabel *titleLabel;
@property (nonatomic, readonly) UILabel *detailLabel;
@property (nonatomic, readonly) UIImageView *imageView;
@property (nonatomic, readonly) UIButton *button;
@property (nonatomic, strong) UIView *customView;
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;

@property (nonatomic, assign) CGPoint offset;
@property (nonatomic, assign) CGFloat verticalSpace;

- (void)removeAllSubviews;

@end

#pragma mark - UIScrollView+EmptyDataSet

static char const * const kEmptyDataSetSource =     "emptyDataSetSource";
static char const * const kEmptyDataSetDelegate =   "emptyDataSetDelegate";
static char const * const kEmptyDataSetView =       "emptyDataSetView";

@interface UIScrollView () <UIGestureRecognizerDelegate>
@property (nonatomic, readonly) DZNEmptyDataSetView *emptyDataSetView;
@end

@implementation UIScrollView (DZNEmptyDataSet)

#pragma mark - Getters (Public)

- (id<DZNEmptyDataSetSource>)emptyDataSetSource
{
    return objc_getAssociatedObject(self, kEmptyDataSetSource);
}

- (id<DZNEmptyDataSetDelegate>)emptyDataSetDelegate
{
    return objc_getAssociatedObject(self, kEmptyDataSetDelegate);
}

- (BOOL)isEmptyDataSetVisible
{
    UIView *view = objc_getAssociatedObject(self, kEmptyDataSetView);
    return view ? !view.hidden : NO;
}


#pragma mark - Getters (Private)

- (DZNEmptyDataSetView *)emptyDataSetView
{
    DZNEmptyDataSetView *view = objc_getAssociatedObject(self, kEmptyDataSetView);
    
    if (!view)
    {
        view = [DZNEmptyDataSetView new];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        view.hidden = YES;
        
        view.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dzn_didTapContentView:)];
        view.tapGesture.delegate = self;
        [view addGestureRecognizer:view.tapGesture];

        [self setEmptyDataSetView:view];
    }
    return view;
}

- (BOOL)dzn_canDisplay
{
    if ([self isKindOfClass:[UITableView class]] || [self isKindOfClass:[UICollectionView class]] || [self isKindOfClass:[UIScrollView class]])
    {
        id source = self.emptyDataSetSource;
        
        if (source && [source conformsToProtocol:@protocol(DZNEmptyDataSetSource)]) {
            return YES;
        }
        else {
            return NO;
        }
    }
    return NO;
}

- (NSInteger)dzn_itemsCount
{
    NSInteger items = 0;
    
    if (![self respondsToSelector:@selector(dataSource)]) {
        return items;
    }
    
    if ([self isKindOfClass:[UITableView class]]) {
        
        id <UITableViewDataSource> dataSource = [self performSelector:@selector(dataSource)];
        UITableView *tableView = (UITableView *)self;
        
        NSInteger sections = 1;
        if ([dataSource respondsToSelector:@selector(numberOfSectionsInTableView:)]) {
            sections = [dataSource numberOfSectionsInTableView:tableView];
        }
        
        for (NSInteger i = 0; i < sections; i++) {
            items += [dataSource tableView:tableView numberOfRowsInSection:i];
        }
    }
    else if ([self isKindOfClass:[UICollectionView class]]) {
        
        id <UICollectionViewDataSource> dataSource = [self performSelector:@selector(dataSource)];
        UICollectionView *collectionView = (UICollectionView *)self;
        
        NSInteger sections = 1;
        if ([dataSource respondsToSelector:@selector(numberOfSectionsInCollectionView:)]) {
            sections = [dataSource numberOfSectionsInCollectionView:collectionView];
        }
        
        for (NSInteger i = 0; i < sections; i++) {
            items += [dataSource collectionView:collectionView numberOfItemsInSection:i];
        }
    }
    
    return items;
}


#pragma mark - Data Source Getters

- (NSAttributedString *)dzn_titleLabelText
{
    if (self.emptyDataSetSource && [self.emptyDataSetSource respondsToSelector:@selector(titleForEmptyDataSet:)]) {
        NSAttributedString *string = [self.emptyDataSetSource titleForEmptyDataSet:self];
        if (string) NSAssert([string isKindOfClass:[NSAttributedString class]], @"You must return a valid NSAttributedString object -titleForEmptyDataSet:");
        return string;
    }
    return nil;
}

- (NSAttributedString *)dzn_detailLabelText
{
    if (self.emptyDataSetSource && [self.emptyDataSetSource respondsToSelector:@selector(descriptionForEmptyDataSet:)]) {
        NSAttributedString *string = [self.emptyDataSetSource descriptionForEmptyDataSet:self];
        if (string) NSAssert([string isKindOfClass:[NSAttributedString class]], @"You must return a valid NSAttributedString object -descriptionForEmptyDataSet:");
        return string;
    }
    return nil;
}

- (UIImage *)dzn_image
{
    if (self.emptyDataSetSource && [self.emptyDataSetSource respondsToSelector:@selector(imageForEmptyDataSet:)]) {
        UIImage *image = [self.emptyDataSetSource imageForEmptyDataSet:self];
        if (image) NSAssert([image isKindOfClass:[UIImage class]], @"You must return a valid UIImage object for -imageForEmptyDataSet:");
        return image;
    }
    return nil;
}

- (UIColor *)dzn_imageTintColor
{
    if (self.emptyDataSetSource && [self.emptyDataSetSource respondsToSelector:@selector(imageTintColorForEmptyDataSet:)]) {
        UIColor *color = [self.emptyDataSetSource imageTintColorForEmptyDataSet:self];
        if (color) NSAssert([color isKindOfClass:[UIColor class]], @"You must return a valid UIColor object -imageTintColorForEmptyDataSet:");
        return color;
    }
    return nil;
}

- (NSAttributedString *)dzn_buttonTitleForState:(UIControlState)state
{
    if (self.emptyDataSetSource && [self.emptyDataSetSource respondsToSelector:@selector(buttonTitleForEmptyDataSet:forState:)]) {
        NSAttributedString *string = [self.emptyDataSetSource buttonTitleForEmptyDataSet:self forState:state];
        if (string) NSAssert([string isKindOfClass:[NSAttributedString class]], @"You must return a valid NSAttributedString object for -buttonTitleForEmptyDataSet:forState:");
        return string;
    }
    return nil;
}

- (UIImage *)dzn_buttonBackgroundImageForState:(UIControlState)state
{
    if (self.emptyDataSetSource && [self.emptyDataSetSource respondsToSelector:@selector(buttonBackgroundImageForEmptyDataSet:forState:)]) {
        UIImage *image = [self.emptyDataSetSource buttonBackgroundImageForEmptyDataSet:self forState:state];
        if (image) NSAssert([image isKindOfClass:[UIImage class]], @"You must return a valid UIImage object for -buttonBackgroundImageForEmptyDataSet:forState:");
        return image;
    }
    return nil;
}

- (UIColor *)dzn_dataSetBackgroundColor
{
    if (self.emptyDataSetSource && [self.emptyDataSetSource respondsToSelector:@selector(backgroundColorForEmptyDataSet:)]) {
        UIColor *color = [self.emptyDataSetSource backgroundColorForEmptyDataSet:self];
        if (color) NSAssert([color isKindOfClass:[UIColor class]], @"You must return a valid UIColor object -backgroundColorForEmptyDataSet:");
        return color;
    }
    return [UIColor clearColor];
}

- (UIView *)dzn_customView
{
    if (self.emptyDataSetSource && [self.emptyDataSetSource respondsToSelector:@selector(customViewForEmptyDataSet:)]) {
        UIView *view = [self.emptyDataSetSource customViewForEmptyDataSet:self];
        if (view) NSAssert([view isKindOfClass:[UIView class]], @"You must return a valid UIView object for -customViewForEmptyDataSet:");
        return view;
    }
    return nil;
}

- (CGPoint)dzn_offset
{
    CGFloat left = roundf(self.contentInset.left / 2.0);
    CGFloat right = roundf(self.contentInset.right / 2.0);
    
    // Honors the scrollView's contentInset
    CGPoint offset = CGPointMake(left-right, 0);
    
    if (self.emptyDataSetSource && [self.emptyDataSetSource respondsToSelector:@selector(offsetForEmptyDataSet:)]) {
        CGPoint customOffset = [self.emptyDataSetSource offsetForEmptyDataSet:self];
        offset = CGPointMake(offset.x + customOffset.x, offset.y + customOffset.y);
    }
    
    return offset;
}

- (CGFloat)dzn_verticalSpace
{
    if (self.emptyDataSetSource && [self.emptyDataSetSource respondsToSelector:@selector(spaceHeightForEmptyDataSet:)]) {
        return [self.emptyDataSetSource spaceHeightForEmptyDataSet:self];
    }
    return 0.0;
}


#pragma mark - Delegate Getters & Events (Private)

- (BOOL)dzn_shouldDisplay
{
    if (self.emptyDataSetDelegate && [self.emptyDataSetDelegate respondsToSelector:@selector(emptyDataSetShouldDisplay:)]) {
        return [self.emptyDataSetDelegate emptyDataSetShouldDisplay:self];
    }
    return YES;
}

- (BOOL)dzn_isTouchAllowed
{
    if (self.emptyDataSetDelegate && [self.emptyDataSetDelegate respondsToSelector:@selector(emptyDataSetShouldAllowTouch:)]) {
        return [self.emptyDataSetDelegate emptyDataSetShouldAllowTouch:self];
    }
    return YES;
}

- (BOOL)dzn_isScrollAllowed
{
    if (self.emptyDataSetDelegate && [self.emptyDataSetDelegate respondsToSelector:@selector(emptyDataSetShouldAllowScroll:)]) {
        return [self.emptyDataSetDelegate emptyDataSetShouldAllowScroll:self];
    }
    return NO;
}

- (void)dzn_willAppear
{
    if (self.emptyDataSetDelegate && [self.emptyDataSetDelegate respondsToSelector:@selector(emptyDataSetWillAppear:)]) {
        [self.emptyDataSetDelegate emptyDataSetWillAppear:self];
    }
}

- (void)dzn_didAppear
{
    if (self.emptyDataSetDelegate && [self.emptyDataSetDelegate respondsToSelector:@selector(emptyDataSetDidAppear:)]) {
        [self.emptyDataSetDelegate emptyDataSetDidAppear:self];
    }
}

- (void)dzn_willDisappear
{
    if (self.emptyDataSetDelegate && [self.emptyDataSetDelegate respondsToSelector:@selector(emptyDataSetWillDisappear:)]) {
        [self.emptyDataSetDelegate emptyDataSetWillDisappear:self];
    }
}

- (void)dzn_didTapContentView:(id)sender
{
    if (self.emptyDataSetDelegate && [self.emptyDataSetDelegate respondsToSelector:@selector(emptyDataSetDidTapView:)]) {
        [self.emptyDataSetDelegate emptyDataSetDidTapView:self];
    }
}

- (void)dzn_didTapDataButton:(id)sender
{
    if (self.emptyDataSetDelegate && [self.emptyDataSetDelegate respondsToSelector:@selector(emptyDataSetDidTapButton:)]) {
        [self.emptyDataSetDelegate emptyDataSetDidTapButton:self];
    }
}


#pragma mark - Setters (Public)

- (void)setEmptyDataSetSource:(id<DZNEmptyDataSetSource>)source
{
    // Registers for device orientation changes
    if (source && !self.emptyDataSetSource) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceDidChangeOrientation:) name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    else if (!source && self.emptyDataSetSource) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    
    objc_setAssociatedObject(self, kEmptyDataSetSource, source, OBJC_ASSOCIATION_ASSIGN);
    
    if (![self dzn_canDisplay]) {
        return;
    }
    
    // We add method sizzling for injecting -dzn_reloadData implementation to the native -reloadData implementation
    [self swizzle:@selector(reloadData)];
    
    // If UITableView, we also inject -dzn_reloadData to -endUpdates
    if ([self isKindOfClass:[UITableView class]]) {
        [self swizzle:@selector(endUpdates)];
    }
}

- (void)setEmptyDataSetDelegate:(id<DZNEmptyDataSetDelegate>)delegate
{
    objc_setAssociatedObject(self, kEmptyDataSetDelegate, delegate, OBJC_ASSOCIATION_ASSIGN);
    
    if (!delegate) {
        [self dzn_invalidate];
    }
}


#pragma mark - Setters (Private)

- (void)setEmptyDataSetView:(DZNEmptyDataSetView *)view
{
    objc_setAssociatedObject(self, kEmptyDataSetView, view, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


#pragma mark - Reload APIs (Public)

- (void)reloadEmptyDataSet
{
    [self dzn_reloadEmptyDataSet];
}


#pragma mark - Reload APIs (Private)

- (void)dzn_reloadEmptyDataSet
{
    if (![self dzn_canDisplay]) {
        return;
    }
    
    if ([self dzn_shouldDisplay] && [self dzn_itemsCount] == 0)
    {
        // Notifies that the empty dataset view will appear
        [self dzn_willAppear];
        
        DZNEmptyDataSetView *view = self.emptyDataSetView;
        UIView *customView = [self dzn_customView];
        
        if (!view.superview) {

            // Send the view to back, in case a header and/or footer is present
            if (([self isKindOfClass:[UITableView class]] || [self isKindOfClass:[UICollectionView class]]) && self.subviews.count > 1) {
                [self insertSubview:view atIndex:1];
            }
            else {
                [self addSubview:view];
            }
        }
        
        // Moves all its subviews
        [view removeAllSubviews];
        
        // If a non-nil custom view is available, let's configure it instead
        if (customView) {
            view.customView = customView;
        }
        else {
            // Configure labels
            view.detailLabel.attributedText = [self dzn_detailLabelText];
            view.titleLabel.attributedText = [self dzn_titleLabelText];
            
            // Configure imageview
            UIColor *tintColor = [self dzn_imageTintColor];
            UIImage *image = [self dzn_image];
            UIImageRenderingMode renderingMode = tintColor ? UIImageRenderingModeAlwaysTemplate : UIImageRenderingModeAlwaysOriginal;
            
            view.imageView.image = [image imageWithRenderingMode:renderingMode];
            view.imageView.tintColor = tintColor;
            
            // Configure button
            [view.button setAttributedTitle:[self dzn_buttonTitleForState:UIControlStateNormal] forState:UIControlStateNormal];
            [view.button setAttributedTitle:[self dzn_buttonTitleForState:UIControlStateHighlighted] forState:UIControlStateHighlighted];
            [view.button setBackgroundImage:[self dzn_buttonBackgroundImageForState:UIControlStateNormal] forState:UIControlStateNormal];
            [view.button setBackgroundImage:[self dzn_buttonBackgroundImageForState:UIControlStateHighlighted] forState:UIControlStateHighlighted];
            
            // Configure spacing
            view.verticalSpace = [self dzn_verticalSpace];
        }
        
        // Configure Offset
        view.offset = [self dzn_offset];
        
        // Configure the empty dataset view
        view.backgroundColor = [self dzn_dataSetBackgroundColor];
        view.hidden = NO;
        
        [view setNeedsLayout];
        [view layoutIfNeeded];
        
        // Configure scroll permission
        self.scrollEnabled = [self dzn_isScrollAllowed];

        // Configure empty dataset userInteraction permission
        view.userInteractionEnabled = [self dzn_isTouchAllowed];

        // Notifies that the empty dataset view did appear
        [self dzn_didAppear];
    }
    else if (self.isEmptyDataSetVisible) {
        [self dzn_invalidate];
    }
}

- (void)dzn_invalidate
{
    // Notifies that the empty dataset view will disappear
    [self dzn_willDisappear];

    if (self.emptyDataSetView) {
        [self.emptyDataSetView removeAllSubviews];
        [self.emptyDataSetView removeFromSuperview];
        
        [self setEmptyDataSetView:nil];
    }
    
    self.scrollEnabled = YES;
}



#pragma mark - Notification Events

- (void)deviceDidChangeOrientation:(NSNotification *)notification
{
    if (self.isEmptyDataSetVisible) {
        [self.emptyDataSetView setNeedsLayout];
        [self.emptyDataSetView layoutIfNeeded];
    }
}


#pragma mark - Method Swizzling

static NSMutableDictionary *_impLookupTable;
static NSString *const DZNSwizzleInfoPointerKey = @"pointer";
static NSString *const DZNSwizzleInfoOwnerKey = @"owner";
static NSString *const DZNSwizzleInfoSelectorKey = @"selector";

// Based on Bryce Buchanan's swizzling technique http://blog.newrelic.com/2014/04/16/right-way-to-swizzle/
// And Juzzin's ideas https://github.com/juzzin/JUSEmptyViewController

static void dzn_original_implementation(id self, SEL _cmd)
{
    // Fetch original implementation from lookup table
    NSString *key = dzn_implementationKey(self, _cmd);
    
    NSDictionary *swizzleInfo = [_impLookupTable objectForKey:key];
    NSValue *impValue = [swizzleInfo valueForKey:DZNSwizzleInfoPointerKey];
    
    IMP impPointer = [impValue pointerValue];
    
    // We then inject the additional implementation for reloading the empty dataset
    // Doing it before calling the original implementation does update the 'isEmptyDataSetVisible' flag on time.
    [self dzn_reloadEmptyDataSet];

    // If found, call original implementation
    if (impPointer) {
        ((void(*)(id,SEL))impPointer)(self,_cmd);
    }
}

static NSString *dzn_implementationKey(id target, SEL selector)
{
    if (!target || !selector) {
        return nil;
    }
    
    Class baseClass;
    if ([target isKindOfClass:[UITableView class]]) baseClass = [UITableView class];
    else if ([target isKindOfClass:[UICollectionView class]]) baseClass = [UICollectionView class];
    else return nil;
    
    NSString *className = NSStringFromClass([baseClass class]);
    
    NSString *selectorName = NSStringFromSelector(selector);
    return [NSString stringWithFormat:@"%@_%@",className,selectorName];
}


- (void)swizzle:(SEL)selector
{
    // Check if the target responds to selector
    if (![self respondsToSelector:selector]) {
        return;
    }
    
    // Create the lookup table
    if (!_impLookupTable) {
        _impLookupTable = [[NSMutableDictionary alloc] initWithCapacity:2];
    }
    
    // We make sure that setImplementation is called once per class kind, UITableView or UICollectionView.
    for (NSDictionary *info in [_impLookupTable allValues]) {
        Class class = [info objectForKey:DZNSwizzleInfoOwnerKey];
        NSString *selectorName = [info objectForKey:DZNSwizzleInfoSelectorKey];
        
        if ([selectorName isEqualToString:NSStringFromSelector(selector)]) {
            if ([self isKindOfClass:class]) {
                return;
            }
        }
    }
    
    NSString *key = dzn_implementationKey(self, selector);
    NSValue *impValue = [[_impLookupTable objectForKey:key] valueForKey:DZNSwizzleInfoPointerKey];
    
    // If the implementation for this class already exist, skip!!
    if (impValue) {
        return;
    }
    
    // Swizzle by injecting additional implementation
    Method method = class_getInstanceMethod([self class], selector);
    IMP dzn_newImplementation = method_setImplementation(method, (IMP)dzn_original_implementation);
    
    // Store the new implementation in the lookup table
    NSDictionary *swizzledInfo = @{DZNSwizzleInfoOwnerKey: [self class],
                                   DZNSwizzleInfoSelectorKey: NSStringFromSelector(selector),
                                   DZNSwizzleInfoPointerKey: [NSValue valueWithPointer:dzn_newImplementation]};
    
    [_impLookupTable setObject:swizzledInfo forKey:key];
}


#pragma mark - UIGestureRecognizerDelegate Methods

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer.view isEqual:self.emptyDataSetView]) {
        return [self dzn_isTouchAllowed];
    }
    
    return [super gestureRecognizerShouldBegin:gestureRecognizer];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    UIGestureRecognizer *tapGesture = self.emptyDataSetView.tapGesture;

    if ([gestureRecognizer isEqual:tapGesture] || [otherGestureRecognizer isEqual:tapGesture]) {
        return YES;
    }

    // defer to emptyDataSetDelegate's implementation if available
    if ([self.emptyDataSetDelegate respondsToSelector:@selector(gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:)]) {
        return [(id)self.emptyDataSetDelegate gestureRecognizer:gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:otherGestureRecognizer];
    }
    
    return NO;
}


@end


#pragma mark - DZNEmptyDataSetView

@interface DZNEmptyDataSetView ()
@end

@implementation DZNEmptyDataSetView
@synthesize contentView = _contentView;
@synthesize titleLabel = _titleLabel, detailLabel = _detailLabel, imageView = _imageView, button = _button;

#pragma mark - Initialization Methods

- (instancetype)init
{
    self =  [super init];
    if (self) {
        [self addSubview:self.contentView];
    }
    return self;
}

- (void)didMoveToSuperview
{
    self.frame = self.superview.bounds;
    
    [UIView animateWithDuration:0.25
                     animations:^{_contentView.alpha = 1.0;}
                     completion:NULL];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    /** We want to be relative to supplementry views, but not cells.
     */
    BOOL(^sillyFilter)(UIView *) = ^BOOL(UIView *testView) {
        return ([testView isKindOfClass:[UICollectionReusableView class]]
                && ![testView isKindOfClass:[UICollectionViewCell class]]
                && CGRectGetMinY(testView.frame) <= FLT_EPSILON);
    };
    
    NSNumber *maxY = [self.superview.subviews bk_reduce:@0 withBlock:^id(NSNumber *max, UIView *sibiling) {
        return sillyFilter(sibiling) ? @(MAX(max.doubleValue, CGRectGetMaxY(sibiling.frame))) : max;
    }];
    
    CGRect newFrame = self.frame;
    newFrame.origin.y = maxY.doubleValue;
    newFrame.size.height = CGRectGetHeight(self.superview.bounds) - [(UIScrollView *)self.superview contentInset].top - newFrame.origin.y;
    
    self.frame = newFrame;
    
    /* layout subviews */
    self.contentView.frame = self.bounds;
    
    /* First, we simply stack them on one side of the view */
    CGPoint center = {CGRectGetMidX(self.contentView.bounds), 0};
    CGFloat totalHeight = 0;
    
    /* Here, we order the subviews */
    NSMutableArray *subviews = [NSMutableArray array];
    
    if (self.customView) {
        [subviews addObject:self.customView];
    }
    else {
        if ([self canShowImage]) [subviews addObject:self.imageView];
        if ([self canShowTitle]) [subviews addObject:self.titleLabel];
        if ([self canShowDetail]) [subviews addObject:self.detailLabel];
        if ([self canShowButton]) [subviews addObject:self.button];
    }
    
    for (UIView *subview in subviews) {
        
        [subview sizeToFit];
        totalHeight += subview.bounds.size.height;
        totalHeight += self.verticalSpace;
    }
    
    totalHeight -= self.verticalSpace;
    
    /* align them */
    center.y = (CGRectGetHeight(self.contentView.bounds) - totalHeight) / 2;
    
    for (UIView *view in subviews) {
        
        center.y += CGRectGetHeight(view.bounds) / 2;
        view.center = center;
        center.y += CGRectGetHeight(view.bounds) / 2 + self.verticalSpace;
    }
}

#pragma mark - Getters

- (UIView *)contentView
{
    if (!_contentView)
    {
        _contentView = [UIView new];
        _contentView.backgroundColor = [UIColor clearColor];
        _contentView.userInteractionEnabled = YES;
        _contentView.alpha = 0;
    }
    return _contentView;
}

- (UIImageView *)imageView
{
    if (!_imageView)
    {
        _imageView = [UIImageView new];
        _imageView.backgroundColor = [UIColor clearColor];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        _imageView.userInteractionEnabled = NO;
        _imageView.accessibilityLabel = @"empty set background image";

        [_contentView addSubview:_imageView];
    }
    return _imageView;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel)
    {
        _titleLabel = [UILabel new];
        _titleLabel.backgroundColor = [UIColor clearColor];
        
        _titleLabel.font = [UIFont systemFontOfSize:27.0];
        _titleLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _titleLabel.numberOfLines = 2;
        _titleLabel.accessibilityLabel = @"empty set title";
        
        [_contentView addSubview:_titleLabel];
    }
    return _titleLabel;
}

- (UILabel *)detailLabel
{
    if (!_detailLabel)
    {
        _detailLabel = [UILabel new];
        _detailLabel.backgroundColor = [UIColor clearColor];
        
        _detailLabel.font = [UIFont systemFontOfSize:17.0];
        _detailLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
        _detailLabel.textAlignment = NSTextAlignmentCenter;
        _detailLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _detailLabel.numberOfLines = 0;
        _detailLabel.accessibilityLabel = @"empty set detail label";
        
        [_contentView addSubview:_detailLabel];
    }
    return _detailLabel;
}

- (UIButton *)button
{
    if (!_button)
    {
        _button = [UIButton buttonWithType:UIButtonTypeCustom];
        _button.backgroundColor = [UIColor clearColor];
        _button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        _button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        _button.accessibilityLabel = @"empty set button";

        [_button addTarget:self action:@selector(didTapButton:) forControlEvents:UIControlEventTouchUpInside];
        
        [_contentView addSubview:_button];
    }
    return _button;
}

- (BOOL)canShowImage {
    return (_imageView.image && _imageView.superview);
}

- (BOOL)canShowTitle {
    return (_titleLabel.attributedText.string.length > 0 && _titleLabel.superview);
}

- (BOOL)canShowDetail {
    return (_detailLabel.attributedText.string.length > 0 && _detailLabel.superview);
}

- (BOOL)canShowButton {
    return ([_button attributedTitleForState:UIControlStateNormal].string.length > 0 && _button.superview);
}


#pragma mark - Setters

- (void)setCustomView:(UIView *)view
{
    if (!view) {
        return;
    }
    
    if (_customView) {
        [_customView removeFromSuperview];
        _customView = nil;
    }
    
    _customView = view;
    [self.contentView addSubview:_customView];
}


#pragma mark - Action Methods

- (void)didTapButton:(id)sender
{
    SEL selector = NSSelectorFromString(@"dzn_didTapDataButton:");
    
    if ([self.superview respondsToSelector:selector]) {
        [self.superview performSelector:selector withObject:sender afterDelay:0.0f];
    }
}

- (void)removeAllSubviews
{
    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    _titleLabel = nil;
    _detailLabel = nil;
    _imageView = nil;
    _button = nil;
    _customView = nil;
}

@end
