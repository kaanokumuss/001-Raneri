import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Firebase Messaging izinleri
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Local notifications başlatma
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Bildirime tıklandığında yapılacak işlemler
        _handleNotificationTap(response.payload);
      },
    );

    // Foreground mesajları dinle
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background mesajları dinle
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Uygulama kapalıyken gelen mesajları dinle
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // FCM token al
    final token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Foreground message received: ${message.messageId}');

    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformDetails,
      payload: message.data.toString(),
    );
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    await Firebase.initializeApp();
    print('Background message received: ${message.messageId}');
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    print('Message clicked: ${message.messageId}');
    // Navigate to specific screen based on message data
  }

  static void _handleNotificationTap(String? payload) {
    print('Notification tapped with payload: $payload');
    // Handle notification tap
  }

  static Future<void> sendNotificationToTopic(
    String topic,
    String title,
    String body,
  ) async {
    // Bu metot sadece server-side'da çalışır
    // Client-side'da bu işlem için backend API'sini kullanmanız gerekir
    print('Notification sent to topic: $topic, Title: $title, Body: $body');
  }

  static Future<void> scheduleDocumentExpirationNotification({
    required String personnelName,
    required String documentName,
    required DateTime expirationDate,
  }) async {
    final now = DateTime.now();
    final daysUntilExpiration = expirationDate.difference(now).inDays;

    if (daysUntilExpiration <= 30 && daysUntilExpiration >= 0) {
      const androidDetails = AndroidNotificationDetails(
        'document_expiration_channel',
        'Document Expiration Notifications',
        channelDescription: 'Notifications for document expiration warnings.',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        documentName.hashCode,
        'Belge Süresi Dolmak Üzere!',
        '$personnelName - $documentName belgesi $daysUntilExpiration gün sonra sona eriyor.',
        platformDetails,
      );
    }
  }

  static Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  static Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }
}
