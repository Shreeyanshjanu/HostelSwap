// Skeleton loading
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingShimmer extends StatelessWidget {
  const LoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 20,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 16,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              Container(
                width: 100,
                height: 16,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 16,
                color: Colors.white,
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                height: 40,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}