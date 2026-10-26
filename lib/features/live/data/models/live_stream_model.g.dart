// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_stream_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LiveStreamSellerModel _$LiveStreamSellerModelFromJson(
  Map<String, dynamic> json,
) => LiveStreamSellerModel(
  id: (json['id'] as num).toInt(),
  firstName: json['firstName'] as String?,
  lastName: json['lastName'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
);

Map<String, dynamic> _$LiveStreamSellerModelToJson(
  LiveStreamSellerModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'avatarUrl': instance.avatarUrl,
};

LiveStreamModel _$LiveStreamModelFromJson(Map<String, dynamic> json) =>
    LiveStreamModel(
      id: (json['id'] as num).toInt(),
      sellerId: (json['sellerId'] as num?)?.toInt(),
      roomName: json['roomName'] as String?,
      title: json['title'] as String?,
      status: json['status'] as String?,
      startedAt: json['startedAt'] as String?,
      endedAt: json['endedAt'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      viewerCount: (json['viewerCount'] as num?)?.toInt() ?? 0,
      peakViewerCount: (json['peakViewerCount'] as num?)?.toInt() ?? 0,
      totalMessages: (json['totalMessages'] as num?)?.toInt() ?? 0,
      pinnedModelId: (json['pinnedModelId'] as num?)?.toInt(),
      coverUrl: json['coverUrl'] as String?,
      seller: json['seller'] == null
          ? null
          : LiveStreamSellerModel.fromJson(
              json['seller'] as Map<String, dynamic>,
            ),
      pinnedModel: json['pinnedModel'] == null
          ? null
          : LiveProductCardModel.fromJson(
              json['pinnedModel'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$LiveStreamModelToJson(LiveStreamModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sellerId': instance.sellerId,
      'roomName': instance.roomName,
      'title': instance.title,
      'status': instance.status,
      'startedAt': instance.startedAt,
      'endedAt': instance.endedAt,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'viewerCount': instance.viewerCount,
      'peakViewerCount': instance.peakViewerCount,
      'totalMessages': instance.totalMessages,
      'pinnedModelId': instance.pinnedModelId,
      'coverUrl': instance.coverUrl,
      'seller': instance.seller?.toJson(),
      'pinnedModel': instance.pinnedModel?.toJson(),
    };
