import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';
import 'user_event.dart';
import 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository userRepository;

  UserBloc({required this.userRepository}) : super(UserInitial()) {
    on<LoadUsers>(_onLoadUsers);
    on<LoadMoreUsers>(_onLoadMoreUsers);
    on<SearchUsers>(_onSearchUsers);
    on<LoadUserDetail>(_onLoadUserDetail);
    on<RefreshUsers>(_onRefreshUsers);
    on<ResetUsers>(_onResetUsers);
    on<AddUser>(_onAddUser);
    on<DeleteUser>(_onDeleteUser);
  }

  Future<void> _onLoadUsers(LoadUsers event, Emitter<UserState> emit) async {
    emit(UserLoading());
    try {
      final response = await userRepository.getUsers(
        page: event.page,
        limit: event.limit,
      );
      emit(UserLoaded(
        users: response.users,
        pagination: response.pagination,
      ));
    } catch (e) {
      emit(UserError(message: e.toString()));
    }
  }

  Future<void> _onLoadMoreUsers(LoadMoreUsers event, Emitter<UserState> emit) async {
    final currentState = state;
    if (currentState is UserLoaded && !currentState.isLoadingMore) {
      emit(currentState.copyWith(isLoadingMore: true));
      
      try {
        // Hitung page berikutnya berdasarkan pagination saat ini
        final nextPage = currentState.pagination.currentPage + 1;
        
        final response = await userRepository.getUsers(
          search: currentState.currentSearch,
          page: nextPage,
          limit: 10, // Gunakan limit default
        );
        
        final updatedUsers = List<User>.from(currentState.users)
          ..addAll(response.users);
        
        emit(UserLoaded(
          users: updatedUsers,
          pagination: response.pagination,
          currentSearch: currentState.currentSearch,
          isLoadingMore: false,
        ));
      } catch (e) {
        emit(currentState.copyWith(isLoadingMore: false));
        emit(UserError(message: e.toString()));
      }
    }
  }

  Future<void> _onSearchUsers(SearchUsers event, Emitter<UserState> emit) async {
    emit(UserLoading());
    try {
      final response = await userRepository.getUsers(
        search: event.query,
        page: 1,
        limit: 10,
      );
      
      emit(UserLoaded(
        users: response.users,
        pagination: response.pagination,
        currentSearch: event.query,
      ));
    } catch (e) {
      emit(UserError(message: e.toString()));
    }
  }

  Future<void> _onLoadUserDetail(LoadUserDetail event, Emitter<UserState> emit) async {
    emit(UserLoading());
    try {
      final user = await userRepository.getUserById(event.userId);
      emit(UserDetailLoaded(user: user));
    } catch (e) {
      emit(UserError(message: e.toString()));
    }
  }

  Future<void> _onRefreshUsers(RefreshUsers event, Emitter<UserState> emit) async {
    final currentState = state;
    String? currentSearch;
    
    if (currentState is UserLoaded) {
      currentSearch = currentState.currentSearch;
    }
    
    try {
      final response = await userRepository.getUsers(
        search: currentSearch,
        page: 1,
        limit: 10,
      );
      
      emit(UserLoaded(
        users: response.users,
        pagination: response.pagination,
        currentSearch: currentSearch,
      ));
    } catch (e) {
      emit(UserError(message: e.toString()));
    }
  }

  Future<void> _onResetUsers(ResetUsers event, Emitter<UserState> emit) async {
    emit(UserInitial());
  }

  Future<void> _onAddUser(AddUser event, Emitter<UserState> emit) async {
    emit(UserLoading());
    try {
      // Create User object for the repository
      final newUser = User(
        id: 0, // ID akan di-generate oleh backend
        name: event.name,
        email: event.email,
        phone: event.phone,
        address: event.address,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await userRepository.createUser(newUser);
      
      // Refresh the user list after adding
      final currentState = state;
      final searchQuery = currentState is UserLoaded ? currentState.currentSearch : '';
      
      final response = await userRepository.getUsers(
        search: searchQuery,
        page: 1,
        limit: 10,
      );
      
      emit(UserLoaded(
        users: response.users,
        pagination: response.pagination,
        currentSearch: searchQuery,
      ));
    } catch (e) {
      emit(UserError(message: e.toString()));
    }
  }

  Future<void> _onDeleteUser(DeleteUser event, Emitter<UserState> emit) async {
    try {
      await userRepository.deleteUser(event.id);
      
      // Refresh the user list after deleting
      final currentState = state;
      final searchQuery = currentState is UserLoaded ? currentState.currentSearch : '';
      
      final response = await userRepository.getUsers(
        search: searchQuery,
        page: 1,
        limit: 10,
      );
      
      emit(UserLoaded(
        users: response.users,
        pagination: response.pagination,
        currentSearch: searchQuery,
      ));
    } catch (e) {
      emit(UserError(message: e.toString()));
    }
  }
}