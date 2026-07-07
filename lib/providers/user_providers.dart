import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart'; 
import '../repositories/user_repository.dart';

final userProfileProvider = StreamProvider.family<UserModel?, String>((ref, userId) {
  return ref.watch(userRepositoryProvider).getUserProfileStream(userId);
});