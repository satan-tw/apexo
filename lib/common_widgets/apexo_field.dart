import 'package:flutter/material.dart';

class ApexoField extends StatelessWidget {
  final TextEditingController controller;

  final String placeHolder;

  final String? Function(String?)? validator;

  final void Function(String)? onChanged;

  const ApexoField(
      {super.key,
      required this.controller,
      this.placeHolder = '',
      this.validator,
      this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: key,
      validator: validator,
      decoration: InputDecoration(
          filled: true, hintText: placeHolder, fillColor: Colors.white),
      onChanged: onChanged,
      controller: controller,
    );
  }
}
