class Customer {
  final String? id;
  final String? name;
  final String? email;
  final String? phone;
  final String? avatar;
  final bool? online;
  final String? language;
  final String? theme;
  Customer({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.avatar,
    this.online,
    this.language,
    this.theme,
  });
  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['_id']?.toString() ?? json['id']?.toString(),
        name: json['name']?.toString(),
        email: json['email']?.toString(),
        phone: json['phone']?.toString(),
        avatar: json['avatar']?.toString(),
        online: json['online'] as bool?,
        language: json['language']?.toString(),
        theme: json['theme']?.toString(),
      );
  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'avatar': avatar,
        'online': online,
        'language': language,
        'theme': theme,
      };
}

class Artisan {
  final String? id;
  final String? name;
  final String? profession;
  final double? rating;
  final String? avatar;
  final String? area;
  final num? distance;
  Artisan({
    this.id,
    this.name,
    this.profession,
    this.rating,
    this.avatar,
    this.area,
    this.distance,
  });
  factory Artisan.fromJson(Map<String, dynamic> json) => Artisan(
        id: json['_id']?.toString() ?? json['id']?.toString(),
        name: json['name']?.toString(),
        profession: json['profession']?.toString(),
        rating: (json['rating'] as num?)?.toDouble(),
        avatar: json['avatar']?.toString(),
        area: json['area']?.toString(),
        distance: json['distance'] as num?,
      );
  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'profession': profession,
        'rating': rating,
        'avatar': avatar,
        'area': area,
        'distance': distance,
      };
}

class Category {
  final String? id;
  final String? name;
  final String? image;
  Category({this.id, this.name, this.image});
  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['_id']?.toString() ?? json['id']?.toString(),
        name: json['name']?.toString(),
        image: json['image']?.toString(),
      );
  Map<String, dynamic> toJson() => {'_id': id, 'name': name, 'image': image};
}

class Request {
  final String? id;
  final String? title;
  final String? description;
  final String? status;
  final String? artisanId;
  final DateTime? createdAt;
  final List<String>? images;
  Request({
    this.id,
    this.title,
    this.description,
    this.status,
    this.artisanId,
    this.createdAt,
    this.images,
  });
  factory Request.fromJson(Map<String, dynamic> json) => Request(
        id: json['_id']?.toString() ?? json['id']?.toString(),
        title: json['title']?.toString(),
        description: json['description']?.toString(),
        status: json['status']?.toString(),
        artisanId: json['artisanId']?.toString(),
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
        images: (json['images'] as List?)
            ?.map((e) => e.toString())
            .toList(),
      );
  Map<String, dynamic> toJson() => {
        '_id': id,
        'title': title,
        'description': description,
        'status': status,
        'artisanId': artisanId,
        'createdAt': createdAt?.toIso8601String(),
        'images': images,
      };
}

class RequestTimelineItem {
  final String? id;
  final String? message;
  final DateTime? at;
  RequestTimelineItem({this.id, this.message, this.at});
  factory RequestTimelineItem.fromJson(Map<String, dynamic> json) =>
      RequestTimelineItem(
        id: json['_id']?.toString() ?? json['id']?.toString(),
        message: json['message']?.toString(),
        at: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
      );
  Map<String, dynamic> toJson() =>
      {'_id': id, 'message': message, 'createdAt': at?.toIso8601String()};
}

class Review {
  final String? id;
  final String? artisanId;
  final String? comment;
  final double? rating;
  Review({this.id, this.artisanId, this.comment, this.rating});
  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['_id']?.toString() ?? json['id']?.toString(),
        artisanId: json['artisanId']?.toString(),
        comment: json['comment']?.toString(),
        rating: (json['rating'] as num?)?.toDouble(),
      );
  Map<String, dynamic> toJson() =>
      {'_id': id, 'artisanId': artisanId, 'comment': comment, 'rating': rating};
}

class Favorite {
  final String? id;
  final Artisan? artisan;
  Favorite({this.id, this.artisan});
  factory Favorite.fromJson(Map<String, dynamic> json) => Favorite(
        id: json['_id']?.toString() ?? json['id']?.toString(),
        artisan: json['artisan'] != null
            ? Artisan.fromJson(Map<String, dynamic>.from(json['artisan']))
            : null,
      );
  Map<String, dynamic> toJson() => {'_id': id, 'artisan': artisan?.toJson()};
}

class NotificationItem {
  final String? id;
  final String? title;
  final String? body;
  final bool? read;
  final DateTime? createdAt;
  NotificationItem({this.id, this.title, this.body, this.read, this.createdAt});
  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      NotificationItem(
        id: json['_id']?.toString() ?? json['id']?.toString(),
        title: json['title']?.toString(),
        body: json['body']?.toString(),
        read: json['read'] as bool?,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
      );
  Map<String, dynamic> toJson() => {
        '_id': id,
        'title': title,
        'body': body,
        'read': read,
        'createdAt': createdAt?.toIso8601String(),
      };
}

class Wallet {
  final double? balance;
  Wallet({this.balance});
  factory Wallet.fromJson(Map<String, dynamic> json) =>
      Wallet(balance: (json['balance'] as num?)?.toDouble());
  Map<String, dynamic> toJson() => {'balance': balance};
}

class WalletTransaction {
  final String? id;
  final double? amount;
  final String? type;
  final DateTime? at;
  WalletTransaction({this.id, this.amount, this.type, this.at});
  factory WalletTransaction.fromJson(Map<String, dynamic> json) =>
      WalletTransaction(
        id: json['_id']?.toString() ?? json['id']?.toString(),
        amount: (json['amount'] as num?)?.toDouble(),
        type: json['type']?.toString(),
        at: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
      );
  Map<String, dynamic> toJson() =>
      {'_id': id, 'amount': amount, 'type': type, 'createdAt': at?.toIso8601String()};
}

class Payment {
  final String? id;
  final double? amount;
  final String? status;
  Payment({this.id, this.amount, this.status});
  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['_id']?.toString() ?? json['id']?.toString(),
        amount: (json['amount'] as num?)?.toDouble(),
        status: json['status']?.toString(),
      );
  Map<String, dynamic> toJson() => {'_id': id, 'amount': amount, 'status': status};
}

class Complaint {
  final String? id;
  final String? subject;
  final String? status;
  Complaint({this.id, this.subject, this.status});
  factory Complaint.fromJson(Map<String, dynamic> json) => Complaint(
        id: json['_id']?.toString() ?? json['id']?.toString(),
        subject: json['subject']?.toString(),
        status: json['status']?.toString(),
      );
  Map<String, dynamic> toJson() =>
      {'_id': id, 'subject': subject, 'status': status};
}

class ComplaintMessage {
  final String? id;
  final String? message;
  final String? sender;
  final DateTime? at;
  ComplaintMessage({this.id, this.message, this.sender, this.at});
  factory ComplaintMessage.fromJson(Map<String, dynamic> json) =>
      ComplaintMessage(
        id: json['_id']?.toString() ?? json['id']?.toString(),
        message: json['message']?.toString(),
        sender: json['sender']?.toString(),
        at: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
      );
  Map<String, dynamic> toJson() =>
      {'_id': id, 'message': message, 'sender': sender, 'createdAt': at?.toIso8601String()};
}

class Coupon {
  final String? code;
  final double? discount;
  final String? description;
  Coupon({this.code, this.discount, this.description});
  factory Coupon.fromJson(Map<String, dynamic> json) => Coupon(
        code: json['code']?.toString(),
        discount: (json['discount'] as num?)?.toDouble(),
        description: json['description']?.toString(),
      );
  Map<String, dynamic> toJson() =>
      {'code': code, 'discount': discount, 'description': description};
}

class Reward {
  final String? id;
  final String? title;
  final String? description;
  Reward({this.id, this.title, this.description});
  factory Reward.fromJson(Map<String, dynamic> json) => Reward(
        id: json['_id']?.toString() ?? json['id']?.toString(),
        title: json['title']?.toString(),
        description: json['description']?.toString(),
      );
  Map<String, dynamic> toJson() =>
      {'_id': id, 'title': title, 'description': description};
}

class Recommendation {
  final String? id;
  final String? title;
  Recommendation({this.id, this.title});
  factory Recommendation.fromJson(Map<String, dynamic> json) =>
      Recommendation(
        id: json['_id']?.toString() ?? json['id']?.toString(),
        title: json['title']?.toString(),
      );
  Map<String, dynamic> toJson() => {'_id': id, 'title': title};
}

class LiveMapItem {
  final String? id;
  final double? lat;
  final double? lng;
  LiveMapItem({this.id, this.lat, this.lng});
  factory LiveMapItem.fromJson(Map<String, dynamic> json) => LiveMapItem(
        id: json['_id']?.toString() ?? json['id']?.toString(),
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
      );
  Map<String, dynamic> toJson() => {'_id': id, 'lat': lat, 'lng': lng};
}

class AIFeedback {
  final String? message;
  final DateTime? createdAt;
  AIFeedback({this.message, this.createdAt});
  factory AIFeedback.fromJson(Map<String, dynamic> json) =>
      AIFeedback(
        message: json['message']?.toString(),
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
      );
  Map<String, dynamic> toJson() =>
      {'message': message, 'createdAt': createdAt?.toIso8601String()};
}

class ViewHistoryItem {
  final String? id;
  final String? artisanId;
  final DateTime? at;
  ViewHistoryItem({this.id, this.artisanId, this.at});
  factory ViewHistoryItem.fromJson(Map<String, dynamic> json) =>
      ViewHistoryItem(
        id: json['_id']?.toString() ?? json['id']?.toString(),
        artisanId: json['artisanId']?.toString(),
        at: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
      );
  Map<String, dynamic> toJson() =>
      {'_id': id, 'artisanId': artisanId, 'createdAt': at?.toIso8601String()};
}

class FcmToken {
  final String? token;
  final String? device;
  FcmToken({this.token, this.device});
  factory FcmToken.fromJson(Map<String, dynamic> json) =>
      FcmToken(token: json['token']?.toString(), device: json['device']?.toString());
  Map<String, dynamic> toJson() => {'token': token, 'device': device};
}
