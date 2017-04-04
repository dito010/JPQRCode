//
//  ViewController.m
//  JPQRCodeTool
//
//  Created by 尹久盼 on 17/3/25.
//  Copyright © 2017年 尹久盼. All rights reserved.
//

#import "ViewController.h"
#import "JPQRCodeTool.h"

@interface ViewController ()

@property (strong, nonatomic) IBOutlet UIImageView *codeImv;

@end

@implementation ViewController

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    NSArray *colors = @[[UIColor colorWithRed:98.0/255.0 green:152.0/255.0 blue:209.0/255.0 alpha:1], [UIColor colorWithRed:190.0/255.0 green:53.0/255.0 blue:77.0/255.0 alpha:1]];
    
    NSString *iconsPath = [NSBundle mainBundle].bundlePath;
    iconsPath = [iconsPath stringByAppendingString:@"/Expression.bundle/"];
//    iconsPath = [iconsPath stringByAppendingString:@"/morpheus.bundle/"];
    
    UIImage *img = [JPQRCodeTool generateCodeForString:@"https://github.com/Chris-Pan" withSizeType:kQRCodeSizeTypeNormal drawType:kQRCodeDrawTypeCircle gradientType:kQRCodeGradientTypeDiagonal gradientColors:colors iconsPath:iconsPath];
    
    self.codeImv.image = img;
}




@end
