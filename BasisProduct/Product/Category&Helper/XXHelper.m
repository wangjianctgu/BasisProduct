//
//  HYHelper.m
//
//  Created by Ghy on 17/1/6.
//  Copyright © 2017年 ghy. All rights reserved.
//
#define TIME_ZONE @"Asia/Beijing"

#import "XXHelper.h"
#import "sys/utsname.h"
#include <sys/socket.h> // Per msqr
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

#include <ifaddrs.h>
#include <arpa/inet.h>
#include <netdb.h>
#import <dlfcn.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <SystemConfiguration/SystemConfiguration.h>

static XXHelper *sectionInstance;

//原始尺寸  ,放大图片方法
static CGRect oldframe;
@interface XXHelper ()

@end
@implementation XXHelper

#pragma mark - Init

+ (id)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sectionInstance = [super allocWithZone:zone];
    });
    return sectionInstance;
}
+ (XXHelper *)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sectionInstance = [[self alloc] init];
    });
    return sectionInstance;
}

+ (NSString *)deleteNewlineAndLineSpace:(NSString *)string {
    NSString *resultString = @"";
    for (int i = 0;i<string.length;i++){
        unichar c = [string characterAtIndex:i];
        if (c!='\n' && c!=' ') {
            resultString = [resultString stringByAppendingString:[NSString stringWithFormat:@"%C",c]];
        }
    }
    
    return resultString;
}

#pragma mark - 验证银行卡号是否规范
+ (BOOL)validateBankCardWithNumber:(NSString *)cardNum {
    NSString *CT = @"^([0-9]{16}|[0-9]{19})$";
    NSPredicate *regextestCard = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CT];

    if ([regextestCard evaluateWithObject:cardNum] == YES) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - 判断身份证号码是否规范
+ (BOOL)checkIdentityCardNo:(NSString *)cardNo {
    if (cardNo.length != 18) {
        return NO;
    }
    NSArray *codeArray = [NSArray arrayWithObjects:@"7", @"9", @"10", @"5", @"8", @"4", @"2", @"1", @"6", @"3", @"7",
                                                   @"9", @"10", @"5", @"8", @"4", @"2", nil];
    NSDictionary *checkCodeDic =
        [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"1", @"0", @"X", @"9", @"8", @"7", @"6", @"5",
                                                                      @"4", @"3", @"2", nil]
                                    forKeys:[NSArray arrayWithObjects:@"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7",
                                                                      @"8", @"9", @"10", nil]];

    NSScanner *scan = [NSScanner scannerWithString:[cardNo substringToIndex:17]];

    int val;
    BOOL isNum = [scan scanInt:&val] && [scan isAtEnd];
    if (!isNum) {
        return NO;
    }
    int sumValue = 0;

    for (int i = 0; i < 17; i++) {
        sumValue += [[cardNo substringWithRange:NSMakeRange(i, 1)] intValue] * [[codeArray objectAtIndex:i] intValue];
    }

    NSString *strlast = [checkCodeDic objectForKey:[NSString stringWithFormat:@"%d", sumValue % 11]];

    if ([strlast isEqualToString:[[cardNo substringWithRange:NSMakeRange(17, 1)] uppercaseString]]) {
        return YES;
    }
    return NO;
}
#pragma mark - 判断输入的是否是中文

/**
 * 判断输入的是否是中文
 */
+ (BOOL)checkInputChinese:(NSString *)text {

    NSString *strRegex = @"^[\u4e00-\u9fa5]+$";

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", strRegex];
    if ([predicate evaluateWithObject:text]) {

        return true;
    } else {
        return false;
    }
}

#pragma mark - 判断字符串中是否有非法字符

/**
 * 非法字符是指 除数字 字母 中文文字以外的所有字符
 */
+ (BOOL)JudgeTheillegalCharacter:(NSString *)content {

    //提示 标签不能输入特殊字符

    NSString *str = @"^[A-Za-z0-9\\u4e00-\u9fa5]+$";

    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", str];

    if (![emailTest evaluateWithObject:content]) {

        return YES;

    } else {

        return NO;
    }
}
#pragma mark - 拨打电话
+ (void)makePhoneCallWithTelNumber:(NSString *)tel {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", tel]]];
}

#pragma mark - 直接打开网页
+ (void)openURLWithUrlString:(NSString *)url {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", url]]];
}

#pragma mark - 获取当前时间
+ (NSString *)currentTime {
    NSDateFormatter *formater = [[NSDateFormatter alloc] init];
    NSDate *curDate = [NSDate date];                 //获取当前日期
    [formater setDateFormat:@"YYYY-MM-dd HH:mm:ss"]; //这里去掉 具体时间 保留日期
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:TIME_ZONE];
    [formater setTimeZone:timeZone];
    NSString *curTime = [formater stringFromDate:curDate];

    return curTime;
}

#pragma mark - 将时间转换成时间戳
/**
 *  时间戳：指格林威治时间1970年01月01日00时00分00秒(北京时间1970年01月01日08时00分00秒)起至现在的总秒数。
 */
+ (NSString *)timeStringIntoTimeStamp:(NSString *)time {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:TIME_ZONE];
    [dateFormatter setTimeZone:timeZone];

    NSDate *date = [dateFormatter dateFromString:time];

    NSString *timeSP = [NSString stringWithFormat:@"%ld", (long) [date timeIntervalSince1970]];

    return timeSP;
}

#pragma mark - 将时间戳转换成时间
+ (NSString *)timeStampIntoTimeString:(NSString *)time {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    /* 设置时区 */
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:TIME_ZONE];
    [dateFormatter setTimeZone:timeZone];

    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[time intValue]];

    NSString *dateString = [dateFormatter stringFromDate:date];
    // dateString = [dateString substringToIndex:20];
    return dateString;
}

#pragma mark - 通过时间字符串获取年、月、日
+ (NSArray *)getYearAndMonthAndDayFromTimeString:(NSString *)time {
    NSString *year = [time substringToIndex:4];
    NSString *month = [[time substringFromIndex:5] substringToIndex:2];
    NSString *day = [[time substringFromIndex:8] substringToIndex:2];

    return @[ year, month, day ];
}
#pragma mark - 获取今天、明天、后天的日期
+ (NSArray *)timeForTheRecentDate {
    NSMutableArray *dateArr = [[NSMutableArray alloc] init];

    //今天
    NSDateFormatter *formater = [[NSDateFormatter alloc] init];
    NSDate *curDate = [NSDate date];                 //获取当前日期
    [formater setDateFormat:@"YYYY-MM-dd HH:mm:ss"]; //这里去掉 具体时间 保留日期
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:TIME_ZONE];
    [formater setTimeZone:timeZone];
    NSString *curTime = [formater stringFromDate:curDate];

    NSArray *today = [XXHelper getYearAndMonthAndDayFromTimeString:curTime];
    [dateArr addObject:today];

    //明天
    NSString *timeStamp = [XXHelper timeStringIntoTimeStamp:curTime];
    NSInteger seconds = 24 * 60 * 60 + [timeStamp integerValue];
    timeStamp = [NSString stringWithFormat:@"%ld", (long) seconds];
    curTime = [XXHelper timeStampIntoTimeString:timeStamp];

    NSArray *tomorrow = [XXHelper getYearAndMonthAndDayFromTimeString:curTime];
    [dateArr addObject:tomorrow];

    return [NSArray arrayWithArray:dateArr];
}

#pragma mark - 当前界面截图
+ (UIImage *)imageFromCurrentView:(UIView *)view {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES, view.layer.contentsScale);

    [view.layer renderInContext:UIGraphicsGetCurrentContext()];

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return image;
}

#pragma mark - 去掉html中的标签
+ (NSString *)stringRemovetheHTMLtags:(NSString *)htmlString {
    NSScanner *scanner = [NSScanner scannerWithString:htmlString];

    NSString *text = nil;

    while (![scanner isAtEnd]) {
        [scanner scanUpToString:@"<" intoString:NULL];
        [scanner scanUpToString:@">" intoString:&text];

        htmlString =
            [htmlString stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@>", text] withString:@""];
    }

    scanner = [NSScanner scannerWithString:htmlString];
    while (![scanner isAtEnd]) {
        [scanner scanUpToString:@"{" intoString:NULL];
        [scanner scanUpToString:@"}" intoString:&text];

        htmlString =
            [htmlString stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@}", text] withString:@""];
    }

    return htmlString;
}

#pragma mark - 获取Documents中文件的路径
+ (NSString *)accessToTheDocumentsInTheFilePath:(NSString *)fileName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *filePath = [path stringByAppendingPathComponent:fileName];

    return filePath;
}

#pragma mark - 生成随机数 n到m
+ (int)getRandomNumber:(int)from to:(int)to {

    return (int) (from + (arc4random() % (to - from + 1)));
}

#pragma mark - 判断网址是否有效
+ (BOOL)validateHttp:(NSString *)textString {
    NSString *number = @"^([w-]+.)+[w-]+(/[w-./?%&=]*)?$";
    NSPredicate *numberPre = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", number];
    return [numberPre evaluateWithObject:textString];
}

#pragma mark - 给view设置边框
+ (void)setBorderWithView:(UIView *)view
                      top:(BOOL)top
                     left:(BOOL)left
                   bottom:(BOOL)bottom
                    right:(BOOL)right
              borderColor:(UIColor *)color
              borderWidth:(CGFloat)width {
    if (top) {
        CALayer *layer = [CALayer layer];
        layer.frame = CGRectMake(0, 0, view.frame.size.width, width);
        layer.backgroundColor = color.CGColor;
        [view.layer addSublayer:layer];
    }
    if (left) {
        CALayer *layer = [CALayer layer];
        layer.frame = CGRectMake(0, 0, width, view.frame.size.height);
        layer.backgroundColor = color.CGColor;
        [view.layer addSublayer:layer];
    }
    if (bottom) {
        CALayer *layer = [CALayer layer];
        layer.frame = CGRectMake(0, view.frame.size.height - width, view.frame.size.width, width);
        layer.backgroundColor = color.CGColor;
        [view.layer addSublayer:layer];
    }
    if (right) {
        CALayer *layer = [CALayer layer];
        layer.frame = CGRectMake(view.frame.size.width - width, 0, width, view.frame.size.height);
        layer.backgroundColor = color.CGColor;
        [view.layer addSublayer:layer];
    }
}

#pragma mark - 给view设置圆角
/**
 *  给view设置圆角(指定圆角)
 *
 */
+ (void)setCornerRadiuswithView:(UIView *)view targetAngles:(UIRectCorner)targetAngles cornerRadii:(CGSize)size {

    UIBezierPath *maskPath =
        [UIBezierPath bezierPathWithRoundedRect:view.bounds byRoundingCorners:targetAngles cornerRadii:size];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = view.bounds;
    maskLayer.path = maskPath.CGPath;
    view.layer.mask = maskLayer;
}

#pragma mark - 将数组中重复的对象去除，只保留一个
+ (NSMutableArray *)arrayWithMemberIsOnly:(NSMutableArray *)array {
    NSMutableArray *categoryArray = [[NSMutableArray alloc] init];
    for (unsigned i = 0; i < [array count]; i++) {
        @autoreleasepool {
            if ([categoryArray containsObject:[array objectAtIndex:i]] == NO) {
                [categoryArray addObject:[array objectAtIndex:i]];
            }
        }
    }
    return categoryArray;
}

#pragma mark - 图片大小设置
+ (UIImage *)scaleToSize:(UIImage *)img size:(CGSize)size {
    // 创建一个bitmap的context
    // 并把它设置成为当前正在使用的context
    UIGraphicsBeginImageContext(size);
    // 绘制改变大小的图片
    [img drawInRect:CGRectMake(0, 0, size.width, size.height)];
    // 从当前context中创建一个改变大小后的图片
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    // 使当前的context出堆栈
    UIGraphicsEndImageContext();

    // the size of CGContextRef
    int w = size.width;
    int h = size.height;

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, w, h, 8, 44 * w, colorSpace, kCGImageAlphaPremultipliedFirst);
    CGRect rect = CGRectMake(0, 0, w, h);

    CGContextBeginPath(context);
    addRoundedRectToPath(context, rect, size.width / 3, size.height / 3);
    CGContextClosePath(context);
    CGContextClip(context);
    CGContextDrawImage(context, CGRectMake(0, 0, w, h), scaledImage.CGImage);
    // CGImageRef imageMasked = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);

    //返回新的改变大小后的图片
    return scaledImage;
}
static void addRoundedRectToPath(CGContextRef context, CGRect rect, float ovalWidth, float ovalHeight) {
    float fw, fh;
    if (ovalWidth == 0 || ovalHeight == 0) {
        CGContextAddRect(context, rect);
        return;
    }

    CGContextSaveGState(context);
    CGContextTranslateCTM(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGContextScaleCTM(context, ovalWidth, ovalHeight);
    fw = CGRectGetWidth(rect) / ovalWidth;
    fh = CGRectGetHeight(rect) / ovalHeight;

    CGContextMoveToPoint(context, fw, fh / 2);              // Start at lower right corner
    CGContextAddArcToPoint(context, fw, fh, fw / 2, fh, 1); // Top right corner
    CGContextAddArcToPoint(context, 0, fh, 0, fh / 2, 1);   // Top left corner
    CGContextAddArcToPoint(context, 0, 0, fw / 2, 0, 1);    // Lower left corner
    CGContextAddArcToPoint(context, fw, 0, fw, fh / 2, 1);  // Back to lower right

    CGContextClosePath(context);
    CGContextRestoreGState(context);
}

#pragma mark - 获取当前屏幕显示的viewcontroller
+ (UIViewController *)getCurrentVC {
    UIViewController *result = nil;

    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal) {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for (UIWindow *tmpWin in windows) {
            if (tmpWin.windowLevel == UIWindowLevelNormal) {
                window = tmpWin;
                break;
            }
        }
    }

    UIView *frontView = [[window subviews] objectAtIndex:0];
    id nextResponder = [frontView nextResponder];

    if ([nextResponder isKindOfClass:[UIViewController class]])
        result = nextResponder;
    else
        result = window.rootViewController;

    return result;
}

#pragma mark - 获取当前处于activity状态的view controller
+ (UIViewController *)activityViewController {
    UIViewController *activityViewController = nil;

    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal) {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for (UIWindow *tmpWin in windows) {
            if (tmpWin.windowLevel == UIWindowLevelNormal) {
                window = tmpWin;
                break;
            }
        }
    }

    NSArray *viewsArray = [window subviews];
    if ([viewsArray count] > 0) {
        UIView *frontView = [viewsArray objectAtIndex:0];

        id nextResponder = [frontView nextResponder];

        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            activityViewController = nextResponder;
        } else {
            activityViewController = window.rootViewController;
        }
    }

    return activityViewController;
}
#pragma mark - 清空字典数据
+ (NSMutableDictionary *)clearNullData:(NSDictionary *)dic {
    NSMutableDictionary *result = [NSMutableDictionary new];

    NSArray *data = dic.allKeys;
    for (int i = 0; i < data.count; i++) {

        NSString *str = dic[data[i]];

        if ((NSNull *) str == [NSNull null]) {
            [result setObject:@"" forKey:data[i]];
        } else {
            [result setObject:dic[data[i]] forKey:data[i]];
        }
    }

    return result;
}

#pragma mark - 将image 转化成nsdata
+ (NSData *)getImageDataWith:(UIImage *)image {
    NSData *data = UIImagePNGRepresentation(image);
    if (data == nil) {
        data = UIImageJPEGRepresentation(image, 0.1);
    }
    return data;
}

#pragma mark - 格式化千分位
+ (NSString *)positiveFormat:(NSString *)text {
    if (!text || [text floatValue] == 0) {
        return @"0.00";
    } else if ([text floatValue] < 0.001) {
        return [NSString stringWithFormat:@"%@", text];
    } else {
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setPositiveFormat:@",###.00"];
        return [numberFormatter stringFromNumber:[NSNumber numberWithDouble:[text doubleValue]]];
    }
    return @"";
}

#pragma mark - 不四舍五入  小数
+ (NSString *)notRounding:(float)price afterPoint:(int)position {
    NSDecimalNumberHandler *roundingBehavior = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundDown
                                                                                                      scale:position
                                                                                           raiseOnExactness:NO
                                                                                            raiseOnOverflow:NO
                                                                                           raiseOnUnderflow:NO
                                                                                        raiseOnDivideByZero:NO];
    NSDecimalNumber *ouncesDecimal;
    NSDecimalNumber *roundedOunces;

    ouncesDecimal = [[NSDecimalNumber alloc] initWithFloat:price];
    roundedOunces = [ouncesDecimal decimalNumberByRoundingAccordingToBehavior:roundingBehavior];

    return [NSString stringWithFormat:@"%0.2f元", [roundedOunces floatValue]];
}

#pragma mark - 获取用户手机信息
+ (NSMutableDictionary *)getUserPhoneInfo {
    NSMutableDictionary *phoneInfoDict = [NSMutableDictionary new];

    //手机系统版本
    NSString *phoneVersion = [[UIDevice currentDevice] systemVersion];

    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    // 当前应用软件版本  比如：1.0.1
    NSString *appCurVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];

    //手机序列号（设备号）
    NSString *identifierNumber = [[UIDevice currentDevice].identifierForVendor UUIDString];

    //手机品牌型号
    [phoneInfoDict setObject:[self getUserPhoneModelNumber] forKey:@"mobiletype"];

    //添加手机系统版本
    [phoneInfoDict setObject:phoneVersion forKey:@"sysversion"];

    //登录来源 PC IOS Android WeChat
    [phoneInfoDict setObject:@"IOS" forKey:@"logintype"];

    //添加应用app版本号
    [phoneInfoDict setObject:appCurVersion forKey:@"appversion"];

    //添加手机序列号（设备号）
    [phoneInfoDict setObject:identifierNumber forKey:@"devicenumber"];
    return phoneInfoDict;
}

#pragma mark - 获取手机品牌型号
+ (NSString *)getUserPhoneModelNumber {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];

    return deviceString;
}

#pragma mark - 转化成手机号空格式字符串
+ (NSString *)becomePhoneNumTypeWithNSString:(NSString *)string {

    NSString *newString = [[NSString alloc] init];

    NSString *first = [string substringToIndex:3];

    NSString *second = [string substringWithRange:NSMakeRange(3, 4)];
    NSString *third = [string substringFromIndex:7];

    newString = [NSString stringWithFormat:@"%@ %@ %@", first, second, third];

    return newString;
}

#pragma mark - 判断手机型号是否是5s以上
+ (BOOL)judgePhoneTypeIsCanFingerprint {

    //获取手机品牌型号
    NSRange range = {6, 1};

    NSString *phoneModelNum = @"0";
    if ([XXHelper getUserPhoneModelNumber].length >= 7) {
        phoneModelNum = [[XXHelper getUserPhoneModelNumber] substringWithRange:range];
    }

    if ([phoneModelNum integerValue] > 5) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - 拼接成中间有空格的字符串(类似银行卡中间空格)
+ (NSString *)jointBlankWithString:(NSString *)str {
    NSString *getString = @"";

    int a = (int) str.length / 4;
    int b = (int) str.length % 4;
    int c = a;
    if (b > 0) {
        c = a + 1;
    } else {
        c = a;
    }
    for (int i = 0; i < c; i++) {
        NSString *string = @"";

        if (i == (c - 1)) {
            if (b > 0) {
                string = [str substringWithRange:NSMakeRange(4 * (c - 1), b)];
            } else {
                string = [str substringWithRange:NSMakeRange(4 * i, 4)];
            }

        } else {
            string = [str substringWithRange:NSMakeRange(4 * i, 4)];
        }
        getString = [NSString stringWithFormat:@"%@ %@", getString, string];
    }
    return getString;
}

#pragma mark - 从单例类（NSUserDefaults）中取出可变数组（用于后面操作添加或者删除元素）
+ (NSMutableArray *)getMutableArrayFromNSUserDefaults:(NSString *)path {
    NSMutableArray *Array = [NSMutableArray new];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // mutableCopy 一定要添加 否则在对数组进行添加或者删除元素等操作的时候线程会卡死
    Array = [[defaults objectForKey:path] mutableCopy];

    return Array;
}

#pragma mark - 字典转化成字符串
+ (NSString *)dictionaryToJson:(NSDictionary *)dic {

    NSError *parseError = nil;

    NSData *jsonData =
        [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&parseError];

    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}
#pragma mark - 获取设备IP地址
+ (NSString *)getIPAddress {
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            if (temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name]
                        isEqualToString:@"en0"]) { // Get NSString from C String
                    address = [NSString
                        stringWithUTF8String:inet_ntoa(((struct sockaddr_in *) temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    } // Free memory
    freeifaddrs(interfaces);
    return address;
}

#pragma mark - 获取host属性
+ (NSString *)hostname {
    char baseHostName[256]; // Thanks, Gunnar Larisch
    int success = gethostname(baseHostName, 255);
    if (success != 0) return nil;
    baseHostName[255] = '/0';

#if TARGET_IPHONE_SIMULATOR
    return [NSString stringWithFormat:@"%s", baseHostName];
#else
    return [NSString stringWithFormat:@"%s.local", baseHostName];
#endif
}

#pragma mark - 获取本地host(主机)的IP地址
+ (NSString *)localIPAddress {
    struct hostent *host = gethostbyname([[XXHelper hostname] UTF8String]);
    if (!host) {
        herror("resolv");
        return nil;
    }
    struct in_addr **list = (struct in_addr **) host->h_addr_list;
    return [NSString stringWithCString:inet_ntoa(*list[0]) encoding:NSUTF8StringEncoding];
}



#pragma mark -  删除多余的cell、 分割线

+ (void)deleteExtraCellLine:(UITableView *)tableView {
    UIView *view = [UIView new];
    view.backgroundColor = [UIColor clearColor];
    [tableView setTableFooterView:view];
    [view removeFromSuperview];
}

#pragma mark -  倒计时按钮 返回重置时间

+ (void)startWithTime:(NSInteger)timeLine
                title:(NSString *)title
       countDownTitle:(NSString *)subTitle
            mainColor:(UIColor *)mColor
           countColor:(UIColor *)color
        disposeButton:(UIButton *)button {

    //倒计时时间
    __block NSInteger timeOut = timeLine;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_source_t _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    //每秒执行一次
    dispatch_source_set_timer(_timer, dispatch_walltime(NULL, 0), 1.0 * NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(_timer, ^{

        //倒计时结束，关闭
        if (timeOut <= 0) {
            dispatch_source_cancel(_timer);
            dispatch_async(dispatch_get_main_queue(), ^{
                button.backgroundColor = mColor;
                [button setTitle:title forState:UIControlStateNormal];
                button.userInteractionEnabled = YES;
            });
        } else {
            int allTime = (int) timeLine + 1;
            int seconds = timeOut % allTime;
            NSString *timeStr = [NSString stringWithFormat:@"%0.2d", seconds];
            dispatch_async(dispatch_get_main_queue(), ^{
                button.backgroundColor = color;
                [button setTitle:[NSString stringWithFormat:@"%@%@", timeStr, subTitle] forState:UIControlStateNormal];
                button.userInteractionEnabled = NO;
            });
            timeOut--;
        }
    });
    dispatch_resume(_timer);
}

#pragma mark -  倒计时按钮 返回页面不重置时间
    
+ (void)startSeniorWithTime:(NSInteger)timeLine
                      title:(NSString *)title
             countDownTitle:(NSString *)subTitle
                  mainColor:(UIColor *)mColor
                 countColor:(UIColor *)color
              disposeButton:(UIButton *)button {
    
    int __block time = (int) timeLine;
    
    button.enabled = NO;
    //获取系统全局队列
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    //基于全局队列创建定时器
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    //设置定时器为点击后马上开始，间隔时间为1秒，没有延迟
    dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, 0), 1 * NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(timer, ^{
        if (time == 0) {
            button.enabled = YES;
            dispatch_source_cancel(timer);
            dispatch_async(dispatch_get_main_queue(), ^{
                button.backgroundColor = mColor;
                [button setTitle:title forState:UIControlStateNormal];
                button.userInteractionEnabled = YES;
            });
        } else {
            time--;
            NSString *string = [NSString stringWithFormat:@"%d%@", time, subTitle];
            dispatch_async(dispatch_get_main_queue(), ^{
                button.backgroundColor = color;
                [button setTitle:[NSString stringWithFormat:@"%@", string] forState:UIControlStateNormal];
                button.userInteractionEnabled = NO;
            });
        }
    });
    
    dispatch_resume(timer);
}

#pragma mark -   图片转成base64编码

+ (NSString *)imageConvertFormatBase64imageName:(NSString *)imageName {
    UIImage *originImage = [UIImage imageNamed:imageName];

    NSData *data = UIImageJPEGRepresentation(originImage, 1.0f);

    NSString *encodedImageStr = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    return encodedImageStr;
}

#pragma mark - 将数组里的字符串排序

+ (NSMutableArray *)Transformation:(NSArray *)dataArray isGrouping:(BOOL)grouping {
    NSMutableArray *TwoArr = [NSMutableArray array];
    for (NSString *TransformationStr in dataArray) {
        NSMutableString *pinyin = [TransformationStr mutableCopy];
        CFStringTransform((__bridge CFMutableStringRef) pinyin, NULL, kCFStringTransformMandarinLatin, NO);
        CFStringTransform((__bridge CFMutableStringRef) pinyin, NULL, kCFStringTransformStripCombiningMarks, NO);
        [TwoArr addObject:pinyin];
    }
    NSMutableArray *ThreeArr = [NSMutableArray array];
    for (__strong NSString *ScreenStr in TwoArr) {
        ScreenStr = [ScreenStr substringToIndex:1];
        if (ThreeArr.count == 0) {
            [ThreeArr addObject:ScreenStr];
        } else {
            BOOL bl = [ThreeArr containsObject:ScreenStr];
            if (!bl) {
                [ThreeArr addObject:ScreenStr];
            }
        }
    }
    NSArray *FourArr = [ThreeArr sortedArrayUsingSelector:@selector(compare:)];
    NSMutableArray *MyArr = [NSMutableArray array];
    NSMutableArray *allNewDataArr = [NSMutableArray array];
    for (NSString *str in FourArr) {
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        [dic setObject:str forKey:@"title"]; // 索引
        NSMutableArray *arr = [NSMutableArray array];
        for (int i = 0; i < TwoArr.count; i++) {
            NSString *missstr = TwoArr[i];
            missstr = [missstr substringToIndex:1];
            if ([str isEqualToString:missstr]) {
                [arr addObject:dataArray[i]];
            }
        }
        [dic setObject:arr forKey:@"info"];
        for (id obj in arr) {
            [allNewDataArr addObject:obj];
        }

        [MyArr addObject:dic];
    }
    return grouping ? MyArr : allNewDataArr;
}

#pragma mark -  获取rootViewController
+ (UIViewController *)rootViewController {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    return window.rootViewController;
}

#pragma mark - 获取Window当前显示的ViewController
+ (UIViewController *)currentViewController {
    UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;

    while (1) {
        if ([vc isKindOfClass:[UITabBarController class]]) {
            vc = ((UITabBarController *) vc).selectedViewController;
        }

        if ([vc isKindOfClass:[UINavigationController class]]) {
            vc = ((UINavigationController *) vc).visibleViewController;
        }

        if (vc.presentedViewController) {
            vc = vc.presentedViewController;
        } else {
            break;
        }
    }

    return vc;
}
+ (CGFloat)heightForImage:(UIImage *)image
              targetWidth:(NSInteger)defineWidth

{
    CGSize size = image.size;

    CGFloat scale = defineWidth / size.width;

    CGFloat imageH = size.height * scale;

    return imageH;
}

/**
 *  检测麦克风权限，仅支持iOS7.0以上系统
 *
 *  @return 准许返回YES;否则返回NO
 */
+ (BOOL)isMicrophonePermissionGranted {
    if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(requestRecordPermission:)]) {
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        __block BOOL isGranted = YES;
        [[AVAudioSession sharedInstance] performSelector:@selector(requestRecordPermission:)
                                              withObject:^(BOOL granted) {
                                                  isGranted = granted;
                                                  dispatch_semaphore_signal(sema);
                                              }];
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        return isGranted;
    } else {
        return YES;
    }
}

/**
 *  检测相机权限
 *
 *  @return 准许返回YES;否则返回NO
 */
+ (BOOL)isCapturePermissionGranted {
    if ([AVCaptureDevice respondsToSelector:@selector(authorizationStatusForMediaType:)]) {
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) {
            return NO;
        } else if (authStatus == AVAuthorizationStatusNotDetermined) {
            dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            __block BOOL isGranted = YES;
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
                                     completionHandler:^(BOOL granted) {
                                         isGranted = granted;
                                         dispatch_semaphore_signal(sema);
                                     }];
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
            return isGranted;
        } else {
            return YES;
        }
    } else {
        return YES;
    }
}

/**
 *  检测相册权限
 *
 *  @return 准许返回YES;否则返回NO
 */
+ (BOOL)isAssetsLibraryPermissionGranted {
    if ([ALAssetsLibrary respondsToSelector:@selector(authorizationStatus)]) {
        ALAuthorizationStatus authStatus = [ALAssetsLibrary authorizationStatus];
        if (authStatus == ALAuthorizationStatusRestricted || authStatus == ALAuthorizationStatusDenied) {
            return NO;
        } else if (authStatus == ALAuthorizationStatusNotDetermined) {
            dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            __block BOOL isGranted = YES;

            dispatch_queue_t dispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            dispatch_async(dispatchQueue, ^(void) {
                ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
                [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll
                    usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                        isGranted = YES;
                        *stop = YES;
                        NSLog(@"enumerate");
                        dispatch_semaphore_signal(sema);
                    }
                    failureBlock:^(NSError *error) {
                        isGranted = NO;
                        NSLog(@"error:%ld %@", (long) error.code, error.description);
                        dispatch_semaphore_signal(sema);
                    }];
            });
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
            return isGranted;
        } else {
            return YES;
        }
    } else {
        return YES;
    }
}

/**
 *  浏览大图
 *
 *  @param currentImageview 图片所在的imageView
 */
+ (void)scanBigImageWithImageView:(UIImageView *)currentImageview {

    //当前imageview的图片
    UIImage *image = currentImageview.image;
    //当前视图
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    //背景
    UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width,
                                                                      [UIScreen mainScreen].bounds.size.height)];
    //当前imageview的原始尺寸->将像素currentImageview.bounds由currentImageview.bounds所在视图转换到目标视图window中，返回在目标视图window中的像素值
    oldframe = [currentImageview convertRect:currentImageview.bounds toView:window];
    [backgroundView setBackgroundColor:[UIColor colorWithRed:107 / 255.0 green:107 / 255.0 blue:99 / 255.0 alpha:0.6]];
    //此时视图不会显示
    [backgroundView setAlpha:0];
    //将所展示的imageView重新绘制在Window中
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:oldframe];
    [imageView setImage:image];
    [imageView setTag:1024];
    [backgroundView addSubview:imageView];
    //将原始视图添加到背景视图中
    [window addSubview:backgroundView];

    //添加点击事件同样是类方法 -> 作用是再次点击回到初始大小
    UITapGestureRecognizer *tapGestureRecognizer =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideImageView:)];
    [backgroundView addGestureRecognizer:tapGestureRecognizer];

    //动画放大所展示的ImageView

    [UIView animateWithDuration:0.4
                     animations:^{
                         CGFloat y, width, height;
                         y = ([UIScreen mainScreen].bounds.size.height -
                              image.size.height * [UIScreen mainScreen].bounds.size.width / image.size.width) *
                             0.5;
                         //宽度为屏幕宽度
                         width = [UIScreen mainScreen].bounds.size.width;
                         //高度 根据图片宽高比设置
                         height = image.size.height * [UIScreen mainScreen].bounds.size.width / image.size.width;
                         [imageView setFrame:CGRectMake(0, y, width, height)];
                         //重要！ 将视图显示出来
                         [backgroundView setAlpha:1];
                     }
                     completion:^(BOOL finished){

                     }];
}

/**
 *  恢复imageView原始尺寸
 *
 *  @param tap 点击事件
 */
+ (void)hideImageView:(UITapGestureRecognizer *)tap {
    UIView *backgroundView = tap.view;
    //原始imageview
    UIImageView *imageView = [tap.view viewWithTag:1024];
    //恢复
    [UIView animateWithDuration:0.4
        animations:^{
            [imageView setFrame:oldframe];
            [backgroundView setAlpha:0];
        }
        completion:^(BOOL finished) {
            //完成后操作->将背景视图删掉
            [backgroundView removeFromSuperview];
        }];
}

#pragma mark -  修正照片方向(手机转90度方向拍照)
- (UIImage *)fixOrientation:(UIImage *)aImage {

    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp) return aImage;

    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;

    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;

        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;

        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }

    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;

        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}
#pragma mark -计算label 所占的高度

+ (CGFloat)calculteTheSizeWithContent:(NSString *)content width:(float)width font:(float )font {
    
    NSDictionary *attribute = @{NSFontAttributeName : [UIFont systemFontOfSize:font]};
    
    CGSize size = [content boundingRectWithSize:CGSizeMake(width, MAXFLOAT)
                                        options:NSStringDrawingTruncatesLastVisibleLine |
                   NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                     attributes:attribute
                                        context:nil].size;
    return size.height;
}

/**
 *  计算文字宽度
 */
+ (CGFloat )widthForLabel:(NSString *)text fontSize:(CGFloat)font
{
    CGSize size = [text sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:font], NSFontAttributeName, nil]];
    return size.width;
}


@end
