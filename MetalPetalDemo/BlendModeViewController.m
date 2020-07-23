//
//  BlendModeViewController.m
//  MetalPetalDemo
//
//  Created by 杨乃川 on 2018/9/19.
//  Copyright © 2018年 MetalPetal. All rights reserved.
//

#import "BlendModeViewController.h"
@import MetalPetal;

@interface BlendModeViewController ()<UIPickerViewDelegate, UIPickerViewDataSource>
@property (weak, nonatomic) IBOutlet UIPickerView *blendModePickerView;

@property (nonatomic, copy) NSArray *lutBlendModes;
@property (nonatomic, copy) NSArray *imageBlendModes;
@property (nonatomic, strong) MTIBlendFilter *pickedBlendFilter;
@property (nonatomic, strong) MTIImageView *renderView;

@property (nonatomic, strong) MTIImage *sourceImage;
@property (nonatomic, strong) MTIImage *backgroundImage;
@property (weak, nonatomic) IBOutlet UISegmentedControl *backgroundAlphaSegment;

@property (nonatomic, strong) MTIImage *backgroundImageAlpha50;
@end

@implementation BlendModeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.renderView = [[MTIImageView alloc] initWithFrame:CGRectZero];
    [self.view insertSubview:self.renderView atIndex:0];
    
    self.blendModePickerView.delegate = self;
    self.blendModePickerView.dataSource = self;

    self.sourceImage = [[[MTIImage alloc] initWithCGImage:[UIImage imageNamed:@"blend_mode_source"].CGImage loadingOptions:nil] imageByUnpremultiplyingAlpha];
    self.backgroundImage = [[[MTIImage alloc] initWithCGImage:[UIImage imageNamed:@"blend_mode_background"].CGImage loadingOptions:nil] imageByUnpremultiplyingAlpha];
    self.backgroundImageAlpha50 = [[[MTIImage alloc] initWithCGImage:[UIImage imageNamed:@"blend_mode_background_a50"].CGImage loadingOptions:nil] imageByUnpremultiplyingAlpha];
    
    self.pickedBlendFilter = [[MTIBlendFilter alloc] initWithBlendMode:MTIBlendModeNormal];
    
    NSMutableArray *supportModes = [[MTIBlendModes allModes] mutableCopy];
    NSMutableArray <MTIBlendMode>*modes = [@[
                             MTIBlendModeNormal,
                             MTIBlendModeDarken,
                             MTIBlendModeMultiply,
                             MTIBlendModeColorBurn,
                             MTIBlendModeLinearBurn,
                             MTIBlendModeDarkerColor,
                             MTIBlendModeLighten,
                             MTIBlendModeScreen,
                             MTIBlendModeColorDodge,
                             MTIBlendModeAdd,
                             MTIBlendModeLighterColor,
                             MTIBlendModeOverlay,
                             MTIBlendModeSoftLight,
                             MTIBlendModeHardLight,
                             MTIBlendModeVividLight,
                             MTIBlendModeLinearLight,
                             MTIBlendModePinLight,
                             MTIBlendModeHardMix,
                             MTIBlendModeDifference,
                             MTIBlendModeExclusion,
                             MTIBlendModeSubtract,
                             MTIBlendModeDivide
                             ] mutableCopy];

    for (MTIBlendMode testMode in modes) {
        BOOL support = NO;
        for (MTIBlendMode supportMode in supportModes) {
            if ([testMode isEqualToString:supportMode]) {
                support = YES;
                break;
            }
        }
        if (!support) {
            [modes removeObject:testMode];
        }
    }
    self.imageBlendModes = [modes copy];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.renderView.frame = self.view.bounds;
    [self render];
}

- (void)render {
    self.pickedBlendFilter.inputImage = self.sourceImage;
    if (self.backgroundAlphaSegment.selectedSegmentIndex) {
                self.pickedBlendFilter.inputBackgroundImage = self.backgroundImageAlpha50;
    } else {
        self.pickedBlendFilter.inputBackgroundImage = self.backgroundImage;
    }
    self.renderView.image = self.pickedBlendFilter.outputImage;
}
- (IBAction)backgroundImageChanged:(UISegmentedControl *)sender {
    [self render];
}

#pragma mark - BlendMode PickerView Delegate & DataSource
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return (NSInteger)self.imageBlendModes.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    if (row < (NSInteger)self.imageBlendModes.count) {
        return self.imageBlendModes[(NSUInteger)row];
    }
    return @"";
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (row < (NSInteger)self.imageBlendModes.count) {
        MTIBlendFilter *pickedBlendFilter = [[MTIBlendFilter alloc] initWithBlendMode:self.imageBlendModes[(NSUInteger)row]];
        if (pickedBlendFilter) {
            self.pickedBlendFilter = pickedBlendFilter;
            [self render];
        }
    }
}
@end
