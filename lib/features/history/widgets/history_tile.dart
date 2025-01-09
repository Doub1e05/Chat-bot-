import 'package:flutter/material.dart';

class historyTitle extends StatelessWidget {

  const historyTitle({
    Key? key,
    required this.historyName,
  }) : super(key: key);

  final String historyName ;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(
          historyName,
          style: theme.textTheme.bodyMedium
      ),
      subtitle: Text(
          'Да да'
      ),
    );
  }
}