import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nested/nested.dart';

class MultiBlocAndRepositoryProvider extends MultiRepositoryProvider {
  final Widget child;
  final List<SingleChildWidget> repositories;
  final List<SingleChildWidget> blocs;
  MultiBlocAndRepositoryProvider({
    super.key,
    required this.child,
    required this.repositories,
    required this.blocs,
  }) : super(
          providers: repositories,
          child: MultiBlocProvider(providers: blocs, child: child),
        );
}
