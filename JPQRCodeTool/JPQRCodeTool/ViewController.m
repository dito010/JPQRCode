/*
 * This file is part of the JPQRCodeTool package.
 * (c) NewPan <13246884282@163.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Click https://github.com/Chris-Pan
 * or http://www.jianshu.com/users/e2f2d779c022/latest_articles to contact me.
 */

#import "ViewController.h"
#import "JPQRCodeTool.h"

@interface ViewController ()

@property (strong, nonatomic) IBOutlet UIImageView *codeImv;

@end

@implementation ViewController

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    NSArray *colors = @[[UIColor colorWithRed:98.0/255.0 green:152.0/255.0 blue:209.0/255.0 alpha:1], [UIColor colorWithRed:190.0/255.0 green:53.0/255.0 blue:77.0/255.0 alpha:1]];
    NSString *codeStr = @"http://weixin.qq.com/r/FeMxKeHeT7wwraVK97YH";
//    codeStr = @"https://github.com/Chris-Pan";
    
    UIImage *img = [JPQRCodeTool generateCodeForString:codeStr withCorrectionLevel:kQRCodeCorrectionLevelHight SizeType:kQRCodeSizeTypeCustom customSizeDelta:50 drawType:kQRCodeDrawTypeCircle gradientType:kQRCodeGradientTypeDiagonal gradientColors:colors];
    
    self.codeImv.image = img;
}

@end
