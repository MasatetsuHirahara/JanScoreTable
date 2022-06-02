import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_app/src/page/gameList/view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  //debugPaintSizeEnabled = true;
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(428, 926),
      builder: (context, child) {
        return MaterialApp(
          title: 'Flutter Demo',
          theme: ThemeData(
            primarySwatch: Colors.blueGrey,
            primaryColor: Colors.white,
            brightness: Brightness.light,
            appBarTheme: AppBarTheme(
                color: Colors.black54,
                titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                )),
            scaffoldBackgroundColor: Colors.green[800],
          ),
          home: child,
        );
      },
      child: GameListPage(),
    );
  }
}
