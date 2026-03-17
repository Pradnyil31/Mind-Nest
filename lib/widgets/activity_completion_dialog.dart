import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActivityCompletionDialog<T> extends StatefulWidget {
  final Future<T> Function() onComplete;
  final String savingText;
  final String doneText;

  const ActivityCompletionDialog({
    Key? key,
    required this.onComplete,
    this.savingText = 'Saving progress...',
    this.doneText = 'Done!',
  }) : super(key: key);

  static Future<T?> show<T>(
    BuildContext context, {
    required Future<T> Function() onComplete,
    String savingText = 'Saving progress...',
    String doneText = 'Done!',
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ActivityCompletionDialog<T>(
          onComplete: onComplete,
          savingText: savingText,
          doneText: doneText,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<ActivityCompletionDialog<T>> createState() =>
      _ActivityCompletionDialogState<T>();
}

class _ActivityCompletionDialogState<T>
    extends State<ActivityCompletionDialog<T>> with SingleTickerProviderStateMixin {
  bool _isSaving = true;
  late AnimationController _doneAnimationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _doneAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _scaleAnimation = CurvedAnimation(
        parent: _doneAnimationController, curve: Curves.elasticOut);

    _executeAndComplete();
  }

  @override
  void dispose() {
    _doneAnimationController.dispose();
    super.dispose();
  }

  Future<void> _executeAndComplete() async {
    try {
      final result = await widget.onComplete();

      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        _doneAnimationController.forward();
      }

      // Hold the successful "Done" state for a moment so the user can see it
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        Navigator.pop(context, result);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isSaving)
              const SizedBox(
                height: 60,
                width: 60,
                child: CircularProgressIndicator(
                  color: Color(0xFF6C63FF),
                  strokeWidth: 4,
                ),
              )
            else
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  height: 60,
                  width: 60,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Text(
              _isSaving ? widget.savingText : widget.doneText,
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D2D2D),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
