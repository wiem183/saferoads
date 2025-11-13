import 'package:flutter/material.dart';

class BlogCommentForm extends StatefulWidget {
  final Future<void> Function(String) onSubmit;
  final bool isSubmitting;

  const BlogCommentForm({
    super.key,
    required this.onSubmit,
    this.isSubmitting = false,
  });

  @override
  State<BlogCommentForm> createState() => _BlogCommentFormState();
}

class _BlogCommentFormState extends State<BlogCommentForm> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() {
        _errorText = 'Le commentaire ne peut pas être vide';
      });
      return;
    }

    setState(() {
      _errorText = null;
    });

    await widget.onSubmit(value);
    if (mounted) {
      _controller.clear();
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          minLines: 1,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Écrire un commentaire...',
            errorText: _errorText,
            suffixIcon: IconButton(
              icon: widget.isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              onPressed: widget.isSubmitting ? null : _handleSubmit,
            ),
          ),
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _handleSubmit(),
        ),
        if (_errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _errorText!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

