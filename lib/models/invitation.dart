class Invitation {
  final String id;
  final String listId;
  final String listName;
  final String senderId;
  final String senderEmail;
  final String receiverEmail;
  final String status;

  Invitation({
    required this.id,
    required this.listId,
    required this.listName,
    required this.senderId,
    required this.senderEmail,
    required this.receiverEmail,
    required this.status,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      id: json['id'] as String,
      listId: json['listId'] as String,
      listName: json['listName'] as String,
      senderId: json['senderId'] as String,
      senderEmail: json['senderEmail'] as String,
      receiverEmail: json['receiverEmail'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listId': listId,
      'listName': listName,
      'senderId': senderId,
      'senderEmail': senderEmail,
      'receiverEmail': receiverEmail,
      'status': status,
    };
  }

  factory Invitation.fromMap(Map<String, dynamic> map) {
    return Invitation(
      id: map['id'] as String,
      listId: map['list_id'] as String,
      listName: map['list_name'] as String,
      senderId: map['sender_id'] as String,
      senderEmail: map['sender_email'] as String,
      receiverEmail: map['receiver_email'] as String,
      status: map['status'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'list_id': listId,
      'list_name': listName,
      'sender_id': senderId,
      'sender_email': senderEmail,
      'receiver_email': receiverEmail,
      'status': status,
    };
  }
}