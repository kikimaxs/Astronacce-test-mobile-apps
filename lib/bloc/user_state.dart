import 'package:equatable/equatable.dart';
import '../models/user.dart';

abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  final List<User> users;
  final Pagination pagination;
  final String? currentSearch;
  final bool isLoadingMore;

  const UserLoaded({
    required this.users,
    required this.pagination,
    this.currentSearch,
    this.isLoadingMore = false,
  });

  UserLoaded copyWith({
    List<User>? users,
    Pagination? pagination,
    String? currentSearch,
    bool? isLoadingMore,
  }) {
    return UserLoaded(
      users: users ?? this.users,
      pagination: pagination ?? this.pagination,
      currentSearch: currentSearch ?? this.currentSearch,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [users, pagination, currentSearch, isLoadingMore];
}

class UserDetailLoaded extends UserState {
  final User user;

  const UserDetailLoaded({required this.user});

  @override
  List<Object> get props => [user];
}

class UserError extends UserState {
  final String message;

  const UserError({required this.message});

  @override
  List<Object> get props => [message];
}