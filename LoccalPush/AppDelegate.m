//
//  AppDelegate.m
//  LoccalPush
//
//  Created by 小飞鸟 on 2019/03/25.
//  Copyright © 2019 小飞鸟. All rights reserved.
//

#import "AppDelegate.h"
#import <UserNotifications/UserNotifications.h>
#import<CoreLocation/CoreLocation.h>

@interface AppDelegate ()<UNUserNotificationCenterDelegate,CLLocationManagerDelegate>

@property(nonatomic,strong)CLLocationManager * locationManager;

// 声明 CLGeocoder 对象
@property (nonatomic, strong)CLGeocoder *geocoder;
/*启动的信息*/
@property(nonatomic,strong)NSDictionary * userInfo;

@end

@implementation AppDelegate

//如果应用被杀死 会先走这个方法
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [self initLocationManager];
    [self addLocalNotice:@"标题"];
    //注册通知
    [self registerRemoteApplication:application WithOptions:launchOptions];
    // 实例化 CLGeocoder 对象
    self.geocoder = [[CLGeocoder alloc] init];
//    [self getCoordinateByAddress:@"鹏润大厦B座"];
    [self checkUserNotificationEnable];
    [self cancelAllLocalNotification];

    return YES;
}

/*注册本地通知*/
-(void)registerRemoteApplication:(UIApplication*)application WithOptions:(NSDictionary *)launchOptions{
    if (@available(iOS 10.0, *)) {
        //iOS10以上的系统
        UNUserNotificationCenter * center = [UNUserNotificationCenter currentNotificationCenter];
        UNAuthorizationOptions options = UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert;
        center.delegate = (id<UNUserNotificationCenterDelegate>)self;
        [center requestAuthorizationWithOptions:options completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if(!error){
                NSLog( @"Push registration success." );
            }else{
                NSLog( @"Push registration FAILED" );
                NSLog( @"ERROR: %@ - %@", error.localizedFailureReason, error.localizedDescription );
                NSLog( @"SUGGESTIONS: %@ - %@", error.localizedRecoveryOptions, error.localizedRecoverySuggestion );
            }
        }];
    }else{
        //iOS8 - iOS10
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge | UIUserNotificationTypeAlert | UIUserNotificationTypeSound) categories:nil];
        [application registerUserNotificationSettings:settings];
    }
}

#pragma mark 根据地名确定地理坐标
- (void)getCoordinateByAddress:(NSString *)address{
   //地理编码
      [_geocoder geocodeAddressString:address completionHandler:^(NSArray *placemarks, NSError *error) {
            //取得第一个地标，地标中存储了详细的地址信息，注意：一个地名可能搜索出多个地址
       CLPlacemark *placemark = [placemarks firstObject];
        NSLog(@"位置=%@-->纬度=%f----经度=%f", address, placemark.location.coordinate.latitude, placemark.location.coordinate.longitude);
      }];
}

-(void)initLocationManager{
    
    self.locationManager = [[CLLocationManager alloc]init];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters;
    self.locationManager.delegate = self;
    [self.locationManager startMonitoringSignificantLocationChanges];
    
    [_locationManager setAllowsBackgroundLocationUpdates:YES];//允许后台更新
    
    CLLocationCoordinate2D locationCenter = CLLocationCoordinate2DMake(39.959036,116.466458);
    CLCircularRegion* region = [[CLCircularRegion alloc] initWithCenter:locationCenter
                                                                 radius:200.0 identifier:@"Headquarters"];
    // 区域监听,监听的是用户,所以应该让用户授权获取用户当前位置
    if ([_locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [_locationManager requestAlwaysAuthorization];
    }
    
    //开启区域监听,没有返回值,在代理方法中得到信息并且处理信息  注:该方法只有用户位置发生变化的时候,相应的代理方法才会触发
    [_locationManager startMonitoringForRegion:region];
    //根据指定区域请求一下用户现在的位置状态  该方法在程序一启动就会请求用户的位置状态.同样当用户位置发生变化时,也会触发相应的代理方法
    [_locationManager requestStateForRegion:region];
    // ###细节二:判断设备是否支持区域监听(指定区域类型,一般是圆形区域)
    if (![CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]]) {
        return;
    }
}


#pragma mark 发送本地推送
-(void)addLocalNotice:(NSString*)title{

    title = title? title:@"推送标题";
    if (@available(iOS 10.0, *)) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        // 标题
        content.title = title;
        // 内容
        content.body = @"推送内容";
        //代理设置
        id delegate =(id<UNUserNotificationCenterDelegate>)[UIApplication sharedApplication].delegate;
        center.delegate = delegate;
        // 默认声音
        content.sound = [UNNotificationSound defaultSound];
        
        NSDictionary * dict =@{
                               UNNotificationAttachmentOptionsThumbnailHiddenKey:@NO,
                               UNNotificationAttachmentOptionsThumbnailClippingRectKey:(__bridge id _Nullable)((CGRectCreateDictionaryRepresentation(CGRectMake(0.5, 0.5, 0.25 ,0.25))))
                               };
        NSError * error;
        //                NSURL * localURL = [NSURL URLWithString:[@"file://" stringByAppendingString:localPath]];
        //普通图片
//        NSString *  localPath =  [[NSBundle mainBundle]pathForResource:@"精选@2x" ofType:@"png"];
        //GIF图片
//        NSString *  localPath =  [[NSBundle mainBundle]pathForResource:@"test1" ofType:@"gif"];
        //视频
        NSString *  localPath =  [[NSBundle mainBundle]pathForResource:@"flvTest" ofType:@"mp4"];

        NSURL * localURL =  [NSURL fileURLWithPath:localPath];
        UNNotificationAttachment * attachment = [UNNotificationAttachment attachmentWithIdentifier:@"photo" URL:localURL options:nil error:&error];
        if (attachment) {
            content.attachments = @[attachment];
        }
        
        
        //图片
//        //launchImageName
//        content.launchImageName = @"精选@2x";
//        NSError * error;
//        NSString *path = [[NSBundle mainBundle] pathForResource:@"精选@2x" ofType:@"png"];
//        // 2.设置通知附件内容
//        UNNotificationAttachment *att = [UNNotificationAttachment attachmentWithIdentifier:@"att1" URL:[NSURL fileURLWithPath:path] options:nil error:&error];
//        if (error) {
//            NSLog(@"attachment error %@", error);
//        }
//        content.attachments = @[att];
//        content.launchImageName = @"精选@2x";
        
        //3.1获取网络图片
//        NSString * imageUrlString = @"https://img1.doubanio.com/img/musician/large/22817.jpg";
//        if (imageUrlString) {
//            NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrlString]];
//            //3.2图片保存到沙盒
//            NSString *documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
//            NSString *localPath = [documentPath stringByAppendingPathComponent:@"localNotificationImage.jpg"];
//            [imageData writeToFile:localPath atomically:YES];
//            localPath =   [[NSBundle mainBundle]pathForResource:@"精选@2x" ofType:@"png"];
//            //3.3设置通知的attachment(附件)
//            if (localPath && ![localPath isEqualToString:@""]) {
//                NSDictionary * dict =@{
//                                       UNNotificationAttachmentOptionsThumbnailHiddenKey:@NO,
//                                       UNNotificationAttachmentOptionsThumbnailClippingRectKey:(__bridge id _Nullable)((CGRectCreateDictionaryRepresentation(CGRectMake(0.5, 0.5, 0.25 ,0.25))))
//                                       };
//                NSError * error;
//                NSURL * localURL = [NSURL URLWithString:[@"file://" stringByAppendingString:localPath]];
//                UNNotificationAttachment * attachment = [UNNotificationAttachment attachmentWithIdentifier:@"photo" URL:localURL options:dict error:&error];
//                if (attachment) {
//                    content.attachments = @[attachment];
//                }
//            }
//        }
        // 角标 （我这里测试的角标无效，暂时没找到原因）
        content.badge = @1;
        //分钟推送 但是 重复推送时间需要60s以上
        /**************************每隔多长时间推送一次************************************************/
        UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];
        
 /**************************按照设定的日期推送************************************************/
        // 周一早上 8：00 上班
//        NSDateComponents *components = [[NSDateComponents alloc] init];
//        // 注意，weekday是从周日开始的，如果想设置为从周一开始，大家可以自己想想~
//        components.weekday = 2;//周二
//        components.hour = 17;//八点 24小时制
//        components.minute =3;//分钟
//        UNCalendarNotificationTrigger *trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:components repeats:YES];
        
/**************************按照设定的区域推送************************************************/
       // 圆形区域，进入时候进行通知
//        CLLocationCoordinate2D locationCenter = CLLocationCoordinate2DMake(39.959036,116.466458);
//        CLCircularRegion* region = [[CLCircularRegion alloc] initWithCenter:locationCenter
//                                                                     radius:1000.0 identifier:@"Headquarters"];
//        region.notifyOnEntry = YES;//进入区域
//        region.notifyOnExit = YES;//退出区域
//        UNLocationNotificationTrigger * trigger = [UNLocationNotificationTrigger
//                                                  triggerWithRegion:region repeats:NO];
        // 添加通知的标识符，可以用于移除，更新等操作
        NSString *identifier = @"noticeId";
        // 可以添加特定信息
        content.userInfo = @{
                             @"title":@"标题",
                             @"scheme":@"http://www.baidu.com"
                             };
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];
        [center addNotificationRequest:request withCompletionHandler:^(NSError *_Nullable error) {
            NSLog(@"成功添加推送");
//            [self removeNofi];
        }];
    }else {
        UILocalNotification *notif = [[UILocalNotification alloc] init];
        // 发出推送的日期
        notif.fireDate = [NSDate dateWithTimeIntervalSinceNow:0.1];
        // 标题
        notif.alertTitle = title;
        // 推送的内容
        notif.alertBody = @"推送内容";
        // 可以添加特定信息
        notif.userInfo = @{
                           @"title":@"标题",
                           @"scheme":@"http://www.baidu.com",
                           @"noticeId":@"noticeId"
                           };
        // 角标
        notif.applicationIconBadgeNumber = 1;
        // 提示音
        notif.soundName = UILocalNotificationDefaultSoundName;
        //是否循环
        notif.repeatInterval = NSCalendarUnitSecond;
        //发送通知
        [[UIApplication sharedApplication] scheduleLocalNotification:notif];
    }
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations{
    CLLocation *lastLocation = [locations lastObject];
    NSLog(@"longitude****%lf~~~latitude***%lf",lastLocation.coordinate.longitude,lastLocation.coordinate.latitude);
    // 开始反编码
    [self.geocoder reverseGeocodeLocation:lastLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        
        // 判断反编码是否成功
        if (error || 0 == placemarks.count) {
            NSLog(@"erroe = %@, placemarks.count = %ld", error, placemarks.count);
            
        } else {  // 反编码成功（找到了具体的位置信息）
            
            // 输出查询到的所有地标信息
            for (CLPlacemark *placemark in placemarks) {
                
                NSLog(@"name=%@, locality=%@, country=%@", placemark.name, placemark.locality, placemark.country);
            }
            
            // 显示最前面的地标信息
            CLPlacemark *firstPlacemark = [placemarks firstObject];
            NSLog(@"%@",    [NSString stringWithFormat:@"%@，%@，%@", firstPlacemark.name, firstPlacemark.locality, firstPlacemark.country]);
        }
    }];
    
}

#warning 区域监听
//开始监听
- (void)locationManager:(CLLocationManager *)manager
didStartMonitoringForRegion:(CLRegion *)region{
    
     NSLog(@"%s",__func__);
}
//区域监听失败
- (void)locationManager:(CLLocationManager *)manager
monitoringDidFailForRegion:(nullable CLRegion *)region
              withError:(NSError *)error{
    NSLog(@"%s",__func__);
    
}
//进入区域
- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region{
 [self addLocalNotice:@"进入区域了"];
}
//离开区域
- (void)locationManager:(CLLocationManager *)manager
          didExitRegion:(CLRegion *)region{
    [self addLocalNotice:@"离开区域了"];
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region{
    /*
     CLRegionStateUnknown, 不知道
     CLRegionStateInside, 进入区域
     CLRegionStateOutside 离开区域
     */
    if (state == CLRegionStateInside) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"进入区域" message:@"You have Entered the Location." delegate:nil cancelButtonTitle:@"OK"  otherButtonTitles: nil];
        [alert show];
    } else if (state == CLRegionStateOutside) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"离开区域" message:@"You have Entered the Location." delegate:nil cancelButtonTitle:@"OK"  otherButtonTitles: nil];
        [alert show];
    }
}

/************************************************通知授权**********************************************/

- (void)checkUserNotificationEnable { // 判断用户是否允许接收通知
    if (@available(iOS 10.0, *)) {
        __block BOOL isOn = NO;
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
            if (settings.notificationCenterSetting == UNNotificationSettingEnabled) {
                isOn = YES;
                NSLog(@"打开了通知");
            }else {
                isOn = NO;
                NSLog(@"关闭了通知");
            }
        }];
    }else {
        if ([[UIApplication sharedApplication] currentUserNotificationSettings].types == UIUserNotificationTypeNone){
            NSLog(@"关闭了通知");
            
        }else {
            NSLog(@"打开了通知");
        }
    }
}

/************************************************v移除通知**********************************************/

-(void)removeNofi{
    if (@available(iOS 10.0, *)) {
        //本地
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> * _Nonnull requests) {
            for (UNNotificationRequest *req in requests){
                NSLog(@"存在的ID:%@\n",req.identifier);
                if ([req.identifier isEqualToString:@"noticeId"]) {
                    [center removePendingNotificationRequestsWithIdentifiers:@[req.identifier]];
                }
            }
        }];
    }else{
        
        NSArray<UILocalNotification *> *localNotifications  =  [[UIApplication sharedApplication]scheduledLocalNotifications];
        for(UILocalNotification * localNotification in localNotifications){
            NSDictionary *userInfo = localNotification.userInfo;
            NSString *obj = [userInfo objectForKey:@"noticeId"];
            if ([obj isEqualToString:@"noticeId"]) {
                [[UIApplication sharedApplication]cancelLocalNotification:localNotification];
            }
        }
    }
}

//取消本地的所有通知
-(void)cancelAllLocalNotification{
    if (@available(iOS 10.0, *)) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center removeAllPendingNotificationRequests];
    }else{
        [[UIApplication sharedApplication]cancelAllLocalNotifications];
    }
}

-(NSString *)jsonStringEncoded:(NSDictionary*)jsonDic{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDic options:0 error:&error];
    NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return json;
}

/************************************************通知**********************************************/
#pragma mark App通知的点击事件  iOS 8.0以后
//方法是 iOS8.0 ~iOS10.0的方法
-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification{
    NSLog(@"iOS 8.0以后");
    
    //后台被杀死
//    [self removeNofi];
    NSLog(@"%@",[NSDate date]);
    if (application.applicationState==UIApplicationStateActive) {
        NSLog(@"UIApplicationStateActive");
    }else if (application.applicationState==UIApplicationStateInactive){
        NSLog(@"UIApplicationStateInactive");
    }
}

#pragma mark App通知的点击事件  iOS 10.0以后
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler{
    
    
}

#pragma mark App处于前台接收通知时  iOS 10.0以后
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler{
    // 展示
    completionHandler(UNNotificationPresentationOptionAlert|UNNotificationPresentationOptionSound);
    // 不展示
    //    completionHandler(UNNotificationPresentationOptionNone);
}
@end
