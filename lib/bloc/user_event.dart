import 'package:equatable/equatable.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class LoadUsers extends UserEvent {
  final String? search;
  final int page;
  final int limit;

  const LoadUsers({
    this.search,
    this.page = 1,
    this.limit = 10,
  });

  @override
  List<Object?> get props => [search, page, limit];
}

class LoadMoreUsers extends UserEvent {}

class SearchUsers extends UserEvent {
  final String query;

  const SearchUsers({required this.query});

  @override
  List<Object> get props => [query];
}

class LoadUserDetail extends UserEvent {
  final int userId;

  const LoadUserDetail({required this.userId});

  @override
  List<Object> get props => [userId];
}

class RefreshUsers extends UserEvent {}

class ResetUsers extends UserEvent {}

class AddUser extends UserEvent {
  final String name;
  final String email;
  final String? phone;
  final String? address;

  const AddUser({
    required this.name, 
    required this.email,
    this.phone,
    this.address,
  });

  @override
  List<Object?> get props => [name, email, phone, address];
}

class DeleteUser extends UserEvent {
  final int id;

  const DeleteUser({required this.id});

  @override
  List<Object> get props => [id];
}