import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:localeat/miscellaneous/provider.dart';
import 'package:localeat/order_management/food_item_template.dart';

class CartListBloc extends BlocBase {
  CartListBloc();

  var _listController = BehaviorSubject<List<FoodItem>>.seeded([]);

//provider class
  CartProvider provider = CartProvider();

//output
  Stream<List<FoodItem>> get listStream => _listController.stream;

//input
  Sink<List<FoodItem>> get listSink => _listController.sink;

  addToList(FoodItem foodItem) {
    listSink.add(provider.addToList(foodItem));
  }

  removeFromList(FoodItem foodItem) {
    listSink.add(provider.removeFromList(foodItem));
  }

//dispose will be called automatically by closing its streams
  @override
  void dispose() {
    _listController.close();
    super.dispose();
  }
}
