import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tdffi/client.dart';

import '../bloc/auth_bloc.dart';

class TdlibInitFailedPage extends StatefulWidget {
  const TdlibInitFailedPage({super.key, required this.error});
  final AuthStateTdlibInitilizedFailed error;
  static String path = '/error_tdlib';

  @override
  State<TdlibInitFailedPage> createState() => _TdlibInitFailedPageState();
}

class _TdlibInitFailedPageState extends State<TdlibInitFailedPage> {
  late AuthStateTdlibInitilizedFailed error = widget.error;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Failed to Initilize Td: retrying: ${error.tries} / ${AuthStateTdlibInitilizedFailed.MAX_TRIES}',
            ),
          ),
          body: const LinearProgressIndicator(),
        );
      },
      listener: (BuildContext context, AuthState state) {
        if (state is AuthStateTdlibInitilizedFailed) {
          error = state;
          if (state.tries == 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Failed to Initilize Client: Exit"),
                action: SnackBarAction(
                  label: 'Exit',
                  onPressed: () {
                    context
                        .read<TdlibEventController>()
                        .destroy()
                        .then((value) => exit(0));
                  },
                ),
                behavior: SnackBarBehavior.fixed,
              ),
            );
          }
        } else {
          state.doRoute(context);
        }
      },
    );
  }
}
