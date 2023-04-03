import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:xdag/common/color.dart';
import 'package:xdag/common/helper.dart';

class NavHeader extends StatelessWidget {
  final String title;
  final bool isColseIcon;
  final Widget? rightWidget;
  const NavHeader({super.key, required this.title, this.isColseIcon = false, this.rightWidget});

  @override
  Widget build(BuildContext context) {
    var topPadding = ScreenHelper.topPadding;
    return Container(
      color: DarkColors.bgColor,
      padding: EdgeInsets.only(top: topPadding),
      height: 50 + topPadding,
      child: Row(
        children: [
          const SizedBox(width: 15),
          SizedBox(
            width: 40,
            height: 40,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              color: DarkColors.blockColor,
              borderRadius: BorderRadius.circular(20),
              onPressed: () => Navigator.of(context).pop(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: isColseIcon ? 0 : 5),
                  Icon(isColseIcon ? Icons.close : Icons.arrow_back_ios, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
          Expanded(
              child: Center(
            child: Text(title,
                style: const TextStyle(
                  decoration: TextDecoration.none,
                  fontSize: 20,
                  fontFamily: 'RobotoMono',
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                )),
          )),
          if (rightWidget != null) rightWidget! else const SizedBox(width: 55)
        ],
      ),
    );
  }
}