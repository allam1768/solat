import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../home_controller.dart';

class LocationCard extends GetView<HomeController> {
  const LocationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
        height: 70.h,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(
            color: colorScheme.onSurface,
            width: 1.5.w,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(15.r),
            onTap: () => controller.handleLocationTap(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Center(
                child: Obx(() {
                  if (controller.isLoadingLocation.value) {
                    return SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    );
                  }

                  final displayText = controller.provinceName.value.isNotEmpty
                      ? '${controller.cityName.value.tr}, ${controller.provinceName.value.tr}'
                      : controller.cityName.value.tr;

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 26.sp,
                        color: colorScheme.onSurface,
                      ),
                      SizedBox(width: 12.w),
                      Flexible(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: 250.w, // Batasan maksimal lebar text
                          ),
                          child: Text(
                            displayText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ));
  }
}
