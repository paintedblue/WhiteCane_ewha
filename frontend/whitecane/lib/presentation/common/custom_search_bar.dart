import 'package:flutter/material.dart';
import 'package:sizing/sizing.dart';
import 'package:whitecane/presentation/map/search_viewmodel.dart';

class CustomSearchBar extends StatelessWidget {
  final bool hasShadow;
  final VoidCallback? onTap;
  final bool readOnly;
  final SearchViewModel? viewModel;

  const CustomSearchBar({
    super.key,
    this.hasShadow = true,
    this.onTap,
    this.readOnly = false,
    this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    return GestureDetector(
      onTap: readOnly ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: hasShadow
              ? [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 3,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 0.72.sw,
              child: TextField(
                controller: controller,
                cursorColor: Colors.grey.shade400,
                readOnly: readOnly,
                onTap: () {
                  if (readOnly && onTap != null) onTap!();
                },
                onChanged: (value) {
                  if (!readOnly && viewModel != null) {
                    viewModel!.searchPlaces(value);
                  }
                },
                decoration: InputDecoration(
                  hintText: '장소 검색',
                  fillColor: Colors.white,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14.0,
                    horizontal: 12.0,
                  ),
                  border: hasShadow
                      ? OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6.0),
                          borderSide: BorderSide.none,
                        )
                      : null,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6.0),
                    borderSide: const BorderSide(
                      color: Color.fromRGBO(169, 169, 169, 1.0),
                      width: 0.6,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6.0),
                    borderSide: const BorderSide(
                      color: Color.fromRGBO(100, 100, 100, 1.0),
                      width: 0.8,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12.0),
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(Icons.search, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
