import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '/ui/widgets/shimmer_widgets/basic_container.dart';

class LyricsShimmerWidget extends StatelessWidget {
  const LyricsShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.white24,
      highlightColor: Colors.white54,
      direction: ShimmerDirection.ltr,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const BasicShimmerContainer(Size(200, 20)),
          const SizedBox(height: 15),
          const BasicShimmerContainer(Size(250, 20)),
          const SizedBox(height: 15),
          const BasicShimmerContainer(Size(180, 20)),
          const SizedBox(height: 15),
          const BasicShimmerContainer(Size(220, 20)),
          const SizedBox(height: 15),
          const BasicShimmerContainer(Size(150, 20)),
          const SizedBox(height: 15),
          const BasicShimmerContainer(Size(230, 20)),
          const SizedBox(height: 15),
          const BasicShimmerContainer(Size(200, 20)),
        ],
      ),
    );
  }
}
