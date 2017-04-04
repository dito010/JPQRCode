//
//  JPQRCodeTool.m
//  JPQRCodeTool
//
//  Created by 尹久盼 on 17/3/25.
//  Copyright © 2017年 尹久盼. All rights reserved.
//

#import "JPQRCodeTool.h"

struct JPIntPixel {
    UInt8 red;
    UInt8 green;
    UInt8 blue;
    UInt8 alpha;
};

const CGFloat JPQRCodeDrawPointMargin = 2;

@implementation JPQRCodeTool

+(UIImage *)generateCodeForString:(NSString *)str withSizeType:(kQRCodeSizeType)sizeType drawType:(kQRCodeDrawType)drawType gradientType:(kQRCodeGradientType)gradientType gradientColors:(NSArray<UIColor *> *)colors iconsPath:(NSString *)iconPath{
    if (str.length==0)
        return nil;
    
    @autoreleasepool {
        CIImage *originalImg = [self createOriginalCIImageWithString:str];
        NSArray<NSArray *> *pixels = [self getPixelsWithCIImage:originalImg];
        NSArray<NSArray *> *codePoints = [self handlePointsShouldDisplayCodeForArr:pixels];
        
        CGRect extent = originalImg.extent;
        CGFloat size = 0;
        switch (sizeType) {
            case kQRCodeSizeTypeSmall:
                size = 10*extent.size.width;
                break;
            case kQRCodeSizeTypeNormal:
                size = 20*extent.size.width;
                break;
            case kQRCodeSizeTypeBig:
                size = 30*extent.size.width;
                break;
            default:
                break;
        }
        return [self drawWithCodePoints:codePoints andSize:size gradientColors:colors drawType:drawType gradientType:gradientType iconsPath:iconPath];
    }
}

// 创建原始二维码
+(CIImage *)createOriginalCIImageWithString:(NSString *)str{
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [filter setDefaults];
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    [filter setValue:data forKeyPath:@"inputMessage"];
    [filter setValue:@"H" forKey:@"inputCorrectionLevel"];
    CIImage *outputImage = [filter outputImage];
    return outputImage;
}

// 将 `CIImage` 转成 `CGImage`
+(CGImageRef)convertCIImage2CGImageForCIImage:(CIImage *)image{
    CGRect extent = CGRectIntegral(image.extent);
    
    size_t width = CGRectGetWidth(extent);
    size_t height = CGRectGetHeight(extent);
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, 1, 1);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    
    return scaledImage;
}

// 将原始图片的所有点的色值保存到二维数组
+(NSArray<NSArray *>*)getPixelsWithCIImage:(CIImage *)ciimg{
    NSMutableArray *pixels = [NSMutableArray array];
    
    CGImageRef imageRef = [self convertCIImage2CGImageForCIImage:ciimg];
    CGFloat width = CGImageGetWidth(imageRef);
    CGFloat height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char *)calloc(height * width * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = width * bytesPerPixel;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    for (int indexY = 0; indexY < height; indexY++) {
        NSMutableArray *tepArrM = [NSMutableArray array];
        for (int indexX = 0; indexX < width; indexX++) {
            @autoreleasepool {
                NSUInteger byteIndex = bytesPerRow * indexY + indexX * bytesPerPixel;
                CGFloat alpha = (CGFloat)rawData[byteIndex + 3];
                CGFloat red = (CGFloat)rawData[byteIndex];
                CGFloat green = (CGFloat)rawData[byteIndex + 1];
                CGFloat blue = (CGFloat)rawData[byteIndex + 2];
                struct JPIntPixel pixel;
                pixel.alpha = alpha;
                pixel.red = red;
                pixel.green = green;
                pixel.blue = blue;
                NSValue *value = [NSValue valueWithBytes:&pixel objCType:@encode(struct JPIntPixel)];
                [tepArrM addObject:value];
                byteIndex += bytesPerPixel;
            }
        }
        [pixels addObject:[tepArrM copy]];
    }
    free(rawData);
    return [pixels copy];
}

// 判断每个点是否有颜色色值
+(NSArray<NSArray *>*)handlePointsShouldDisplayCodeForArr:(NSArray<NSArray *>*)pixels{
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:pixels.count];
    for (int indexY = 0; indexY < pixels.count; indexY++) {
        NSMutableArray *tepArrM = [NSMutableArray arrayWithCapacity:pixels[indexY].count];
        for (int indexX = 0; indexX < pixels[indexY].count; indexX++) {
            @autoreleasepool {
                NSValue *value = pixels[indexY][indexX];
                struct JPIntPixel pixel;
                [value getValue:&pixel];
                BOOL shouldDisplay = pixel.red == 0 && pixel.green == 0 && pixel.blue == 0;
                [tepArrM addObject:@(shouldDisplay)];
            }
        }
        [results addObject:[tepArrM copy]];
    }
    return [results copy];
}

+(UIImage *)drawWithCodePoints:(NSArray<NSArray *> *)codePoints andSize:(CGFloat)size gradientColors:(NSArray<UIColor *> *)colors drawType:(kQRCodeDrawType)drawType gradientType:(kQRCodeGradientType)gradientType iconsPath:(NSString *)iconPath{
    CGFloat scale = 3;
    CGFloat imgWH = size * scale;
    CGFloat delta = imgWH/codePoints.count;
    
    UIGraphicsBeginImageContext(CGSizeMake(imgWH, imgWH));
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    NSArray<UIImage *> *icons = nil;
    if (iconPath.length>0) {
        NSURL *url = [NSURL fileURLWithPath:iconPath isDirectory:YES];
        NSArray<NSString *> *resourceKeys = @[NSURLIsDirectoryKey];
        NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtURL:url includingPropertiesForKeys:resourceKeys options:NSDirectoryEnumerationSkipsHiddenFiles  errorHandler:NULL];
        NSMutableArray<UIImage *> *iconsArrM = [NSMutableArray array];
        for (NSURL *fileURL in fileEnumerator) {
            @autoreleasepool {
                NSData *data = [NSData dataWithContentsOfURL:fileURL];
                UIImage *img = [UIImage imageWithData:data];
                if (img) {
                    [iconsArrM addObject:img];
                }
            }
        }
        icons = [iconsArrM copy];
    }
    
    NSInteger iconIndex = -1;
    
    for (int indexY = 0; indexY < codePoints.count; indexY++) {
        for (int indexX = 0; indexX < codePoints[indexY].count; indexX++) {
            @autoreleasepool {
                BOOL shouldDisplay = [codePoints[indexY][indexX] boolValue];
                if (shouldDisplay) {
                    switch (drawType) {
                        case kQRCodeDrawTypeCircle:
                        case kQRCodeDrawTypeSquare:
                        {
                            [self drawPointWithIndexX:indexX indexY:indexY delta:delta imgWH:imgWH colors:colors gradientType:gradientType drawType:drawType inContext:ctx];
                        }
                            break;
                        case kQRCodeDrawTypeIcon:
                        {
                            NSInteger count = icons.count-2;
                            if (iconIndex <= count) {
                                iconIndex++;
                            }
                            else if(iconIndex==icons.count-1){
                                iconIndex = 0;
                            }
                            
                            [self drawPointWithIndexX:indexX indexY:indexY delta:delta icon:icons[iconIndex] inContext:ctx];
                            
                        }
                            
                        default:
                            break;
                    }
                }
            }
        }
    }
    
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return img;
}

+(void)drawPointWithIndexX:(CGFloat)indexX indexY:(CGFloat)indexY delta:(CGFloat)delta icon:(UIImage*)icon inContext:(CGContextRef)ctx{
    CGContextSaveGState(ctx);
    CGRect drawRect = CGRectMake(indexX*delta, indexY*delta, delta, delta);
    [icon drawInRect:drawRect];
    CGContextRestoreGState(ctx);
}

+(void)drawPointWithIndexX:(CGFloat)indexX indexY:(CGFloat)indexY delta:(CGFloat)delta imgWH:(CGFloat)imgWH colors:(NSArray<UIColor *> *)colors gradientType:(kQRCodeGradientType)gradientType drawType:(kQRCodeDrawType)drawType inContext:(CGContextRef)ctx{
    
    UIBezierPath *bezierPath;
    if (drawType==kQRCodeDrawTypeCircle) {
        CGFloat centerX = indexX*delta + 0.5*delta;
        CGFloat centerY = indexY*delta + 0.5*delta;
        CGFloat radius =  0.5*delta-JPQRCodeDrawPointMargin;
        CGFloat startAngle = 0;
        CGFloat endAngle = 2*M_PI;
        bezierPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(centerX, centerY) radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];
        
    }
    else if (drawType==kQRCodeDrawTypeSquare){
        bezierPath = [UIBezierPath bezierPathWithRect:CGRectMake(indexX*delta, indexY*delta, delta, delta)];
    }
    NSArray<UIColor *> *gradientColors = [self getGradientColorsWithStratPoint:CGPointMake(indexX*delta, indexY*delta) andEndPoint:CGPointMake((indexX+1)*delta, (indexY+1)*delta) totalWid:imgWH BetweenColors:colors gradientType:gradientType];
    
    [self drawLinearGradient:ctx path:bezierPath.CGPath startColor:[gradientColors firstObject].CGColor endColor:[gradientColors lastObject].CGColor];
    CGContextSaveGState(ctx);
}

+(NSArray<UIColor *> *)getGradientColorsWithStratPoint:(CGPoint)startP andEndPoint:(CGPoint)endP totalWid:(CGFloat)totalWid BetweenColors:(NSArray<UIColor *> *)colors gradientType:(kQRCodeGradientType)gradientType{
    UIColor *color1 = colors.firstObject;
    UIColor *color2 = colors.lastObject;
    
    const CGFloat *components1 = CGColorGetComponents(color1.CGColor);
    const CGFloat *components2 = CGColorGetComponents(color2.CGColor);
    
    CGFloat red1 = components1[0];
    CGFloat green1 = components1[1];
    CGFloat blue1 = components1[2];
    
    CGFloat red2 = components2[0];
    CGFloat green2 = components2[1];
    CGFloat blue2 = components2[2];

    NSArray<UIColor *> *result = nil;
    switch (gradientType) {
        case kQRCodeGradientTypeHorizontal:
        {
            CGFloat startDelta = startP.x / totalWid;
            CGFloat endDelta = endP.x / totalWid;
            
            CGFloat startRed = (1-startDelta)*red1 + startDelta*red2;
            CGFloat startGreen = (1-startDelta)*green1 + startDelta*green2;
            CGFloat startBlue = (1-startDelta)*blue1 + startDelta*blue2;
            UIColor *startColor = [UIColor colorWithRed:startRed green:startGreen blue:startBlue alpha:1];
            
            CGFloat endRed = (1-endDelta)*red1 + endDelta*red2;
            CGFloat endGreen = (1-endDelta)*green1 + endDelta*green2;
            CGFloat endBlue = (1-endDelta)*blue1 + endDelta*blue2;
            UIColor *endColor = [UIColor colorWithRed:endRed green:endGreen blue:endBlue alpha:1];
            
            result = @[startColor, endColor];
        }
            break;
            
        case kQRCodeGradientTypeDiagonal:
        {
            
            CGFloat startDelta = [self calculateTarHeiForPoint:startP] / (totalWid * totalWid);
            CGFloat endDelta = [self calculateTarHeiForPoint:endP] / (totalWid * totalWid);
            
            CGFloat startRed = red1 + startDelta*(red2-red1);
            CGFloat startGreen = green1 + startDelta*(green2-green1);
            CGFloat startBlue = blue1 + startDelta*(blue2-blue1);
            UIColor *startColor = [UIColor colorWithRed:startRed green:startGreen blue:startBlue alpha:1];
            
            CGFloat endRed = red1 + endDelta*(red2-red1);
            CGFloat endGreen = green1 + endDelta*(green2-green1);
            CGFloat endBlue = blue1 + endDelta*(blue2-blue1);
            UIColor *endColor = [UIColor colorWithRed:endRed green:endGreen blue:endBlue alpha:1];
            
            result = @[startColor, endColor];
        }
            
        default:
            break;
    }
    
    return result;
}

+(CGFloat)calculateTarHeiForPoint:(CGPoint)point{
    CGFloat pointX = point.x;
    CGFloat pointY = point.y;
    
    CGFloat tarArcValue = pointX >= pointY ? M_PI_4-atan(pointY/pointX) : M_PI_4-atan(pointX/pointY);
    return cos(tarArcValue)*(pointX*pointX + pointY*pointY);
}

+(void)drawLinearGradient:(CGContextRef)context path:(CGPathRef)path startColor:(CGColorRef)startColor endColor:(CGColorRef)endColor{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[] = { 0.0, 1.0 };
    
    NSArray *colors = @[(__bridge id) startColor, (__bridge id) endColor];
    
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef) colors, locations);
    
    CGRect pathRect = CGPathGetBoundingBox(path);
    
    //具体方向可根据需求修改
    CGPoint startPoint = CGPointMake(CGRectGetMinX(pathRect), CGRectGetMidY(pathRect));
    CGPoint endPoint = CGPointMake(CGRectGetMaxX(pathRect), CGRectGetMidY(pathRect));
    
    CGContextSaveGState(context);
    CGContextAddPath(context, path);
    CGContextClip(context);
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    CGContextRestoreGState(context);
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
}

@end
