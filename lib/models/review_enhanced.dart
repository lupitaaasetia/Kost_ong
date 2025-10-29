// models/review_enhanced.dart
import 'dart:io';

// Rating categories
class RatingCategories {
  final double cleanliness; // Kebersihan
  final double security; // Keamanan
  final double facilities; // Fasilitas
  final double ownerResponsiveness; // Pemilik responsif
  final double valueForMoney; // Harga sesuai

  RatingCategories({
    required this.cleanliness,
    required this.security,
    required this.facilities,
    required this.ownerResponsiveness,
    required this.valueForMoney,
  });

  // Get overall average
  double get overall {
    return (cleanliness +
            security +
            facilities +
            ownerResponsiveness +
            valueForMoney) /
        5;
  }

  Map<String, dynamic> toJson() {
    return {
      'cleanliness': cleanliness,
      'security': security,
      'facilities': facilities,
      'ownerResponsiveness': ownerResponsiveness,
      'valueForMoney': valueForMoney,
    };
  }

  factory RatingCategories.fromJson(Map<String, dynamic> json) {
    return RatingCategories(
      cleanliness: json['cleanliness'].toDouble(),
      security: json['security'].toDouble(),
      facilities: json['facilities'].toDouble(),
      ownerResponsiveness: json['ownerResponsiveness'].toDouble(),
      valueForMoney: json['valueForMoney'].toDouble(),
    );
  }
}

// Owner response to review
class OwnerResponse {
  final String response;
  final DateTime timestamp;
  final String ownerName;

  OwnerResponse({
    required this.response,
    required this.timestamp,
    required this.ownerName,
  });

  Map<String, dynamic> toJson() {
    return {
      'response': response,
      'timestamp': timestamp.toIso8601String(),
      'ownerName': ownerName,
    };
  }

  factory OwnerResponse.fromJson(Map<String, dynamic> json) {
    return OwnerResponse(
      response: json['response'],
      timestamp: DateTime.parse(json['timestamp']),
      ownerName: json['ownerName'],
    );
  }
}

// Enhanced Review with all features
class EnhancedReview {
  final String id;
  final String kostId;
  final String userEmail;
  final String userName;
  final String? userAvatarUrl;

  // Ratings
  final RatingCategories ratings;

  // Content
  final String comment;
  final List<String> photoUrls;
  final List<String> pros;
  final List<String> cons;

  // Metadata
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isVerified; // User pernah ngekost disini
  final bool isUNESAStudent;
  final int helpfulCount;
  final List<String> helpfulByUsers; // User IDs who found it helpful

  // Owner response
  final OwnerResponse? ownerResponse;

  // Stay duration
  final String? stayDuration; // e.g., "3 bulan", "1 tahun"

  EnhancedReview({
    required this.id,
    required this.kostId,
    required this.userEmail,
    required this.userName,
    this.userAvatarUrl,
    required this.ratings,
    required this.comment,
    required this.photoUrls,
    required this.pros,
    required this.cons,
    required this.createdAt,
    this.updatedAt,
    required this.isVerified,
    required this.isUNESAStudent,
    this.helpfulCount = 0,
    required this.helpfulByUsers,
    this.ownerResponse,
    this.stayDuration,
  });

  // Check if user found this helpful
  bool isHelpfulBy(String userId) {
    return helpfulByUsers.contains(userId);
  }

  // Get formatted date
  String getFormattedDate() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} menit yang lalu';
      }
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} minggu yang lalu';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} bulan yang lalu';
    } else {
      return '${(difference.inDays / 365).floor()} tahun yang lalu';
    }
  }

  EnhancedReview copyWith({
    String? id,
    String? kostId,
    String? userEmail,
    String? userName,
    String? userAvatarUrl,
    RatingCategories? ratings,
    String? comment,
    List<String>? photoUrls,
    List<String>? pros,
    List<String>? cons,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
    bool? isUNESAStudent,
    int? helpfulCount,
    List<String>? helpfulByUsers,
    OwnerResponse? ownerResponse,
    String? stayDuration,
  }) {
    return EnhancedReview(
      id: id ?? this.id,
      kostId: kostId ?? this.kostId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      ratings: ratings ?? this.ratings,
      comment: comment ?? this.comment,
      photoUrls: photoUrls ?? this.photoUrls,
      pros: pros ?? this.pros,
      cons: cons ?? this.cons,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
      isUNESAStudent: isUNESAStudent ?? this.isUNESAStudent,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      helpfulByUsers: helpfulByUsers ?? this.helpfulByUsers,
      ownerResponse: ownerResponse ?? this.ownerResponse,
      stayDuration: stayDuration ?? this.stayDuration,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kostId': kostId,
      'userEmail': userEmail,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'ratings': ratings.toJson(),
      'comment': comment,
      'photoUrls': photoUrls,
      'pros': pros,
      'cons': cons,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isVerified': isVerified,
      'isUNESAStudent': isUNESAStudent,
      'helpfulCount': helpfulCount,
      'helpfulByUsers': helpfulByUsers,
      'ownerResponse': ownerResponse?.toJson(),
      'stayDuration': stayDuration,
    };
  }

  factory EnhancedReview.fromJson(Map<String, dynamic> json) {
    return EnhancedReview(
      id: json['id'],
      kostId: json['kostId'],
      userEmail: json['userEmail'],
      userName: json['userName'],
      userAvatarUrl: json['userAvatarUrl'],
      ratings: RatingCategories.fromJson(json['ratings']),
      comment: json['comment'],
      photoUrls: List<String>.from(json['photoUrls']),
      pros: List<String>.from(json['pros']),
      cons: List<String>.from(json['cons']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      isVerified: json['isVerified'],
      isUNESAStudent: json['isUNESAStudent'],
      helpfulCount: json['helpfulCount'] ?? 0,
      helpfulByUsers: List<String>.from(json['helpfulByUsers']),
      ownerResponse: json['ownerResponse'] != null
          ? OwnerResponse.fromJson(json['ownerResponse'])
          : null,
      stayDuration: json['stayDuration'],
    );
  }
}

// Review filter options
class ReviewFilter {
  final int? minRating;
  final bool? unesaOnly;
  final bool? withPhotos;
  final bool? verifiedOnly;
  final ReviewSortBy sortBy;

  ReviewFilter({
    this.minRating,
    this.unesaOnly,
    this.withPhotos,
    this.verifiedOnly,
    this.sortBy = ReviewSortBy.newest,
  });

  bool matches(EnhancedReview review) {
    if (minRating != null && review.ratings.overall < minRating!) {
      return false;
    }
    if (unesaOnly == true && !review.isUNESAStudent) {
      return false;
    }
    if (withPhotos == true && review.photoUrls.isEmpty) {
      return false;
    }
    if (verifiedOnly == true && !review.isVerified) {
      return false;
    }
    return true;
  }
}

enum ReviewSortBy { newest, oldest, highestRating, lowestRating, mostHelpful }

// Review statistics for a kost
class ReviewStatistics {
  final int totalReviews;
  final double averageOverall;
  final RatingCategories averageCategories;
  final Map<int, int> ratingDistribution; // star count -> number of reviews
  final int verifiedReviewsCount;
  final int unesaReviewsCount;
  final int reviewsWithPhotos;

  ReviewStatistics({
    required this.totalReviews,
    required this.averageOverall,
    required this.averageCategories,
    required this.ratingDistribution,
    required this.verifiedReviewsCount,
    required this.unesaReviewsCount,
    required this.reviewsWithPhotos,
  });

  // Get percentage for each star rating
  double getPercentageForRating(int stars) {
    if (totalReviews == 0) return 0;
    return ((ratingDistribution[stars] ?? 0) / totalReviews) * 100;
  }

  factory ReviewStatistics.fromReviews(List<EnhancedReview> reviews) {
    if (reviews.isEmpty) {
      return ReviewStatistics(
        totalReviews: 0,
        averageOverall: 0,
        averageCategories: RatingCategories(
          cleanliness: 0,
          security: 0,
          facilities: 0,
          ownerResponsiveness: 0,
          valueForMoney: 0,
        ),
        ratingDistribution: {},
        verifiedReviewsCount: 0,
        unesaReviewsCount: 0,
        reviewsWithPhotos: 0,
      );
    }

    // Calculate averages
    double totalCleanliness = 0;
    double totalSecurity = 0;
    double totalFacilities = 0;
    double totalOwnerResponsiveness = 0;
    double totalValueForMoney = 0;
    double totalOverall = 0;

    Map<int, int> distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    int verifiedCount = 0;
    int unesaCount = 0;
    int withPhotos = 0;

    for (var review in reviews) {
      totalCleanliness += review.ratings.cleanliness;
      totalSecurity += review.ratings.security;
      totalFacilities += review.ratings.facilities;
      totalOwnerResponsiveness += review.ratings.ownerResponsiveness;
      totalValueForMoney += review.ratings.valueForMoney;
      totalOverall += review.ratings.overall;

      int starRating = review.ratings.overall.round();
      distribution[starRating] = (distribution[starRating] ?? 0) + 1;

      if (review.isVerified) verifiedCount++;
      if (review.isUNESAStudent) unesaCount++;
      if (review.photoUrls.isNotEmpty) withPhotos++;
    }

    int count = reviews.length;

    return ReviewStatistics(
      totalReviews: count,
      averageOverall: totalOverall / count,
      averageCategories: RatingCategories(
        cleanliness: totalCleanliness / count,
        security: totalSecurity / count,
        facilities: totalFacilities / count,
        ownerResponsiveness: totalOwnerResponsiveness / count,
        valueForMoney: totalValueForMoney / count,
      ),
      ratingDistribution: distribution,
      verifiedReviewsCount: verifiedCount,
      unesaReviewsCount: unesaCount,
      reviewsWithPhotos: withPhotos,
    );
  }
}

// Request for creating review
class CreateReviewRequest {
  final String kostId;
  final String userEmail;
  final RatingCategories ratings;
  final String comment;
  final List<File> photos; // Max 3
  final List<String> pros;
  final List<String> cons;
  final String? stayDuration;

  CreateReviewRequest({
    required this.kostId,
    required this.userEmail,
    required this.ratings,
    required this.comment,
    required this.photos,
    required this.pros,
    required this.cons,
    this.stayDuration,
  });

  bool validate() {
    if (comment.length < 20) return false;
    if (photos.length > 3) return false;
    if (ratings.overall < 1 || ratings.overall > 5) return false;
    return true;
  }
}
