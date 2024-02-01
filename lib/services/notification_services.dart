import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'keys.dart';

class NotificationServices {
  Future onReceiveFCMNotification(RemoteMessage message) async {
    // log(message.messageId! as num);
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: message.hashCode,
        channelKey: Keys.sponsorChannelKey,
        title: message.notification!.title,
        body: message.notification!.body,
        notificationLayout: NotificationLayout.BigText,
        displayOnBackground: true,
        displayOnForeground: true,
        autoDismissible: true,
        wakeUpScreen: true,
      ),
    );
  }
}
