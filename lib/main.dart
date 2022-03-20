import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:email_validator/email_validator.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
//--------------------------------------------
//................................................................
//................................................................
//................................................................
//................................................................
//................................................................
//................................................................

void OnlineAppeals() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  final prefs = await SharedPreferences.getInstance();

  bool channel = prefs.getBool('channel') ?? false;

  if (channel == false) {
    String myPhone = prefs.getString('phone') ?? 'phone';

    if (myPhone != 'phone') {
      FirebaseDatabase myRealData = FirebaseDatabase.instance;
      DatabaseReference myRealDataRef = myRealData.reference();

      DatabaseReference newUserRef =
          myRealDataRef.child('users').child(myPhone).child('donation');

      bool subNow = false;
      bool saveSubNow = false;

      await newUserRef.once().then((value) {
        if (value.value != null) {
          if (value.value == true) {
            saveSubNow = true;
          } else {
            subNow = true;
            saveSubNow = true;
          }
        } else {
          subNow = true;
          saveSubNow = true;
        }
      });

      if (subNow == true) {
        await FirebaseMessaging.instance.subscribeToTopic('donation');
      }
      if (saveSubNow == true) {
        prefs.setBool('channel', true);
      }
    } else {
      await FirebaseMessaging.instance.subscribeToTopic('donation');
      prefs.setBool('channel', true);
    }
  }

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
    }
  });
  //FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  print("Handling a background message: ${message.messageId}");
}

BuildContext myContext;

void GetNotification() async {
  // Get any messages which caused the application to open from
  // a terminated state.
  RemoteMessage initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();

  // If the message also contains a data property with a "type" of "chat",
  // navigate to a chat screen
  Navigator.pushNamed(myContext, '/MoneyOptionsScreen');

  // Also handle any interaction when the app is in the background via a
  // Stream listener
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    Navigator.pushNamed(myContext, '/MoneyOptionsScreen');
  });
}

//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
//main and routing pages of the app
//---------------------------------------------------------------------------

void main() {
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  OnlineAppeals();
  //GetNotification();
  runApp(
    MaterialApp(
      title: 'Navier Blood',
      initialRoute: '/SplashScreen',
      routes: {
        '/SplashScreen': (context) => SplashScreen(),
        '/SignUpScreen': (context) => SignUpScreen(),
        '/SMSCodeScreen': (context) => SMSCodeScreen(),
        '/DonorProfileScreen': (context) => DonorProfileScreen(),
        '/LocationScreen': (context) => LocationScreen(),
        '/BloodScreen': (context) => BloodScreen(),
        '/MainUserScreen': (context) => MainUserScreen(),
        '/GetBloodDonationScreen': (context) => GetBloodDonationScreen(),
        '/ResultsScreen': (context) => ResultsScreen(),
        '/AppealScreen': (context) => AppealScreen(),
        '/MoneyOptionsScreen': (context) => MoneyOptionsScreen(),
      },
    ),
  );
}
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
//Splash Screen

//launch data test function
bool signedIn = false;
bool userDataSaved = false;
String intialPage = '';

void launchDataTest(context) async {
  await Firebase.initializeApp();

  RemoteMessage initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();

  // If the message also contains a data property with a "type" of "chat",
  // navigate to a chat screen

  if (initialMessage?.data != null) {
    Navigator.pushReplacementNamed(context, '/MoneyOptionsScreen');

    return;
  }

  // Also handle any interaction when the app is in the background via a
  // Stream listener
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    Navigator.pushReplacementNamed(context, '/MoneyOptionsScreen');
  });

  final prefs = await SharedPreferences.getInstance();
  signedIn = prefs.getBool('signedin') ?? false;
  userDataSaved = prefs.getBool('userdata') ?? false;
  await Future.delayed(Duration(milliseconds: 400));
  if (signedIn == false && userDataSaved == false) {
    intialPage = '/SignUpScreen';
  } else if (signedIn == true && userDataSaved == false) {
    intialPage = '/DonorProfileScreen';
  } else {
    selectedName = prefs.getString('name') ?? 'name';
    selectedCity = prefs.getString('city') ?? 'city';
    selectedBlood = prefs.getString('blood') ?? 'blood';

    intialPage = '/MainUserScreen';
  }
  Navigator.pushReplacementNamed(context, intialPage);
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //GetNotification(context);
    launchDataTest(context);
    return Material(
      child: Center(
        child: Image.asset(
          'images/logoName.png',
          width: MediaQuery.of(context).size.width * 0.8,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
//First SignUpScreen screen of the app
FirebaseAuth authPassed;
String veriID;
String selectedPhoneNumber;

Future<void> sendSMSCode(context, phoneNum) async {
  double width = MediaQuery.of(context).size.width;
  try {
    await Firebase.initializeApp();
    FirebaseAuth auth = FirebaseAuth.instance;

    await auth.verifyPhoneNumber(
      phoneNumber: phoneNum,
      timeout: const Duration(seconds: 40),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await auth.signInWithCredential(credential);
        //final prefs = await SharedPreferences.getInstance();
        //prefs.setBool('signedin',true);
        //prefs.setString('phone',selectedPhoneNumber);
        //Navigator.pop(context);
        Navigator.pushNamedAndRemoveUntil(
            context, '/DonorProfileScreen', (route) => false);
        //Navigator.popUntil(context, (route) => false);
        /*if(Navigator.canPop(context))
        {
          Navigator.pop(context);
        }
        print('what the hell');
        Navigator.pushReplacementNamed(context, '/DonorProfileScreen');*/
      },
      verificationFailed: (FirebaseAuthException e) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Center(
              child: Text(
                'Failed',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.08,
                ),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: width * 0.3,
                  width: width * 0.5,
                  child: Center(
                    child: Text(
                      //'Could not verify\nphone number',
                      e.code.toString().replaceAll('-', ' '),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.06,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: width * 0.8,
                  height: width * 0.12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(width),
                    child: FlatButton(
                      height: width * 0.12,
                      color: Colors.redAccent,
                      child: Text(
                        'OK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.07,
                          fontWeight: FontWeight.bold,
                          letterSpacing: width * 0.005,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(width * 0.1),
            ),
          ),
          barrierDismissible: true,
        );
        /*if (e.code == 'invalid-phone-number') {
          print('The provided phone number is not valid.');
        }*/
      },
      codeSent: (String verificationId, int resendToken) async {
        authPassed = auth;
        veriID = verificationId;
        //Navigator.pushNamedAndRemoveUntil(context, '/SMSCodeScreen', (route) => false);
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        Navigator.pushNamed(context, '/SMSCodeScreen');
        //String smsCode = 'xxxx';
        //PhoneAuthCredential phoneAuthCredential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode);
        //await auth.signInWithCredential(phoneAuthCredential);
        //print('signed in');
        //Navigator.pushNamed(context, '/DonorProfileScreen');
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        //print('could not retrieve auto');
      },
    );
  } catch (noInt) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Center(
          child: Text(
            'Failed',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
              fontSize: width * 0.08,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: width * 0.3,
              width: width * 0.5,
              child: Center(
                child: Text(
                  //'Could not verify\n phone number',
                  noInt.toString().replaceAll('-', ' '),
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.06,
                  ),
                ),
              ),
            ),
            Container(
              width: width * 0.8,
              height: width * 0.12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(width),
                child: FlatButton(
                  height: width * 0.12,
                  color: Colors.redAccent,
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: width * 0.07,
                      fontWeight: FontWeight.bold,
                      letterSpacing: width * 0.005,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(width * 0.1),
        ),
      ),
      barrierDismissible: true,
    );
  }
}

class SignUpScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        centerTitle: true,
        title: Text(
          'Navier Blood',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: width * 0.06,
            letterSpacing: width * 0.006,
            wordSpacing: width * 0.01,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: width * 0.03,
            ),
            Center(
              child: AutoSizeText(
                'Enter mobile number with country code',
                maxLines: 1,
                maxFontSize: 50,
                minFontSize: 10,
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.05,
                ),
              ),
            ),
            Container(
              height: width * 0.03,
            ),
            Center(
              child: AutoSizeText(
                '+491605556218',
                maxLines: 1,
                maxFontSize: 50,
                minFontSize: 10,
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.07,
                ),
              ),
            ),
            Container(
              height: width * 0.03,
            ),
            Container(
              alignment: Alignment.topCenter,
              child: SignUpScreen_Form(),
            ),
            Container(
              height: width * 0.06,
            ),
            Image.asset(
              'images/logo300.png',
              width: width * 0.5,
              fit: BoxFit.cover,
            ),
          ],
        ),
      ),
    );
  }
}

void SavePhoneString() async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString('phone', selectedPhoneNumber);

  bool channel = prefs.getBool('channel') ?? false;

  if (channel == false) {
    String myPhone = selectedPhoneNumber;

    if (myPhone != 'phone') {
      await Firebase.initializeApp();

      FirebaseDatabase myRealData = FirebaseDatabase.instance;
      DatabaseReference myRealDataRef = myRealData.reference();

      DatabaseReference newUserRef =
          myRealDataRef.child('users').child(myPhone).child('donation');

      bool subNow = false;
      bool saveSubNow = false;
      bool unSubNow = false;

      await newUserRef.once().then((value) {
        if (value.value != null) {
          if (value.value == true) {
            unSubNow = true;
            saveSubNow = true;
          } else {
            subNow = true;
            saveSubNow = true;
          }
        } else {
          subNow = true;
          saveSubNow = true;
        }
      });

      if (subNow == true) {
        await FirebaseMessaging.instance.subscribeToTopic('donation');
      }
      if (saveSubNow == true) {
        prefs.setBool('channel', true);
      }
      if (unSubNow == true) {
        await FirebaseMessaging.instance.unsubscribeFromTopic('donation');
      }
    }
  }
}

class SignUpScreen_Form extends StatefulWidget {
  SignUpScreen_Form({Key key}) : super(key: key);
  @override
  _SignUpScreen_Form_State createState() => _SignUpScreen_Form_State();
}

class _SignUpScreen_Form_State extends State<SignUpScreen_Form> {
  final _SignUpScreen_Form_Key = GlobalKey<FormState>();
  final _SignUpScreen_FormField_Key = GlobalKey<FormFieldState>();
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Form(
      key: _SignUpScreen_Form_Key,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: width * 0.9,
            child: TextFormField(
              key: _SignUpScreen_FormField_Key,
              onFieldSubmitted: (value) {
                _SignUpScreen_FormField_Key.currentState.validate();
              },
              cursorColor: Colors.redAccent,
              style: TextStyle(
                fontSize: width * 0.07,
                color: Colors.black,
                letterSpacing: width * 0.006,
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.phone,
                  color: Colors.redAccent,
                ),
                //border: InputBorder.none,
                hintText: 'Enter your mobile number',
                hintStyle: TextStyle(
                  fontSize: width * 0.05,
                ),
                errorStyle: TextStyle(
                  fontSize: width * 0.06,
                ),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(width),
                  borderSide: BorderSide(color: Colors.redAccent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(width),
                  borderSide: BorderSide(color: Colors.redAccent),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(width),
                  borderSide: BorderSide(color: Colors.redAccent),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(width),
                  borderSide: BorderSide(color: Colors.redAccent),
                ),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                try {
                  int.parse(value.substring(0));
                } catch (notInt) {
                  return 'Incorrect mobile number !';
                }
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Center(
                      child: Text(
                        'Sending OTP',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.08,
                        ),
                      ),
                    ),
                    content: Container(
                      height: width * 0.5,
                      width: width * 0.5,
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.redAccent),
                        strokeWidth: width * 0.05,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(width * 0.1),
                    ),
                  ),
                  barrierDismissible: false,
                );
                selectedPhoneNumber = value.toString().replaceAll(' ', '');
                SavePhoneString();
                sendSMSCode(context, value.toString().replaceAll(' ', ''));
                return null;
              },
            ),
          ),
          Container(
            height: width * 0.1,
          ),
          Container(
            width: width * 0.8,
            height: width * 0.12,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(width),
              child: FlatButton(
                height: width * 0.12,
                color: Colors.redAccent,
                child: Text(
                  'Confirm',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: width * 0.07,
                    fontWeight: FontWeight.bold,
                    letterSpacing: width * 0.005,
                  ),
                ),
                onPressed: () {
                  _SignUpScreen_Form_Key.currentState.validate();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//-----------------------------------------------------------------
//-----------------------------------------------------------------
//-----------------------------------------------------------------
//Enter SMS Code Screen

enterCodeManual(context, smsCodePassed) async {
  double width = MediaQuery.of(context).size.width;
  //authPassed = auth;
  //veriID = verificationId;
  //Navigator.pushNamed(context, '/SMSCodeScreen');

  // PhoneAuthCredential phoneAuthCredential = PhoneAuthProvider.credential(verificationId: veriID, smsCode: smsCodePassed);
  //
  // await authPassed.signInWithCredential(phoneAuthCredential);
  // print('saved sign in value');
  // final prefs = await SharedPreferences.getInstance();
  // prefs.setBool('signedin',true);
  // prefs.setString('phone',selectedPhoneNumber);
  //
  // Navigator.pushNamedAndRemoveUntil(context, '/DonorProfileScreen', (route) => false);
  try {
    PhoneAuthCredential phoneAuthCredential = PhoneAuthProvider.credential(
        verificationId: veriID, smsCode: smsCodePassed);

    await authPassed.signInWithCredential(phoneAuthCredential);
    //final prefs = await SharedPreferences.getInstance();
    //prefs.setBool('signedin',true);
    //prefs.setString('phone',selectedPhoneNumber);

    Navigator.pushNamedAndRemoveUntil(
        context, '/DonorProfileScreen', (route) => false);
    //Navigator.pushReplacementNamed(context, '/DonorProfileScreen');
  } catch (noInt) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Center(
          child: Text(
            'Failed',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
              fontSize: width * 0.08,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: width * 0.3,
              width: width * 0.5,
              child: Center(
                child: Text(
                  //'Could not verify\n phone number',
                  noInt.toString().replaceAll('-', ' '),
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.06,
                  ),
                ),
              ),
            ),
            Container(
              width: width * 0.8,
              height: width * 0.12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(width),
                child: FlatButton(
                  height: width * 0.12,
                  color: Colors.redAccent,
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: width * 0.07,
                      fontWeight: FontWeight.bold,
                      letterSpacing: width * 0.005,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(width * 0.1),
        ),
      ),
      barrierDismissible: true,
    );
  }
}

class SMSCodeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        centerTitle: true,
        title: Text(
          'Navier Blood',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: width * 0.06,
            letterSpacing: width * 0.006,
            wordSpacing: width * 0.01,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: width * 0.1,
            ),
            Center(
              child: AutoSizeText(
                'Enter the passocde sent through SMS',
                maxLines: 1,
                maxFontSize: 50,
                minFontSize: 10,
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.05,
                ),
              ),
            ),
            Container(
              height: width * 0.1,
            ),
            Container(
              alignment: Alignment.topCenter,
              child: SMSCodeScreen_Form(),
            ),
            Container(
              height: width * 0.06,
            ),
            Image.asset(
              'images/logo300.png',
              width: width * 0.5,
              fit: BoxFit.cover,
            ),
          ],
        ),
      ),
    );
  }
}

class SMSCodeScreen_Form extends StatefulWidget {
  SMSCodeScreen_Form({Key key}) : super(key: key);
  @override
  _SMSCodeScreen_Form_State createState() => _SMSCodeScreen_Form_State();
}

class _SMSCodeScreen_Form_State extends State<SMSCodeScreen_Form> {
  final _SMSCodeScreen_Form_Key = GlobalKey<FormState>();
  final _SMSCodeScreen_FormField_Key = GlobalKey<FormFieldState>();
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Form(
      key: _SMSCodeScreen_Form_Key,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: width * 0.9,
            child: TextFormField(
              key: _SMSCodeScreen_FormField_Key,
              onFieldSubmitted: (value) {
                _SMSCodeScreen_FormField_Key.currentState.validate();
              },
              cursorColor: Colors.redAccent,
              style: TextStyle(
                fontSize: width * 0.07,
                color: Colors.black,
                letterSpacing: width * 0.006,
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.vpn_key,
                  color: Colors.redAccent,
                ),
                //border: InputBorder.none,
                hintText: 'Enter OTP Code',
                hintStyle: TextStyle(
                  fontSize: width * 0.05,
                ),
                errorStyle: TextStyle(
                  fontSize: width * 0.06,
                ),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(width),
                  borderSide: BorderSide(color: Colors.redAccent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(width),
                  borderSide: BorderSide(color: Colors.redAccent),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(width),
                  borderSide: BorderSide(color: Colors.redAccent),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(width),
                  borderSide: BorderSide(color: Colors.redAccent),
                ),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                try {
                  int.parse(value);
                } catch (notInt) {
                  return 'Incorrect Code!';
                }
                enterCodeManual(context, value);
                //Navigator.pushReplacementNamed(context, '/GetBloodDonationScreen');
                return null;
              },
            ),
          ),
          Container(
            height: width * 0.1,
          ),
          Container(
            width: width * 0.8,
            height: width * 0.12,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(width),
              child: FlatButton(
                height: width * 0.12,
                color: Colors.redAccent,
                child: Text(
                  'Verify',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: width * 0.07,
                    fontWeight: FontWeight.bold,
                    letterSpacing: width * 0.005,
                  ),
                ),
                onPressed: () {
                  _SMSCodeScreen_Form_Key.currentState.validate();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//--------------------------------------------
//First DonorProfileScreen screen of the app

bool nameEntered = false;
bool emailEntered = false;
bool countryEntered = false;
bool stateEntered = false;
bool cityEntered = false;
bool bloodEntered = false;

String locationLevel = 'Country';
String selectedCountry = 'Select Country';
String selectedState = 'Select State';
String selectedCity = 'Select City';
String selectedBlood = 'Select Blood Group';

String selectedName;
String selectedEmail;

void SaveSignedInBool() async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setBool('signedin', true);
}

final locations_Key = GlobalKey<_Profile_Form_State>();

class DonorProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    SaveSignedInBool();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        centerTitle: true,
        title: Text(
          'Navier Blood',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: width * 0.06,
            letterSpacing: width * 0.006,
            wordSpacing: width * 0.01,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: width * 0.02,
            ),
            Center(
              child: AutoSizeText(
                'Enter details below',
                maxLines: 1,
                maxFontSize: 50,
                minFontSize: 10,
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.05,
                ),
              ),
            ),
            Container(
              height: width * 0.02,
            ),
            Container(
              alignment: Alignment.topCenter,
              child: Profile_Form(),
            ),
          ],
        ),
      ),
    );
  }
}

void ChangeLocationName(String LocationNameSet) {
  if (locationLevel == 'Country') {
    countryEntered = true;
    locations_Key.currentState.setState(() {
      selectedCountry = LocationNameSet;
    });
  } else if (locationLevel == 'State') {
    if (LocationNameSet.length >= 2) {
      stateEntered = true;
    }
    locations_Key.currentState.setState(() {
      selectedState = LocationNameSet;
    });
  } else if (locationLevel == 'City') {
    if (LocationNameSet.length >= 2) {
      cityEntered = true;
    }
    locations_Key.currentState.setState(() {
      selectedCity = LocationNameSet;
    });
  } else {
    bloodEntered = true;
    locations_Key.currentState.setState(() {
      selectedBlood = LocationNameSet;
    });
  }
}

class Profile_Form extends StatefulWidget {
  Profile_Form({Key key}) : super(key: key);
  @override
  Key get key => locations_Key;
  @override
  _Profile_Form_State createState() => _Profile_Form_State();
}

class _Profile_Form_State extends State<Profile_Form> {
  final _Profile_Name_Key = GlobalKey<FormFieldState>();
  final _Profile_email_Key = GlobalKey<FormFieldState>();
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Container(
      child: Column(
        children: [
          Container(
            width: width * 0.9,
            child: TextFormField(
              key: _Profile_Name_Key,
              cursorColor: Colors.redAccent,
              style: TextStyle(
                fontSize: width * 0.05,
                color: Colors.black,
                letterSpacing: width * 0.004,
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.person,
                  color: Colors.redAccent,
                ),
                //border: InputBorder.none,
                hintText: 'Enter Full Name',
                hintStyle: TextStyle(
                  fontSize: width * 0.04,
                ),
                errorStyle: TextStyle(
                  fontSize: width * 0.04,
                ),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(width),
                  borderSide: BorderSide(color: Colors.redAccent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(width),
                  borderSide: BorderSide(color: Colors.redAccent),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(width),
                  borderSide: BorderSide(color: Colors.redAccent),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(width),
                  borderSide: BorderSide(color: Colors.redAccent),
                ),
              ),
              keyboardType: TextInputType.name,
              validator: (value) {
                if (value.length <= 2) {
                  nameEntered = false;
                  return 'Please enter complete name !';
                }
                nameEntered = true;
                selectedName = value;
                return null;
              },
            ),
          ),
          Container(
            height: width * 0.02,
          ),
          Container(
            width: width * 0.9,
            child: TextFormField(
              key: _Profile_email_Key,
              cursorColor: Colors.redAccent,
              style: TextStyle(
                fontSize: width * 0.05,
                color: Colors.black,
                letterSpacing: width * 0.004,
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.email,
                  color: Colors.redAccent,
                ),
                //border: InputBorder.none,
                hintText: 'Enter Email Address',
                hintStyle: TextStyle(
                  fontSize: width * 0.04,
                ),
                errorStyle: TextStyle(
                  fontSize: width * 0.04,
                ),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(width),
                  borderSide: BorderSide(color: Colors.redAccent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(width),
                  borderSide: BorderSide(color: Colors.redAccent),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(width),
                  borderSide: BorderSide(color: Colors.redAccent),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(width),
                  borderSide: BorderSide(color: Colors.redAccent),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (!EmailValidator.validate(value)) {
                  emailEntered = false;
                  return 'Incorrect email address';
                }

                emailEntered = true;
                selectedEmail = value;
                return null;
              },
            ),
          ),
          Container(
            height: width * 0.02,
          ),
          GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              locationLevel = 'Country';
              customLocation = '';
              suggestions.clear();
              Navigator.pushNamed(context, '/LocationScreen');
            },
            child: Container(
              width: width * 0.9,
              height: width * 0.15,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(width),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    width: width * 0.05,
                  ),
                  Expanded(
                    child: AutoSizeText(
                      selectedCountry,
                      maxLines: 1,
                      maxFontSize: 50,
                      minFontSize: 10,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.05,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down),
                  Container(
                    width: width * 0.05,
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: width * 0.02,
          ),
          GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              if (countryEntered == true) {
                locationLevel = 'State';
                customLocation = '';
                suggestions.clear();
                Navigator.pushNamed(context, '/LocationScreen');
              } else {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Center(
                      child: Text(
                        'Alert',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.08,
                        ),
                      ),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: width * 0.3,
                          width: width * 0.5,
                          child: Center(
                            child: Text(
                              'Please select\ncountry first',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: width * 0.06,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: width * 0.8,
                          height: width * 0.12,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(width),
                            child: FlatButton(
                              height: width * 0.12,
                              color: Colors.redAccent,
                              child: Text(
                                'OK',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: width * 0.07,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: width * 0.005,
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(width * 0.1),
                    ),
                  ),
                  barrierDismissible: true,
                );
              }
            },
            child: Container(
              width: width * 0.9,
              height: width * 0.15,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(width),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    width: width * 0.05,
                  ),
                  Expanded(
                    child: AutoSizeText(
                      selectedState,
                      maxLines: 1,
                      maxFontSize: 50,
                      minFontSize: 10,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.05,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down),
                  Container(
                    width: width * 0.05,
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: width * 0.02,
          ),
          GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              if (stateEntered == true) {
                locationLevel = 'City';
                customLocation = '';
                suggestions.clear();
                Navigator.pushNamed(context, '/LocationScreen');
              } else {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Center(
                      child: Text(
                        'Alert',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.08,
                        ),
                      ),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: width * 0.3,
                          width: width * 0.5,
                          child: Center(
                            child: Text(
                              'Please select\nstate first',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: width * 0.06,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: width * 0.8,
                          height: width * 0.12,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(width),
                            child: FlatButton(
                              height: width * 0.12,
                              color: Colors.redAccent,
                              child: Text(
                                'OK',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: width * 0.07,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: width * 0.005,
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(width * 0.1),
                    ),
                  ),
                  barrierDismissible: true,
                );
              }
            },
            child: Container(
              width: width * 0.9,
              height: width * 0.15,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(width),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    width: width * 0.05,
                  ),
                  Expanded(
                    child: AutoSizeText(
                      selectedCity,
                      maxLines: 1,
                      maxFontSize: 50,
                      minFontSize: 10,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.05,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down),
                  Container(
                    width: width * 0.05,
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: width * 0.02,
          ),
          GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              locationLevel = 'Blood Group';
              suggestions.clear();
              Navigator.pushNamed(context, '/BloodScreen');
            },
            child: Container(
              width: width * 0.9,
              height: width * 0.15,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(width),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    width: width * 0.05,
                  ),
                  Expanded(
                    child: AutoSizeText(
                      selectedBlood,
                      maxLines: 1,
                      maxFontSize: 50,
                      minFontSize: 10,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.05,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down),
                  Container(
                    width: width * 0.05,
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: width * 0.08,
          ),
          Container(
            width: width * 0.8,
            height: width * 0.12,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(width),
              child: FlatButton(
                height: width * 0.12,
                color: Colors.redAccent,
                child: Text(
                  'Submit',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: width * 0.07,
                    fontWeight: FontWeight.bold,
                    letterSpacing: width * 0.005,
                  ),
                ),
                onPressed: () {
                  _Profile_Name_Key.currentState.validate();
                  _Profile_email_Key.currentState.validate();
                  if (nameEntered == true &&
                      emailEntered == true &&
                      countryEntered == true &&
                      stateEntered == true &&
                      cityEntered == true &&
                      bloodEntered == true) {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Center(
                          child: Text(
                            'Loading',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: width * 0.08,
                            ),
                          ),
                        ),
                        content: Container(
                          height: width * 0.5,
                          width: width * 0.5,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.redAccent),
                            strokeWidth: width * 0.05,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(width * 0.1),
                        ),
                      ),
                      barrierDismissible: false,
                    );
                    SaveAllUserData(context);
                  } else {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Center(
                          child: Text(
                            'Failed',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: width * 0.08,
                            ),
                          ),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              height: width * 0.3,
                              width: width * 0.5,
                              child: Center(
                                child: Text(
                                  'Please fill\ncomplete details',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: width * 0.06,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: width * 0.8,
                              height: width * 0.12,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(width),
                                child: FlatButton(
                                  height: width * 0.12,
                                  color: Colors.redAccent,
                                  child: Text(
                                    'OK',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: width * 0.07,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: width * 0.005,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(width * 0.1),
                        ),
                      ),
                      barrierDismissible: true,
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//--------------------------------------------
//--------------------------------------------
//--------------------------------------------
//LocationScreen screen of the app

List<String> suggestions = new List<String>();

class LocationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        centerTitle: true,
        title: Text(
          'Select ' + locationLevel,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: width * 0.06,
            letterSpacing: width * 0.006,
            wordSpacing: width * 0.01,
          ),
        ),
      ),
      body: LocationScreenLists(),
    );
  }
}

final LocationScreenLists_key = GlobalKey<_LocationScreenLists_State>();
String customLocation = '';
var jsonData;
var stringData;

void GetLocationLists(String queryLocal) async {
  if (locationLevel == 'State') {
    stringData = await http.read(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=' +
            queryLocal +
            '&types=(regions)&components=country:' +
            dataBaseCountries[selectedCountry] +
            '&key=sampleKey');
  } else {
    stringData = await http.read(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=' +
            queryLocal +
            '&types=(cities)&components=country:' +
            dataBaseCountries[selectedCountry] +
            '&key=sampleKey');
  }

  jsonData = json.decode(stringData);
  if (jsonData['status'] == 'OK') {
    LocationScreenLists_key.currentState.setState(() {
      suggestions.clear();
      for (var predictions in jsonData['predictions']) {
        suggestions.add(predictions['structured_formatting']['main_text']);
      }
    });
  } else {
    //(jsonData['status']);
  }
}

void GetCountriesList(String searchQuery) async {
  suggestions.clear();
  String loewrQuery = searchQuery.toLowerCase();
  if (loewrQuery == 'us' || loewrQuery == 'usa') {
    LocationScreenLists_key.currentState.setState(() {
      suggestions.add('United States');
    });
  } else if (loewrQuery == 'uk') {
    LocationScreenLists_key.currentState.setState(() {
      suggestions.add('United Kingdom');
    });
  }
  for (var indCount in dataBaseCountries.keys) {
    if (indCount.toString().toLowerCase().contains(loewrQuery)) {
      LocationScreenLists_key.currentState.setState(() {
        suggestions.add(indCount.toString());
      });
    }
  }
}

void TextXhanged(String changedValue) {
  if (locationLevel == 'Country') {
    GetCountriesList(changedValue);
  } else {
    GetLocationLists(changedValue);
  }
  LocationScreenLists_key.currentState.setState(() {
    customLocation = changedValue;
  });
}

class LocationScreenLists extends StatefulWidget {
  LocationScreenLists({Key key}) : super(key: key);
  @override
  Key get key => LocationScreenLists_key;
  @override
  _LocationScreenLists_State createState() => _LocationScreenLists_State();
}

class _LocationScreenLists_State extends State<LocationScreenLists> {
  final _Location_Key = GlobalKey<FormFieldState>();
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          TextFormField(
            autofocus: true,
            key: _Location_Key,
            style: TextStyle(
              fontSize: width * 0.07,
              letterSpacing: 1,
              wordSpacing: 4,
              fontWeight: FontWeight.bold,
            ),
            cursorColor: Colors.blue,
            decoration: InputDecoration(
              hintText: 'Enter full ' + locationLevel + ' name',
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (changedValue) {
              TextXhanged(changedValue);
            },
          ),
          Container(
            height: width * 0.02,
          ),
          locationLevel == 'Country'
              ? Container(
                  height: 10,
                  color: Colors.white,
                )
              : GestureDetector(
                  onTap: () {
                    ChangeLocationName(_Location_Key.currentState.value);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: width * 0.92,
                    height: width * 0.13,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(width),
                    ),
                    child: Center(
                      child: AutoSizeText(
                        customLocation,
                        maxLines: 1,
                        maxFontSize: 50,
                        minFontSize: 10,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.05,
                        ),
                      ),
                    ),
                  ),
                ),
          Container(
            height: width * 0.02,
          ),
          Container(
            height: 5,
            margin: EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          Container(
            height: width * 0.02,
          ),
          Expanded(
            child: Container(
              child: buildFixedSuggestions(context),
            ),
          ),
        ],
      ),
    );
  }
}

Widget buildFixedSuggestions(context) {
  double width = MediaQuery.of(context).size.width;
  return ListView.builder(
    itemCount: suggestions.length,
    itemBuilder: (context, index) {
      return GestureDetector(
        onTap: () {
          ChangeLocationName('${suggestions[index]}');
          Navigator.pop(context);
        },
        child: Container(
          height: width * 0.13,
          margin: EdgeInsets.only(
              bottom: width * 0.02, left: width * 0.04, right: width * 0.04),
          decoration: BoxDecoration(
            color: Colors.redAccent,
            borderRadius: BorderRadius.circular(width),
          ),
          child: Center(
            child: AutoSizeText(
              '${suggestions[index]}',
              textAlign: TextAlign.center,
              maxLines: 1,
              maxFontSize: 50,
              minFontSize: 10,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: width * 0.05,
              ),
            ),
          ),
        ),
      );
    },
  );
}

class BloodScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        centerTitle: true,
        title: Text(
          'Select ' + locationLevel,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: width * 0.06,
            letterSpacing: width * 0.006,
            wordSpacing: width * 0.01,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              height: width * 0.04,
            ),
            Expanded(
              child: Container(
                child: ListView(
                  children: [
                    BloodGroupName(context, 'A+'),
                    BloodGroupName(context, 'A-'),
                    BloodGroupName(context, 'B+'),
                    BloodGroupName(context, 'B-'),
                    BloodGroupName(context, 'O+'),
                    BloodGroupName(context, 'O-'),
                    BloodGroupName(context, 'AB+'),
                    BloodGroupName(context, 'AB-'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget BloodGroupName(context, String bloodName) {
  double width = MediaQuery.of(context).size.width;
  return GestureDetector(
    onTap: () {
      ChangeLocationName(bloodName);
      Navigator.pop(context);
    },
    child: Container(
      height: width * 0.13,
      margin: EdgeInsets.fromLTRB(width * 0.1, 0, width * 0.1, width * 0.02),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(width),
      ),
      child: Center(
        child: Text(
          bloodName,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: width * 0.06,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  );
}

void SaveAllUserData(context) async {
  await Firebase.initializeApp();
  FirebaseDatabase myRealData = FirebaseDatabase.instance;
  DatabaseReference myRealDataRef = myRealData.reference();

  DatabaseReference newUserRef =
      myRealDataRef.child('users').child(selectedPhoneNumber);

  await newUserRef.once().then((value) {
    if (value.value == null) {
      newUserRef.child('donation').set(false);
      newUserRef.child('payment').set(0);
    }
  });

  newUserRef.child('name').set(selectedName);
  newUserRef.child('email').set(selectedEmail);
  newUserRef.child('country').set(selectedCountry);
  newUserRef.child('state').set(selectedState);
  newUserRef.child('city').set(selectedCity);
  newUserRef.child('blood').set(selectedBlood);

  //newUserRef.child('donation').set(false);
  //newUserRef.child('payment').set(0);

  DatabaseReference newCountryRef = myRealDataRef
      .child('countries')
      .child(selectedCountry)
      .child(selectedState)
      .child(selectedCity)
      .child(selectedBlood)
      .child(selectedPhoneNumber);

  newCountryRef.child('name').set(selectedName);
  newCountryRef.child('email').set(selectedEmail);

  final prefs = await SharedPreferences.getInstance();
  prefs.setString('name', selectedName);
  prefs.setString('email', selectedEmail);
  prefs.setString('country', selectedCountry);
  prefs.setString('state', selectedState);
  prefs.setString('city', selectedCity);
  prefs.setString('blood', selectedBlood);

  prefs.setBool('userdata', true);

  Navigator.pushNamedAndRemoveUntil(
      context, '/MainUserScreen', (route) => false);
  //Navigator.pushReplacementNamed(context, '/MainUserScreen');
}

//--------------------------------------------
//--------------------------------------------
//--------------------------------------------
//MainUserScreen screen of the app
class MainUserScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        centerTitle: true,
        title: Text(
          'Navier Blood',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: width * 0.06,
            letterSpacing: width * 0.006,
            wordSpacing: width * 0.01,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: width * 0.04,
            ),
            Center(
              child: Image.asset(
                'images/logo300.png',
                width: width * 0.5,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
            Container(
              height: width * 0.04,
            ),
            Center(
              child: AutoSizeText(
                selectedName,
                maxLines: 1,
                maxFontSize: 50,
                minFontSize: 10,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.07,
                ),
              ),
            ),
            Container(
              height: width * 0.04,
            ),
            Center(
              child: AutoSizeText(
                selectedCity,
                maxLines: 1,
                maxFontSize: 50,
                minFontSize: 10,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.07,
                ),
              ),
            ),
            Container(
              height: width * 0.04,
            ),
            Center(
              child: AutoSizeText(
                'Blood Group : ' + selectedBlood,
                maxLines: 1,
                maxFontSize: 50,
                minFontSize: 10,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.07,
                ),
              ),
            ),
            Container(
              height: width * 0.06,
            ),
            Container(
              width: width * 0.8,
              height: width * 0.12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(width),
                child: FlatButton(
                  height: width * 0.12,
                  color: Colors.redAccent,
                  child: Text(
                    'Get Blood Donation',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: width * 0.07,
                      fontWeight: FontWeight.bold,
                      letterSpacing: width * 0.005,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/GetBloodDonationScreen');
                  },
                ),
              ),
            ),
            Container(
              height: width * 0.06,
            ),
            Container(
              width: width * 0.8,
              height: width * 0.12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(width),
                child: FlatButton(
                  height: width * 0.12,
                  color: Colors.redAccent,
                  child: Text(
                    'Donate Blood',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: width * 0.07,
                      fontWeight: FontWeight.bold,
                      letterSpacing: width * 0.005,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/AppealScreen');
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//--------------------------------------------
//--------------------------------------------
//--------------------------------------------
//GetBloodDonation screen of the app
class GetBloodDonationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        centerTitle: true,
        title: Text(
          'Navier Blood',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: width * 0.06,
            letterSpacing: width * 0.006,
            wordSpacing: width * 0.01,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: width * 0.06,
            ),
            Text(
              'Select required blood',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: width * 0.06,
              ),
            ),
            Container(
              height: width * 0.05,
            ),
            Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      BloodButtonsFormat(context, 'A+'),
                      BloodButtonsFormat(context, 'B+'),
                      BloodButtonsFormat(context, 'O+'),
                      BloodButtonsFormat(context, 'AB+'),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      BloodButtonsFormat(context, 'A-'),
                      BloodButtonsFormat(context, 'B-'),
                      BloodButtonsFormat(context, 'O-'),
                      BloodButtonsFormat(context, 'AB-'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget BloodButtonsFormat(context, String bloodName) {
  double width = MediaQuery.of(context).size.width;
  return GestureDetector(
    onTap: () {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Center(
            child: Text(
              'Searching',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: width * 0.08,
              ),
            ),
          ),
          content: Container(
            height: width * 0.5,
            width: width * 0.5,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
              strokeWidth: width * 0.05,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(width * 0.1),
          ),
        ),
        barrierDismissible: false,
      );
      SearchForBlood(bloodName, context);
    },
    child: Container(
      margin: EdgeInsets.symmetric(vertical: width * 0.05),
      alignment: Alignment.center,
      width: width * 0.4,
      height: width * 0.15,
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(width),
      ),
      child: Text(
        bloodName,
        style: TextStyle(
          color: Colors.white,
          fontSize: width * 0.07,
          fontWeight: FontWeight.bold,
          letterSpacing: width * 0.005,
        ),
      ),
    ),
  );
}

List<String> resultNames = new List<String>();
List<String> resultPhones = new List<String>();
List<String> resultBloods = new List<String>();
List<String> resultCities = new List<String>();

String searchCountry;
String searchState;
String searchCity;
String givenBlood;
String myPhoneNum;
String searchBloodSingle;
List<String> searchBloods = new List<String>();

SearchForBlood(String bloodType, context) async {
  final prefs = await SharedPreferences.getInstance();
  searchCountry = prefs.getString('country') ?? 'country';
  searchState = prefs.getString('state') ?? 'state';
  searchCity = prefs.getString('city') ?? 'city';
  myPhoneNum = prefs.getString('phone') ?? 'phone';

  //print(searchCity);

  //searchCountry = 'Pakistan';
  //searchState = 'Punjab';
  //searchCity = 'Lahore';
  //myPhoneNum = '+923365544700';

  givenBlood = bloodType;
  searchBloods.clear();
  resultBloods.clear();
  resultPhones.clear();
  resultCities.clear();
  resultNames.clear();

  if (givenBlood == 'A+') {
    searchBloods.add('A+');
    searchBloods.add('A-');
    searchBloods.add('O+');
    searchBloods.add('O-');
  } else if (givenBlood == 'A-') {
    searchBloods.add('A-');
    searchBloods.add('O-');
  } else if (givenBlood == 'B+') {
    searchBloods.add('B+');
    searchBloods.add('B-');
    searchBloods.add('O+');
    searchBloods.add('O-');
  } else if (givenBlood == 'B-') {
    searchBloods.add('B-');
    searchBloods.add('O-');
  } else if (givenBlood == 'AB+') {
    searchBloods.add('A+');
    searchBloods.add('A-');
    searchBloods.add('B+');
    searchBloods.add('B-');
    searchBloods.add('AB+');
    searchBloods.add('AB-');
    searchBloods.add('O+');
    searchBloods.add('O-');
  } else if (givenBlood == 'AB-') {
    searchBloods.add('AB-');
    searchBloods.add('A-');
    searchBloods.add('B-');
    searchBloods.add('O-');
  } else if (givenBlood == 'O+') {
    searchBloods.add('O+');
    searchBloods.add('O-');
  } else if (givenBlood == 'O-') {
    searchBloods.add('O-');
  }

  FirebaseDatabase myData = FirebaseDatabase.instance;
  DatabaseReference mDatabase = myData.reference();

  for (searchBloodSingle in searchBloods) {
    DatabaseReference resultData = mDatabase
        .child('countries')
        .child(searchCountry)
        .child(searchState)
        .child(searchCity)
        .child(searchBloodSingle);

    await resultData.once().then((value) {
      if (value.value != null) {
        var searchedData = json.encode(value.value);
        var allresults = json.decode(searchedData);

        for (var phones in allresults.keys) {
          if (myPhoneNum == phones.toString()) {
            continue;
          }
          resultBloods.add(value.key.toString());
          resultPhones.add(phones.toString());
          resultCities.add(searchCity);
          resultNames.add(allresults[phones.toString()]['name'].toString());
        }
      }
    });
  }

  if (resultNames.length != 0) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    Navigator.pushNamed(context, '/ResultsScreen');
  } else {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    double width = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Center(
          child: Text(
            'Failed',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
              fontSize: width * 0.08,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: width * 0.3,
              width: width * 0.5,
              child: Center(
                child: Text(
                  'No compatible blood donors\navailable',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.06,
                  ),
                ),
              ),
            ),
            Container(
              width: width * 0.8,
              height: width * 0.12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(width),
                child: FlatButton(
                  height: width * 0.12,
                  color: Colors.redAccent,
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: width * 0.07,
                      fontWeight: FontWeight.bold,
                      letterSpacing: width * 0.005,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(width * 0.1),
        ),
      ),
      barrierDismissible: true,
    );
  }
}

//................................................................
//................................................................
//................................................................
//................................................................

CallPerson(String numberPhone) async {
  String url = 'tel:' + numberPhone;
  if (await canLaunch(url)) {
    await launch(url);
  }
}

SMSPerson(String numberPhone) async {
  String url = 'sms:' + numberPhone;
  if (await canLaunch(url)) {
    await launch(url);
  }
}

//ResultsScreen screen of the app
class ResultsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        centerTitle: true,
        title: Text(
          'Navier Blood',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: width * 0.06,
            letterSpacing: width * 0.006,
            wordSpacing: width * 0.01,
          ),
        ),
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            Container(
              height: width * 0.06,
            ),
            Text(
              'Compatible blood donors',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: width * 0.06,
              ),
            ),
            Container(
              height: width * 0.05,
            ),
            Expanded(
              child: buildSearchResults(context),
            ),
          ],
        ),
      ),
    );
  }
}

Widget buildSearchResults(context) {
  double width = MediaQuery.of(context).size.width;
  return ListView.builder(
    itemCount: resultNames.length,
    itemBuilder: (context, index) {
      return Container(
        //width: width/2,
        height: width * 0.5,
        margin: EdgeInsets.fromLTRB(
            width * 0.04, width * 0.02, width * 0.04, width * 0.02),
        //padding: EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(width * 0.07),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: width * 0.03,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.person,
                  color: Colors.white,
                ),
                Container(
                  width: width * 0.04,
                ),
                Center(
                  child: AutoSizeText(
                    '${resultNames[index]}',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    maxFontSize: 50,
                    minFontSize: 10,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: width * 0.06,
                    ),
                  ),
                ),
              ],
            ),
            Container(
              height: width * 0.03,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.white,
                ),
                Container(
                  width: width * 0.04,
                ),
                Center(
                  child: AutoSizeText(
                    '${resultCities[index]}',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    maxFontSize: 50,
                    minFontSize: 10,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: width * 0.05,
                    ),
                  ),
                ),
              ],
            ),
            Container(
              height: width * 0.03,
            ),
            Center(
              child: AutoSizeText(
                'Group : ' + '${resultBloods[index]}',
                textAlign: TextAlign.center,
                maxLines: 1,
                maxFontSize: 50,
                minFontSize: 10,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.05,
                ),
              ),
            ),
            Container(
              height: width * 0.03,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    SMSPerson(resultPhones[index]);
                  },
                  child: Container(
                    width: width * 0.4,
                    height: width * 0.13,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(width),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: width * 0.02,
                        ),
                        Icon(
                          Icons.message,
                          color: Colors.white,
                        ),
                        Container(
                          width: width * 0.02,
                        ),
                        Expanded(
                          child: AutoSizeText(
                            'Send Message',
                            maxLines: 1,
                            maxFontSize: 50,
                            minFontSize: 10,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: width * 0.04,
                            ),
                          ),
                        ),
                        Container(
                          width: width * 0.02,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: width * 0.04,
                ),
                GestureDetector(
                  onTap: () {
                    CallPerson(resultPhones[index]);
                  },
                  child: Container(
                    width: width * 0.3,
                    height: width * 0.13,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(width),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: width * 0.02,
                        ),
                        Icon(
                          Icons.call,
                          color: Colors.white,
                        ),
                        Container(
                          width: width * 0.02,
                        ),
                        Expanded(
                          child: AutoSizeText(
                            'Call Now',
                            maxLines: 1,
                            maxFontSize: 50,
                            minFontSize: 10,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: width * 0.04,
                            ),
                          ),
                        ),
                        Container(
                          width: width * 0.02,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Container(
              height: width * 0.03,
            ),
          ],
        ),
      );
    },
  );
}

//--------------------------------------------
//--------------------------------------------
//--------------------------------------------
//AppealScreen screen of the app
class AppealScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        centerTitle: true,
        title: Text(
          'Navier Blood',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: width * 0.06,
            letterSpacing: width * 0.006,
            wordSpacing: width * 0.01,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: width * 0.04,
            ),
            Center(
              child: Image.asset(
                'images/logo300.png',
                width: width * 0.5,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
            Container(
              height: width * 0.04,
            ),
            Center(
              child: AutoSizeText(
                'People with blood requirements\nwill contact you directly',
                maxLines: 2,
                maxFontSize: 50,
                minFontSize: 10,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.058,
                ),
              ),
            ),
            Container(
              height: width * 0.05,
            ),
            Center(
              child: AutoSizeText(
                'Thank You',
                maxLines: 2,
                maxFontSize: 50,
                minFontSize: 10,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.05,
                ),
              ),
            ),
            Container(
              height: width * 0.025,
            ),
            Container(
              height: width * 0.02,
              color: Colors.redAccent,
            ),
            Container(
              height: width * 0.025,
            ),
            Center(
              child: AutoSizeText(
                //'Help in other ways',
                'Consider donating money to support our operations and app development.',
                maxLines: 4,
                maxFontSize: 50,
                minFontSize: 10,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.065,
                ),
              ),
            ),
            Container(
              height: width * 0.1,
            ),
            Container(
              width: width * 0.8,
              height: width * 0.12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(width),
                child: FlatButton(
                  height: width * 0.12,
                  color: Colors.redAccent,
                  child: Text(
                    'Donate',
                    //'Support Our Cause',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: width * 0.07,
                      fontWeight: FontWeight.bold,
                      letterSpacing: width * 0.005,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/MoneyOptionsScreen');
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//................................................................
//................................................................
//................................................................
//MoneyOptionsScreen..............................
class MoneyOptionsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    GetPriceValues(context, width);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        centerTitle: true,
        title: Text(
          'Navier Blood',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: width * 0.06,
            letterSpacing: width * 0.006,
            wordSpacing: width * 0.01,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(
              height: width * 0.03,
            ),
            Center(
              child: Text(
                'Select amount',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: MediaQuery.of(context).size.width * 0.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            MoneyOptions(),
            Container(
              height: width * 0.1,
            ),
            Container(
              width: width * 0.8,
              height: width * 0.12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(width),
                child: FlatButton(
                  height: width * 0.12,
                  color: Colors.redAccent,
                  child: Text(
                    'Donate',
                    //'Support',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: width * 0.07,
                      fontWeight: FontWeight.bold,
                      letterSpacing: width * 0.005,
                    ),
                  ),
                  onPressed: () {
                    if (buyThisIndex != -1) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Center(
                            child: Text(
                              'Loading',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: width * 0.08,
                              ),
                            ),
                          ),
                          content: Container(
                            height: width * 0.5,
                            width: width * 0.5,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.redAccent),
                              strokeWidth: width * 0.05,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(width * 0.1),
                          ),
                        ),
                        barrierDismissible: false,
                      );
                      SubscribingNow(context, width);
                    } else {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Center(
                            child: Text(
                              'Alert',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: width * 0.08,
                              ),
                            ),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                height: width * 0.3,
                                width: width * 0.5,
                                child: Center(
                                  child: AutoSizeText(
                                    'Please select an amount to donate',
                                    maxLines: 3,
                                    maxFontSize: 50,
                                    minFontSize: 10,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: width * 0.06,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: width * 0.8,
                                height: width * 0.12,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(width),
                                  child: FlatButton(
                                    height: width * 0.12,
                                    color: Colors.redAccent,
                                    child: Text(
                                      'OK',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: width * 0.07,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: width * 0.005,
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(width * 0.1),
                          ),
                        ),
                        barrierDismissible: true,
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<String> localPrices = [
  '\$ 50',
  '\$ 100',
  '\$ 150',
  '\$ 200',
  '\$ 300',
  '\$ 400'
];

void GetPriceValues(context, width) async {
  InAppPurchaseConnection.enablePendingPurchases();
  final bool available = await InAppPurchaseConnection.instance.isAvailable();
  if (available) {
    const Set<String> _kIds = {
      'nba1',
      'nbm100',
      'nbm150',
      'nbm200',
      'nbm300',
      'nbm400'
    };
    final ProductDetailsResponse response =
        await InAppPurchaseConnection.instance.queryProductDetails(_kIds);
    if (response.notFoundIDs.isEmpty) {
      List<ProductDetails> products = response.productDetails;

      MoneyOptions_key.currentState.setState(() {
        int newIndex = 0;
        for (ProductDetails singleProduct in products) {
          localPrices[newIndex] = singleProduct.price;
          newIndex++;
        }
      });
    }
  } else {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Center(
          child: Text(
            'Failed',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
              fontSize: width * 0.08,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: width * 0.3,
              width: width * 0.5,
              child: Center(
                child: AutoSizeText(
                  'Unable to connect to Play Store',
                  maxLines: 3,
                  maxFontSize: 50,
                  minFontSize: 10,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.06,
                  ),
                ),
              ),
            ),
            Container(
              width: width * 0.8,
              height: width * 0.12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(width),
                child: FlatButton(
                  height: width * 0.12,
                  color: Colors.redAccent,
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: width * 0.07,
                      fontWeight: FontWeight.bold,
                      letterSpacing: width * 0.005,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(width * 0.1),
        ),
      ),
      barrierDismissible: true,
    );
  }
}

void SubscribingNow(context, width) async {
  InAppPurchaseConnection.enablePendingPurchases();
  final bool available = await InAppPurchaseConnection.instance.isAvailable();
  if (available) {
    const Set<String> _kIds = {
      'nba1',
      'nbm100',
      'nbm150',
      'nbm200',
      'nbm300',
      'nbm400'
    };
    final ProductDetailsResponse response =
        await InAppPurchaseConnection.instance.queryProductDetails(_kIds);
    //final QueryPurchaseDetailsResponse productDetails = await InAppPurchaseConnection.instance.queryPastPurchases();
    if (response.notFoundIDs.isEmpty) {
      List<ProductDetails> products = response.productDetails;

      StreamSubscription<List<PurchaseDetails>> _subscription;

      Stream purchaseUpdated =
          InAppPurchaseConnection.instance.purchaseUpdatedStream;
      _subscription = purchaseUpdated.listen((purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList, context, width);
      }, onDone: () {
        //InAppPurchaseConnection.instance.completePurchase(productDetails.pastPurchases.last);
        _subscription.cancel();
      }, onError: (error) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Center(
              child: Text(
                'Failed',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.08,
                ),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: width * 0.3,
                  width: width * 0.5,
                  child: Center(
                    child: AutoSizeText(
                      'Unexpected error occured',
                      maxLines: 3,
                      maxFontSize: 50,
                      minFontSize: 10,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.06,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: width * 0.8,
                  height: width * 0.12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(width),
                    child: FlatButton(
                      height: width * 0.12,
                      color: Colors.redAccent,
                      child: Text(
                        'OK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.07,
                          fontWeight: FontWeight.bold,
                          letterSpacing: width * 0.005,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(width * 0.1),
            ),
          ),
          barrierDismissible: true,
        );
      });

      final PurchaseParam purchaseParam =
          PurchaseParam(productDetails: products[buyThisIndex]);
      InAppPurchaseConnection.instance
          .buyNonConsumable(purchaseParam: purchaseParam);
    } else {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Center(
            child: Text(
              'Failed',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: width * 0.08,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: width * 0.3,
                width: width * 0.5,
                child: Center(
                  child: AutoSizeText(
                    'Unable to find any products',
                    maxLines: 3,
                    maxFontSize: 50,
                    minFontSize: 10,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: width * 0.06,
                    ),
                  ),
                ),
              ),
              Container(
                width: width * 0.8,
                height: width * 0.12,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(width),
                  child: FlatButton(
                    height: width * 0.12,
                    color: Colors.redAccent,
                    child: Text(
                      'OK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: width * 0.07,
                        fontWeight: FontWeight.bold,
                        letterSpacing: width * 0.005,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(width * 0.1),
          ),
        ),
        barrierDismissible: true,
      );
    }
  } else {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Center(
          child: Text(
            'Failed',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
              fontSize: width * 0.08,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: width * 0.3,
              width: width * 0.5,
              child: Center(
                child: AutoSizeText(
                  'Unable to connect to Play Store',
                  maxLines: 3,
                  maxFontSize: 50,
                  minFontSize: 10,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.06,
                  ),
                ),
              ),
            ),
            Container(
              width: width * 0.8,
              height: width * 0.12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(width),
                child: FlatButton(
                  height: width * 0.12,
                  color: Colors.redAccent,
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: width * 0.07,
                      fontWeight: FontWeight.bold,
                      letterSpacing: width * 0.005,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(width * 0.1),
        ),
      ),
      barrierDismissible: true,
    );
  }
}

void _listenToPurchaseUpdated(
    List<PurchaseDetails> purchaseDetailsList, context, width) {
  purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.status == PurchaseStatus.pending) {
      //showPendingUI();  purchase is pending progress bar
    } else {
      if (purchaseDetails.status == PurchaseStatus.error) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Center(
              child: Text(
                'Failed',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.08,
                ),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: width * 0.3,
                  width: width * 0.5,
                  child: Center(
                    child: AutoSizeText(
                      'Unexpected error occured',
                      maxLines: 3,
                      maxFontSize: 50,
                      minFontSize: 10,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.06,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: width * 0.8,
                  height: width * 0.12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(width),
                    child: FlatButton(
                      height: width * 0.12,
                      color: Colors.redAccent,
                      child: Text(
                        'OK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.07,
                          fontWeight: FontWeight.bold,
                          letterSpacing: width * 0.005,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(width * 0.1),
            ),
          ),
          barrierDismissible: true,
        );
      } else if (purchaseDetails.status == PurchaseStatus.purchased) {
        //thank the user here for donation
        //bool valid = await _verifyPurchase(purchaseDetails);
        /*if (true)
        {
          //deliverProduct(purchaseDetails);
        }
        else
          {
          //_handleInvalidPurchase(purchaseDetails);
          return;
        }*/
      }
      /*if (Platform.isAndroid) {
        if (!_kAutoConsume && purchaseDetails.productID == _kConsumableId) {
          await InAppPurchaseConnection.instance.consumePurchase(purchaseDetails);
        }
      }*/
      if (purchaseDetails.pendingCompletePurchase) {
        await InAppPurchaseConnection.instance
            .completePurchase(purchaseDetails);
        await SaveDonationStat();
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Center(
              child: Text(
                'Success',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.08,
                ),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: width * 0.3,
                  width: width * 0.5,
                  child: Center(
                    child: AutoSizeText(
                      'Thank you for your donation',
                      maxLines: 3,
                      maxFontSize: 50,
                      minFontSize: 10,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.06,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: width * 0.8,
                  height: width * 0.12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(width),
                    child: FlatButton(
                      height: width * 0.12,
                      color: Colors.redAccent,
                      child: Text(
                        'OK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.07,
                          fontWeight: FontWeight.bold,
                          letterSpacing: width * 0.005,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(width * 0.1),
            ),
          ),
          barrierDismissible: true,
        );
      }
    }
  });
}

Future<void> SaveDonationStat() async {
  await Firebase.initializeApp();

  await FirebaseMessaging.instance.unsubscribeFromTopic('donation');

  final prefs = await SharedPreferences.getInstance();

  String myPhone = prefs.getString('phone') ?? 'phone';

  if (myPhone != 'phone') {
    FirebaseDatabase myRealData = FirebaseDatabase.instance;
    DatabaseReference myRealDataRef = myRealData.reference();

    DatabaseReference newUserRef = myRealDataRef.child('users').child(myPhone);

    newUserRef.child('donation').set(true);
    newUserRef.child('payment').set(buyThisIndex);
  }
}

final MoneyOptions_key = GlobalKey<_MoneyOptions_State>();
String selectedAmount = '';
int buyThisIndex = -1;

void ChangeMoney(int passedBuyIndex) {
  MoneyOptions_key.currentState.setState(() {
    buyThisIndex = passedBuyIndex;
  });
}

class MoneyOptions extends StatefulWidget {
  MoneyOptions({Key key}) : super(key: key);
  @override
  Key get key => MoneyOptions_key;
  @override
  _MoneyOptions_State createState() => _MoneyOptions_State();
}

class _MoneyOptions_State extends State<MoneyOptions> {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Container(
      child: Container(
        child: Column(
          children: [
            Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      MoneyButtonsFormat(context, 0),
                      MoneyButtonsFormat(context, 2),
                      MoneyButtonsFormat(context, 4),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      MoneyButtonsFormat(context, 1),
                      MoneyButtonsFormat(context, 3),
                      MoneyButtonsFormat(context, 5),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget MoneyButtonsFormat(context, int listIndex) {
  double width = MediaQuery.of(context).size.width;
  return GestureDetector(
    onTap: () {
      ChangeMoney(listIndex);
    },
    child: Container(
      margin: EdgeInsets.symmetric(vertical: width * 0.05),
      alignment: Alignment.center,
      width: width * 0.45,
      height: width * 0.18,
      decoration: BoxDecoration(
        color: buyThisIndex == listIndex ? Colors.redAccent : Colors.blueAccent,
        borderRadius: BorderRadius.circular(width),
      ),
      child: AutoSizeText(
        localPrices[listIndex],
        maxLines: 1,
        maxFontSize: 50,
        minFontSize: 10,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: width * 0.07,
        ),
      ),
    ),
  );
}

//................................................................
//................................................................
//................................................................
//................................................................
//................................................................

var dataBaseCountries = {
  "Afghanistan": "AF",
  "Aland Islands": "AX",
  "Albania": "AL",
  "Algeria": "DZ",
  "American Samoa": "AS",
  "Andorra": "AD",
  "Angola": "AO",
  "Anguilla": "AI",
  "Antarctica": "AQ",
  "Antigua And Barbuda": "AG",
  "Argentina": "AR",
  "Armenia": "AM",
  "Aruba": "AW",
  "Australia": "AU",
  "Austria": "AT",
  "Azerbaijan": "AZ",
  "Bahamas The": "BS",
  "Bahrain": "BH",
  "Bangladesh": "BD",
  "Barbados": "BB",
  "Belarus": "BY",
  "Belgium": "BE",
  "Belize": "BZ",
  "Benin": "BJ",
  "Bermuda": "BM",
  "Bhutan": "BT",
  "Bolivia": "BO",
  "Bosnia and Herzegovina": "BA",
  "Botswana": "BW",
  "Bouvet Island": "BV",
  "Brazil": "BR",
  "British Indian Ocean Territory": "IO",
  "Brunei": "BN",
  "Bulgaria": "BG",
  "Burkina Faso": "BF",
  "Burundi": "BI",
  "Cambodia": "KH",
  "Cameroon": "CM",
  "Canada": "CA",
  "Cape Verde": "CV",
  "Cayman Islands": "KY",
  "Central African Republic": "CF",
  "Chad": "TD",
  "Chile": "CL",
  "China": "CN",
  "Christmas Island": "CX",
  "Cocos (Keeling) Islands": "CC",
  "Colombia": "CO",
  "Comoros": "KM",
  "Congo": "CG",
  "Congo The Democratic Republic Of The": "CD",
  "Cook Islands": "CK",
  "Costa Rica": "CR",
  "Cote D'Ivoire (Ivory Coast)": "CI",
  "Croatia (Hrvatska)": "HR",
  "Cuba": "CU",
  "Curacao": "CW",
  "Cyprus": "CY",
  "Czech Republic": "CZ",
  "Denmark": "DK",
  "Djibouti": "DJ",
  "Dominica": "DM",
  "Dominican Republic": "DO",
  "East Timor": "TL",
  "Ecuador": "EC",
  "Egypt": "EG",
  "El Salvador": "SV",
  "Equatorial Guinea": "GQ",
  "Eritrea": "ER",
  "Estonia": "EE",
  "Ethiopia": "ET",
  "Falkland Islands": "FK",
  "Faroe Islands": "FO",
  "Fiji Islands": "FJ",
  "Finland": "FI",
  "France": "FR",
  "French Guiana": "GF",
  "French Polynesia": "PF",
  "French Southern Territories": "TF",
  "Gabon": "GA",
  "Gambia The": "GM",
  "Georgia": "GE",
  "Germany": "DE",
  "Ghana": "GH",
  "Gibraltar": "GI",
  "Greece": "GR",
  "Greenland": "GL",
  "Grenada": "GD",
  "Guadeloupe": "GP",
  "Guam": "GU",
  "Guatemala": "GT",
  "Guernsey and Alderney": "GG",
  "Guinea": "GN",
  "Guinea-Bissau": "GW",
  "Guyana": "GY",
  "Haiti": "HT",
  "Heard and McDonald Islands": "HM",
  "Honduras": "HN",
  "Hong Kong SAR": "HK",
  "Hungary": "HU",
  "Iceland": "IS",
  "India": "IN",
  "Indonesia": "ID",
  "Iran": "IR",
  "Iraq": "IQ",
  "Ireland": "IE",
  "Israel": "IL",
  "Italy": "IT",
  "Jamaica": "JM",
  "Japan": "JP",
  "Jersey": "JE",
  "Jordan": "JO",
  "Kazakhstan": "KZ",
  "Kenya": "KE",
  "Kiribati": "KI",
  "Korea North": "KP",
  "Korea South": "KR",
  "Kosovo": "XK",
  "Kuwait": "KW",
  "Kyrgyzstan": "KG",
  "Laos": "LA",
  "Latvia": "LV",
  "Lebanon": "LB",
  "Lesotho": "LS",
  "Liberia": "LR",
  "Libya": "LY",
  "Liechtenstein": "LI",
  "Lithuania": "LT",
  "Luxembourg": "LU",
  "Macau SAR": "MO",
  "Macedonia": "MK",
  "Madagascar": "MG",
  "Malawi": "MW",
  "Malaysia": "MY",
  "Maldives": "MV",
  "Mali": "ML",
  "Malta": "MT",
  "Man (Isle of)": "IM",
  "Marshall Islands": "MH",
  "Martinique": "MQ",
  "Mauritania": "MR",
  "Mauritius": "MU",
  "Mayotte": "YT",
  "Mexico": "MX",
  "Micronesia": "FM",
  "Moldova": "MD",
  "Monaco": "MC",
  "Mongolia": "MN",
  "Montenegro": "ME",
  "Montserrat": "MS",
  "Morocco": "MA",
  "Mozambique": "MZ",
  "Myanmar": "MM",
  "Namibia": "NA",
  "Nauru": "NR",
  "Nepal": "NP",
  "Netherlands Antilles": "AN",
  "Netherlands The": "NL",
  "New Caledonia": "NC",
  "New Zealand": "NZ",
  "Nicaragua": "NI",
  "Niger": "NE",
  "Nigeria": "NG",
  "Niue": "NU",
  "Norfolk Island": "NF",
  "Northern Mariana Islands": "MP",
  "Norway": "NO",
  "Oman": "OM",
  "Pakistan": "PK",
  "Palau": "PW",
  "Palestinian Territory Occupied": "PS",
  "Panama": "PA",
  "Papua new Guinea": "PG",
  "Paraguay": "PY",
  "Peru": "PE",
  "Philippines": "PH",
  "Pitcairn Island": "PN",
  "Poland": "PL",
  "Portugal": "PT",
  "Puerto Rico": "PR",
  "Qatar": "QA",
  "Reunion": "RE",
  "Romania": "RO",
  "Russia": "RU",
  "Rwanda": "RW",
  "Saint Helena": "SH",
  "Saint Kitts And Nevis": "KN",
  "Saint Lucia": "LC",
  "Saint Pierre and Miquelon": "PM",
  "Saint Vincent And The Grenadines": "VC",
  "Saint-Barthelemy": "BL",
  "Saint-Martin (French part)": "MF",
  "Samoa": "WS",
  "San Marino": "SM",
  "Sao Tome and Principe": "ST",
  "Saudi Arabia": "SA",
  "Senegal": "SN",
  "Serbia": "RS",
  "Seychelles": "SC",
  "Sierra Leone": "SL",
  "Singapore": "SG",
  "Slovakia": "SK",
  "Slovenia": "SI",
  "Solomon Islands": "SB",
  "Somalia": "SO",
  "South Africa": "ZA",
  "South Georgia": "GS",
  "South Sudan": "SS",
  "Spain": "ES",
  "Sri Lanka": "LK",
  "Sudan": "SD",
  "Suriname": "SR",
  "Svalbard And Jan Mayen Islands": "SJ",
  "Swaziland": "SZ",
  "Sweden": "SE",
  "Switzerland": "CH",
  "Syria": "SY",
  "Taiwan": "TW",
  "Tajikistan": "TJ",
  "Tanzania": "TZ",
  "Thailand": "TH",
  "Togo": "TG",
  "Tokelau": "TK",
  "Tonga": "TO",
  "Trinidad And Tobago": "TT",
  "Tunisia": "TN",
  "Turkey": "TR",
  "Turkmenistan": "TM",
  "Turks And Caicos Islands": "TC",
  "Tuvalu": "TV",
  "Uganda": "UG",
  "Ukraine": "UA",
  "United Arab Emirates": "AE",
  "United Kingdom": "GB",
  "United States": "US",
  "United States Minor Outlying Islands": "UM",
  "Uruguay": "UY",
  "Uzbekistan": "UZ",
  "Vanuatu": "VU",
  "Vatican City State (Holy See)": "VA",
  "Venezuela": "VE",
  "Vietnam": "VN",
  "Virgin Islands (British)": "VG",
  "Virgin Islands (US)": "VI",
  "Wallis And Futuna Islands": "WF",
  "Western Sahara": "EH",
  "Yemen": "YE",
  "Zambia": "ZM",
  "Zimbabwe": "ZW"
};
