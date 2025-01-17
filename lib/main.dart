import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:localeat/customer_user/customer_home.dart';
import 'package:localeat/customer_user/customer_login.dart';
import 'package:localeat/customer_user/customer_sign_up.dart';
import 'package:localeat/miscellaneous/cart_bloc.dart';
import 'package:localeat/miscellaneous/color_bloc.dart';
import 'package:localeat/miscellaneous/globals.dart' as globals;
import 'package:localeat/miscellaneous/Menu.dart';
import 'package:localeat/order_management/cart.dart';
import 'package:localeat/order_management/food_item_template.dart';
import 'package:localeat/restaurant_user/restaurant_login.dart';
import 'package:localeat/restaurant_user/restaurant_sign_up.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location_permissions/location_permissions.dart';


//get current position of the user
Future<Position> determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  await LocationPermissions().requestPermissions();

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.deniedForever) {
    return Future.error(
        'Location permissions are permantly denied, we cannot request permissions.');
  }

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      return Future.error(
          'Location permissions are denied (actual value: $permission).');
    }
  }

  Position userPosition = await Geolocator.getCurrentPosition();

  print('\nUser\'s latitude: ${userPosition.latitude} longitude: ${userPosition.longitude}');
  //User's latitude: 18.6114617 longitude: 73.7470233
  //User's latitude: 24.584475 longitude: 73.7195267
  double distanceInMeters = Geolocator.distanceBetween(18.6114617, 73.7470233, 24.584475, 73.7195267);
  print('Distance between you and the user in udaipur: ${distanceInMeters}');
  return userPosition;
}

//get restaurant data
Future<void> getData() async {
  QuerySnapshot querySnapshot;
  // Get docs from collection reference
  querySnapshot = await Firestore.instance.collection('Restaurant').getDocuments();

  for(var i=0;i<querySnapshot.documents.length;i++){
    String name = querySnapshot.documents[i].data['name'];
    String location = querySnapshot.documents[i].data['location'];
    String uri = querySnapshot.documents[i].data['image_url'];
    String uid = querySnapshot.documents[i].data['uid'];
    var menu = querySnapshot.documents[i].data['menu'];
    var latitude = querySnapshot.documents[i].data['coordinates'][0];
    var longitude = querySnapshot.documents[i].data['coordinates'][1];
    //print('${latitude} and ${longitude}');
    var restaurant = globals.Restaurant(name: name, uri:uri, uid:uid, location: location, menu: menu,latitude: latitude,longitude: longitude);
    globals.restaurantList.add(restaurant);
  }

}
void main() {
  debugDefaultTargetPlatformOverride =TargetPlatform.fuchsia;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    getData();
    determinePosition();
    return BlocProvider(
      blocs: [
        //add yours BLoCs controlles
        Bloc((i) => CartListBloc()),
        Bloc((i) => ColorBloc()),
      ],
      child: MaterialApp(
          title: "Local Eat",
          home: FirstPage(),
          debugShowCheckedModeBanner: false,
          routes: <String, WidgetBuilder>{
            '/landingpage': (BuildContext context) => new MyApp(),
            '/signup': (BuildContext context) => new SignUpPage(),
            '/homepage': (BuildContext context) => new Home(),
            '/signin': (BuildContext context) => new SignInPage(),
            '/rlogin': (BuildContext context) => new RestaurantLogin(),
            '/rsignup': (BuildContext context) => new RestaurantSignup(),
            '/firstpage': (BuildContext context) => new FirstPage(),
          }),
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {


  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  Widget build(BuildContext context) {

    // List<Restaurant> restaurantList = [Restaurant(name:'Popu Popu',uri:'https://sevenrooms.com/wp-content/uploads/2020/03/coronavirusrestaurants-768x512.jpg',uid:'Achi678',location:'Kiska ghar')];
    //
    // print(restaurantList);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      drawer: Drawer(
        child: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              color: globals.accent_color,
              child: Center(
                child: Column(
                  children: <Widget>[
                    Container(
                      width: 100,
                      height: 100,
                      margin: EdgeInsets.only(top: 30, bottom: 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                            image: NetworkImage(
                                'https://cdn2.iconfinder.com/data/icons/website-icons/512/User_Avatar-512.png'),
                            fit: BoxFit.fill),
                      ),
                    ),
                    Text(
                      'Name: user',
                      style: TextStyle(fontSize: 22, color: Colors.black87),
                    ),
                    Text(
                      'Email: user@gmail.com',
                      style: TextStyle(color: Colors.black87),
                    )
                  ],
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text(
                'Setting',
                style: TextStyle(fontSize: 18),
              ),
              onTap: null,
            ),
            ListTile(
              leading: Icon(Icons.arrow_back),
              title: Text(
                'Logout',
                style: TextStyle(fontSize: 18),
              ),
              onTap: () {
                _googleSignIn.signOut();
                print('User Signed Out');
                Navigator.of(context).pop();
                FirebaseAuth.instance.signOut().then((value) {
                  Navigator.of(context).pushReplacementNamed('/firstpage');
                }).catchError((e) {
                  print(e);
                });
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
          child: Container(
            child: ListView(
              children: <Widget>[
                FirstHalf(),
                SizedBox(height: 45),
                for (var restaurant in globals.restaurantList)
                  Builder(
                    builder: (context) {
                      return RestaurantTile(restaurant: restaurant);
                    },
                  )
              ],
            ),
          )),
    );
  }
}

class FirstHalf extends StatelessWidget {
  const FirstHalf({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(35, 25, 0, 0),
      child: Column(
        children: <Widget>[
          CustomAppBar(),
          //you could also use the spacer widget to give uneven distances, i just decided to go with a sizebox
          SizedBox(height: 30),
          title(),
          SizedBox(height: 45),
          // categories(),
        ],
      ),
    );
  }
}


class Items extends StatelessWidget {
  Items({
    @required this.leftAligned,
    @required this.imgUrl,
    @required this.itemName,
    @required this.itemPrice,
    @required this.hotel,
  });

  final bool leftAligned;
  final String imgUrl;
  final String itemName;
  final double itemPrice;
  final String hotel;

  @override
  Widget build(BuildContext context) {
    double containerPadding = 45;
    double containerBorderRadius = 10;

    return Column(
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(
            left: leftAligned ? 0 : containerPadding,
            right: leftAligned ? containerPadding : 0,
          ),
          child: Column(
            children: <Widget>[
              Container(
                width: double.infinity,
                height: 200,
                decoration:
                BoxDecoration(borderRadius: BorderRadius.circular(10)),
                child: ClipRRect(
                  borderRadius: BorderRadius.horizontal(
                    left: leftAligned
                        ? Radius.circular(0)
                        : Radius.circular(containerBorderRadius),
                    right: leftAligned
                        ? Radius.circular(containerBorderRadius)
                        : Radius.circular(0),
                  ),
                  child: Image.network(
                    imgUrl,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Container(
                  padding: EdgeInsets.only(
                    left: leftAligned ? 20 : 0,
                    right: leftAligned ? 0 : 20,
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(itemName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  )),
                            ),
                            Text("\₹$itemPrice",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                )),
                          ],
                        ),
                        SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: RichText(
                            text: TextSpan(
                                style: TextStyle(
                                    color: Colors.black45, fontSize: 15),
                                children: [
                                  TextSpan(text: "by "),
                                  TextSpan(
                                      text: hotel,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700))
                                ]),
                          ),
                        ),
                        SizedBox(height: containerPadding),
                      ])),
            ],
          ),
        )
      ],
    );
  }
}

class CategoryListItem extends StatelessWidget {
  const CategoryListItem({
    Key key,
    @required this.categoryIcon,
    @required this.categoryName,
    @required this.availability,
    @required this.selected,
  }) : super(key: key);

  final IconData categoryIcon;
  final String categoryName;
  final int availability;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 20),
      padding: EdgeInsets.fromLTRB(10, 10, 10, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        color: selected ? globals.accent_color : Colors.white,
        border: Border.all(
            color: selected ? Colors.transparent : Colors.grey[200],
            width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[100],
            blurRadius: 15,
            offset: Offset(15, 0),
            spreadRadius: 5,
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                    color: selected ? Colors.transparent : Colors.grey[200],
                    width: 1.5)),
            child: Icon(
              categoryIcon,
              color: Colors.black,
              size: 30,
            ),
          ),
          SizedBox(height: 10),
          Text(
            categoryName,
            style: TextStyle(
                fontWeight: FontWeight.w700, color: Colors.black, fontSize: 15),
          ),
          Container(
            margin: EdgeInsets.fromLTRB(0, 6, 0, 10),
            width: 1.5,
            height: 15,
            color: Colors.black26,
          ),
          Text(
            availability.toString(),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          )
        ],
      ),
    );
  }
}

Widget searchBar() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: <Widget>[
      Icon(
        Icons.search,
        color: Colors.black45,
      ),
      SizedBox(width: 20),
      Expanded(
        child: TextField(
          decoration: InputDecoration(
              hintText: "Search....",
              contentPadding: EdgeInsets.symmetric(vertical: 10),
              hintStyle: TextStyle(
                color: Colors.black87,
              ),
              border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.red))),
        ),
      ),
    ],
  );
}

Widget title() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.start,
    children: <Widget>[
      SizedBox(width: 45),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "Local",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 30,
            ),
          ),
          Text(
            "Eat",
            style: TextStyle(
              fontWeight: FontWeight.w200,
              fontSize: 30,
            ),
          ),
        ],
      )
    ],
  );
}

class CustomAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final CartListBloc bloc = BlocProvider.getBloc<CartListBloc>();
    return Container(
      margin: EdgeInsets.only(bottom: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Icon(Icons.menu),
          StreamBuilder(
            stream: bloc.listStream,
            builder: (context, snapshot) {
              List<FoodItem> foodItems = snapshot.data;
              int length = foodItems != null ? foodItems.length : 0;
              return buildGestureDetector(length, context, foodItems);
            },
          )
        ],
      ),
    );
  }


  GestureDetector buildGestureDetector(
      int length, BuildContext context, List<FoodItem> foodItems) {
    return GestureDetector(
      onTap: () {
        if (length >= 0) {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => Cart()));
        } else {
          return;
        }
      },
      child: Container(
        margin: EdgeInsets.only(right: 30),
        child: Text(length.toString()),
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: globals.accent_color, borderRadius: BorderRadius.circular(50)),
      ),
    );
  }
}

class RestaurantTile extends StatelessWidget{

  RestaurantTile({
    @required this.restaurant,
  });

  final globals.Restaurant restaurant;

  @override
  Widget build(BuildContext context){
    return InkWell(
      onTap: ()=>{
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => Menu(this.restaurant,)))
      } ,
        child:Container(
      margin:const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0) ,
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
      decoration: BoxDecoration(
        color:Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 1,
            offset: Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            decoration:
            BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
              child: Image.network(
                restaurant.uri,
                fit: BoxFit.fitWidth,
                height: 200 ,
              ),
            ),
          ),
          Align(
              alignment: Alignment.centerLeft,
              child:Padding(
                  padding: EdgeInsets.fromLTRB(5, 10, 5, 5),
                  child:Text(
                    restaurant.name,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black
                    ),
                  ))
          ),
          Align(
            alignment: Alignment.centerLeft,
            child:Padding(
                padding: EdgeInsets.fromLTRB(5, 5, 5, 10),
                child:Text(
                    restaurant.location,
                    style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.black38
                    )
                )),
          ),
        ],
      ),
    )
    );
  }
}

