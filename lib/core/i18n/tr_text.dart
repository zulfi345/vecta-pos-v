import 'package:flutter/material.dart' as m;
import 'package:flutter/material.dart' hide Text;
import 'app_lang.dart';
/// Drop-in pengganti Text bawaan Flutter: otomatis menerjemahkan teks
/// sesuai bahasa yang dipilih (Indonesia / English).
class Text extends StatelessWidget {
const Text(
this.data, {
super.key,
this.style,
this.strutStyle,
this.textAlign,
this.textDirection,
this.locale,
this.softWrap,
this.overflow,
this.textScaler,
this.maxLines,
this.semanticsLabel,
this.textWidthBasis,
this.textHeightBehavior,
});
final String data;
final TextStyle? style;
final StrutStyle? strutStyle;
final TextAlign? textAlign;
final TextDirection? textDirection;
final Locale? locale;
final bool? softWrap;
final TextOverflow? overflow;
final TextScaler? textScaler;
final int? maxLines;
final String? semanticsLabel;
final TextWidthBasis? textWidthBasis;
final TextHeightBehavior? textHeightBehavior;
@override
Widget build(BuildContext context) {
return ValueListenableBuilder<String>(
valueListenable: AppLang.notifier,
builder: (context, lang, _) {
return m.Text(
tr(data),
style: style,
strutStyle: strutStyle,
textAlign: textAlign,
textDirection: textDirection,
locale: locale,
softWrap: softWrap,
overflow: overflow,
textScaler: textScaler,
maxLines: maxLines,
semanticsLabel: semanticsLabel,
textWidthBasis: textWidthBasis,
textHeightBehavior: textHeightBehavior,
);
},
);
}
}
