import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AssetsHelper {
  static Image getImageAsset(
    String imageName, {
    double? width,
    double? height,
    Color? iconColor,
    BoxFit? fit,
  }) {
    return Image.asset(
      'assets/images/$imageName',
      width: width,
      height: height,
      color: iconColor,
      fit: fit,
    );
  }

  /* static Widget getImageFile({
    required dynamic imageName,
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    return Image.file(imageName, width: width, height: height, fit: fit);
  } */

  static Image getImageNetwork(
    String imageName, {
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    return Image.network(imageName, width: width, height: height, fit: fit);
  }

  static String getSVGString(String iconsName) {
    return 'assets/icons/$iconsName';
  }

  static String getImageString(String imageName) {
    return 'assets/images/$imageName';
  }

  static SvgPicture getSVGIcon(
    String iconsName, {
    double? width,
    double? height,
    Color? color,
    BoxFit? fit,
  }) {
    return SvgPicture.asset(
      'assets/icons/$iconsName',
      width: width,
      height: height,
      colorFilter: color != null
          ? ColorFilter.mode(color, BlendMode.srcIn)
          : null,
      fit: fit ?? BoxFit.contain,
    );
  }
}
