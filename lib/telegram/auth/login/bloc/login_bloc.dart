import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../bloc/auth_bloc.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthBloc _authBloc;

  LoginBloc(
    this._authBloc,
  ) : super(LoginBlocInitial()) {
    on<FormSubmittedEvent>((event, emit) {
      _authBloc.add(
        event.state.completeNumber.isNotEmpty
            ? AuthPhoneNumberAquiredEvent(event.state.completeNumber)
            : event.state.botToken.isNotEmpty
                ? AuthPhoneBotTokenAquiredEvent(event.state.botToken)
                : AuthCodeAquiredEvent(event.state.code),
      );
    });
    on<SubmitButtonFocusedEvent>((event, emit) {
      emit(SubmitButtonFocused.event(event));
    });
    on<SubmitButtonNotFocusedEvent>((event, emit) {
      emit(SubmitButtonNotFocused(hasError: event.hasError));
    });
  }
  // @override
  // void onEvent(LoginEvent event) {
  //   super.onEvent(event);
  //   debugPrint(event.runtimeType.toString());
  // }
}

class FormSubmittedEvent extends LoginEvent {
  final SubmitButtonFocused state;
  const FormSubmittedEvent({
    required this.state,
  });
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
  factory SubmitButtonFocused.event(SubmitButtonFocusedEvent e) {
    return SubmitButtonFocused(
      completeNumber: e.completeNumber,
      code: e.code,
      botToken: e.botToken,
    );
  }

  SubmitButtonFocused(
      {this.completeNumber = '', this.botToken = '', this.code = ''})
      : assert(
            completeNumber.isNotEmpty ^ botToken.isNotEmpty ^ code.isNotEmpty);

  @override
  List<Object> get props => [completeNumber, botToken, code];
}

final class SubmitButtonNotFocusedEvent extends LoginEvent {
  final bool hasError;

  const SubmitButtonNotFocusedEvent({this.hasError = false});
}

final class SubmitButtonNotFocused extends LoginState {
  final bool hasError;

  const SubmitButtonNotFocused({this.hasError = false});
}
