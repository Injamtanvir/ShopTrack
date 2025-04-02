// import 'package:flutter/material.dart';
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         // This is the theme of your application.
//         //
//         // TRY THIS: Try running your application with "flutter run". You'll see
//         // the application has a purple toolbar. Then, without quitting the app,
//         // try changing the seedColor in the colorScheme below to Colors.green
//         // and then invoke "hot reload" (save your changes or press the "hot
//         // reload" button in a Flutter-supported IDE, or press "r" if you used
//         // the command line to start the app).
//         //
//         // Notice that the counter didn't reset back to zero; the application
//         // state is not lost during the reload. To reset the state, use hot
//         // restart instead.
//         //
//         // This works for code too, not just values: Most code changes can be
//         // tested with just a hot reload.
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//       ),
//       home: const MyHomePage(title: 'Flutter Demo Home Page'),
//     );
//   }
// }
//
// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});
//
//   // This widget is the home page of your application. It is stateful, meaning
//   // that it has a State object (defined below) that contains fields that affect
//   // how it looks.
//
//   // This class is the configuration for the state. It holds the values (in this
//   // case the title) provided by the parent (in this case the App widget) and
//   // used by the build method of the State. Fields in a Widget subclass are
//   // always marked "final".
//
//   final String title;
//
//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }
//
// class _MyHomePageState extends State<MyHomePage> {
//   int _counter = 0;
//
//   void _incrementCounter() {
//     setState(() {
//       // This call to setState tells the Flutter framework that something has
//       // changed in this State, which causes it to rerun the build method below
//       // so that the display can reflect the updated values. If we changed
//       // _counter without calling setState(), then the build method would not be
//       // called again, and so nothing would appear to happen.
//       _counter++;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // This method is rerun every time setState is called, for instance as done
//     // by the _incrementCounter method above.
//     //
//     // The Flutter framework has been optimized to make rerunning build methods
//     // fast, so that you can just rebuild anything that needs updating rather
//     // than having to individually change instances of widgets.
//     return Scaffold(
//       appBar: AppBar(
//         // TRY THIS: Try changing the color here to a specific color (to
//         // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
//         // change color while the other colors stay the same.
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         // Here we take the value from the MyHomePage object that was created by
//         // the App.build method, and use it to set our appbar title.
//         title: Text(widget.title),
//       ),
//       body: Center(
//         // Center is a layout widget. It takes a single child and positions it
//         // in the middle of the parent.
//         child: Column(
//           // Column is also a layout widget. It takes a list of children and
//           // arranges them vertically. By default, it sizes itself to fit its
//           // children horizontally, and tries to be as tall as its parent.
//           //
//           // Column has various properties to control how it sizes itself and
//           // how it positions its children. Here we use mainAxisAlignment to
//           // center the children vertically; the main axis here is the vertical
//           // axis because Columns are vertical (the cross axis would be
//           // horizontal).
//           //
//           // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
//           // action in the IDE, or press "p" in the console), to see the
//           // wireframe for each widget.
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             const Text('You have pushed the button this many times:'),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.headlineMedium,
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _incrementCounter,
//         tooltip: 'Increment',
//         child: const Icon(Icons.add),
//       ), // This trailing comma makes auto-formatting nicer for build methods.
//     );
//   }
// }




// ======================================================================================


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
Launching lib\main.dart on V2061 (wireless) in debug mode...
Running Gradle task 'assembleDebug'...
Your project is configured with Android NDK 26.3.11579264, but the following plugin(s) depend on a different Android NDK version:
- flutter_secure_storage requires Android NDK 27.0.12077973
- path_provider_android requires Android NDK 27.0.12077973
- shared_preferences_android requires Android NDK 27.0.12077973
Fix this issue by using the highest Android NDK version (they are backward compatible).
Add the following to C:\Users\injam\OneDrive\Desktop\ShopTrack\ShopTrack\frontend\shoptrack_app\android\app\build.gradle.kts:

android {
ndkVersion = "27.0.12077973"
...
}


FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':app:cleanMergeDebugAssets'.
> java.io.IOException: Unable to delete directory 'C:\Users\injam\OneDrive\Desktop\ShopTrack\ShopTrack\frontend\shoptrack_app\build\app\intermediates\assets\debug\mergeDebugAssets'
Failed to delete some children. This might happen because a process has files open or has its working directory set in the target directory.
- C:\Users\injam\OneDrive\Desktop\ShopTrack\ShopTrack\frontend\shoptrack_app\build\app\intermediates\assets\debug\mergeDebugAssets\flutter_assets\assets\fonts
- C:\Users\injam\OneDrive\Desktop\ShopTrack\ShopTrack\frontend\shoptrack_app\build\app\intermediates\assets\debug\mergeDebugAssets\flutter_assets\assets\images
- C:\Users\injam\OneDrive\Desktop\ShopTrack\ShopTrack\frontend\shoptrack_app\build\app\intermediates\assets\debug\mergeDebugAssets\flutter_assets\assets
- C:\Users\injam\OneDrive\Desktop\ShopTrack\ShopTrack\frontend\shoptrack_app\build\app\intermediates\assets\debug\mergeDebugAssets\flutter_assets\fonts
- C:\Users\injam\OneDrive\Desktop\ShopTrack\ShopTrack\frontend\shoptrack_app\build\app\intermediates\assets\debug\mergeDebugAssets\flutter_assets\packages\cupertino_icons\assets
- C:\Users\injam\OneDrive\Desktop\ShopTrack\ShopTrack\frontend\shoptrack_app\build\app\intermediates\assets\debug\mergeDebugAssets\flutter_assets\packages\cupertino_icons
- C:\Users\injam\OneDrive\Desktop\ShopTrack\ShopTrack\frontend\shoptrack_app\build\app\intermediates\assets\debug\mergeDebugAssets\flutter_assets\packages
- C:\Users\injam\OneDrive\Desktop\ShopTrack\ShopTrack\frontend\shoptrack_app\build\app\intermediates\assets\debug\mergeDebugAssets\flutter_assets\shaders
- C:\Users\injam\OneDrive\Desktop\ShopTrack\ShopTrack\frontend\shoptrack_app\build\app\intermediates\assets\debug\mergeDebugAssets\flutter_assets

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights.
> Get more help at https://help.gradle.org.

BUILD FAILED in 21s
Error: Gradle task assembleDebug failed with exit code 1
import 'providers/auth_provider.dart';
import 'screens/admin_home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_admin_screen.dart';
import 'screens/register_sales_person_screen.dart';
import 'screens/register_screen.dart';
import 'screens/seller_home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => AuthProvider(),
      child: Consumer<AuthProvider>(
        builder: (ctx, auth, _) => MaterialApp(
          title: 'ShopTrack',
          theme: ThemeData(
            primarySwatch: Colors.indigo,
            fontFamily: 'Roboto',
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 2,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
            ),
            cardTheme: CardTheme(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // home: FutureBuilder(
          //   future: auth.initialize(),
          //   builder: (ctx, snapshot) {
          //     if (snapshot.connectionState == ConnectionState.waiting) {
          //       return const Scaffold(
          //         body: Center(child: CircularProgressIndicator()),
          //       );
          //     }
          //
          //     if (auth.isLoggedIn) {
          //       if (auth.isAdmin) {
          //         return const AdminHomeScreen();
          //       } else {
          //         return const SellerHomeScreen();
          //       }
          //     } else {
          //       return const LoginScreen();
          //     }
          //   },
          // ),
          // In your main.dart, change:
          home: FutureBuilder(
            future: auth.initialize(),
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // Use Future.microtask to avoid calling setState during build
              if (auth.isLoggedIn) {
                return auth.isAdmin ? const AdminHomeScreen() : const SellerHomeScreen();
              } else {
                return const LoginScreen();
              }
            },
          ),
          routes: {
            LoginScreen.routeName: (ctx) => const LoginScreen(),
            RegisterScreen.routeName: (ctx) => const RegisterScreen(),
            AdminHomeScreen.routeName: (ctx) => const AdminHomeScreen(),
            SellerHomeScreen.routeName: (ctx) => const SellerHomeScreen(),
            RegisterSalesPersonScreen.routeName: (ctx) => const RegisterSalesPersonScreen(),
            RegisterAdminScreen.routeName: (ctx) => const RegisterAdminScreen(),
          },
        ),
      ),
    );
  }
}





