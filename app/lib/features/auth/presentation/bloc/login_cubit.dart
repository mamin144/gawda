import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/app_failure.dart';
import '../../domain/repositories/auth_repository.dart';

part 'login_cubit.freezed.dart';

enum LoginStatus { initial, submitting, success, failure }

/// Field-level validation codes; the UI maps them to Arabic strings.
enum LoginFieldError { required, invalidEmail }

@freezed
abstract class LoginState with _$LoginState {
  const factory LoginState({
    @Default(LoginStatus.initial) LoginStatus status,
    @Default('') String email,
    @Default('') String password,
    LoginFieldError? emailError,
    LoginFieldError? passwordError,
    AppFailure? failure,
  }) = _LoginState;
}

class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._repo) : super(const LoginState());

  final AuthRepository _repo;

  void emailChanged(String value) => emit(state.copyWith(email: value, emailError: null));

  void passwordChanged(String value) =>
      emit(state.copyWith(password: value, passwordError: null));

  Future<void> submitted() async {
    final email = state.email.trim();
    final emailError = _validateEmail(email);
    final passwordError = state.password.isEmpty ? LoginFieldError.required : null;
    if (emailError != null || passwordError != null) {
      emit(
        state.copyWith(
          email: email,
          emailError: emailError,
          passwordError: passwordError,
          failure: null,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: LoginStatus.submitting,
        email: email,
        emailError: null,
        passwordError: null,
        failure: null,
      ),
    );
    final result = await _repo.signIn(email: email, password: state.password);
    if (isClosed) {
      return;
    }
    result.match(
      (failure) => emit(state.copyWith(status: LoginStatus.failure, failure: failure)),
      (_) => emit(state.copyWith(status: LoginStatus.success)),
    );
  }

  LoginFieldError? _validateEmail(String email) {
    if (email.isEmpty) {
      return LoginFieldError.required;
    }
    final parts = email.split('@');
    if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
      return LoginFieldError.invalidEmail;
    }
    return null;
  }
}
