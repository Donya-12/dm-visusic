// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

/// One scene-wide post-processing effect.
final class PostEffect {
  /// Creates a post effect.
  const PostEffect({required this.id, required this.intensity});

  /// Known effect identifiers: bloom, vignette, grain, shake.
  final String id;

  /// Strength in 0..1.
  final double intensity;

  /// Serializes the effect.
  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'intensity': intensity,
  };

  /// Parses an effect.
  factory PostEffect.fromJson(Map<String, Object?> json) => PostEffect(
    id: json['id'] as String? ?? 'vignette',
    intensity: (json['intensity'] as num? ?? 0).toDouble().clamp(0, 1),
  );
}
