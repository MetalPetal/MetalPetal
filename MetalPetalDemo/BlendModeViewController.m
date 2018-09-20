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
@end

@implementation BlendModeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.renderView = [[MTIImageView alloc] initWithFrame:CGRectZero];
    [self.view insertSubview:self.renderView atIndex:0];
    
    self.blendModePickerView.delegate = self;
    self.blendModePickerView.dataSource = self;

//    self.sourceImage = [MTIImage transparentImage];
    self.sourceImage = [[MTIImage alloc] initWithCGImage:[UIImage imageNamed:@"blend_mode_source"].CGImage options:@{MTKTextureLoaderOptionSRGB: @(NO)} alphaType:MTIAlphaTypeAlphaIsOne];
    self.backgroundImage = [[MTIImage alloc] initWithCGImage:[UIImage imageNamed:@"blend_mode_background"].CGImage options:@{MTKTextureLoaderOptionSRGB: @(NO)} alphaType:MTIAlphaTypeAlphaIsOne];
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
        self.navigationController.navigationBar.hidden = NO;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.renderView.frame = self.view.bounds;
    [self render];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)render {
    self.pickedBlendFilter.inputImage = self.sourceImage;
    self.pickedBlendFilter.inputBackgroundImage = self.backgroundImage;
    self.renderView.image = self.pickedBlendFilter.outputImage;
}

#pragma mark - BlendMode PickerView Delegate & DataSource
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.imageBlendModes.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    if (row < self.imageBlendModes.count) {
        return  [self.imageBlendModes objectAtIndex:row];
    }
    return @"";
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (row < self.imageBlendModes.count) {
        MTIBlendFilter *pickedBlendFilter = [[MTIBlendFilter alloc] initWithBlendMode:self.imageBlendModes[row]];
        if (pickedBlendFilter) {
            self.pickedBlendFilter = pickedBlendFilter;
            [self render];
        }
    }
}
@end
