import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(LoginBlocInitial()) {
    on<SubmitButtonFocusedEvent>(
      (event, emit) => emit(
        SubmitButtonFocused(
          completeNumber: event.completeNumber,
          botToken: event.botToken,
          code: event.code,
        ),
      ),
    );
    on<SubmitButtonNotFocusedEvent>(
      (event, emit) => emit(SubmitButtonNotFocused()),
    );
  }
  // @override
  // void onEvent(LoginEvent event) {
  //   super.onEvent(event);
  //   debugPrint(event.runtimeType.toString());
  // }
}

// ignore: must_be_immutable
final class SubmitButtonFocusedEvent extends LoginEvent {
  String completeNumber;
  String botToken;
  String code;
  SubmitButtonFocusedEvent(
      {this.completeNumber = '', this.botToken = '', this.code = ''})
      : assert(
            completeNumber.isNotEmpty ^ botToken.isNotEmpty ^ code.isNotEmpty);
  @override
  List<Object> get props => [completeNumber, botToken, code];
}

// ignore: must_be_immutable
final class SubmitButtonFocused extends LoginState {
  String completeNumber;
  String botToken;
  String code;

  SubmitButtonFocused(
      {this.completeNumber = '', this.botToken = '', this.code = ''})
      : assert(
            completeNumber.isNotEmpty ^ botToken.isNotEmpty ^ code.isNotEmpty);

  @override
  List<Object> get props => [completeNumber, botToken, code];
}

final class SubmitButtonNotFocusedEvent extends LoginEvent {}

final class SubmitButtonNotFocused extends LoginState {}
