//
//  JPQRCodeTool.h
//  JPQRCodeTool
//
//  Created by 尹久盼 on 17/3/25.
//  Copyright © 2017年 尹久盼. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, kQRCodeSizeType) {
    kQRCodeSizeTypeSmall,
    kQRCodeSizeTypeNormal,
    kQRCodeSizeTypeBig
};

typedef NS_ENUM(NSInteger, kQRCodeDrawType) {
    kQRCodeDrawTypeNone,
    kQRCodeDrawTypeSquare, // 正方形
    kQRCodeDrawTypeCircle, // 圆
    kQRCodeDrawTypeIcon // 图标
};

typedef NS_ENUM(NSInteger, kQRCodeGradientType) {
    kQRCodeGradientTypeNone, // 纯色
    kQRCodeGradientTypeHorizontal, // 水平渐变
    kQRCodeGradientTypeDiagonal, // 对角线渐变
};

@interface JPQRCodeTool : NSObject

//
+(UIImage *)generateCodeForString:(NSString *)str withSizeType:(kQRCodeSizeType)sizeType drawType:(kQRCodeDrawType)drawType gradientType:(kQRCodeGradientType)gradientType gradientColors:(NSArray<UIColor *> *)colors iconsPath:(NSString *)iconPath;

@end
