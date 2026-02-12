import 'package:flutter/material.dart';

class SafeAssetImage extends StatelessWidget {
  final String assetName;
  final BoxFit? fit;
  final AlignmentGeometry alignment;
  final double? width;
  final double? height;

  const SafeAssetImage(
    this.assetName, {
    Key? key,
    this.fit,
    this.alignment = Alignment.center,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetName,
      fit: fit,
      alignment: alignment,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          ),
        );
      },
    );
  }
}
